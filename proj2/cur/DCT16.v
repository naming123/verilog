`timescale 1ns / 10ps
//============================================================================
//  dct16 : 16-point 1D-DCT core
//  - 곱셈은 상수 shift-add (mulc 함수, 자료 7번)
//  - 대칭성 활용: s_i = x_i + x_(15-i), d_i = x_i - x_(15-i)
//      짝수 출력 z[0,2,4,..,14] : s 만 사용
//      홀수 출력 z[1,3,5,..,15] : d 만 사용
//  - 계수 행렬은 C_quant_bit=9 (scale 2^9=512) 정수값, 출력 시 >>> SH
//
//  파라미터:
//    INW      : 입력 워드 비트폭
//    INSIGNED : 입력이 signed 인지 (0=unsigned 픽셀, 1=signed 계수)
//    SH       : 출력 시 산술 우시프트 양 (Row=9, Col=0  ※ Col 스케일은 Top quant 단)
//    OUTW     : 출력 워드 비트폭
//
//  입출력 패킹 : i_x = { ch0, ch1, ... , ch15 } (ch0 가 MSB)
//============================================================================
module dct16 #(
    parameter INW      = 8,
    parameter INSIGNED = 0,
    parameter SH       = 9,
    parameter OUTW     = 13
)(
    input  [16*INW-1:0]  i_x,
    output [16*OUTW-1:0] o_z
);

    //--------------------------------------------------------
    // 상수 shift-add 곱셈 (multiplier 미사용)
    //   지원 계수 : 18,35,53,69,85,101,115,128,140,151,160,167,173,178,180
    //   value 는 충분히 넓은 signed (입력 13b + 합산 여유)
    //--------------------------------------------------------
    function signed [31:0] mulc;
        input signed [31:0] value;
        input integer c;
        begin
            case (c)
                18 : mulc = (value <<< 4) + (value <<< 1);
                35 : mulc = (value <<< 5) + (value <<< 1) + value;
                53 : mulc = (value <<< 5) + (value <<< 4) + (value <<< 2) + value;
                69 : mulc = (value <<< 6) + (value <<< 2) + value;
                85 : mulc = (value <<< 6) + (value <<< 4) + (value <<< 2) + value;
               101 : mulc = (value <<< 6) + (value <<< 5) + (value <<< 2) + value;
               115 : mulc = (value <<< 6) + (value <<< 5) + (value <<< 4) + (value <<< 1) + value;
               128 : mulc = (value <<< 7);
               140 : mulc = (value <<< 7) + (value <<< 3) + (value <<< 2);
               151 : mulc = (value <<< 7) + (value <<< 4) + (value <<< 2) + (value <<< 1) + value;
               160 : mulc = (value <<< 7) + (value <<< 5);
               167 : mulc = (value <<< 7) + (value <<< 5) + (value <<< 2) + (value <<< 1) + value;
               173 : mulc = (value <<< 7) + (value <<< 5) + (value <<< 3) + (value <<< 2) + value;
               178 : mulc = (value <<< 7) + (value <<< 5) + (value <<< 4) + (value <<< 1);
               180 : mulc = (value <<< 7) + (value <<< 5) + (value <<< 4) + (value <<< 2);
               default: mulc = 32'sd0;
            endcase
        end
    endfunction

    //--------------------------------------------------------
    // 입력 언패킹 (signed 확장)
    //--------------------------------------------------------
    wire signed [INW:0] x [0:15];
    genvar n;
    generate
        for (n = 0; n < 16; n = n + 1) begin : UNPACK
            if (INSIGNED)
                assign x[n] = $signed(i_x[16*INW-1-INW*n -: INW]);
            else
                assign x[n] = $signed({1'b0, i_x[16*INW-1-INW*n -: INW]});
        end
    endgenerate

    //--------------------------------------------------------
    // 대칭 합/차 (s = 짝수 출력용, d = 홀수 출력용)
    //--------------------------------------------------------
    wire signed [INW+1:0] s [0:7];
    wire signed [INW+1:0] d [0:7];
    generate
        for (n = 0; n < 8; n = n + 1) begin : SD
            assign s[n] = x[n] + x[15-n];
            assign d[n] = x[n] - x[15-n];
        end
    endgenerate

    //--------------------------------------------------------
    // 누산 (acc[k]) — shift-add 곱셈 사용
    //   짝수 k : s[] 만, 홀수 k : d[] 만
    //   부호는 DCT 행렬 T[k][n] 의 부호를 그대로 반영
    //--------------------------------------------------------
    wire signed [31:0] acc [0:15];

    // ---- 짝수 출력 (s 사용) ----
    assign acc[ 0] = mulc(s[0],128)+mulc(s[1],128)+mulc(s[2],128)+mulc(s[3],128)
                   + mulc(s[4],128)+mulc(s[5],128)+mulc(s[6],128)+mulc(s[7],128);

    assign acc[ 2] = mulc(s[0],178)+mulc(s[1],151)+mulc(s[2],101)+mulc(s[3], 35)
                   - mulc(s[4], 35)-mulc(s[5],101)-mulc(s[6],151)-mulc(s[7],178);

    assign acc[ 4] = mulc(s[0],167)+mulc(s[1], 69)-mulc(s[2], 69)-mulc(s[3],167)
                   - mulc(s[4],167)-mulc(s[5], 69)+mulc(s[6], 69)+mulc(s[7],167);

    assign acc[ 6] = mulc(s[0],151)-mulc(s[1], 35)-mulc(s[2],178)-mulc(s[3],101)
                   + mulc(s[4],101)+mulc(s[5],178)+mulc(s[6], 35)-mulc(s[7],151);

    assign acc[ 8] = mulc(s[0],128)-mulc(s[1],128)-mulc(s[2],128)+mulc(s[3],128)
                   + mulc(s[4],128)-mulc(s[5],128)-mulc(s[6],128)+mulc(s[7],128);

    assign acc[10] = mulc(s[0],101)-mulc(s[1],178)+mulc(s[2], 35)+mulc(s[3],151)
                   - mulc(s[4],151)-mulc(s[5], 35)+mulc(s[6],178)-mulc(s[7],101);

    assign acc[12] = mulc(s[0], 69)-mulc(s[1],167)+mulc(s[2],167)-mulc(s[3], 69)
                   - mulc(s[4], 69)+mulc(s[5],167)-mulc(s[6],167)+mulc(s[7], 69);

    assign acc[14] = mulc(s[0], 35)-mulc(s[1],101)+mulc(s[2],151)-mulc(s[3],178)
                   + mulc(s[4],178)-mulc(s[5],151)+mulc(s[6],101)-mulc(s[7], 35);

    // ---- 홀수 출력 (d 사용) ----
    assign acc[ 1] = mulc(d[0],180)+mulc(d[1],173)+mulc(d[2],160)+mulc(d[3],140)
                   + mulc(d[4],115)+mulc(d[5], 85)+mulc(d[6], 53)+mulc(d[7], 18);

    assign acc[ 3] = mulc(d[0],173)+mulc(d[1],115)+mulc(d[2], 18)-mulc(d[3], 85)
                   - mulc(d[4],160)-mulc(d[5],180)-mulc(d[6],140)-mulc(d[7], 53);

    assign acc[ 5] = mulc(d[0],160)+mulc(d[1], 18)-mulc(d[2],140)-mulc(d[3],173)
                   - mulc(d[4], 53)+mulc(d[5],115)+mulc(d[6],180)+mulc(d[7], 85);

    assign acc[ 7] = mulc(d[0],140)-mulc(d[1], 85)-mulc(d[2],173)+mulc(d[3], 18)
                   + mulc(d[4],180)+mulc(d[5], 53)-mulc(d[6],160)-mulc(d[7],115);

    assign acc[ 9] = mulc(d[0],115)-mulc(d[1],160)-mulc(d[2], 53)+mulc(d[3],180)
                   - mulc(d[4], 18)-mulc(d[5],173)+mulc(d[6], 85)+mulc(d[7],140);

    assign acc[11] = mulc(d[0], 85)-mulc(d[1],180)+mulc(d[2],115)+mulc(d[3], 53)
                   - mulc(d[4],173)+mulc(d[5],140)+mulc(d[6], 18)-mulc(d[7],160);

    assign acc[13] = mulc(d[0], 53)-mulc(d[1],140)+mulc(d[2],180)-mulc(d[3],160)
                   + mulc(d[4], 85)+mulc(d[5], 18)-mulc(d[6],115)+mulc(d[7],173);

    assign acc[15] = mulc(d[0], 18)-mulc(d[1], 53)+mulc(d[2], 85)-mulc(d[3],115)
                   + mulc(d[4],140)-mulc(d[5],160)+mulc(d[6],173)-mulc(d[7],180);

    //--------------------------------------------------------
    // 출력 스케일 (>>> SH) 및 비트 절단
    //--------------------------------------------------------
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : OUT
            wire signed [31:0] sh = acc[k] >>> SH;
            assign o_z[16*OUTW-1-OUTW*k -: OUTW] = sh[OUTW-1:0];
        end
    endgenerate

endmodule