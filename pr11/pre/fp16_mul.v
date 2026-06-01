// =================================================================
// 1. FP8 Synchronous Top Wrapper
// =================================================================
module FP8_sync (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] c,
    input clk, rst_n
);
    wire [7:0] a_q, b_q, c_q;

    DFF_8bit DFF_a_in (.q(a_q), .d(a), .clk(clk), .rst_n(rst_n));
    DFF_8bit DFF_b_in (.q(b_q), .d(b), .clk(clk), .rst_n(rst_n));

    fp8_mul fp8_sync_core (.clk(clk), .rst_n(rst_n), .a(a_q), .b(b_q), .c(c_q));

    DFF_8bit DFF_c_out (.q(c), .d(c_q), .clk(clk), .rst_n(rst_n));

endmodule

// =================================================================
// 2. FP8 Multiplier Top Module (PDF 아키텍처 준수)
// =================================================================
module fp8_mul (
    input        clk,
    input        rst_n,
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] c
);

    wire        c_sign;
    wire [2:0]  sum_exponent, biased_sum_exponent;
    wire [4:0]  multiplier_input1, multiplier_input2;

    wire [9:0]  multiplier_output;
    wire [6:0]  normalized_out;
    wire [9:0]  mantissa_prod;
    wire        c1, c2;

    // 1. 부호 비트 결정 (Sign XOR)
    assign c_sign = a[7] ^ b[7];

    // 2. Hidden Bit '1'을 포함한 가수부 구성 (SEEEMMMM 구조 반영)
    // Exponent가 0일 때의 부동소수점 예외처리는 실습 스펙상 제외하므로 일반 1.M 형태로 패킹
    assign multiplier_input1 = {1'b1, a[3:0]};
    assign multiplier_input2 = {1'b1, b[3:0]};

    // 3. 1-Stage 파이프라인 레지스터 구조 (PDF 원래 코드 유지)
    reg [9:0] multiplier_output_tmp;
    reg       c_sign_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplier_output_tmp <= 10'b0;
            c_sign_q              <= 1'b0;
        end else begin
            multiplier_output_tmp <= multiplier_output;
            c_sign_q              <= c_sign;
        end
    end

    assign mantissa_prod = multiplier_output_tmp;

    // 4. 구조적 서브모듈 인스턴스화 (Structural Instantiation)
    // 가수부 곱셈용 5x5 곱셈기 (하위 계층 mul4x4, mul2x2 기반)
    mul5x5 u1 (
        .clk(clk),
        .rst_n(rst_n),
        .a(multiplier_input1),
        .b(multiplier_input2),
        .c(multiplier_output)
    );

    // 지수부 가산 및 bias 연산 (3비트 CLA 구조 적용)
    cla_3bit u2 (.a(a[6:4]), .b(b[6:4]), .ci(1'b0), .s(sum_exponent), .co(c1));        // Add Exponent
    cla_3bit u3 (.a(sum_exponent), .b(3'b101), .ci(1'b0), .s(biased_sum_exponent), .co(c2)); // Minus Bias (Subtract 3 = Add 2's complement 101)

    // 곱셈 결과 정규화 및 최종 패킹 모듈
    mul_normalizer_fp8 u4 (
        .exponent(biased_sum_exponent),
        .mantissa_prod(mantissa_prod),
        .result(normalized_out)
    );

    // 최종 8비트 패킹 출력 조립
    assign c = {c_sign_q, normalized_out};

endmodule

// =================================================================
// 3. PDF 구조를 반영한 하위 연산 컴포넌트 계층 설계
// =================================================================

// 5x5 가수부 곱셈기 (내부적으로 mul4x4와 2비트 곱셈 조합 레이아웃 구현)
module mul5x5 (
    input        clk,
    input        rst_n,
    input  [4:0] a,
    input  [4:0] b,
    output [9:0] c
);
    // PDF의 계층 구조 설계를 따르기 위해 상위 4비트는 기존 mul4x4를 활용하고,
    // LSB(0번 비트) 연산 영역을 확장하여 엮는 CLA 트리 구조로 유도합니다.
    wire [7:0] m4x4_out;
    wire [3:0] ext_a = a[0] ? b[4:1] : 4'b0;
    wire [4:0] ext_b = b[0] ? a[4:0] : 5'b0;
    
    mul4x4 u_m4x4 (.a(a[4:1]), .b(b[4:1]), .c(m4x4_out));

    // 부분곱(Partial Product) 병합 연산
    wire [9:0] pprod1 = {m4x4_out, 2'b0};
    wire [9:0] pprod2 = {4'b0, ext_a, 2'b0};
    wire [9:0] pprod3 = {5'b0, ext_b};

    assign c = pprod1 + pprod2 + pprod3;
endmodule

// PDF에 작성되어 있던 4x4 곱셈기 컴포넌트 구조 재활용
module mul4x4 (
    input  [3:0] a,
    input  [3:0] b,
    output [7:0] c
);
    wire [15:0] tmp1;
    wire [5:0]  result1;
    wire [5:0]  result2;
    wire        co1, co2, co3;

    mul2x2 u1 (a[3:2], b[3:2], tmp1[15:12]);
    mul2x2 u2 (a[1:0], b[3:2], tmp1[11:8]);
    mul2x2 u3 (a[3:2], b[1:0], tmp1[7:4]);
    mul2x2 u4 (a[1:0], b[1:0], tmp1[3:0]);

    cla_6bit u5 ({tmp1[15:12], 2'b0}, {2'b0, tmp1[11:8]}, 1'b0, result1, co1);
    cla_6bit u6 ({2'b0, tmp1[7:4]},   {4'b0, tmp1[3:2]},   co1,  result2, co2);
    cla_6bit u7 (result1,              result2,            co2,  c[7:2],  co3);

    assign c[1:0] = tmp1[3:0];
endmodule

module mul2x2 (
    input  [1:0] a,
    input  [1:0] b,
    output [3:0] c
);
    wire [3:0] tmp;
    
    assign tmp[0] = a[0] & b[0];
    assign tmp[1] = (a[1] & b[0]) ^ (a[0] & b[1]);
    assign tmp[2] = (a[0] & b[1]) & (a[1] & b[0]) ^ (a[1] & b[1]);
    assign tmp[3] = (a[0] & b[1]) & (a[1] & b[0]) & (a[1] & b[1]);
    assign c      = {tmp[3], tmp[2], tmp[1], tmp[0]};
endmodule

// =================================================================
// 4. 가산기 및 정규화(Normalizer) 모듈 디자인
// =================================================================

// FP8 지수 가산용 3-bit Carry Look-ahead Adder (CLA)
module cla_3bit (
    input  [2:0] a,
    input  [2:0] b,
    input        ci,
    output [2:0] s,
    output       co
);
    wire [2:0] g = a & b;
    wire [2:0] p = a | b;
    wire [3:0] c;

    assign c[0] = ci;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);

    assign s    = a ^ b ^ c[2:0];
    assign co   = c[3];
endmodule

module cla_6bit (
    input  [5:0] a,
    input  [5:0] b,
    input        ci,
    output [5:0] s,
    output       co
);
    wire [5:0] g = a & b;
    wire [5:0] p = a | b;
    wire [6:0] c;

    assign c[0] = ci;
    assign co   = c[6];

    genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : addbit
            assign s[i]     = a[i] ^ b[i] ^ c[i];
            assign c[i + 1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
endmodule

// FP8 스펙 규격 맞춤형 정규화기 (Normalization & Pack, 7비트 출력)
module mul_normalizer_fp8 (
    input  [2:0] exponent,
    input  [9:0] mantissa_prod,
    output [6:0] result
);
    wire [2:0] result_exponent;
    wire [3:0] result_mantissa;

    // 5x5 가수부 곱 결과물(10비트)의 MSB [9]번 비트가 1이면 결과가 2 이상이므로 우측 시프트 및 지수 +1 수행
    assign result_exponent = (mantissa_prod[9]) ? (exponent + 1'b1) : exponent;
    
    // 유효 소수점 아래 4비트(M) 추출
    assign result_mantissa = (mantissa_prod[9]) ? mantissa_prod[8:5] : mantissa_prod[7:4];
    
    assign result          = {result_exponent, result_mantissa};
endmodule

module DFF_8bit (
    output reg [7:0] q,
    input      [7:0] d,
    input            clk, rst_n
);
    always @(posedge clk) begin
        if (!rst_n)
            q <= 8'b0;
        else
            q <= d;
    end
endmodule