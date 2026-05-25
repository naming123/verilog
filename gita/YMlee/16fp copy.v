module fp16_mul (
`ifdef PIPLINE
    input         clk,      // 파이프라인 모드용 클록
    input         rst_n,    // 파이프라인 모드용 리셋 (Active Low)
`endif
    input  [15:0] a,        // 입력 Floating Point A
    input  [15:0] b,        // 입력 Floating Point B
    output [15:0] c,        // 최종 곱셈 결과
    output        error     // 오버플로우/언더플로우 발생 플래그
    );

    // 내부 신호 선언
    wire [15:0] c_tmp;
    wire        c_sign, a_zero, b_zero;
    wire [4:0]  sum_exponent, biased_sum_exponent;
    wire [15:0] multiplier_input1, multiplier_input2;

    wire [31:0] multiplier_output;
    wire [14:0] normalized_out;
    wire [21:0] mantissa_prod;
    wire        c1, c2, underflow, overflow;

    // -----------------------------------------------------------------
    // [1단계] 부호(Sign) 및 예외 감지
    // -----------------------------------------------------------------
    assign a_zero = ~(|a);         // A가 0인지 검사
    assign b_zero = ~(|b);         // B가 0인지 검사
    assign c_sign = a[15] ^ b[15]; // 부호 비트 결정 (XOR: 다르면 음수, 같으면 양수)

    // -----------------------------------------------------------------
    // [2단계] 지수부(Exponent) 연산 (덧셈 및 Bias 차감)
    // -----------------------------------------------------------------
    // u2: 두 지수부(5비트)를 더함 -> sum_exponent
    cla_nbit #(.n(5)) u2(a[14:10], b[14:10], 1'b0, sum_exponent, c1); 
    
    // u3: 부동소수점 곱셈 공식에 따라 Bias(15)를 빼줌 -> biased_sum_exponent
    cla_nbit #(.n(5)) u3(sum_exponent, 5'b10001, 1'b0, biased_sum_exponent, c2); 

    // 지수 연산 결과 캐리(c1, c2) 분석을 통한 에러 감지
    assign overflow  = (c1 && c2 && ~biased_sum_exponent[4]) ? 1'b1 : 1'b0;
    assign underflow = (~c1 && ~c2 && biased_sum_exponent[4]) ? 1'b1 : 1'b0;
    assign error     = overflow | underflow; 

    // -----------------------------------------------------------------
    // [3단계] 가수부(Mantissa) 전처리 및 곱셈기 입력
    // -----------------------------------------------------------------
    // 입력 부호(7번 비트)에 따라 양수/음수(2의 보수)를 판단하여 16비트 곱셈기 입력으로 변환
    assign multiplier_input1 = (a[7]==1'b0) ? {9'b0, a[6:0]} : {9'b0, ~a[6:0]+1'b1};
    assign multiplier_input2 = (b[7]==1'b0) ? {9'b0, b[6:0]} : {9'b0, ~b[6:0]+1'b1};

`ifdef PIPLINE
    // --- [파이프라인 모드] 중간 결과를 레지스터에 저장 (1클록 지연) ---
    reg [31:0] multiplier_output_tmp;
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplier_output_tmp <= 32'b0;
        end else begin
            multiplier_output_tmp <= multiplier_output;
        end
    end
    
    assign mantissa_prod = multiplier_output_tmp[21:0];
    // 16비트 계층형 곱셈기 인스턴스 (클록/리셋 공급)
    mul16x16 u1(clk, rst_n, multiplier_input1, multiplier_input2, multiplier_output);

`else 
    // --- [조합회로 모드] 지연 없이 바로 연결 ---
    assign mantissa_prod = multiplier_output[21:0];
    // 16비트 계층형 곱셈기 인스턴스 (순수 연산)
    mul16x16 u1(multiplier_input1, multiplier_input2, multiplier_output);

`endif

    // -----------------------------------------------------------------
    // [4단계] 정규화 및 최종 조립
    // -----------------------------------------------------------------
    // u4: 곱셈 결과에 따라 소수점 위치를 잡고 지수를 보정함
    mul_normalizer u4(biased_sum_exponent, mantissa_prod, normalized_out);

    // 곱셈기 결과 부호 처리
    assign c = (a[7]^b[7] == 1'b0) ? multiplier_output[15:0] : {1'b1, ~multiplier_output[14:0]+1'b1};

    // 에러 발생 여부에 따른 최종 출력 선택 (정상 / 언더플로우=0 / 오버플로우=최댓값)
    assign c_tmp = (~error) ? {c_sign, normalized_out} : 
                              (underflow ? {c_sign, 15'b0000_0000_0000_000} : 
                                           {c_sign, 5'b1111_1, 10'b0000_0000_00});

endmodule