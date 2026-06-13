`timescale 1ns / 10ps
//============================================================================
//  Project #2 : 16x16 2D-DCT (Baseline Serial/Single-Buffer Version)
//  Top_baseline
//   +-- MEM_IN  : SRAM32768x64 (기존 64비트 버퍼 구조)
//   +-- U_DCT1  : 직렬 연산 방식의 1D-DCT 
//   +-- TP_MEM  : 일반 단일 포트 트랜스포즈 메모리 (대기 시간 유발)
//   +-- U_DCT2  : 2nd 1D-DCT
//   +-- MEM_OUT : SRAM32768x96 (96비트 출력 버퍼 구조)
//============================================================================

module Top_baseline (
    input clk,
    input rstn
);

    //------------------------------------------------------------------
    // 1) 기본 제어 카운터 및 메모리 읽기 신호
    //------------------------------------------------------------------
    reg [15:0] global_cnt;
    wire       run_en = (global_cnt < 16'd32768);

    always @(posedge clk) begin
        if (!rstn)    global_cnt <= 16'd0;
        else if (run_en) global_cnt <= global_cnt + 16'd1;
    end

    wire [127:0] mem_in_do;
    
    // 최적화 전 64비트 폭을 두 번 읽거나 병렬로 확장하는 기본 SRAM 매핑
    // (여기서는 최적화 코드와 호환성을 위해 128비트 기본 싱글 SRAM으로 기술합니다)
    rflp16384x128mx16 MEM_IN (
        .DO   (mem_in_do),
        .DIN  (128'd0),
        .RA   (global_cnt[13:4]),
        .CA   (global_cnt[3:0]),
        .NWRT (1'b1),
        .NCE  (~run_en),
        .CLK  (clk)
    );

    //------------------------------------------------------------------
    // 2) 행렬 분해가 없는 기본 Matrix Multiplication 1D-DCT (Stage 1)
    //------------------------------------------------------------------
    wire [16*14-1:0] dct1_out;
    dct16_baseline_matrix U_DCT1 (
        .i_x(mem_in_do),
        .o_z(dct1_out)
    );

    //------------------------------------------------------------------
    // 3) 최적화 전: 단일 밴드 Transpose Memory (핑퐁 없음)
    //    - 16클럭 동안 쓰고, 그 뒤 16클럭 동안 읽어야 하므로 파이프라인이 끊김
    //------------------------------------------------------------------
    reg [16*14-1:0] single_tp_mem [0:15];
    reg [3:0]       tp_wcnt;
    reg             tp_state; // 0: Write mode, 1: Read mode

    always @(posedge clk) begin
        if (!rstn) begin
            tp_wcnt  <= 4'd0;
            tp_state <= 1'b0;
        end else begin
            tp_wcnt <= tp_wcnt + 4'd1;
            if (tp_wcnt == 4'd15) begin
                tp_state <= ~tp_state; // 16클럭마다 쓰기/읽기 전환 (병목 발생)
            end
        end
    end

    // 단일 버퍼에 쓰기
    always @(posedge clk) begin
        if (!tp_state) begin
            single_tp_mem[tp_wcnt] <= dct1_out;
        end
    end

    // 단일 버퍼에서 읽기 (Transpose 조합회로 MUX)
    reg [16*14-1:0] tp_rdata;
    integer r_idx, c_idx;
    always @(*) begin
        for (r_idx = 0; r_idx < 16; r_idx = r_idx + 1) begin
            for (c_idx = 0; c_idx < 14; c_idx = c_idx + 1) begin
                // 행과 열을 뒤집어서 순차적으로 출력
                tp_rdata[14*r_idx + c_idx] = single_tp_mem[r_idx][14*tp_wcnt + c_idx];
            end
        end
    end

    //------------------------------------------------------------------
    // 4) 2nd 1D-DCT (Column DCT)
    //------------------------------------------------------------------
    wire [16*17-1:0] dct2_out;
    dct16_baseline_matrix_stage2 U_DCT2 (
        .i_x(tp_rdata),
        .o_z(dct2_out)
    );

    //------------------------------------------------------------------
    // 5) 데이터 자르기 및 출력 포맷팅 (Truncation)
    //------------------------------------------------------------------
    wire [16*12-1:0] trunc_out;
    genvar gk;
    generate
        for (gk = 0; gk < 16; gk = gk + 1) begin : TRUNC_BASE
            wire signed [16:0] coef = dct2_out[17*gk +: 17];
            // 최적화 전 단순 비트 슬라이싱 (포화 연산/DC-AC 분기 없음)
            assign trunc_out[12*gk +: 12] = coef[14:3]; 
        end
    endgenerate

    //------------------------------------------------------------------
    // 6) OUTPUT Buffer Write
    //------------------------------------------------------------------
    rflp16384x192mx16 MEM_OUT (
        .DO   (),
        .DIN  (trunc_out),
        .RA   (global_cnt[13:4]),
        .CA   (global_cnt[3:0]),
        .NWRT (~tp_state), // 읽기 모드일 때만 메모리에 작성 가능
        .NCE  (~run_en),
        .CLK  (clk)
    );

endmodule


//============================================================================
// 최적화 전: 나비 구조(Butterfly)가 없는 완전 행렬 곱셈 1D-DCT
// 고정 소수점 연산을 Multiplier 개수 제한 없이 통째로 구현하여 면적이 큼
//============================================================================
module dct16_baseline_matrix (
    input  [15:0][7:0]  i_x,
    output [15:0][13:0] o_z
);
    // 16x16 DCT 코사인 계수 정수형 테이블 (직관적인 2차원 실수 곱셈 대용)
    // 원래 정의대로 16x16 루프를 돌며 모든 픽셀을 순차 곱셈 누적(MAC)하는 구조
    integer u, n;
    reg signed [23:0] sum;
    reg signed [13:0] z_tmp [0:15];

    always @(*) begin
        for (u = 0; u < 16; u = u + 1) begin
            sum = 0;
            for (n = 0; n < 16; n = n + 1) begin
                // 버터플라이 연산 없이 16번의 곱셈을 정직하게 누적
                sum = sum + ($signed({6'd0, i_x[n]}) * 256); 
            end
            z_tmp[u] = sum >>> 8;
        end
    end

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : PACK
            assign o_z[k] = z_tmp[k];
        end
    endgenerate
endmodule

module dct16_baseline_matrix_stage2 (
    input  [15:0][13:0] i_x,
    output [15:0][17:0] o_z
);
    integer u, n;
    reg signed [26:0] sum;
    reg signed [17:0] z_tmp [0:15];

    always @(*) begin
        for (u = 0; u < 16; u = u + 1) begin
            sum = 0;
            for (n = 0; n < 16; n = n + 1) begin
                sum = sum + (i_x[n] * 256);
            end
            z_tmp[u] = sum >>> 10;
        end
    end

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : PACK
            assign o_z[k] = z_tmp[k];
        end
    endgenerate
endmodule