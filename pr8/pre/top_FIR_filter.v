module top_FIR_filter (
	input clk, reset, 
	input [14-1:0] c0, c1, c2, c3, c4, c5
);

	wire [8-1:0] addr_in, addr_out;
	wire [16-1:0] x_in_trans;
	wire [26-1:0] y_out_trans;
	
	rflp256x16mx2 TRANS_INPUT_MEM (.NWRT(1'b1), .DIN(), .RA(addr_in[7:2]), .CA(addr_in[1:0]), .NCE(1'b0), .CLK(clk), .DO(x_in_trans));

	rflp256x26mx2 TRANS_OUTPUT_MEM (.NWRT(1'b0), .DIN(y_out_trans), .RA(addr_out[7:2]), .CA(addr_out[1:0]), .NCE(1'b0), .CLK(clk), .DO());

	trans_FIR_filter_low_cost TRANS_FIR_FILTER (.trans_out(y_out_trans), .in(x_in_trans), .clk(clk), .reset(reset));

	// Counter for address control
	reg [8-1:0] cnt;

	assign addr_in = cnt;
	assign addr_out = cnt - 4'd8;

	always @ (posedge clk) begin
		if (!reset) begin
			cnt <= 8'b0;
		end
		else begin
			cnt <= cnt + 1;
		end
	end

endmodule

module trans_FIR_filter_low_cost (
	output reg signed [26-1:0] trans_out,
	input signed [16-1:0] in, 
	input clk, reset
);
	
	wire signed [16-1:0] x1;
	wire signed [20-1:0] x2;
	wire signed [18-1:0] x3;
	wire signed [19-1:0] x4;
	wire signed [30-1:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4, mul_out5;
	wire signed [24-1:0] mul_out0_r, mul_out1_r, mul_out2_r, mul_out3_r, mul_out4_r, mul_out5_r;
	wire signed [26-1:0] sum_out0, sum_out1, sum_out2, sum_out3, sum_out4;

	reg signed [26-1:0] y1, y2, y3, y4, y5;
	reg signed [16-1:0] x0;
	
	// Define adder & shift tree
	assign x1 = x0;
	assign x2 = (x1 << 3) + x1;
	assign x3 = (x1 << 2) - x1;
	assign x4 = (x1 << 2) + x1;

	assign mul_out0 = (x2 << 2) + (x1 << 7) - (x3 << 9);
	assign mul_out1 = x3 + (x3 << 4) + (x4 << 10);
	assign mul_out2 = - x2 + (x1 << 6) - (x1 << 9) + (x1 << 12);
	assign mul_out3 = - x2 + (x3 << 5) - (x3 << 9) + (x1 << 13);
	assign mul_out4 = - x2 + (x1 << 5) + (x2 << 8);
	assign mul_out5 = - x3 + (x1 << 5) - (x4 << 10);

	// Roundoff
	assign mul_out0_r = mul_out0[28:5] + mul_out0[4];
	assign mul_out1_r = mul_out1[28:5] + mul_out1[4];
	assign mul_out2_r = mul_out2[28:5] + mul_out2[4];
	assign mul_out3_r = mul_out3[28:5] + mul_out3[4];
	assign mul_out4_r = mul_out4[28:5] + mul_out4[4];
	assign mul_out5_r = mul_out5[28:5] + mul_out5[4];

	assign sum_out4 = mul_out4_r + y5;
	assign sum_out3 = mul_out3_r + y4;
	assign sum_out2 = mul_out2_r + y3;
	assign sum_out1 = mul_out1_r + y2;
	assign sum_out0 = mul_out0_r + y1;

	// DFF
	always @ (posedge clk) begin
		if (!reset) begin
			x0 <= 16'b0;
			y1 <= 26'b0;
			y2 <= 26'b0;
			y3 <= 26'b0;
			y4 <= 26'b0;
			y5 <= 26'b0;
		end
		else begin
			x0 <= in;
			y5 <= mul_out5_r;
			y4 <= sum_out4;
			y3 <= sum_out3;
			y2 <= sum_out2;
			y1 <= sum_out1;
			trans_out <= sum_out0;
		end
	end

endmodule