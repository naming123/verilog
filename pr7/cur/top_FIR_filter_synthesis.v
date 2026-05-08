module top_FIR_filter_synthesis (
	output reg [26-1:0] y_out_direct_d, y_out_trans_d,
	output reg [8-1:0] addr_in_d, addr_out_d,
	input [16-1:0] x_in_direct_q, x_in_trans_q,
	input clk, reset, 
	input [14-1:0] c0, c1, c2, c3, c4, c5
	
);

	wire [16-1:0] x_in_direct, x_in_trans;
	wire [26-1:0] y_out_direct, y_out_trans;
	wire [8-1:0] addr_in, addr_out;
	reg [16-1:0] x_in_direct_tmp, x_in_trans_tmp;

	assign x_in_direct = x_in_direct_tmp;
	assign x_in_trans = x_in_trans_tmp;
	
	// DFF for synthesis
	always @ (posedge clk) begin
		if (!reset) begin
			y_out_direct_d <= 0;
			y_out_trans_d <= 0;
			addr_in_d <= 0;
			addr_out_d <= 0;
			x_in_direct_tmp <= 0;
			x_in_trans_tmp <= 0;
		end
		else begin
			y_out_direct_d <= y_out_direct;
			y_out_trans_d <= y_out_trans;
			addr_in_d <= addr_in;
			addr_out_d <= addr_out;
			x_in_direct_tmp <= x_in_direct_q;
			x_in_trans_tmp <= x_in_trans_q;
		end
	end

	direct_FIR_filter DIRECT_FIR_FILTER (.direct_out(y_out_direct), .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .in(x_in_direct), .clk(clk), .reset(reset));
	trans_FIR_filter TRANS_FIR_FILTER (.trans_out(y_out_trans), .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .in(x_in_trans), .clk(clk), .reset(reset));

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

module direct_FIR_filter (
	output reg signed [26-1:0] direct_out,
	input signed [14-1:0] c0, c1, c2, c3, c4, c5,
	input signed [16-1:0] in, 
	input clk, reset
);

	wire signed [24-1:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4, mul_out5;
	wire signed [16-1:0] x0, x1, x2, x3, x4, x5;
	wire [26-1:0] sum_out;

	reg signed [16-1:0] x0_tmp, x1_tmp, x2_tmp, x3_tmp, x4_tmp, x5_tmp;

	assign sum_out = mul_out0 + mul_out1 + mul_out2 + mul_out3 + mul_out4 + mul_out5;
	assign x0 = x0_tmp;
	assign x1 = x1_tmp;
	assign x2 = x2_tmp;
	assign x3 = x3_tmp;
	assign x4 = x4_tmp;
	assign x5 = x5_tmp;

	multiplier_roundoff mul0 (.mul_out_roundoff(mul_out0), .in(x0), .c(c0));
	multiplier_roundoff mul1 (.mul_out_roundoff(mul_out1), .in(x1), .c(c1));
	multiplier_roundoff mul2 (.mul_out_roundoff(mul_out2), .in(x2), .c(c2));
	multiplier_roundoff mul3 (.mul_out_roundoff(mul_out3), .in(x3), .c(c3));
	multiplier_roundoff mul4 (.mul_out_roundoff(mul_out4), .in(x4), .c(c4));
	multiplier_roundoff mul5 (.mul_out_roundoff(mul_out5), .in(x5), .c(c5));

	always @ (posedge clk) begin
		if (!reset) begin
			x0_tmp <= 14'b0;
			x1_tmp <= 14'b0;
			x2_tmp <= 14'b0;
			x3_tmp <= 14'b0;
			x4_tmp <= 14'b0;
			x5_tmp <= 14'b0;
		end
		else begin
			x0_tmp <= in;
			x1_tmp <= x0;
			x2_tmp <= x1;
			x3_tmp <= x2;
			x4_tmp <= x3;
			x5_tmp <= x4;
			direct_out <= sum_out;
		end
	end

endmodule

module trans_FIR_filter (
	output reg signed [26-1:0] trans_out,
	input signed [14-1:0] c0, c1, c2, c3, c4, c5,
	input signed [16-1:0] in, 
	input clk, reset
);
	
	wire signed [24-1:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4, mul_out5;
	wire signed [26-1:0] sum_out0, sum_out1, sum_out2, sum_out3, sum_out4;

	reg signed [26-1:0] y1, y2, y3, y4, y5;
	reg signed [16-1:0] x0;

	assign sum_out4 = mul_out4 + y5;
	assign sum_out3 = mul_out3 + y4;
	assign sum_out2 = mul_out2 + y3;
	assign sum_out1 = mul_out1 + y2;
	assign sum_out0 = mul_out0 + y1;

	multiplier_roundoff mul0 (.mul_out_roundoff(mul_out0), .in(x0), .c(c0));
	multiplier_roundoff mul1 (.mul_out_roundoff(mul_out1), .in(x0), .c(c1));
	multiplier_roundoff mul2 (.mul_out_roundoff(mul_out2), .in(x0), .c(c2));
	multiplier_roundoff mul3 (.mul_out_roundoff(mul_out3), .in(x0), .c(c3));
	multiplier_roundoff mul4 (.mul_out_roundoff(mul_out4), .in(x0), .c(c4));
	multiplier_roundoff mul5 (.mul_out_roundoff(mul_out5), .in(x0), .c(c5));

	always @ (posedge clk) begin
		if (!reset) begin
			x0 <= 26'b0;
			y1 <= 26'b0;
			y1 <= 26'b0;
			y2 <= 26'b0;
			y3 <= 26'b0;
			y5 <= 26'b0;
		end
		else begin
			x0 <= in;
			y5 <= mul_out5;
			y4 <= sum_out4;
			y3 <= sum_out3;
			y2 <= sum_out2;
			y1 <= sum_out1;
			trans_out <= sum_out0;
		end
	end

endmodule

module multiplier_roundoff (
	output signed [24-1:0] mul_out_roundoff,
	input signed [16-1:0] in,
	input signed [14-1:0] c
);
	wire [30-1:0] mul_out;

	assign mul_out = in * c;
	assign mul_out_roundoff = mul_out[29:5] + mul_out[4];

endmodule