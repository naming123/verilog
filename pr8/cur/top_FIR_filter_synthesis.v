module top_FIR_filter (
    input clk, reset, 
    input [14-1:0] c0, c1, c2, c3, c4
);

    wire [8-1:0] addr_in, addr_out;
    wire [14-1:0] x_in_trans;
    wire [24-1:0] y_out_trans;
    
    // 입력 메모리: 14-bit
    rflp256x14mx4 TRANS_INPUT_MEM (
        .NWRT(1'b1), .DIN(14'b0), .RA(addr_in[7:2]), .CA(addr_in[1:0]), 
        .NCE(1'b0), .CLK(clk), .DO(x_in_trans)
    );

    // 출력 메모리: 24-bit
    rflp256x24mx4 TRANS_OUTPUT_MEM (
        .NWRT(1'b0), .DIN(y_out_trans), .RA(addr_out[7:2]), .CA(addr_out[1:0]), 
        .NCE(1'b0), .CLK(clk), .DO()
    );

    // FIR Filter Instance (5-tap)
    trans_FIR_filter_low_cost TRANS_FIR_FILTER (
        .trans_out(y_out_trans), 
        .in(x_in_trans), 
        .clk(clk), 
        .reset(reset)
    );

    // Address Control (5-tap latency: 7)
    reg [8-1:0] cnt;
    assign addr_in = cnt;
    assign addr_out = cnt - 4'd7; 

    always @ (posedge clk) begin
        if (!reset) cnt <= 8'b0;
        else cnt <= cnt + 1;
    end

endmodule

module trans_FIR_filter_low_cost (
    output reg signed [24-1:0] trans_out,
    input signed [14-1:0] in, 
    input clk, reset
);
    
    wire signed [14-1:0] x1;
    wire signed [19-1:0] x2; 
    wire signed [17-1:0] x3; 
    wire signed [16-1:0] x4; 
    
    wire signed [31-1:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4;
    wire signed [24-1:0] mul_out0_r, mul_out1_r, mul_out2_r, mul_out3_r, mul_out4_r;
    wire signed [24-1:0] sum_out0, sum_out1, sum_out2, sum_out3;

    reg signed [24-1:0] y1, y2, y3, y4;
    reg signed [14-1:0] x0;
    
    // 1. Common Subexpression (하부 구조)
    assign x1 = x0;
    assign x2 = (x1 << 5) + x1;
    assign x3 = (x1 << 2) - x1;
    assign x4 = (x1 << 1) + x1;

    // 2. Optimized Multipliers (Shift & Add)
    assign mul_out0 = (x1 << 11) - (x1 << 7) + x3;
    assign mul_out1 = -(x1 << 12) + (x1 << 9) + (x4 << 6) - (x3 << 2);
    assign mul_out2 = (x1 << 12) + (x1 << 7) - (x1 << 3);
    assign mul_out3 = -(x1 << 12) + (x1 << 7) - x1;
    assign mul_out4 = (x4 << 11) + (x1 << 8) + (x1 << 7) - (x3 << 3) - x1;

    // 3. Roundoff (5-bit shift to match 24-bit output)
    assign mul_out0_r = mul_out0[28:5] + mul_out0[4];
    assign mul_out1_r = mul_out1[28:5] + mul_out1[4];
    assign mul_out2_r = mul_out2[28:5] + mul_out2[4];
    assign mul_out3_r = mul_out3[28:5] + mul_out3[4];
    assign mul_out4_r = mul_out4[28:5] + mul_out4[4];

    // 4. Transpose Form Adder Chain
    assign sum_out3 = mul_out3_r + y4;
    assign sum_out2 = mul_out2_r + y3;
    assign sum_out1 = mul_out1_r + y2;
    assign sum_out0 = mul_out0_r + y1;

    always @ (posedge clk) begin
        if (!reset) begin
            x0 <= 14'b0;
            y1 <= 24'b0; y2 <= 24'b0; y3 <= 24'b0; y4 <= 24'b0;
            trans_out <= 24'b0;
        end
        else begin
            x0 <= in;
            y4 <= mul_out4_r;
            y3 <= sum_out3;
            y2 <= sum_out2;
            y1 <= sum_out1;
            trans_out <= sum_out0;
        end
    end

endmodule