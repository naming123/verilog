// =====================================================================
//  5-tap FIR Synthesis Top -- v2 BIT-EXACT Full-Precision Edition
//  계수: C0=2435, C1=-3404, C2=4221, C3=-3457, C4=6599  (14-bit fixed)
// =====================================================================

module top_FIR_filter_synthesis (
    input clk, reset,
    input signed [13:0] c0, c1, c2, c3, c4,
    input signed [13:0] x_in,              // 외부 입력 데이터
    output reg signed [23:0] y_out_direct, // DFF 라우팅 완료 Direct 출력
    output reg signed [23:0] y_out_trans   // DFF 라우팅 완료 Transposed 출력
);

    reg signed [13:0] x_in_reg;
    wire signed [23:0] y_filtered_direct;
    wire signed [23:0] y_filtered_trans;

    // 1. Input D-FlipFlop (입력 타이밍 안정화)
    always @(posedge clk) begin
        if (!reset) begin
            x_in_reg <= 14'd0;
        end else begin
            x_in_reg <= x_in;
        end
    end

    // 2. Direct Form FIR Filter 인스턴스화 (BIT-EXACT 적용 완료)
    direct_FIR_filter DIRECT_FIR_FILTER (
        .direct_out(y_filtered_direct),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4),
        .in(x_in_reg),
        .clk(clk),
        .reset(reset)
    );

    // 3. Transposed Form FIR Filter 인스턴스화 (BIT-EXACT 적용 완료)
    trans_FIR_filter TRANS_FIR_FILTER (
        .trans_out(y_filtered_trans),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4),
        .in(x_in_reg),
        .clk(clk),
        .reset(reset)
    );

    // 4. Output D-FlipFlop (출력 타이밍 안정화)
    always @(posedge clk) begin
        if (!reset) begin
            y_out_direct <= 24'd0;
            y_out_trans  <= 24'd0;
        end else begin
            y_out_direct <= y_filtered_direct;
            y_out_trans  <= y_filtered_trans;
        end
    end

endmodule


module direct_FIR_filter (
    output reg signed [23:0] direct_out,
    input signed [13:0] c0, c1, c2, c3, c4,
    input signed [13:0] in,
    input clk, reset
);

    reg signed [13:0] x0, x1, x2, x3, x4;

    // 28비트 풀 정밀도 개별 탭 곱셈 영역 (Q3.25)
    wire signed [27:0] ex_x0, ex_x1, ex_x2, ex_x3, ex_x4;
    wire signed [27:0] mul0, mul1, mul2, mul3, mul4;
    
    // 오차 누적 방지를 위한 31비트 풀 정밀도 합산 공간 (Q6.25)
    wire signed [30:0] sum_out;

    // 개별 레지스터 signed 부호 확장
    assign ex_x0 = $signed({ {14{x0[13]}}, x0 });
    assign ex_x1 = $signed({ {14{x1[13]}}, x1 });
    assign ex_x2 = $signed({ {14{x2[13]}}, x2 });
    assign ex_x3 = $signed({ {14{x3[13]}}, x3 });
    assign ex_x4 = $signed({ {14{x4[13]}}, x4 });

    // CSD 내장형 멀티플라이어리스 트리 빌드
    assign mul0 =  (ex_x0 << 11) + (ex_x0 << 8) + (ex_x0 << 7) + (ex_x0 << 1) + ex_x0;
    assign mul1 = -(ex_x1 << 12) + (ex_x1 << 9) + (((ex_x1 << 1) + ex_x1) << 6) - (((ex_x1 << 2) - ex_x1) << 2);
    assign mul2 =  (ex_x2 << 12) + (ex_x2 << 7) - (ex_x2 << 1) - ex_x2;
    assign mul3 = -(ex_x3 << 12) + (ex_x3 << 9) + (ex_x3 << 7) - ex_x3;
    assign mul4 =  (ex_x4 << 13) - (ex_x4 << 11) + (ex_x4 << 9) - (ex_x4 << 6) + (ex_x4 << 3) - ex_x4;

    // 탭별 독립 반올림을 완전히 삭제하고, 31비트 공간에서 한 번에 풀 누적
    assign sum_out = { {3{mul0[27]}}, mul0 } +
                     { {3{mul1[27]}}, mul1 } +
                     { {3{mul2[27]}}, mul2 } +
                     { {3{mul3[27]}}, mul3 } +
                     { {3{mul4[27]}}, mul4 };

    always @(posedge clk) begin
        if (!reset) begin
            x0 <= 14'd0;
            x1 <= 14'd0;
            x2 <= 14'd0;
            x3 <= 14'd0;
            x4 <= 14'd0;
            direct_out <= 24'd0;
        end
        else begin
            x0 <= in;
            x1 <= x0;
            x2 <= x1;
            x3 <= x2;
            x4 <= x3;
            // 최하단 통합 1회 반올림 연산 처리 (Q6.25 -> Q4.20 매핑)
            direct_out <= sum_out[28:5] + sum_out[4];
        end
    end

