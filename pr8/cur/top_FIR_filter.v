module top_FIR_filter (
    input clk, reset, 
    input [13:0] c0, c1, c2, c3, c4
);

    wire [7:0] addr_in, addr_out;
    wire [13:0] x_in_trans;
    wire [23:0] y_out_trans;
    
    reg [7:0] cnt;
    assign addr_in = cnt;
    assign addr_out = cnt - 8'd7; 

    // rflp256x14mx2 -> rflp256x14mx4로 변경
    rflp256x14mx4 TRANS_INPUT_MEM (
        .NWRT(1'b1), .DIN(14'b0), 
        .RA(addr_in[7:2]), .CA(addr_in[1:0]), 
        .NCE(1'b0), .CLK(clk), .DO(x_in_trans)
    );

    // rflp256x24mx2 -> rflp256x24mx4로 변경
    rflp256x24mx4 TRANS_OUTPUT_MEM (
        .NWRT(reset ? 1'b0 : 1'b1), 
        .DIN(y_out_trans), 
        .RA(addr_out[7:2]), .CA(addr_out[1:0]), 
        .NCE(1'b0), .CLK(clk), .DO()
    );

    trans_FIR_filter TRANS_FIR_FILTER (
        .trans_out(y_out_trans), 
        .in(x_in_trans), 
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4),
        .clk(clk), .reset(reset)
    );

    always @ (posedge clk) begin
        if (!reset) cnt <= 8'b0;
        else cnt <= cnt + 1;
    end

endmodule

module trans_FIR_filter (
    output reg signed [23:0] trans_out,
    input signed [13:0] in,
    input signed [13:0] c0, c1, c2, c3, c4,
    input clk, reset
);

    // 내부 상태 모니터링용 레지스터
    reg signed [13:0] x0;
    reg signed [31:0] m0, m1, m2, m3, m4;
    reg signed [23:0] m0_r, m1_r, m2_r, m3_r, m4_r;
    reg signed [23:0] y1, y2, y3, y4;

    // 1. Optimized Multipliers (Always 블록 내부에서 순차 연산으로 고정)
    // 괄호와 $signed를 떡칠해서 Gate-level에서 오해할 소지를 없앰
    always @(*) begin
        m0 = ($signed({ {18{x0[13]}}, x0 }) << 11) - ($signed({ {18{x0[13]}}, x0 }) << 7) + ($signed({ {18{x0[13]}}, x0 }) << 2) - $signed({ {18{x0[13]}}, x0 });
        m1 = -($signed({ {18{x0[13]}}, x0 }) << 12) + ($signed({ {18{x0[13]}}, x0 }) << 9) + (($signed({ {18{x0[13]}}, x0 }) << 1) + $signed({ {18{x0[13]}}, x0 }) << 6) - (($signed({ {18{x0[13]}}, x0 }) << 2) - $signed({ {18{x0[13]}}, x0 }) << 2);
        m2 = ($signed({ {18{x0[13]}}, x0 }) << 12) + ($signed({ {18{x0[13]}}, x0 }) << 7) - ($signed({ {18{x0[13]}}, x0 }) << 3);
        m3 = -($signed({ {18{x0[13]}}, x0 }) << 12) + ($signed({ {18{x0[13]}}, x0 }) << 7) - $signed({ {18{x0[13]}}, x0 });
        m4 = (($signed({ {18{x0[13]}}, x0 }) << 1) + $signed({ {18{x0[13]}}, x0 }) << 11) + ($signed({ {18{x0[13]}}, x0 }) << 8) + ($signed({ {18{x0[13]}}, x0 }) << 7) - (($signed({ {18{x0[13]}}, x0 }) << 2) - $signed({ {18{x0[13]}}, x0 }) << 3) - $signed({ {18{x0[13]}}, x0 });
    end

    // 2. Rounding (부호 비트를 수동으로 연장하는 방식)
    always @(*) begin
        m0_r = $signed((m0 + 32'sd16) >>> 5);
        m1_r = $signed((m1 + 32'sd16) >>> 5);
        m2_r = $signed((m2 + 32'sd16) >>> 5);
        m3_r = $signed((m3 + 32'sd16) >>> 5);
        m4_r = $signed((m4 + 32'sd16) >>> 5);
    end

    // 3. Pipeline & Debug Display
    always @(posedge clk) begin
        if (!reset) begin
            x0 <= 14'b0;
            y1 <= 24'b0; y2 <= 24'b0; y3 <= 24'b0; y4 <= 24'b0;
            trans_out <= 24'b0;
        end
        else begin
            x0 <= in;
            y4 <= m4_r;
            y3 <= m3_r + y4;
            y2 <= m2_r + y3;
            y1 <= m1_r + y2;
            trans_out <= m0_r + y1;

            // [DEBUG LOG] 매 클럭마다 중요한 중간값을 찍음
            // 만약 너무 시끄러우면 if(in != 0) 같은 조건을 걸어줘
            $display("[DEBUG] Time:%0t | IN:%h | m0_r:%h | y1:%h | OUT:%h", $time, in, m0_r, y1, trans_out);
        end
    end

endmodule