`timescale 1ns / 10ps

module Top (
    input wire          clk,
    input wire          rstn,

    // 외부 MEM_IN (Input Buffer) 인터페이스 포트
    output wire [9:0]   mem_in_ra,   // Row Address
    output wire [3:0]   mem_in_ca,   // Column Address
    output wire         mem_in_nce,  // Chip Enable (Active Low)
    input wire [127:0]  mem_in_do,   // Data Out 에서 읽어오는 값

    // 외부 MEM_OUT (Output Buffer) 인터페이스 포트
    output wire [13:0]  mem_out_addr,// 통일된 주소 포트 (필요시 RA/CA 분할 가능)
    output wire         mem_out_nwr, // Write Enable (Active Low)
    output wire         mem_out_nce, // Chip Enable (Active Low)
    output wire [191:0] mem_out_din  // Data In 으로 쓸 값
);

    //------------------------------------------------------------------
    // 1) INPUT side : Stream-read control
    //------------------------------------------------------------------
    reg  [14:0] in_cnt;                       // bit14 = finished flag
    wire        in_run  = ~in_cnt[14];
    wire [13:0] addr_in = in_cnt[13:0];

    always @(posedge clk) begin
        if (!rstn)        in_cnt <= 15'd0;
        else if (in_run)  in_cnt <= in_cnt + 15'd1;
    end

    // 외부 MEM_IN 매핑용 출력 할당
    assign mem_in_ra  = addr_in[13:4];
    assign mem_in_ca  = addr_in[3:0];
    assign mem_in_nce = ~in_run;

    // valid pipeline : addr applied(t) -> DO valid(t+1) -> DCT1 reg(t+2)
    reg v_do, v_tp;
    always @(posedge clk) begin
        if (!rstn) begin 
            v_do <= 1'b0; 
            v_tp <= 1'b0; 
        end else begin 
            v_do <= in_run; 
            v_tp <= v_do; 
        end
    end

    //------------------------------------------------------------------
    // 2) 1st 1D-DCT (row DCT)
    //------------------------------------------------------------------
    wire [16*14-1:0] dct1_w;
    reg  [16*14-1:0] dct1_r;

    dct16_stage1 U_DCT1 ( .i_x(mem_in_do), .o_z(dct1_w) );

    always @(posedge clk) begin
        dct1_r <= dct1_w;
    end

    //------------------------------------------------------------------
    // 3) Ping-pong transpose memories (TP1 / TP2)
    //------------------------------------------------------------------
    reg [4:0] tp_phase;
    always @(posedge clk) begin
        if (!rstn)      tp_phase <= 5'd0;
        else if (v_tp)  tp_phase <= tp_phase + 5'd1;
    end
    wire sel2 = tp_phase[4];

    wire [16*14-1:0] tp1_o, tp2_o;
    wire             tp1_oen, tp2_oen;

    TPmem_16x16 #(.BW(14)) TP1 (
        .i_data(dct1_r), .i_enable(v_tp & ~sel2),
        .i_clk(clk), .i_Reset(rstn),
        .o_data(tp1_o), .o_en(tp1_oen) );

    TPmem_16x16 #(.BW(14)) TP2 (
        .i_data(dct1_r), .i_enable(v_tp &  sel2),
        .i_clk(clk), .i_Reset(rstn),
        .o_data(tp2_o), .o_en(tp2_oen) );

    wire             tp_oen  = tp1_oen | tp2_oen;
    wire [16*14-1:0] tp_odat = tp1_oen ? tp1_o : tp2_o;

    //------------------------------------------------------------------
    // 4) 2nd 1D-DCT (column DCT) + truncation to 12 bits
    //------------------------------------------------------------------
    wire [16*17-1:0] dct2_w;
    dct16_stage2 U_DCT2 ( .i_x(tp_odat), .o_z(dct2_w) );

    reg [3:0] vcnt;
    always @(posedge clk) begin
        if (!rstn)        vcnt <= 4'd0;
        else if (tp_oen)  vcnt <= vcnt + 4'd1;
    end
    wire dc_word = (vcnt == 4'd0);

    wire [16*12-1:0] trunc_w;
    genvar gk;
    generate
        for (gk = 0; gk < 16; gk = gk + 1) begin : TRUNC
            wire signed [16:0] zz = dct2_w[16*17-1-17*gk -: 17];
            wire signed [15:0] zh = zz >>> 1;
            if (gk == 0) begin : DC_PATH
                assign trunc_w[191-12*gk -: 12] =
                    dc_word ? zz[14:3] :
                    (zh > 16'sd2047)  ? 12'h7FF :
                    (zh < -16'sd2048) ? 12'h800 : zh[11:0];
            end
            else begin : AC_PATH
                assign trunc_w[191-12*gk -: 12] =
                    (zh > 16'sd2047)  ? 12'h7FF :
                    (zh < -16'sd2048) ? 12'h800 : zh[11:0];
            end
        end
    endgenerate

    //------------------------------------------------------------------
    // 5) Output transpose (Pure DFF Matrix array)
    //------------------------------------------------------------------
    // 2차원 Reg 배열을 합성 가능하도록 1차원의 개별 12비트 DFF 플립플롭으로 전개
    reg [11:0] bankA_reg [0:255];
    reg [11:0] bankB_reg [0:255];
    reg [4:0]  wcnt;

    integer r_u, c_v;
    always @(posedge clk) begin
        if (!rstn) begin
            for (r_u = 0; r_u < 16; r_u = r_u + 1) begin
                for (c_v = 0; c_v < 16; c_v = c_v + 1) begin
                    bankA_reg[(r_u << 4) + c_v] <= 12'd0;
                    bankB_reg[(r_u << 4) + c_v] <= 12'd0;
                end
            end
            wcnt <= 5'd0;
        end else if (tp_oen) begin
            wcnt <= wcnt + 5'd1;
            for (r_u = 0; r_u < 16; r_u = r_u + 1) begin
                // bank[u][v] 순서로 전치(Transpose)하여 DFF에 래치 생성
                if (~wcnt[4]) 
                    bankA_reg[(r_u << 4) + wcnt[3:0]] <= trunc_w[191-12*r_u -: 12];
                else          
                    bankB_reg[(r_u << 4) + wcnt[3:0]] <= trunc_w[191-12*r_u -: 12];
            end
        end
    end

    // read enable 딜레이 라인
    reg [15:0] oen_dly;
    always @(posedge clk) begin
        if (!rstn) oen_dly <= 16'd0;
        else       oen_dly <= {oen_dly[14:0], tp_oen};
    end
    wire rd_en = oen_dly[15];

    reg [4:0] rcnt;
    always @(posedge clk) begin
        if (!rstn)      rcnt <= 5'd0;
        else if (rd_en) rcnt <= rcnt + 5'd1;
    end

    // DFF Mux 리드 백
    wire [191:0] out_word;
    generate
        for (gk = 0; gk < 16; gk = gk + 1) begin : RDMUX
            assign out_word[191-12*gk -: 12] =
                (~rcnt[4]) ? bankA_reg[(rcnt[3:0] << 4) + gk] : bankB_reg[(rcnt[3:0] << 4) + gk];
        end
    endgenerate

    //------------------------------------------------------------------
    // 6) OUTPUT 인터페이스 할당
    //------------------------------------------------------------------
    reg [13:0] addr_out_reg;
    always @(posedge clk) begin
        if (!rstn)      addr_out_reg <= 14'd0;
        else if (rd_en) addr_out_reg <= addr_out_reg + 14'd1;
    end

    assign mem_out_addr = addr_out_reg;
    assign mem_out_nwr  = ~rd_en;
    assign mem_out_nce  = ~rd_en;
    assign mem_out_din  = out_word;

endmodule