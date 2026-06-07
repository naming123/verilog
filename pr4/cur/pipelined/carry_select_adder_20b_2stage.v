module carry_select_adder_20bit_2stage (
    output [20:0] sum,
    input  [19:0] a, b,
    input         c_in, clk, rstn
);

    // Input DFF outputs
    wire c_in_q;
    wire [19:0] a_q, b_q;

    DFF_input_20b DFF_in (
        .a_q(a_q), .b_q(b_q), .c_in_q(c_in_q),
        .a(a), .b(b), .c_in(c_in),
        .clk(clk), .rstn(rstn)
    );

    // =========================================
    // Stage 1: Block 0 (4-bit RCA, bits [3:0])
    // =========================================
    wire [3:0] sum0;
    wire c0_i0, c0_i1, c0_i2, c0;

    fulladd_gate b0f0 (sum0[0], c0_i0, a_q[0], b_q[0], c_in_q);
    fulladd_gate b0f1 (sum0[1], c0_i1, a_q[1], b_q[1], c0_i0);
    fulladd_gate b0f2 (sum0[2], c0_i2, a_q[2], b_q[2], c0_i1);
    fulladd_gate b0f3 (sum0[3], c0,    a_q[3], b_q[3], c0_i2);

    // =========================================
    // Stage 1: Block 1 (4-bit carry select, bits [7:4])
    // =========================================
    wire [3:0] sum1_0, sum1_1, sum1;
    wire c1_0_i0, c1_0_i1, c1_0_i2, c1_0;
    wire c1_1_i0, c1_1_i1, c1_1_i2, c1_1;
    wire c1;

    fulladd_gate b1f0_0 (sum1_0[0], c1_0_i0, a_q[4], b_q[4], 1'b0);
    fulladd_gate b1f1_0 (sum1_0[1], c1_0_i1, a_q[5], b_q[5], c1_0_i0);
    fulladd_gate b1f2_0 (sum1_0[2], c1_0_i2, a_q[6], b_q[6], c1_0_i1);
    fulladd_gate b1f3_0 (sum1_0[3], c1_0,    a_q[7], b_q[7], c1_0_i2);

    fulladd_gate b1f0_1 (sum1_1[0], c1_1_i0, a_q[4], b_q[4], 1'b1);
    fulladd_gate b1f1_1 (sum1_1[1], c1_1_i1, a_q[5], b_q[5], c1_1_i0);
    fulladd_gate b1f2_1 (sum1_1[2], c1_1_i2, a_q[6], b_q[6], c1_1_i1);
    fulladd_gate b1f3_1 (sum1_1[3], c1_1,    a_q[7], b_q[7], c1_1_i2);

    mux2to1 b1m0 (sum1[0], sum1_0[0], sum1_1[0], c0);
    mux2to1 b1m1 (sum1[1], sum1_0[1], sum1_1[1], c0);
    mux2to1 b1m2 (sum1[2], sum1_0[2], sum1_1[2], c0);
    mux2to1 b1m3 (sum1[3], sum1_0[3], sum1_1[3], c0);
    mux2to1 b1mc (c1,      c1_0,      c1_1,      c0);

    // =========================================
    // Stage 1: Block 2 (4-bit carry select, bits [11:8])
    // =========================================
    wire [3:0] sum2_0, sum2_1, sum2;
    wire c2_0_i0, c2_0_i1, c2_0_i2, c2_0;
    wire c2_1_i0, c2_1_i1, c2_1_i2, c2_1;
    wire c2;

    fulladd_gate b2f0_0 (sum2_0[0], c2_0_i0, a_q[8],  b_q[8],  1'b0);
    fulladd_gate b2f1_0 (sum2_0[1], c2_0_i1, a_q[9],  b_q[9],  c2_0_i0);
    fulladd_gate b2f2_0 (sum2_0[2], c2_0_i2, a_q[10], b_q[10], c2_0_i1);
    fulladd_gate b2f3_0 (sum2_0[3], c2_0,    a_q[11], b_q[11], c2_0_i2);

    fulladd_gate b2f0_1 (sum2_1[0], c2_1_i0, a_q[8],  b_q[8],  1'b1);
    fulladd_gate b2f1_1 (sum2_1[1], c2_1_i1, a_q[9],  b_q[9],  c2_1_i0);
    fulladd_gate b2f2_1 (sum2_1[2], c2_1_i2, a_q[10], b_q[10], c2_1_i1);
    fulladd_gate b2f3_1 (sum2_1[3], c2_1,    a_q[11], b_q[11], c2_1_i2);

    mux2to1 b2m0 (sum2[0], sum2_0[0], sum2_1[0], c1);
    mux2to1 b2m1 (sum2[1], sum2_0[1], sum2_1[1], c1);
    mux2to1 b2m2 (sum2[2], sum2_0[2], sum2_1[2], c1);
    mux2to1 b2m3 (sum2[3], sum2_0[3], sum2_1[3], c1);
    mux2to1 b2mc (c2,      c2_0,      c2_1,      c1);

    // =========================================
    // Mid Pipeline Registers
    // =========================================
    reg [11:0]  sum_low_q;
    reg         c_mid_q;
    reg [19:12] a_mid_q, b_mid_q;

    always @(posedge clk) begin
        if (!rstn) begin
            sum_low_q <= 0;
            c_mid_q   <= 0;
            a_mid_q   <= 0;
            b_mid_q   <= 0;
        end else begin
            sum_low_q <= {sum2, sum1, sum0};
            c_mid_q   <= c2;
            a_mid_q   <= a_q[19:12];
            b_mid_q   <= b_q[19:12];
        end
    end

    // =========================================
    // Stage 2: Block 3 (4-bit carry select, bits [15:12])
    // =========================================
    wire [3:0] sum3_0, sum3_1, sum3;
    wire c3_0_i0, c3_0_i1, c3_0_i2, c3_0;
    wire c3_1_i0, c3_1_i1, c3_1_i2, c3_1;
    wire c3;

    fulladd_gate b3f0_0 (sum3_0[0], c3_0_i0, a_mid_q[12], b_mid_q[12], 1'b0);
    fulladd_gate b3f1_0 (sum3_0[1], c3_0_i1, a_mid_q[13], b_mid_q[13], c3_0_i0);
    fulladd_gate b3f2_0 (sum3_0[2], c3_0_i2, a_mid_q[14], b_mid_q[14], c3_0_i1);
    fulladd_gate b3f3_0 (sum3_0[3], c3_0,    a_mid_q[15], b_mid_q[15], c3_0_i2);

    fulladd_gate b3f0_1 (sum3_1[0], c3_1_i0, a_mid_q[12], b_mid_q[12], 1'b1);
    fulladd_gate b3f1_1 (sum3_1[1], c3_1_i1, a_mid_q[13], b_mid_q[13], c3_1_i0);
    fulladd_gate b3f2_1 (sum3_1[2], c3_1_i2, a_mid_q[14], b_mid_q[14], c3_1_i1);
    fulladd_gate b3f3_1 (sum3_1[3], c3_1,    a_mid_q[15], b_mid_q[15], c3_1_i2);

    mux2to1 b3m0 (sum3[0], sum3_0[0], sum3_1[0], c_mid_q);
    mux2to1 b3m1 (sum3[1], sum3_0[1], sum3_1[1], c_mid_q);
    mux2to1 b3m2 (sum3[2], sum3_0[2], sum3_1[2], c_mid_q);
    mux2to1 b3m3 (sum3[3], sum3_0[3], sum3_1[3], c_mid_q);
    mux2to1 b3mc (c3,      c3_0,      c3_1,      c_mid_q);

    // =========================================
    // Stage 2: Block 4 (4-bit carry select, bits [19:16])
    // =========================================
    wire [3:0] sum4_0, sum4_1, sum4;
    wire c4_0_i0, c4_0_i1, c4_0_i2, c4_0;
    wire c4_1_i0, c4_1_i1, c4_1_i2, c4_1;
    wire c4;

    fulladd_gate b4f0_0 (sum4_0[0], c4_0_i0, a_mid_q[16], b_mid_q[16], 1'b0);
    fulladd_gate b4f1_0 (sum4_0[1], c4_0_i1, a_mid_q[17], b_mid_q[17], c4_0_i0);
    fulladd_gate b4f2_0 (sum4_0[2], c4_0_i2, a_mid_q[18], b_mid_q[18], c4_0_i1);
    fulladd_gate b4f3_0 (sum4_0[3], c4_0,    a_mid_q[19], b_mid_q[19], c4_0_i2);

    fulladd_gate b4f0_1 (sum4_1[0], c4_1_i0, a_mid_q[16], b_mid_q[16], 1'b1);
    fulladd_gate b4f1_1 (sum4_1[1], c4_1_i1, a_mid_q[17], b_mid_q[17], c4_1_i0);
    fulladd_gate b4f2_1 (sum4_1[2], c4_1_i2, a_mid_q[18], b_mid_q[18], c4_1_i1);
    fulladd_gate b4f3_1 (sum4_1[3], c4_1,    a_mid_q[19], b_mid_q[19], c4_1_i2);

    mux2to1 b4m0 (sum4[0], sum4_0[0], sum4_1[0], c3);
    mux2to1 b4m1 (sum4[1], sum4_0[1], sum4_1[1], c3);
    mux2to1 b4m2 (sum4[2], sum4_0[2], sum4_1[2], c3);
    mux2to1 b4m3 (sum4[3], sum4_0[3], sum4_1[3], c3);
    mux2to1 b4mc (c4,      c4_0,      c4_1,      c3);

    // =========================================
    // Output DFF
    // =========================================
    reg [20:0] sum_q;

    always @(posedge clk) begin
        if (!rstn)
            sum_q <= 0;
        else
            sum_q <= {c4, sum4, sum3, sum_low_q};
    end

    assign sum = sum_q;

endmodule

module fulladd_gate (
    output sum, c_out,
    input  a, b, c_in
);
    wire s1, s2, c1;
    xor(s1, a, b);
    and(c1, a, b);
    and(s2, s1, c_in);
    xor(sum, s1, c_in);
    xor(c_out, c1, s2);
endmodule

module mux2to1 (
    output out,
    input  in0, in1, sel
);
    wire s0, s1, sel_n;
    not(sel_n, sel);
    and(s0, in0, sel_n);
    and(s1, in1, sel);
    or(out, s0, s1);
endmodule

module DFF_input_20b (
    output reg [19:0] a_q, b_q,
    output reg c_in_q,
    input [19:0] a, b,
    input c_in, clk, rstn
);
    always @(posedge clk) begin
        if (!rstn) begin
            a_q    <= 0;
            b_q    <= 0;
            c_in_q <= 0;
        end else begin
            a_q    <= a;
            b_q    <= b;
            c_in_q <= c_in;
        end
    end
endmodule