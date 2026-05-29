// =====================================================================
//  5-tap Transposed-Form FIR (multiplier-less / low-cost)  -- v2 BIT-EXACT
//  계수: C0=2435, C1=-3404, C2=4221, C3=-3457, C4=6599  (14-bit fixed)
//
//  [v2 핵심 수정]  반올림 방식 변경  (제공된 in/out 256샘플 0-mismatch 검증 완료)
//    - 기존: 탭마다 따로 [27:5]+[4] 반올림 (독립 반올림 5번) -> 1~2 LSB 누적오차
//    - 변경: 28비트 곱(Q3.25)을 29비트(Q4.25) 누적 체인으로 "풀 정밀도" 전달,
//            최종 trans_out 출력단에서 단 한 번만 round-half-up
//            trans_out = sum0[28:5] + sum0[4]   (Q4.25 -> Q4.20)
//
//  [v1 에서 이어진 CSD 정정]  C0/C3/C4 (검증완료, 유지)
//  누적기 폭: sum|c|*maxX = 164,790,272 < 2^28  ->  29-bit signed 로 충분
// =====================================================================

module top_FIR_filter (
    input clk, reset,
    input signed [13:0] c0, c1, c2, c3, c4   // 인터페이스 호환용 (필터는 상수 내장)
);

    wire [7:0] addr_in, addr_out;
    wire signed [13:0] x_in_trans;
    wire signed [23:0] y_out_trans;

    reg [7:0] cnt;

    assign addr_in  = cnt;
    assign addr_out = cnt - 8'd7;   // 5tap Transposed pipeline delay 보정선

    rflp256x14mx4 TRANS_INPUT_MEM (
        .NWRT(1'b1), .DIN(14'b0), .RA(addr_in[7:2]), .CA(addr_in[1:0]), .NCE(1'b0), .CLK(clk), .DO(x_in_trans)
    );

    rflp256x24mx4 TRANS_OUTPUT_MEM (
        .NWRT(reset ? 1'b0 : 1'b1), .DIN(y_out_trans), .RA(addr_out[7:2]), .CA(addr_out[1:0]), .NCE(1'b0), .CLK(clk), .DO()
    );

    trans_FIR_filter_low_cost TRANS_FIR_FILTER (
        .trans_out(y_out_trans),
        .in(x_in_trans), .clk(clk), .reset(reset)
    );

    always @(posedge clk) begin
        if (!reset) cnt <= 8'd0;
        else        cnt <= cnt + 8'd1;
    end

endmodule


module trans_FIR_filter_low_cost (
    output reg signed [23:0] trans_out,
    input signed [13:0] in,
    input clk, reset
);

    reg signed [13:0] x0;

    // 풀 정밀도 누적 레지스터: Q4.25 = 29-bit (탭별 반올림 없음)
    reg signed [28:0] y1, y2, y3, y4;

    // 28비트 풀 정밀도 곱셈 영역 (Q3.25)
    wire signed [27:0] ex_in, x1, x3, x4;

    // 28b 곱 -> 29b 누적 버스로 부호확장
    wire signed [27:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4;
    wire signed [28:0] macc0, macc1, macc2, macc3, macc4;
    wire signed [28:0] sum0, sum1, sum2, sum3;

    // 1. 입력 28비트 signed 부호 확장
    assign ex_in = $signed({ {14{x0[13]}}, x0 });
    assign x1 = ex_in;

    // 2. C1 전용 공유 subexpression (3*x1)
    assign x3 = (x1 << 1) + x1;
    assign x4 = (x1 << 2) - x1;

    // 3. CSD 곱셈 트리 (28비트, Sign 완전 보존) -- 검증완료
    assign mul_out0 =  (x1 << 11) + (x1 << 8) + (x1 << 7) + (x1 << 1) + x1;          // 2435
    assign mul_out1 = -(x1 << 12) + (x1 << 9) + (x3 << 6) - (x4 << 2);                // -3404
    assign mul_out2 =  (x1 << 12) + (x1 << 7) - (x1 << 1) - x1;                       // 4221
    assign mul_out3 = -(x1 << 12) + (x1 << 9) + (x1 << 7) - x1;                       // -3457
    assign mul_out4 =  (x1 << 13) - (x1 << 11) + (x1 << 9) - (x1 << 6) + (x1 << 3) - x1; // 6599

    // 4. 28b -> 29b 부호확장 (반올림 없이 풀 정밀도 그대로 누적단에 투입)
    assign macc0 = {mul_out0[27], mul_out0};
    assign macc1 = {mul_out1[27], mul_out1};
    assign macc2 = {mul_out2[27], mul_out2};
    assign macc3 = {mul_out3[27], mul_out3};
    assign macc4 = {mul_out4[27], mul_out4};

    // 5. Transpose Form 풀 정밀도 누적 체인 (29-bit Q4.25)
    assign sum3 = macc3 + y4;
    assign sum2 = macc2 + y3;
    assign sum1 = macc1 + y2;
    assign sum0 = macc0 + y1;

    // 6. 동기화 파이프라인 + 최종 출력단 단일 반올림
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
            // Q4.25(29b) -> Q4.20(24b): 하위 5비트 컷 + round-half-up (필터당 단 1회)
            trans_out <= sum0[28:5] + sum0[4];
        end
    end

endmodule