endmodule


module trans_FIR_filter (
    output reg signed [23:0] trans_out,
    input signed [13:0] c0, c1, c2, c3, c4,
    input signed [13:0] in,
    input clk, reset
);

    reg signed [13:0] x0;

    // 풀 정밀도(소수점 아래 25비트) 보존용 29비트(Q4.25) 누적 파이프라인
    reg signed [28:0] y1, y2, y3, y4;

    // 28비트 signed 내부 시프트 공간 (Q3.25)
    wire signed [27:0] ex_in, x1, x3, x4;
    wire signed [27:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4;
    
    // 29비트 확장선 및 누적 버스 와이어
    wire signed [28:0] macc0, macc1, macc2, macc3, macc4;
    wire signed [28:0] sum0, sum1, sum2, sum3;

    // 입력 데이터 28비트 부호 확장 완료
    assign ex_in = $signed({ {14{x0[13]}}, x0 });
    assign x1 = ex_in;

    // C1 전용 공통 서브 익스프레션
    assign x3 = (x1 << 1) + x1;
    assign x4 = (x1 << 2) - x1;

    // 정답 CSD 구조 복원 (28비트 부호 완전 사수)
    assign mul_out0 =  (x1 << 11) + (x1 << 8) + (x1 << 7) + (x1 << 1) + x1;          // C0 = 2435
    assign mul_out1 = -(x1 << 12) + (x1 << 9) + (x3 << 6) - (x4 << 2);                // C1 = -3404
    assign mul_out2 =  (x1 << 12) + (x1 << 7) - (x1 << 1) - x1;                       // C2 = 4221
    assign mul_out3 = -(x1 << 12) + (x1 << 9) + (x1 << 7) - x1;                       // C3 = -3457
    assign mul_out4 =  (x1 << 13) - (x1 << 11) + (x1 << 9) - (x1 << 6) + (x1 << 3) - x1; // C4 = 6599

    // 반올림을 생략하고 29비트 누적단으로 부호 비트 유지 채널링
    assign macc0 = {mul_out0[27], mul_out0};
    assign macc1 = {mul_out1[27], mul_out1};
    assign macc2 = {mul_out2[27], mul_out2};
    assign macc3 = {mul_out3[27], mul_out3};
    assign macc4 = {mul_out4[27], mul_out4};

    // Transposed 가산기 체인 링크 (29-bit 풀 정밀도 영역)
    assign sum3 = macc3 + y4;
    assign sum2 = macc2 + y3;
    assign sum1 = macc1 + y2;
    assign sum0 = macc0 + y1;

    always @(posedge clk) begin
        if (!reset) begin
            x0        <= 14'd0;
            y1        <= 29'd0;
            y2        <= 29'd0;
            y3        <= 29'd0;
            y4        <= 29'd0;
            trans_out <= 24'd0;
        end
        else begin
            x0        <= in;
            y4        <= macc4;
            y3        <= sum3;
            y2        <= sum2;
            y1        <= sum1;
            // 가산이 완전 차단된 종착점 sum0에서 단 1회 통합 반올림 연산 수행
            trans_out <= sum0[28:5] + sum0[4];
        end
    end

endmodule