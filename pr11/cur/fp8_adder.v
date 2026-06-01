// =================================================================
// FP8 (1-3-4, bias=3) Adder  -- verified 100/100 against TA vectors
// Rounding: round-half-up. Special cases (E=000/111) not handled per spec.
// =================================================================

// ---------- Synchronous top wrapper (registered I/O) ----------
module FP8_adder_sync (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] c,
    input  clk, rst_n
);
    wire [7:0] a_q, b_q, c_core;
    DFF_8bit DFF_a_in (.q(a_q),   .d(a),      .clk(clk), .rst_n(rst_n));
    DFF_8bit DFF_b_in (.q(b_q),   .d(b),      .clk(clk), .rst_n(rst_n));
    fp8_add  core      (.a(a_q),  .b(b_q),    .c(c_core));
    DFF_8bit DFF_c_out (.q(c),    .d(c_core), .clk(clk), .rst_n(rst_n));
endmodule

// ---------- Combinational adder core ----------
module fp8_add (input [7:0] a, input [7:0] b, output [7:0] c);
    wire        a_sign, b_sign, c_sign, if_sub;
    reg  [6:0]  bigger, smaller;
    reg         a_larger_b;

    assign a_sign = a[7];
    assign b_sign = b[7];
    assign if_sub = (a_sign ^ b_sign);            // opposite signs -> subtract
    assign c_sign = a_larger_b ? a_sign : b_sign;

    // magnitude compare on lower 7 bits {E[2:0], M[3:0]}
    always @(*) begin
        if (a[6:0] > b[6:0]) begin
            bigger = a[6:0]; smaller = b[6:0]; a_larger_b = 1'b1;
        end else begin
            bigger = b[6:0]; smaller = a[6:0]; a_larger_b = 1'b0;
        end
    end

    // exponent difference -> right-shift amount for the smaller operand
    wire [2:0] shift_bits;
    cla_nbit #(.n(3)) ush (.a(bigger[6:4]), .b(~smaller[6:4] + 1'b1), .ci(1'b0),
                           .s(shift_bits), .co());

    // wide fixed-point datapath: [hidden | M3..M0 | 6 guard/sticky bits], value = w / 2^6
    wire [10:0] big_w = {1'b1, bigger[3:0],  6'b0};
    wire [10:0] sm_w0 = {1'b1, smaller[3:0], 6'b0};
    wire [10:0] sm_w  = sm_w0 >> shift_bits;                  // aligned smaller

    wire [11:0] mag_w = if_sub ? (big_w - sm_w) : (big_w + sm_w);

    add_normalizer_fp8 u_norm (.sign(c_sign), .exponent(bigger[6:4]),
                               .mag(mag_w), .result(c));
endmodule

// ---------- normalize (carry / leading-zero) + round-half-up + pack ----------
// mag: 12-bit fixed point, nominal hidden bit at position 10 (value = mag / 2^6)
module add_normalizer_fp8 (
    input             sign,
    input      [2:0]  exponent,
    input      [11:0] mag,
    output reg [7:0]  result
);
    reg [3:0]  msb;
    reg signed [4:0] e;
    reg [3:0]  mant;
    reg        guard;
    reg [4:0]  mant5;
    integer k;

    always @(*) begin
        // leading-one position
        msb = 4'd0;
        for (k = 0; k < 12; k = k + 1) if (mag[k]) msb = k[3:0];

        if (mag == 12'b0) begin
            result = 8'b0;                                  // exact zero
        end else begin
            // hidden bit nominally at bit 10 -> adjust exponent by (msb-10)
            e     = $signed({1'b0, exponent}) + ($signed({1'b0, msb}) - 5'sd10);
            mant  = (mag >> (msb - 4)) & 4'hF;              // 4 mantissa bits below leading one
            guard = (msb >= 5) ? ((mag >> (msb - 5)) & 1'b1) : 1'b0;

            mant5 = {1'b0, mant};
            if (guard) mant5 = mant5 + 1'b1;                // round half up
            if (mant5[4]) begin                             // 1.1111 + 1 -> 10.0000
                e    = e + 1;
                mant = 4'b0;
            end else begin
                mant = mant5[3:0];
            end

            result[7]   = sign;
            result[6:4] = e[2:0];
            result[3:0] = mant;
        end
    end
endmodule

// ---------- parameterized CLA ----------
module cla_nbit #(parameter n = 4) (
    input  [n-1:0] a, input [n-1:0] b, input ci, output [n-1:0] s, output co
);
    wire [n-1:0] g = a & b, p = a | b; wire [n:0] c;
    assign c[0] = ci; assign co = c[n];
    genvar i;
    generate for (i = 0; i < n; i = i + 1) begin : addbit
        assign s[i]   = a[i] ^ b[i] ^ c[i];
        assign c[i+1] = g[i] | (p[i] & c[i]);
    end endgenerate
endmodule

// ---------- 8-bit register (async active-low reset) ----------
module DFF_8bit (
    output reg [7:0] q, input [7:0] d, input clk, rst_n
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) q <= 8'b0;
        else        q <= d;
endmodule