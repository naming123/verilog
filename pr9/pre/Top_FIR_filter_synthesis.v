module Top_FIR_filter_synthesis (
	output reg [22-1:0] y_out_folded_d,
	output reg [8-1:0] addr_in_d, addr_out_d,
	input [12-1:0] x_in_folded_q,
	input clk100, clk20, reset, 
	input [13-1:0] c0, c1, c2, c3, c4
);

	wire [8-1:0] addr_in, addr_out;
	wire [12-1:0] x_in_folded;
	wire [22-1:0] y_out_folded;
	reg [12-1:0] x_in_folded_tmp;

	// DFF for synthesis
	always @ (posedge clk20) begin
		if (!reset) begin
			y_out_folded_d <= 0;
			addr_in_d <= 0;
			addr_out_d <= 0;
			x_in_folded_tmp <= 0;
		end
		else begin
			y_out_folded_d <= y_out_folded;
			addr_in_d <= addr_in;
			addr_out_d <= addr_out;
			x_in_folded_tmp <= x_in_folded_q;
		end
	end
	
	folded_FIR_filter FOLDED_FIR_FILTER (.folded_out(y_out_folded), .in(x_in_folded), .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .clk100(clk100), .clk20(clk20), .reset(reset));

	// Counter for address control
	reg [8-1:0] cnt;

	assign addr_in = cnt;
	assign addr_out = cnt - 3'd7;

	always @ (posedge clk20) begin
		if (!reset) begin
			cnt <= 8'b0;
		end
		else begin
			cnt <= cnt + 1;
		end
	end

endmodule

module folded_FIR_filter (
	output reg signed [22-1:0] folded_out,
	input signed [12-1:0] in,
	input signed [13-1:0] c0, c1, c2, c3, c4,
	input clk100, clk20, reset
);
	
	wire signed [12-1:0] x0, x1, x2, x3, x4;
	wire signed [22-1:0] sum_out, mux_out, mac_out, mac_mux_out;
	wire signed [25-1:0] mul_out_reg;
	wire signed [20-1:0] mul_out;

	reg signed [12-1:0] x0_tmp, x1_tmp, x2_tmp, x3_tmp, x4_tmp, x_mux_out, x_d;
	reg signed [13-1:0] c_mux_out, c_d;
	reg signed [22-1:0] sum_out_d;
	reg [3-1:0] cnt100;

	assign x0 = x0_tmp;
	assign x1 = x1_tmp;
	assign x2 = x2_tmp;
	assign x3 = x3_tmp;
	assign x4 = x4_tmp;

	// DFF at the input
	always @ (posedge clk20 or negedge reset) begin
		if (!reset) begin
			x0_tmp <= 12'b0;
			x1_tmp <= 12'b0;
			x2_tmp <= 12'b0;
			x3_tmp <= 12'b0;
			x4_tmp <= 12'b0;
		end
		else begin
			x0_tmp <= in;
			x1_tmp <= x0;
			x2_tmp <= x1;
			x3_tmp <= x2;
			x4_tmp <= x3;
		end
	end

	// Counter of 100MHz
	always @ (posedge clk100) begin
		if (!reset) begin
			cnt100 <= 3'b0;
		end
		else begin
			if (cnt100 >= 4) begin
				cnt100 <= 0;
			end
			else begin
				cnt100 <= cnt100 + 1;
			end
		end
	end

	// Input MUX
	always @ (*) begin
		case (cnt100 % 3'd5)
			1 : x_mux_out <= x0;
			2 : x_mux_out <= x1;
			3 : x_mux_out <= x2;
			4 : x_mux_out <= x3;
			0 : x_mux_out <= x4;
			default : x_mux_out <= 12'b0;
		endcase
	end

	// DFF for input MUX
	always @ (posedge clk100) begin
		if (!reset) begin
			x_d <= 0;
		end
		else begin
			x_d <= x_mux_out;
		end
	end

	// Coefficient MUX
	always @ (*) begin
		case (cnt100 % 3'd5)
			1 : c_mux_out <= c0;
			2 : c_mux_out <= c1;
			3 : c_mux_out <= c2;
			4 : c_mux_out <= c3;
			0 : c_mux_out <= c4;
			default : c_mux_out <= 13'b0;
		endcase
	end
	
	// DFF for coefficient mux
	always @ (posedge clk100) begin
		if (!reset) begin
			c_d <= 0;
		end
		else begin
			c_d <= c_mux_out;
		end
	end

	// Multiplication & round-off
	assign mul_out_reg = c_d * x_d;
	assign mul_out = mul_out_reg[23:4] + mul_out_reg[3];

	// Accumulation
	assign sum_out = mul_out + mux_out;
	assign mux_out = (cnt100 % 3'd5 == 2) ? 1'b0 : sum_out_d;
	assign mac_out = sum_out_d;

	always @ (posedge clk100) begin
		if (!reset) begin
			sum_out_d <= 0;
		end
		else begin
			sum_out_d <= sum_out;
		end
	end

	// Output MUX
	assign mac_mux_out = (cnt100 % 3'd5 == 2) ? mac_out : folded_out;

	always @ (posedge clk100) begin
		if (!reset) begin
			folded_out <= 0;
		end
		else begin
			folded_out <= mac_mux_out;
		end
	end

endmodule
