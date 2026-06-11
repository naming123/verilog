`timescale 1ns / 10ps
//============================================================================
//  Project #2 : 16x16 2D-DCT for 512x512 JPEG compression
//
//  Top
//   +-- MEM_IN  : rflp16384x128mx16  (input  buffer, 16384 x 128b, 16px x 8b)
//   +-- U_DCT1  : 16-point 1D-DCT (row DCT,    8b unsigned in -> 14b out)
//   +-- TP1/TP2 : TPmem_16x16 #(BW=14)  ping-pong transpose
//   +-- U_DCT2  : 16-point 1D-DCT (column DCT, 14b signed in -> 17b out)
//   +-- MEM_OUT : rflp16384x192mx16  (output buffer, 16384 x 192b, 16 x 12b)
//
//  Throughput : 1 row / clk  ->  16 clk / block  ->  ~16.4k clk total
//               (fits the given stimulus window of #164210 @ 10ns clk)
//
//  Internal quantization (designer's choice, matches MATLAB defaults:
//   Result_1D_DCT_quantization_bit = 14, num_int = 12)
//   - DCT coefficients : Ck = (1/sqrt(8))cos(k*pi/32), x1024 (10 frac bits)
//   - 1st 1D-DCT out   : 14b signed = {12b integer . 2b fraction}  (BW = 14)
//   - 2nd 1D-DCT out   : 17b signed = {15b integer . 2b fraction}
//   - 2D output 12b    : DC  (block row0, element0) -> integer part >> 1
//                        AC  -> keep 2 fractional bits + saturation
//                        (given MATLAB reads DC as-is and divides AC by 4)
//============================================================================
module Top (
    input clk,
    input rstn
);

    //------------------------------------------------------------------
    // 1) INPUT side : stream-read all 16384 words (1 word = 1 block row)
    //------------------------------------------------------------------
    reg  [14:0] in_cnt;                       // bit14 = finished flag
    wire        in_run  = ~in_cnt[14];
    wire [13:0] addr_in = in_cnt[13:0];
    wire [127:0] mem_in_do;

    always @(posedge clk) begin
        if (!rstn)        in_cnt <= 15'd0;
        else if (in_run)  in_cnt <= in_cnt + 15'd1;
    end

    rflp16384x128mx16 MEM_IN (              // read-only here
        .DO   (mem_in_do),
        .DIN  (128'd0),
        .RA   (addr_in[13:4]),
        .CA   (addr_in[3:0]),
        .NWRT (1'b1),
        .NCE  (~in_run),
        .CLK  (clk)
    );

    // valid pipeline : addr applied(t) -> DO valid(t+1) -> DCT1 reg(t+2)
    reg v_do, v_tp;
    always @(posedge clk) begin
        if (!rstn) begin v_do <= 1'b0; v_tp <= 1'b0; end
        else       begin v_do <= in_run; v_tp <= v_do; end
    end

    //------------------------------------------------------------------
    // 2) 1st 1D-DCT (row DCT)
    //------------------------------------------------------------------
    wire [16*14-1:0] dct1_w;
    reg  [16*14-1:0] dct1_r;

    dct16_stage1 U_DCT1 ( .i_x(mem_in_do), .o_z(dct1_w) );

    always @(posedge clk) dct1_r <= dct1_w;

    //------------------------------------------------------------------
    // 3) Ping-pong transpose memories (write 16 clk -> read 16 clk)
    //------------------------------------------------------------------
    reg [4:0] tp_phase;                       // counts written rows
    always @(posedge clk) begin
        if (!rstn)      tp_phase <= 5'd0;
        else if (v_tp)  tp_phase <= tp_phase + 5'd1;
    end
    wire sel2 = tp_phase[4];                  // 0..15 -> TP1, 16..31 -> TP2

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
    // 4) 2nd 1D-DCT (column DCT)
    //------------------------------------------------------------------
    wire [16*17-1:0] dct2_w;
    reg  [16*17-1:0] dct2_r;
    reg              v_w;

    dct16_stage2 U_DCT2 ( .i_x(tp_odat), .o_z(dct2_w) );

    always @(posedge clk) begin
        if (!rstn) v_w <= 1'b0;
        else       v_w <= tp_oen;
        dct2_r <= dct2_w;
    end

    //------------------------------------------------------------------
    // 5) Truncation to 12 bits + OUTPUT buffer write
    //------------------------------------------------------------------
    reg [13:0] addr_out;
    always @(posedge clk) begin
        if (!rstn)     addr_out <= 14'd0;
        else if (v_w)  addr_out <= addr_out + 14'd1;
    end
    wire first_word = (addr_out[3:0] == 4'd0);   // v = 0 word of a block

    wire [191:0] out_word;
    genvar gk;
    generate
        for (gk = 0; gk < 16; gk = gk + 1) begin : TRUNC
            wire signed [16:0] zz = dct2_r[16*17-1-17*gk -: 17]; // value*4
            if (gk == 0) begin : DC_PATH
                // element0 of the v=0 word is the true DC (u=0,v=0)
                //  DC : drop 2 frac bits, then truncate LSB of integer part
                //  AC(u>0, v=0) : keep 2 frac bits + saturation
                assign out_word[191-12*gk -: 12] =
                    first_word ? zz[14:3] :
                    (zz > 17'sd2047)  ? 12'h7FF :
                    (zz < -17'sd2048) ? 12'h800 : zz[11:0];
            end
            else begin : AC_PATH
                assign out_word[191-12*gk -: 12] =
                    (zz > 17'sd2047)  ? 12'h7FF :
                    (zz < -17'sd2048) ? 12'h800 : zz[11:0];
            end
        end
    endgenerate

    rflp16384x192mx16 MEM_OUT (              // write-only here
        .DO   (),
        .DIN  (out_word),
        .RA   (addr_out[13:4]),
        .CA   (addr_out[3:0]),
        .NWRT (~v_w),
        .NCE  (~v_w),
        .CLK  (clk)
    );

endmodule


//============================================================================
//  16-point 1D-DCT, stage 1  (row DCT)
//  in  : 16 x 8b unsigned pixels, x0 in MSBs
//  out : 16 x 14b signed, value = real * 4  (2 fractional bits kept)
//  Ck = (1/sqrt(8))*cos(k*pi/32) quantized to 10 fractional bits (x1024)
//  Even/Odd decomposition: 16x16 matrix -> two 8x8 matrices
//============================================================================
module dct16_stage1 (
    input  [16*8-1:0]  i_x,
    output [16*14-1:0] o_z
);
    wire [7:0] x [0:15];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : UNPACK
            assign x[i] = i_x[16*8-1-8*i -: 8];
        end
    endgenerate

    // butterflies : s[n] = x[n]+x[15-n] (even rows), d[n] = x[n]-x[15-n] (odd)
    wire signed [10:0] s [0:7];
    wire signed [10:0] d [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : BFLY
            assign s[i] = $signed({3'b000, x[i]}) + $signed({3'b000, x[15-i]});
            assign d[i] = $signed({3'b000, x[i]}) - $signed({3'b000, x[15-i]});
        end
    endgenerate

    // coefficient values (x1024):
    // C1..C15 = 360 356 346 334 320 302 280 256 230 202 170 138 106 70 36
    wire signed [22:0] ze [0:7];   // even rows k = 0,2,...,14
    wire signed [22:0] zo [0:7];   // odd  rows k = 1,3,...,15

    assign ze[0] = 256*(s[0]+s[1]+s[2]+s[3]+s[4]+s[5]+s[6]+s[7]);                        // k=0  (C8)
    assign ze[1] = 356*s[0]+302*s[1]+202*s[2]+ 70*s[3]- 70*s[4]-202*s[5]-302*s[6]-356*s[7]; // k=2
    assign ze[2] = 334*s[0]+138*s[1]-138*s[2]-334*s[3]-334*s[4]-138*s[5]+138*s[6]+334*s[7]; // k=4
    assign ze[3] = 302*s[0]- 70*s[1]-356*s[2]-202*s[3]+202*s[4]+356*s[5]+ 70*s[6]-302*s[7]; // k=6
    assign ze[4] = 256*(s[0]-s[1]-s[2]+s[3]+s[4]-s[5]-s[6]+s[7]);                        // k=8
    assign ze[5] = 202*s[0]-356*s[1]+ 70*s[2]+302*s[3]-302*s[4]- 70*s[5]+356*s[6]-202*s[7]; // k=10
    assign ze[6] = 138*s[0]-334*s[1]+334*s[2]-138*s[3]-138*s[4]+334*s[5]-334*s[6]+138*s[7]; // k=12
    assign ze[7] =  70*s[0]-202*s[1]+302*s[2]-356*s[3]+356*s[4]-302*s[5]+202*s[6]- 70*s[7]; // k=14

    assign zo[0] = 360*d[0]+346*d[1]+320*d[2]+280*d[3]+230*d[4]+170*d[5]+106*d[6]+ 36*d[7]; // k=1
    assign zo[1] = 346*d[0]+230*d[1]+ 36*d[2]-170*d[3]-320*d[4]-360*d[5]-280*d[6]-106*d[7]; // k=3
    assign zo[2] = 320*d[0]+ 36*d[1]-280*d[2]-346*d[3]-106*d[4]+230*d[5]+360*d[6]+170*d[7]; // k=5
    assign zo[3] = 280*d[0]-170*d[1]-346*d[2]+ 36*d[3]+360*d[4]+106*d[5]-320*d[6]-230*d[7]; // k=7
    assign zo[4] = 230*d[0]-320*d[1]-106*d[2]+360*d[3]- 36*d[4]-346*d[5]+170*d[6]+280*d[7]; // k=9
    assign zo[5] = 170*d[0]-360*d[1]+230*d[2]+106*d[3]-346*d[4]+280*d[5]+ 36*d[6]-320*d[7]; // k=11
    assign zo[6] = 106*d[0]-280*d[1]+360*d[2]-320*d[3]+170*d[4]+ 36*d[5]-230*d[6]+346*d[7]; // k=13
    assign zo[7] =  36*d[0]-106*d[1]+170*d[2]-230*d[3]+280*d[4]-320*d[5]+346*d[6]-360*d[7]; // k=15

    // >>>8 : drop 8 of the 10 fractional bits -> keep 2 (value = real*4)
    generate
        for (i = 0; i < 8; i = i + 1) begin : PACK
            assign o_z[16*14-1-14*(2*i)   -: 14] = ze[i] >>> 8; // even k = 2i
            assign o_z[16*14-1-14*(2*i+1) -: 14] = zo[i] >>> 8; // odd  k = 2i+1
        end
    endgenerate
endmodule


//============================================================================
//  16-point 1D-DCT, stage 2  (column DCT)
//  in  : 16 x 14b signed (value = real*4), element0 in MSBs
//  out : 16 x 17b signed (value = real*4)
//============================================================================
module dct16_stage2 (
    input  [16*14-1:0] i_x,
    output [16*17-1:0] o_z
);
    wire signed [13:0] x [0:15];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : UNPACK
            assign x[i] = i_x[16*14-1-14*i -: 14];
        end
    endgenerate

    wire signed [14:0] s [0:7];
    wire signed [14:0] d [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : BFLY
            assign s[i] = x[i] + x[15-i];
            assign d[i] = x[i] - x[15-i];
        end
    endgenerate

    wire signed [25:0] ze [0:7];
    wire signed [25:0] zo [0:7];

    assign ze[0] = 256*(s[0]+s[1]+s[2]+s[3]+s[4]+s[5]+s[6]+s[7]);                        // k=0
    assign ze[1] = 356*s[0]+302*s[1]+202*s[2]+ 70*s[3]- 70*s[4]-202*s[5]-302*s[6]-356*s[7]; // k=2
    assign ze[2] = 334*s[0]+138*s[1]-138*s[2]-334*s[3]-334*s[4]-138*s[5]+138*s[6]+334*s[7]; // k=4
    assign ze[3] = 302*s[0]- 70*s[1]-356*s[2]-202*s[3]+202*s[4]+356*s[5]+ 70*s[6]-302*s[7]; // k=6
    assign ze[4] = 256*(s[0]-s[1]-s[2]+s[3]+s[4]-s[5]-s[6]+s[7]);                        // k=8
    assign ze[5] = 202*s[0]-356*s[1]+ 70*s[2]+302*s[3]-302*s[4]- 70*s[5]+356*s[6]-202*s[7]; // k=10
    assign ze[6] = 138*s[0]-334*s[1]+334*s[2]-138*s[3]-138*s[4]+334*s[5]-334*s[6]+138*s[7]; // k=12
    assign ze[7] =  70*s[0]-202*s[1]+302*s[2]-356*s[3]+356*s[4]-302*s[5]+202*s[6]- 70*s[7]; // k=14

    assign zo[0] = 360*d[0]+346*d[1]+320*d[2]+280*d[3]+230*d[4]+170*d[5]+106*d[6]+ 36*d[7]; // k=1
    assign zo[1] = 346*d[0]+230*d[1]+ 36*d[2]-170*d[3]-320*d[4]-360*d[5]-280*d[6]-106*d[7]; // k=3
    assign zo[2] = 320*d[0]+ 36*d[1]-280*d[2]-346*d[3]-106*d[4]+230*d[5]+360*d[6]+170*d[7]; // k=5
    assign zo[3] = 280*d[0]-170*d[1]-346*d[2]+ 36*d[3]+360*d[4]+106*d[5]-320*d[6]-230*d[7]; // k=7
    assign zo[4] = 230*d[0]-320*d[1]-106*d[2]+360*d[3]- 36*d[4]-346*d[5]+170*d[6]+280*d[7]; // k=9
    assign zo[5] = 170*d[0]-360*d[1]+230*d[2]+106*d[3]-346*d[4]+280*d[5]+ 36*d[6]-320*d[7]; // k=11
    assign zo[6] = 106*d[0]-280*d[1]+360*d[2]-320*d[3]+170*d[4]+ 36*d[5]-230*d[6]+346*d[7]; // k=13
    assign zo[7] =  36*d[0]-106*d[1]+170*d[2]-230*d[3]+280*d[4]-320*d[5]+346*d[6]-360*d[7]; // k=15

    // >>>10 : remove the 10 coefficient fraction bits (input frac kept)
    generate
        for (i = 0; i < 8; i = i + 1) begin : PACK
            assign o_z[16*17-1-17*(2*i)   -: 17] = ze[i] >>> 10;
            assign o_z[16*17-1-17*(2*i+1) -: 17] = zo[i] >>> 10;
        end
    endgenerate
endmodule