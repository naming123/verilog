module sqrt_carry_select_adder_22b (
	output [22:0] sum,
	input [21:0] a, b,
	input c_in, clk, rstn
);
	wire c_in_q;
	wire [21:0] a_q, b_q;
	wire [22:0] sum_d;

	SRCSA_22bit SRCSA (.sum(sum_d), .a(a_q), .b(b_q), .c_in(c_in_q));
	DFF_input DFF_in (.a_q(a_q), .b_q(b_q), .c_in_q(c_in_q), .a(a), .b(b), .c_in(c_in), .clk(clk), .rstn(rstn));
	DFF_output DFF_out (.sum(sum), .sum_d(sum_d), .clk(clk), .rstn(rstn));

endmodule

module SRCSA_22bit (
	output [22:0] sum,
	input [21:0] a, b,
	input c_in
);
	//Stage_1 : FA 4bit

	wire c_out_1;

	FA_4bit FA_1_0 (.sum(sum[3:0]), .c_out(c_out_1), .a(a[3:0]), .b(b[3:0]), .c_in(1'b0));

	//Stage_2 : FA w/ MUX 5bit

	wire [4:0] s_mux6_0, s_mux6_1;
	wire c_out_2_0, c_out_2_1, c_out_2_s;

	FA_5bit FA_2_0 (.sum(s_mux6_0), .c_out(c_out_2_0), .a(a[8:4]), .b(b[8:4]), .c_in(1'b0));
	FA_5bit FA_2_1 (.sum(s_mux6_1), .c_out(c_out_2_1), .a(a[8:4]), .b(b[8:4]), .c_in(1'b1));
	mux2to1_6bit mux_6bit (.out({c_out_2_s, sum[8:4]}), .i0({c_out_2_0, s_mux6_0}), .i1({c_out_2_1, s_mux6_1}), .s(c_out_1));

	//Stage_3 : FA w/ MUX 6bit

	wire [5:0] s_mux7_0, s_mux7_1;
	wire c_out_3_0, c_out_3_1, c_out_3_s;

	FA_6bit FA_3_0 (.sum(s_mux7_0), .c_out(c_out_3_0), .a(a[14:9]), .b(b[14:9]), .c_in(1'b0));
	FA_6bit FA_3_1 (.sum(s_mux7_1), .c_out(c_out_3_1), .a(a[14:9]), .b(b[14:9]), .c_in(1'b1));
	mux2to1_7bit mux_7bit (.out({c_out_3_s, sum[14:9]}), .i0({c_out_3_0, s_mux7_0}), .i1({c_out_3_1, s_mux7_1}), .s(c_out_2_s));

	//Stage_4 : FA w/ MUX 7bit

	wire [6:0] s_mux8_0, s_mux8_1;

	FA_7bit FA_4_0 (.sum(s_mux8_0), .c_out(), .a(a[21:15]), .b(b[21:15]), .c_in(1'b0));
	FA_7bit FA_4_1 (.sum(s_mux8_1), .c_out(), .a(a[21:15]), .b(b[21:15]), .c_in(1'b1));
	mux2to1_8bit mux_8bit (.out(sum[22:15]), .i0({1'b0, s_mux8_0}), .i1({1'b1, s_mux8_1}), .s(c_out_3_s));

endmodule

module DFF_input (
	output reg [21:0] a_q, b_q, 
	output reg c_in_q,
	input [21:0] a, b,
	input c_in, clk, rstn
);
	always @(posedge clk) begin
		if (!rstn) begin
			a_q <= 0;
			b_q <= 0;
			c_in_q <= 0;
		end
		else begin
			a_q <= a;
			b_q <= b;
			c_in_q <= c_in;
		end
	end
endmodule

module DFF_output (
	output reg [22:0] sum,
	input [22:0] sum_d, 
	input clk, rstn
);
	always @(posedge clk) begin
		if (!rstn)
			sum <= 0;
		else
			sum <= sum_d;
	end
endmodule

module FA_4bit (
	output [3:0] sum,
	output c_out,
	input [3:0] a, b,
	input c_in
);
	wire [2:0] c;
	fulladd_gate fa00 (.sum(sum[0]), .c_out(c[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	fulladd_gate fa01 (.sum(sum[1]), .c_out(c[1]), .a(a[1]), .b(b[1]), .c_in(c[0]));
	fulladd_gate fa02 (.sum(sum[2]), .c_out(c[2]), .a(a[2]), .b(b[2]), .c_in(c[1]));
	fulladd_gate fa03 (.sum(sum[3]), .c_out(c_out), .a(a[3]), .b(b[3]), .c_in(c[2]));
endmodule

module FA_5bit (
	output [4:0] sum,
	output c_out,
	input [4:0] a, b,
	input c_in
);
	wire [3:0] c;
	fulladd_gate fa00 (.sum(sum[0]), .c_out(c[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	fulladd_gate fa01 (.sum(sum[1]), .c_out(c[1]), .a(a[1]), .b(b[1]), .c_in(c[0]));
	fulladd_gate fa02 (.sum(sum[2]), .c_out(c[2]), .a(a[2]), .b(b[2]), .c_in(c[1]));
	fulladd_gate fa03 (.sum(sum[3]), .c_out(c[3]), .a(a[3]), .b(b[3]), .c_in(c[2]));
	fulladd_gate fa04 (.sum(sum[4]), .c_out(c_out), .a(a[4]), .b(b[4]), .c_in(c[3]));
endmodule

module FA_6bit (
	output [5:0] sum,
	output c_out,
	input [5:0] a, b,
	input c_in
);
	wire [4:0] c;
	fulladd_gate fa00 (.sum(sum[0]), .c_out(c[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	fulladd_gate fa01 (.sum(sum[1]), .c_out(c[1]), .a(a[1]), .b(b[1]), .c_in(c[0]));
	fulladd_gate fa02 (.sum(sum[2]), .c_out(c[2]), .a(a[2]), .b(b[2]), .c_in(c[1]));
	fulladd_gate fa03 (.sum(sum[3]), .c_out(c[3]), .a(a[3]), .b(b[3]), .c_in(c[2]));
	fulladd_gate fa04 (.sum(sum[4]), .c_out(c[4]), .a(a[4]), .b(b[4]), .c_in(c[3]));
	fulladd_gate fa05 (.sum(sum[5]), .c_out(c_out), .a(a[5]), .b(b[5]), .c_in(c[4]));
endmodule

module FA_7bit (
	output [6:0] sum,
	output c_out,
	input [6:0] a, b,
	input c_in
);
	wire [5:0] c;
	fulladd_gate fa00 (.sum(sum[0]), .c_out(c[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	fulladd_gate fa01 (.sum(sum[1]), .c_out(c[1]), .a(a[1]), .b(b[1]), .c_in(c[0]));
	fulladd_gate fa02 (.sum(sum[2]), .c_out(c[2]), .a(a[2]), .b(b[2]), .c_in(c[1]));
	fulladd_gate fa03 (.sum(sum[3]), .c_out(c[3]), .a(a[3]), .b(b[3]), .c_in(c[2]));
	fulladd_gate fa04 (.sum(sum[4]), .c_out(c[4]), .a(a[4]), .b(b[4]), .c_in(c[3]));
	fulladd_gate fa05 (.sum(sum[5]), .c_out(c[5]), .a(a[5]), .b(b[5]), .c_in(c[4]));
	fulladd_gate fa06 (.sum(sum[6]), .c_out(c_out), .a(a[6]), .b(b[6]), .c_in(c[5]));
endmodule

module fulladd_gate (
	output sum, c_out,
	input a, b, c_in
);
	wire s1, s2, c1;
	xor(s1, a, b);
	and(c1, a, b);
	and(s2, s1, c_in);
	xor(sum, s1, c_in);
	xor(c_out, c1, s2);
endmodule

module mux2to1_6bit (
	output [5:0] out,
	input [5:0] i0, i1,
	input s
);
	mux2to1 mux0 (out[0], i0[0], i1[0], s);
	mux2to1 mux1 (out[1], i0[1], i1[1], s);
	mux2to1 mux2 (out[2], i0[2], i1[2], s);
	mux2to1 mux3 (out[3], i0[3], i1[3], s);
	mux2to1 mux4 (out[4], i0[4], i1[4], s);
	mux2to1 mux5 (out[5], i0[5], i1[5], s);
endmodule

module mux2to1_7bit (
	output [6:0] out,
	input [6:0] i0, i1,
	input s
);
	mux2to1 mux0 (out[0], i0[0], i1[0], s);
	mux2to1 mux1 (out[1], i0[1], i1[1], s);
	mux2to1 mux2 (out[2], i0[2], i1[2], s);
	mux2to1 mux3 (out[3], i0[3], i1[3], s);
	mux2to1 mux4 (out[4], i0[4], i1[4], s);
	mux2to1 mux5 (out[5], i0[5], i1[5], s);
	mux2to1 mux6 (out[6], i0[6], i1[6], s);
endmodule

module mux2to1_8bit (
	output [7:0] out,
	input [7:0] i0, i1,
	input s
);
	mux2to1 mux0 (out[0], i0[0], i1[0], s);
	mux2to1 mux1 (out[1], i0[1], i1[1], s);
	mux2to1 mux2 (out[2], i0[2], i1[2], s);
	mux2to1 mux3 (out[3], i0[3], i1[3], s);
	mux2to1 mux4 (out[4], i0[4], i1[4], s);
	mux2to1 mux5 (out[5], i0[5], i1[5], s);
	mux2to1 mux6 (out[6], i0[6], i1[6], s);
	mux2to1 mux7 (out[7], i0[7], i1[7], s);
endmodule

module mux2to1 (
	output out,
	input i0, i1,
	input s
);
	wire s_not, and0, and1;
	not(s_not, s);
	and(and0, i0, s_not);
	and(and1, i1, s);
	or(out, and0, and1);
endmodule