module ripple_carry_adder_22bit_2stage (
    output [22:0] sum,
    input  [21:0] a, b,
    input         c_in, clk, rstn
);

    // Stage 1 입력 레지스터 출력
    wire        c_in_q;
    wire [21:0] a_q, b_q;

    // Stage 1 결과 (하위 11-bit RCA)
    wire [10:0] sum_low_d;
    wire        c_mid_d;

    // 중간 레지스터 출력
    reg  [10:0] sum_low_q;
    reg         c_mid_q;
    reg  [21:11] a_mid_q, b_mid_q;

    // Stage 2 결과 (상위 11-bit RCA)
    wire [11:0] sum_high_d;

    // 출력 레지스터
    reg  [22:0] sum_q;

    // -------------------------
    // 입력 DFF
    // -------------------------
    DFF_input DFF_in (
        .a_q(a_q), .b_q(b_q), .c_in_q(c_in_q),
        .a(a), .b(b), .c_in(c_in),
        .clk(clk), .rstn(rstn)
    );

    // -------------------------
    // Stage 1: 하위 11-bit RCA (bit 0~10)
    // -------------------------
    wire [9:0] c_s1;

    fulladd_gate fa00 (sum_low_d[0],  c_s1[0], a_q[0],  b_q[0],  c_in_q);
    fulladd_gate fa01 (sum_low_d[1],  c_s1[1], a_q[1],  b_q[1],  c_s1[0]);
    fulladd_gate fa02 (sum_low_d[2],  c_s1[2], a_q[2],  b_q[2],  c_s1[1]);
    fulladd_gate fa03 (sum_low_d[3],  c_s1[3], a_q[3],  b_q[3],  c_s1[2]);
    fulladd_gate fa04 (sum_low_d[4],  c_s1[4], a_q[4],  b_q[4],  c_s1[3]);
    fulladd_gate fa05 (sum_low_d[5],  c_s1[5], a_q[5],  b_q[5],  c_s1[4]);
    fulladd_gate fa06 (sum_low_d[6],  c_s1[6], a_q[6],  b_q[6],  c_s1[5]);
    fulladd_gate fa07 (sum_low_d[7],  c_s1[7], a_q[7],  b_q[7],  c_s1[6]);
    fulladd_gate fa08 (sum_low_d[8],  c_s1[8], a_q[8],  b_q[8],  c_s1[7]);
    fulladd_gate fa09 (sum_low_d[9],  c_s1[9], a_q[9],  b_q[9],  c_s1[8]);
    fulladd_gate fa10 (sum_low_d[10], c_mid_d, a_q[10], b_q[10], c_s1[9]);

    // -------------------------
    // 중간 DFF (Stage 1 → Stage 2)
    // -------------------------
    always @(posedge clk) begin
        if (!rstn) begin
            sum_low_q <= 0;
            c_mid_q   <= 0;
            a_mid_q   <= 0;
            b_mid_q   <= 0;
        end else begin
            sum_low_q <= sum_low_d;
            c_mid_q   <= c_mid_d;
            a_mid_q   <= a_q[21:11];
            b_mid_q   <= b_q[21:11];
        end
    end

    // -------------------------
    // Stage 2: 상위 11-bit RCA (bit 11~21)
    // -------------------------
    wire [9:0] c_s2;

    fulladd_gate fa11 (sum_high_d[0],  c_s2[0], a_mid_q[11], b_mid_q[11], c_mid_q);
    fulladd_gate fa12 (sum_high_d[1],  c_s2[1], a_mid_q[12], b_mid_q[12], c_s2[0]);
    fulladd_gate fa13 (sum_high_d[2],  c_s2[2], a_mid_q[13], b_mid_q[13], c_s2[1]);
    fulladd_gate fa14 (sum_high_d[3],  c_s2[3], a_mid_q[14], b_mid_q[14], c_s2[2]);
    fulladd_gate fa15 (sum_high_d[4],  c_s2[4], a_mid_q[15], b_mid_q[15], c_s2[3]);
    fulladd_gate fa16 (sum_high_d[5],  c_s2[5], a_mid_q[16], b_mid_q[16], c_s2[4]);
    fulladd_gate fa17 (sum_high_d[6],  c_s2[6], a_mid_q[17], b_mid_q[17], c_s2[5]);
    fulladd_gate fa18 (sum_high_d[7],  c_s2[7], a_mid_q[18], b_mid_q[18], c_s2[6]);
    fulladd_gate fa19 (sum_high_d[8],  c_s2[8], a_mid_q[19], b_mid_q[19], c_s2[7]);
    fulladd_gate fa20 (sum_high_d[9],  c_s2[9], a_mid_q[20], b_mid_q[20], c_s2[8]);
    fulladd_gate fa21 (sum_high_d[10], sum_high_d[11], a_mid_q[21], b_mid_q[21], c_s2[9]);

    // -------------------------
    // 출력 DFF
    // -------------------------
    always @(posedge clk) begin
        if (!rstn)
            sum_q <= 0;
        else
            sum_q <= {sum_high_d[11:0], sum_low_q[10:0]};
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