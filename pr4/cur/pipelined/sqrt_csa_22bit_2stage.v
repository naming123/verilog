module sqrt_csa_22bit_2stage (
    output [22:0] sum,
    input  [21:0] a, b,
    input         c_in, clk, rstn
);

    // =========================================
    // Input DFF
    // =========================================
    wire c_in_q;
    wire [21:0] a_q, b_q;

    DFF_input DFF_in (
        .a_q(a_q), .b_q(b_q), .c_in_q(c_in_q),
        .a(a), .b(b), .c_in(c_in),
        .clk(clk), .rstn(rstn)
    );

    // =========================================
    // Stage 1: Block 0 (2-bit RCA, bits [1:0])
    // =========================================
    wire [1:0] sum0;
    wire c0_i, c0;

    fulladd_gate b0f0 (sum0[0], c0_i, a_q[0], b_q[0], c_in_q);
    fulladd_gate b0f1 (sum0[1], c0,   a_q[1], b_q[1], c0_i);

    // =========================================
    // Stage 1: Block 1 (2-bit carry select, bits [3:2])
    // =========================================
    wire [1:0] sum1_0, sum1_1, sum1;
    wire c1_0_i, c1_0, c1_1_i, c1_1, c1;

    // cin=0
    fulladd_gate b1f0_0 (sum1_0[0], c1_0_i, a_q[2], b_q[2], 1'b0);
    fulladd_gate b1f1_0 (sum1_0[1], c1_0,   a_q[3], b_q[3], c1_0_i);
    // cin=1
    fulladd_gate b1f0_1 (sum1_1[0], c1_1_i, a_q[2], b_q[2], 1'b1);
    fulladd_gate b1f1_1 (sum1_1[1], c1_1,   a_q[3], b_q[3], c1_1_i);
    // MUX
    mux2to1 b1m0 (sum1[0], sum1_0[0], sum1_1[0], c0);
    mux2to1 b1m1 (sum1[1], sum1_0[1], sum1_1[1], c0);
    mux2to1 b1mc (c1,      c1_0,      c1_1,      c0);

    // =========================================
    // Stage 1: Block 2 (3-bit carry select, bits [6:4])
    // =========================================
    wire [2:0] sum2_0, sum2_1, sum2;
    wire c2_0_i0, c2_0_i1, c2_0;
    wire c2_1_i0, c2_1_i1, c2_1;
    wire c2;

    // cin=0
    fulladd_gate b2f0_0 (sum2_0[0], c2_0_i0, a_q[4], b_q[4], 1'b0);
    fulladd_gate b2f1_0 (sum2_0[1], c2_0_i1, a_q[5], b_q[5], c2_0_i0);
    fulladd_gate b2f2_0 (sum2_0[2], c2_0,    a_q[6], b_q[6], c2_0_i1);
    // cin=1
    fulladd_gate b2f0_1 (sum2_1[0], c2_1_i0, a_q[4], b_q[4], 1'b1);
    fulladd_gate b2f1_1 (sum2_1[1], c2_1_i1, a_q[5], b_q[5], c2_1_i0);
    fulladd_gate b2f2_1 (sum2_1[2], c2_1,    a_q[6], b_q[6], c2_1_i1);
    // MUX
    mux2to1 b2m0 (sum2[0], sum2_0[0], sum2_1[0], c1);
    mux2to1 b2m1 (sum2[1], sum2_0[1], sum2_1[1], c1);
    mux2to1 b2m2 (sum2[2], sum2_0[2], sum2_1[2], c1);
    mux2to1 b2mc (c2,      c2_0,      c2_1,      c1);

    // =========================================
    // Mid Pipeline Registers (Stage 1 -> Stage 2)
    // =========================================
    reg [6:0]    sum_low_q;
    reg          c_mid_q;
    reg [21:7]   a_mid_q, b_mid_q;

    always @(posedge clk) begin
        if (!rstn) begin
            sum_low_q <= 0;
            c_mid_q   <= 0;
            a_mid_q   <= 0;
            b_mid_q   <= 0;
        end else begin
            sum_low_q <= {sum2, sum1, sum0};
            c_mid_q   <= c2;
            a_mid_q   <= a_q[21:7];
            b_mid_q   <= b_q[21:7];
        end
    end

    // =========================================
    // Stage 2: Block 3 (4-bit carry select, bits [10:7])
    // =========================================
    wire [3:0] sum3_0, sum3_1, sum3;
    wire c3_0_i0, c3_0_i1, c3_0_i2, c3_0;
    wire c3_1_i0, c3_1_i1, c3_1_i2, c3_1;
    wire c3;

    // cin=0
    fulladd_gate b3f0_0 (sum3_0[0], c3_0_i0, a_mid_q[7],  b_mid_q[7],  1'b0);
    fulladd_gate b3f1_0 (sum3_0[1], c3_0_i1, a_mid_q[8],  b_mid_q[8],  c3_0_i0);
    fulladd_gate b3f2_0 (sum3_0[2], c3_0_i2, a_mid_q[9],  b_mid_q[9],  c3_0_i1);
    fulladd_gate b3f3_0 (sum3_0[3], c3_0,    a_mid_q[10], b_mid_q[10], c3_0_i2);
    // cin=1
    fulladd_gate b3f0_1 (sum3_1[0], c3_1_i0, a_mid_q[7],  b_mid_q[7],  1'b1);
    fulladd_gate b3f1_1 (sum3_1[1], c3_1_i1, a_mid_q[8],  b_mid_q[8],  c3_1_i0);
    fulladd_gate b3f2_1 (sum3_1[2], c3_1_i2, a_mid_q[9],  b_mid_q[9],  c3_1_i1);
    fulladd_gate b3f3_1 (sum3_1[3], c3_1,    a_mid_q[10], b_mid_q[10], c3_1_i2);
    // MUX
    mux2to1 b3m0 (sum3[0], sum3_0[0], sum3_1[0], c_mid_q);
    mux2to1 b3m1 (sum3[1], sum3_0[1], sum3_1[1], c_mid_q);
    mux2to1 b3m2 (sum3[2], sum3_0[2], sum3_1[2], c_mid_q);
    mux2to1 b3m3 (sum3[3], sum3_0[3], sum3_1[3], c_mid_q);
    mux2to1 b3mc (c3,      c3_0,      c3_1,      c_mid_q);

    // =========================================
    // Stage 2: Block 4 (5-bit carry select, bits [15:11])
    // =========================================
    wire [4:0] sum4_0, sum4_1, sum4;
    wire c4_0_i0, c4_0_i1, c4_0_i2, c4_0_i3, c4_0;
    wire c4_1_i0, c4_1_i1, c4_1_i2, c4_1_i3, c4_1;
    wire c4;

    // cin=0
    fulladd_gate b4f0_0 (sum4_0[0], c4_0_i0, a_mid_q[11], b_mid_q[11], 1'b0);
    fulladd_gate b4f1_0 (sum4_0[1], c4_0_i1, a_mid_q[12], b_mid_q[12], c4_0_i0);
    fulladd_gate b4f2_0 (sum4_0[2], c4_0_i2, a_mid_q[13], b_mid_q[13], c4_0_i1);
    fulladd_gate b4f3_0 (sum4_0[3], c4_0_i3, a_mid_q[14], b_mid_q[14], c4_0_i2);
    fulladd_gate b4f4_0 (sum4_0[4], c4_0,    a_mid_q[15], b_mid_q[15], c4_0_i3);
    // cin=1
    fulladd_gate b4f0_1 (sum4_1[0], c4_1_i0, a_mid_q[11], b_mid_q[11], 1'b1);
    fulladd_gate b4f1_1 (sum4_1[1], c4_1_i1, a_mid_q[12], b_mid_q[12], c4_1_i0);
    fulladd_gate b4f2_1 (sum4_1[2], c4_1_i2, a_mid_q[13], b_mid_q[13], c4_1_i1);
    fulladd_gate b4f3_1 (sum4_1[3], c4_1_i3, a_mid_q[14], b_mid_q[14], c4_1_i2);
    fulladd_gate b4f4_1 (sum4_1[4], c4_1,    a_mid_q[15], b_mid_q[15], c4_1_i3);
    // MUX
    mux2to1 b4m0 (sum4[0], sum4_0[0], sum4_1[0], c3);
    mux2to1 b4m1 (sum4[1], sum4_0[1], sum4_1[1], c3);
    mux2to1 b4m2 (sum4[2], sum4_0[2], sum4_1[2], c3);
    mux2to1 b4m3 (sum4[3], sum4_0[3], sum4_1[3], c3);
    mux2to1 b4m4 (sum4[4], sum4_0[4], sum4_1[4], c3);
    mux2to1 b4mc (c4,      c4_0,      c4_1,      c3);

    // =========================================
    // Stage 2: Block 5 (6-bit carry select, bits [21:16])
    // =========================================
    wire [5:0] sum5_0, sum5_1, sum5;
    wire c5_0_i0, c5_0_i1, c5_0_i2, c5_0_i3, c5_0_i4, c5_0;
    wire c5_1_i0, c5_1_i1, c5_1_i2, c5_1_i3, c5_1_i4, c5_1;
    wire c5;

    // cin=0
    fulladd_gate b5f0_0 (sum5_0[0], c5_0_i0, a_mid_q[16], b_mid_q[16], 1'b0);
    fulladd_gate b5f1_0 (sum5_0[1], c5_0_i1, a_mid_q[17], b_mid_q[17], c5_0_i0);
    fulladd_gate b5f2_0 (sum5_0[2], c5_0_i2, a_mid_q[18], b_mid_q[18], c5_0_i1);
    fulladd_gate b5f3_0 (sum5_0[3], c5_0_i3, a_mid_q[19], b_mid_q[19], c5_0_i2);
    fulladd_gate b5f4_0 (sum5_0[4], c5_0_i4, a_mid_q[20], b_mid_q[20], c5_0_i3);
    fulladd_gate b5f5_0 (sum5_0[5], c5_0,    a_mid_q[21], b_mid_q[21], c5_0_i4);
    // cin=1
    fulladd_gate b5f0_1 (sum5_1[0], c5_1_i0, a_mid_q[16], b_mid_q[16], 1'b1);
    fulladd_gate b5f1_1 (sum5_1[1], c5_1_i1, a_mid_q[17], b_mid_q[17], c5_1_i0);
    fulladd_gate b5f2_1 (sum5_1[2], c5_1_i2, a_mid_q[18], b_mid_q[18], c5_1_i1);
    fulladd_gate b5f3_1 (sum5_1[3], c5_1_i3, a_mid_q[19], b_mid_q[19], c5_1_i2);
    fulladd_gate b5f4_1 (sum5_1[4], c5_1_i4, a_mid_q[20], b_mid_q[20], c5_1_i3);
    fulladd_gate b5f5_1 (sum5_1[5], c5_1,    a_mid_q[21], b_mid_q[21], c5_1_i4);
    // MUX
    mux2to1 b5m0 (sum5[0], sum5_0[0], sum5_1[0], c4);
    mux2to1 b5m1 (sum5[1], sum5_0[1], sum5_1[1], c4);
    mux2to1 b5m2 (sum5[2], sum5_0[2], sum5_1[2], c4);
    mux2to1 b5m3 (sum5[3], sum5_0[3], sum5_1[3], c4);
    mux2to1 b5m4 (sum5[4], sum5_0[4], sum5_1[4], c4);
    mux2to1 b5m5 (sum5[5], sum5_0[5], sum5_1[5], c4);
    mux2to1 b5mc (c5,      c5_0,      c5_1,      c4);

    // =========================================
    // Output DFF
    // =========================================
    reg [22:0] sum_q;

    always @(posedge clk) begin
        if (!rstn)
            sum_q <= 0;
        else
            sum_q <= {c5, sum5, sum4, sum3, sum_low_q};
    end

    assign sum = sum_q;

endmodule

// =========================================
// Gate-level Full Adder
// =========================================
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

// =========================================
// Gate-level 2:1 MUX
// =========================================
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

// =========================================
// Input DFF
// =========================================
module DFF_input (
    output reg [21:0] a_q, b_q,
    output reg c_in_q,
    input [21:0] a, b,
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