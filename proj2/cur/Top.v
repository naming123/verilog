`timescale 1ns / 10ps
//============================================================================
//  Top : 16x16 2D-DCT (512x512 JPEG front-end)
//
//  데이터 경로 (모두 자료 2번 구조 + 골든 검증 완료):
//    MEM_IN(128b) -> Row dct16(shift-add,>>9) -> dct1_r
//                 -> TP1/TP2 ping-pong (BW13, transpose)
//                 -> Col dct16(shift-add,SH=0) -> dct2_r
//                 -> Quant (DC: >>>10, AC: >>>8 + saturate) -> q_word(192b)
//                 -> OTP1/OTP2 ping-pong (BW12, transpose)
//                 -> MEM_OUT(192b)
//
//  계수 = round(coef*512)  (MATLAB func_DCT_Coefficient_quant round 버전과 일치)
//
//  TPmem_16x16 동작 : i_enable=1 인 동안 16 write -> 16 read 자동 토글,
//                     counter[4]==1 구간에서 o_en=1 & transpose 출력(1cyc reg).
//  ping-pong : phase[4] 로 두 TP 에 write 를 번갈아 배정, read 는 자동 정렬.
//============================================================================
module Top (
    input clk,
    input rstn
);

    //========================================================================
    // [1] 입력 메모리 + 입력 카운터
    //   16384 word(=1024블록 x 16row) 를 순차 read
    //========================================================================
    reg  [14:0]  in_cnt;
    wire         in_run  = ~in_cnt[14];     // 16384개 동안만 진행
    wire [13:0]  addr_in = in_cnt[13:0];
    wire [127:0] mem_in_do;

    always @(posedge clk) begin
        if (!rstn)       in_cnt <= 15'd0;
        else if (in_run) in_cnt <= in_cnt + 15'd1;
    end

    rflp16384x128mx16 MEM_IN (
        .DO(mem_in_do), .DIN(128'd0),
        .RA(addr_in[13:4]), .CA(addr_in[3:0]),
        .NWRT(1'b1),                // read only
        .NCE(~in_run),
        .CLK(clk)
    );

    // 메모리 read 는 1-cycle latency -> valid 를 1단 지연시켜 정렬
    reg v_mem;                       // mem_in_do 가 유효한 사이클
    always @(posedge clk) begin
        if (!rstn) v_mem <= 1'b0;
        else       v_mem <= in_run;
    end

    //========================================================================
    // [2] ROW 1D-DCT  (16x8 -> 16x13, shift-add, >>9)
    //========================================================================
    wire [16*13-1:0] dct1_w;
    reg  [16*13-1:0] dct1_r;
    reg              v_dct1;

    dct16 #(.INW(8), .INSIGNED(0), .SH(9), .OUTW(13)) U_DCT1 (
        .i_x(mem_in_do),
        .o_z(dct1_w)
    );

    always @(posedge clk) begin
        if (!rstn) v_dct1 <= 1'b0;
        else       v_dct1 <= v_mem;
        dct1_r <= dct1_w;
    end

    //========================================================================
    // [3] ROW TRANSPOSE MEMORY (ping-pong, BW13)
    //   v_dct1 동안 16개씩 write, phase[4] 로 TP1/TP2 교대
    //========================================================================
    reg [4:0] tp_phase;
    always @(posedge clk) begin
        if (!rstn)        tp_phase <= 5'd0;
        else if (v_dct1)  tp_phase <= tp_phase + 5'd1;
    end
    wire sel = tp_phase[4];

    wire [16*13-1:0] tp1_o, tp2_o;
    wire             tp1_oen, tp2_oen;

    TPmem_16x16 #(.BW(13)) TP1 (
        .i_data(dct1_r), .i_enable(v_dct1 & ~sel),
        .i_clk(clk), .i_Reset(rstn), .o_data(tp1_o), .o_en(tp1_oen)
    );
    TPmem_16x16 #(.BW(13)) TP2 (
        .i_data(dct1_r), .i_enable(v_dct1 &  sel),
        .i_clk(clk), .i_Reset(rstn), .o_data(tp2_o), .o_en(tp2_oen)
    );

    wire             tp_oen  = tp1_oen | tp2_oen;
    wire [16*13-1:0] tp_odat = tp1_oen ? tp1_o : tp2_o;

    //========================================================================
    // [4] COLUMN 1D-DCT  (16x13 -> 16x24, shift-add, SH=0)
    //   스케일 2^9 은 quant 단에서 한꺼번에 처리
    //========================================================================
    wire [16*24-1:0] dct2_w;
    reg  [16*24-1:0] dct2_r;
    reg              v_dct2;

    dct16 #(.INW(13), .INSIGNED(1), .SH(0), .OUTW(24)) U_DCT2 (
        .i_x(tp_odat),
        .o_z(dct2_w)
    );

    always @(posedge clk) begin
        if (!rstn) v_dct2 <= 1'b0;
        else       v_dct2 <= tp_oen;
        dct2_r <= dct2_w;
    end

    //========================================================================
    // [5] QUANTIZATION & 12bit PACKING
    //   골든 검증 결과:
    //     DC(블록 첫 워드의 ch0) : out = R2 >>> 10
    //     AC(그 외)              : out = R2 >>> 8   (12bit saturate)
    //   각 워드(=한 row, 16ch) 에서 ch0 만 DC 후보, 블록 첫 워드일 때만 DC 처리
    //========================================================================
    reg [4:0] q_cnt;
    always @(posedge clk) begin
        if (!rstn)      q_cnt <= 5'd0;
        else if (v_dct2) q_cnt <= q_cnt + 5'd1;
    end
    // 한 블록 = 16 word. 블록 첫 word 이면서 ch0 가 DC.
    wire q_blk_first = (q_cnt[3:0] == 4'd0);

    wire [16*12-1:0] q_word;

    genvar gk;
    generate
        for (gk = 0; gk < 16; gk = gk + 1) begin : QUANT
            wire signed [23:0] s2 = $signed(dct2_r[16*24-1-24*gk -: 24]);

            wire signed [23:0] dc_sh = s2 >>> 10;   // floor
            wire signed [23:0] ac_sh = s2 >>>  8;

            // 12bit 포화 (signed -2048 ~ +2047)
            wire [11:0] dc12 = (dc_sh >  24'sd2047) ? 12'h7FF :
                               (dc_sh < -24'sd2048) ? 12'h800 : dc_sh[11:0];
            wire [11:0] ac12 = (ac_sh >  24'sd2047) ? 12'h7FF :
                               (ac_sh < -24'sd2048) ? 12'h800 : ac_sh[11:0];

            // DC 는 블록 첫 word 의 ch0(gk==0) 에만
            assign q_word[16*12-1-12*gk -: 12] =
                       (q_blk_first && gk == 0) ? dc12 : ac12;
        end
    endgenerate

    //========================================================================
    // [6] COLUMN TRANSPOSE MEMORY (ping-pong, BW12)
    //========================================================================
    reg [4:0] otp_phase;
    always @(posedge clk) begin
        if (!rstn)       otp_phase <= 5'd0;
        else if (v_dct2) otp_phase <= otp_phase + 5'd1;
    end
    wire osel = otp_phase[4];

    wire [16*12-1:0] otp1_o, otp2_o;
    wire             otp1_oen, otp2_oen;

    TPmem_16x16 #(.BW(12)) OTP1 (
        .i_data(q_word), .i_enable(v_dct2 & ~osel),
        .i_clk(clk), .i_Reset(rstn), .o_data(otp1_o), .o_en(otp1_oen)
    );
    TPmem_16x16 #(.BW(12)) OTP2 (
        .i_data(q_word), .i_enable(v_dct2 &  osel),
        .i_clk(clk), .i_Reset(rstn), .o_data(otp2_o), .o_en(otp2_oen)
    );

    wire             otp_oen  = otp1_oen | otp2_oen;
    wire [16*12-1:0] otp_odat = otp1_oen ? otp1_o : otp2_o;

    //========================================================================
    // [7] 출력 메모리 (192b word)
    //========================================================================
    reg [13:0] addr_out;
    always @(posedge clk) begin
        if (!rstn)        addr_out <= 14'd0;
        else if (otp_oen) addr_out <= addr_out + 14'd1;
    end

    rflp16384x192mx16 MEM_OUT (
        .DO(), .DIN(otp_odat),
        .RA(addr_out[13:4]), .CA(addr_out[3:0]),
        .NWRT(~otp_oen),
        .NCE(~otp_oen),
        .CLK(clk)
    );

endmodule