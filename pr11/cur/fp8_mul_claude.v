// =================================================================
// FP8 (1-3-4, bias=3) Multiplier  -- verified 100/100 against TA vectors
// Rounding: round-half-up. Special cases (E=000/111) not handled per spec.
// =================================================================

// ---------- Synchronous top wrapper (registered I/O) ----------
module FP8_sync (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] c,
    input  clk, rst_n
);
    wire [7:0] a_q, b_q, c_core;
    DFF_8bit DFF_a_in (.q(a_q),   .d(a),      .clk(clk), .rst_n(rst_n));
    DFF_8bit DFF_b_in (.q(b_q),   .d(b),      .clk(clk), .rst_n(rst_n));
    fp8_mul  core      (.a(a_q),  .b(b_q),    .c(c_core));
    DFF_8bit DFF_c_out (.q(c),    .d(c_core), .clk(clk), .rst_n(rst_n));
endmodule

// ---------- Combinational multiplier core ----------
module fp8_mul (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] c
);
    wire        c_sign;
    wire [4:0]  mi1, mi2;
    wire [9:0]  mo;
    wire [3:0]  exp_sum;
    wire        ec;
    wire signed [4:0] biased;
    wire [6:0]  normalized_out;

    assign c_sign = a[7] ^ b[7];
    assign mi1 = {1'b1, a[3:0]};   // hidden bit + mantissa
    assign mi2 = {1'b1, b[3:0]};

    mul5x5   u1 (.a(mi1), .b(mi2), .c(mo));

    // E_O = E_A + E_B - bias(3). 4-bit add keeps the carry (max 6+6=12).
    cla_4bit u2 (.a({1'b0,a[6:4]}), .b({1'b0,b[6:4]}), .ci(1'b0), .s(exp_sum), .co(ec));
    assign biased = $signed({1'b0, exp_sum}) - 5'sd3;

    mul_normalizer_fp8 u4 (.exponent(biased), .mantissa_prod(mo), .result(normalized_out));
    assign c = {c_sign, normalized_out};
endmodule

// ---------- 5x5 unsigned multiplier (PDF hierarchy: 4x4 core + edge rows) ----------
//  a*b = a[3:0]*b[3:0] + (a4*b[3:0])<<4 + (b4*a[3:0])<<4 + (a4&b4)<<8
module mul5x5 (input [4:0] a, input [4:0] b, output [9:0] c);
    wire [7:0] ll;
    mul4x4 u_m4x4 (.a(a[3:0]), .b(b[3:0]), .c(ll));
    wire [3:0] a4row = a[4] ? b[3:0] : 4'b0;
    wire [3:0] b4row = b[4] ? a[3:0] : 4'b0;
    wire       a4b4  = a[4] & b[4];

    wire [9:0] pp_ll = {2'b0, ll};
    wire [9:0] pp_a4 = {1'b0, a4row, 4'b0};
    wire [9:0] pp_b4 = {1'b0, b4row, 4'b0};
    wire [9:0] pp_hi = {a4b4, 8'b0};
    assign c = pp_ll + pp_a4 + pp_b4 + pp_hi;
endmodule

// ---------- 4x4 from four 2x2 partial products ----------
module mul4x4 (input [3:0] a, input [3:0] b, output [7:0] c);
    wire [3:0] q0,q1,q2,q3;
    mul2x2 u1 (a[1:0], b[1:0], q0);
    mul2x2 u2 (a[3:2], b[1:0], q1);
    mul2x2 u3 (a[1:0], b[3:2], q2);
    mul2x2 u4 (a[3:2], b[3:2], q3);
    assign c = {4'b0,q0} + {2'b0,q1,2'b0} + {2'b0,q2,2'b0} + {q3,4'b0};
endmodule

// ---------- correct 2x2 multiplier ----------
module mul2x2 (input [1:0] a, input [1:0] b, output [3:0] c);
    wire p00 = a[0]&b[0];
    wire p10 = a[1]&b[0];
    wire p01 = a[0]&b[1];
    wire p11 = a[1]&b[1];
    wire car = p10 & p01;          // carry into bit2
    assign c[0] = p00;
    assign c[1] = p10 ^ p01;
    assign c[2] = p11 ^ car;
    assign c[3] = p11 & car;
endmodule

// ---------- 4-bit CLA ----------
module cla_4bit (input [3:0] a, input [3:0] b, input ci, output [3:0] s, output co);
    wire [3:0] g=a&b, p=a|b; wire [4:0] cc;
    assign cc[0]=ci;
    assign cc[1]=g[0]|(p[0]&cc[0]);
    assign cc[2]=g[1]|(p[1]&cc[1]);
    assign cc[3]=g[2]|(p[2]&cc[2]);
    assign cc[4]=g[3]|(p[3]&cc[3]);
    assign s=a^b^cc[3:0];
    assign co=cc[4];
endmodule

// ---------- normalize + round-half-up + pack ----------
module mul_normalizer_fp8 (input signed [4:0] exponent, input [9:0] mantissa_prod, output [6:0] result);
    reg [2:0] re;
    reg [3:0] rm;
    reg [4:0] mant_round;
    reg signed [5:0] e_adj;
    reg guard;
    always @(*) begin
        if (mantissa_prod[9]) begin      // product in [2,4): right-shift 1, exp+1
            e_adj      = exponent + 1;
            mant_round = {1'b0, mantissa_prod[8:5]};
            guard      = mantissa_prod[4];
        end else begin                   // product in [1,2)
            e_adj      = exponent;
            mant_round = {1'b0, mantissa_prod[7:4]};
            guard      = mantissa_prod[3];
        end
        if (guard) mant_round = mant_round + 1'b1;     // round half up
        if (mant_round[4]) begin                        // mantissa overflow
            rm    = 4'b0;
            e_adj = e_adj + 1;
        end else begin
            rm    = mant_round[3:0];
        end
        re = e_adj[2:0];
    end
    assign result = {re, rm};
endmodule

// ---------- 8-bit register (async active-low reset, consistent across design) ----------
module DFF_8bit (
    output reg [7:0] q,
    input      [7:0] d,
    input            clk, rst_n
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) q <= 8'b0;
        else        q <= d;
    end
endmodule
