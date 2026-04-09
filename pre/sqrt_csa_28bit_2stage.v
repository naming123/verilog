module sqrt_csa_28bit_2stage (
	output [29-1:0] sum,
	input [28-1:0] a, b,
	input c_in, clk, rstn
);
	
	//DFF_input

	wire [28-1:0] a_q, b_q;
	wire c_in_q;
	
	DFF_28bit DFF_in_0(.q(a_q), .d(a), .clk(clk), .rstn(rstn));
	DFF_28bit DFF_in_1(.q(b_q), .d(b), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_in_2(.q(c_in_q), .d(c_in), .clk(clk), .rstn(rstn));

	//Stage_1 : 3-bit FA

	wire c_out_1;
	wire [6-1:0] sum_d_pipe;
	wire [29-1:0] sum_d;

	FA_3bit FA3_1_0(.sum(sum_d_pipe[2:0]), .c_out(c_out_1), .a(a_q[2:0]), .b(b_q[2:0]), .c_in(c_in_q));

	DFF_3bit DFF_1_0(.q(sum_d[2:0]), .d(sum_d_pipe[2:0]), .clk(clk), .rstn(rstn));

	//Stage_2 : 3-bit FA w/ 4-bit MUX  

	wire [3-1:0] sum0_2, sum1_2;
	wire c_out_2_0, c_out_2_1, c_out_2_s_pipe, c_out_2_s;

	FA_3bit FA3_2_0(.sum(sum0_2), .c_out(c_out_2_0), .a(a_q[5:3]), .b(b_q[5:3]), .c_in(1'b0));
	FA_3bit FA3_2_1(.sum(sum1_2), .c_out(c_out_2_1), .a(a_q[5:3]), .b(b_q[5:3]), .c_in(1'b1));
	mux2to1_4bit M4_2_0(.out({c_out_2_s_pipe, sum_d_pipe[5:3]}), .i0({c_out_2_0, sum0_2}), .i1({c_out_2_1, sum1_2}), .s(c_out_1));

	DFF_3bit DFF_2_0 (.q(sum_d[5:3]), .d(sum_d_pipe[5:3]), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_2_1 (.q(c_out_2_s), .d(c_out_2_s_pipe), .clk(clk), .rstn(rstn));

	//Stage_3 : 4-bit FA w/ 5-bit MUX

	wire [4-1:0] sum0_3_pipe, sum1_3_pipe, sum0_3, sum1_3;
	wire c_out_3_0_pipe, c_out_3_1_pipe;
	wire c_out_3_0, c_out_3_1, c_out_3_s;

	FA_4bit FA4_3_0(.sum(sum0_3_pipe), .c_out(c_out_3_0_pipe), .a(a_q[9:6]), .b(b_q[9:6]), .c_in(1'b0));
	FA_4bit FA4_3_1(.sum(sum1_3_pipe), .c_out(c_out_3_1_pipe), .a(a_q[9:6]), .b(b_q[9:6]), .c_in(1'b1));

	DFF_4bit DFF_3_0(.q(sum0_3), .d(sum0_3_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_3_1(.q(sum1_3), .d(sum1_3_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_3_2(.q(c_out_3_0), .d(c_out_3_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_3_3(.q(c_out_3_1), .d(c_out_3_1_pipe), .clk(clk), .rstn(rstn));

	mux2to1_5bit M5_3_0(.out({c_out_3_s, sum_d[9:6]}), .i0({c_out_3_0, sum0_3}), .i1({c_out_3_1, sum1_3}), .s(c_out_2_s));

	//Stage_4 : 4-bit + 1-bit FA w/ 6-bit MUX

	wire [6-1:0] a_q_pipe, b_q_pipe;
	wire [4-1:0] sum0_4_pipe, sum1_4_pipe;
	wire [5-1:0] sum0_4, sum1_4;
	wire c_in_4_0, c_in_4_1, c_out_4_0_pipe, c_out_4_1_pipe;
	wire c_out_4_0, c_out_4_1, c_out_4_s;

	DFF_1bit DFF_4_0(.q(a_q_pipe[0]), .d(a_q[14]), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_4_1(.q(b_q_pipe[0]), .d(b_q[14]), .clk(clk), .rstn(rstn));

	FA_4bit FA4_4_0(.sum(sum0_4_pipe), .c_out(c_out_4_0_pipe), .a(a_q[13:10]), .b(b_q[13:10]), .c_in(1'b0));
	FA_4bit FA4_4_1(.sum(sum1_4_pipe), .c_out(c_out_4_1_pipe), .a(a_q[13:10]), .b(b_q[13:10]), .c_in(1'b1));
	DFF_1bit DFF_4_2(.q(c_in_4_0), .d(c_out_4_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_4_3(.q(c_in_4_1), .d(c_out_4_1_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_4_4(.q(sum0_4[3:0]), .d(sum0_4_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_4_5(.q(sum1_4[3:0]), .d(sum1_4_pipe), .clk(clk), .rstn(rstn));

	FA_1bit FA1_4_2(.sum(sum0_4[4]), .c_out(c_out_4_0), .a(a_q_pipe[0]), .b(b_q_pipe[0]), .c_in(c_in_4_0));
	FA_1bit FA1_4_3(.sum(sum1_4[4]), .c_out(c_out_4_1), .a(a_q_pipe[0]), .b(b_q_pipe[0]), .c_in(c_in_4_1));

	mux2to1_6bit M6_4_0(.out({c_out_4_s, sum_d[14:10]}), .i0({c_out_4_0, sum0_4}), .i1({c_out_4_1, sum1_4}), .s(c_out_3_s));

	//Stage_5 : 4-bit + 2-bit FA w/ 7-bit MUX

	wire [4-1:0] sum0_5_pipe, sum1_5_pipe;
	wire [6-1:0] sum0_5, sum1_5;
	wire c_in_5_0, c_in_5_1, c_out_5_0_pipe, c_out_5_1_pipe;
	wire c_out_5_0, c_out_5_1, c_out_5_s;

	DFF_2bit DFF_5_0(.q(a_q_pipe[2:1]), .d(a_q[20:19]), .clk(clk), .rstn(rstn));
	DFF_2bit DFF_5_1(.q(b_q_pipe[2:1]), .d(b_q[20:19]), .clk(clk), .rstn(rstn));

	FA_4bit FA4_5_0(.sum(sum0_5_pipe), .c_out(c_out_5_0_pipe), .a(a_q[18:15]), .b(b_q[18:15]), .c_in(1'b0));
	FA_4bit FA4_5_1(.sum(sum1_5_pipe), .c_out(c_out_5_1_pipe), .a(a_q[18:15]), .b(b_q[18:15]), .c_in(1'b1));
	DFF_1bit DFF_5_2(.q(c_in_5_0), .d(c_out_5_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_5_3(.q(c_in_5_1), .d(c_out_5_1_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_5_4(.q(sum0_5[3:0]), .d(sum0_5_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_5_5(.q(sum1_5[3:0]), .d(sum1_5_pipe), .clk(clk), .rstn(rstn));

	FA_2bit FA2_5_2(.sum(sum0_5[5:4]), .c_out(c_out_5_0), .a(a_q_pipe[2:1]), .b(b_q_pipe[2:1]), .c_in(c_in_5_0));
	FA_2bit FA2_5_3(.sum(sum1_5[5:4]), .c_out(c_out_5_1), .a(a_q_pipe[2:1]), .b(b_q_pipe[2:1]), .c_in(c_in_5_1));

	mux2to1_7bit M7_5_0(.out({c_out_5_s, sum_d[20:15]}), .i0({c_out_5_0, sum0_5}), .i1({c_out_5_1, sum1_5}), .s(c_out_4_s));

	//Stage_6 : 4-bit + 3-bit FA w/ 8-bit MUX

	wire [4-1:0] sum0_6_pipe, sum1_6_pipe;
	wire [7-1:0] sum0_6, sum1_6;
	wire c_in_6_0, c_in_6_1;
	wire c_out_6_0, c_out_6_1;

	DFF_3bit DFF_6_0(.q(a_q_pipe[5:3]), .d(a_q[27:25]), .clk(clk), .rstn(rstn));
	DFF_3bit DFF_6_1(.q(b_q_pipe[5:3]), .d(b_q[27:25]), .clk(clk), .rstn(rstn));

	FA_4bit FA4_6_0(.sum(sum0_6_pipe), .c_out(c_out_6_0_pipe), .a(a_q[24:21]), .b(b_q[24:21]), .c_in(1'b0));
	FA_4bit FA4_6_1(.sum(sum1_6_pipe), .c_out(c_out_6_1_pipe), .a(a_q[24:21]), .b(b_q[24:21]), .c_in(1'b1));
	DFF_1bit DFF_6_2(.q(c_in_6_0), .d(c_out_6_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_6_3(.q(c_in_6_1), .d(c_out_6_1_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_6_4(.q(sum0_6[3:0]), .d(sum0_6_pipe), .clk(clk), .rstn(rstn));
	DFF_4bit DFF_6_5(.q(sum1_6[3:0]), .d(sum1_6_pipe), .clk(clk), .rstn(rstn));

	FA_3bit FA3_6_2(.sum(sum0_6[6:4]), .c_out(c_out_6_0), .a(a_q_pipe[5:3]), .b(b_q_pipe[5:3]), .c_in(c_in_6_0));
	FA_3bit FA3_6_3(.sum(sum1_6[6:4]), .c_out(c_out_6_1), .a(a_q_pipe[5:3]), .b(b_q_pipe[5:3]), .c_in(c_in_6_1));

	mux2to1_8bit M8_6_0(.out(sum_d[28:21]), .i0({c_out_6_0, sum0_6}), .i1({c_out_6_1, sum1_6}), .s(c_out_5_s));

	//DFF_output
	DFF_29bit DFF_out(.q(sum), .d(sum_d), .clk(clk), .rstn(rstn));
	
endmodule

module DFF_1bit (
	output reg q,
	input d,
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule

module DFF_2bit (
	output reg [2-1:0] q,
	input [2-1:0] d,
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule

module DFF_3bit (
	output reg [3-1:0] q,
	input [3-1:0] d,
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule

module DFF_4bit (
	output reg [4-1:0] q,
	input [4-1:0] d,
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule

module DFF_28bit (
	output reg [28-1:0] q,
	input [28-1:0] d,
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule

module DFF_29bit (
	output reg [29-1:0] q,
	input [29-1:0] d, 
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule

module FA_2bit (
	output [2-1:0] sum,
	output c_out,
	input [2-1:0] a, b,
	input c_in
);

	wire c_out_2bit;

	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_2bit), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out), .a(a[1]), .b(b[1]), .c_in(c_out_2bit));
	
endmodule

module FA_3bit (
	output [3-1:0] sum,
	output c_out,
	input [3-1:0] a, b,
	input c_in
);

	wire [1:0] c_out_3bit;

	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_3bit[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out_3bit[1]), .a(a[1]), .b(b[1]), .c_in(c_out_3bit[0]));
	FA_1bit fa02 (.sum(sum[2]), .c_out(c_out), .a(a[2]), .b(b[2]), .c_in(c_out_3bit[1]));
	
endmodule

module FA_4bit (
	output [3:0] sum,
	output c_out,
	input [3:0] a, b,
	input c_in
);

	wire [2:0] c_out_4bit;

	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_4bit[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out_4bit[1]), .a(a[1]), .b(b[1]), .c_in(c_out_4bit[0]));
	FA_1bit fa02 (.sum(sum[2]), .c_out(c_out_4bit[2]), .a(a[2]), .b(b[2]), .c_in(c_out_4bit[1]));
	FA_1bit fa03 (.sum(sum[3]), .c_out(c_out), .a(a[3]), .b(b[3]), .c_in(c_out_4bit[2]));
	
endmodule

module FA_5bit (
	output [4:0] sum,
	output c_out,
	input [4:0] a, b,
	input c_in
);

	wire [3:0] c_out_5bit;

	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_5bit[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out_5bit[1]), .a(a[1]), .b(b[1]), .c_in(c_out_5bit[0]));
	FA_1bit fa02 (.sum(sum[2]), .c_out(c_out_5bit[2]), .a(a[2]), .b(b[2]), .c_in(c_out_5bit[1]));
	FA_1bit fa03 (.sum(sum[3]), .c_out(c_out_5bit[3]), .a(a[3]), .b(b[3]), .c_in(c_out_5bit[2]));
	FA_1bit fa04 (.sum(sum[4]), .c_out(c_out), .a(a[4]), .b(b[4]), .c_in(c_out_5bit[3]));
	
endmodule

module FA_6bit (
	output [5:0] sum,
	output c_out,
	input [5:0] a, b,
	input c_in
);

	wire [4:0] c_out_6bit;

	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_6bit[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out_6bit[1]), .a(a[1]), .b(b[1]), .c_in(c_out_6bit[0]));
	FA_1bit fa02 (.sum(sum[2]), .c_out(c_out_6bit[2]), .a(a[2]), .b(b[2]), .c_in(c_out_6bit[1]));
	FA_1bit fa03 (.sum(sum[3]), .c_out(c_out_6bit[3]), .a(a[3]), .b(b[3]), .c_in(c_out_6bit[2]));
	FA_1bit fa04 (.sum(sum[4]), .c_out(c_out_6bit[4]), .a(a[4]), .b(b[4]), .c_in(c_out_6bit[3]));
	FA_1bit fa05 (.sum(sum[5]), .c_out(c_out), .a(a[5]), .b(b[5]), .c_in(c_out_6bit[4]));
	
endmodule

module FA_7bit (
	output [6:0] sum,
	output c_out,
	input [6:0] a, b,
	input c_in
);

	wire [5:0] c_out_7bit;

	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_7bit[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out_7bit[1]), .a(a[1]), .b(b[1]), .c_in(c_out_7bit[0]));
	FA_1bit fa02 (.sum(sum[2]), .c_out(c_out_7bit[2]), .a(a[2]), .b(b[2]), .c_in(c_out_7bit[1]));
	FA_1bit fa03 (.sum(sum[3]), .c_out(c_out_7bit[3]), .a(a[3]), .b(b[3]), .c_in(c_out_7bit[2]));
	FA_1bit fa04 (.sum(sum[4]), .c_out(c_out_7bit[4]), .a(a[4]), .b(b[4]), .c_in(c_out_7bit[3]));
	FA_1bit fa05 (.sum(sum[5]), .c_out(c_out_7bit[5]), .a(a[5]), .b(b[5]), .c_in(c_out_7bit[4]));
	FA_1bit fa06 (.sum(sum[6]), .c_out(c_out), .a(a[6]), .b(b[6]), .c_in(c_out_7bit[5]));
	
endmodule

module FA_1bit (
	output sum, c_out,
	input a, b, c_in
);

	wire s1, s2;
	wire c1;

	xor(s1, a, b);
	and(c1, a, b);
	and(s2, s1, c_in);

	xor(sum, s1, c_in);
	xor(c_out, c1, s2);
	
endmodule

module mux2to1_4bit (
	output [3:0] out,
	input [3:0] i0, i1,
	input s
);

	mux2to1 mux0 (out[0], i0[0], i1[0], s);
	mux2to1 mux1 (out[1], i0[1], i1[1], s);
	mux2to1 mux2 (out[2], i0[2], i1[2], s);
	mux2to1 mux3 (out[3], i0[3], i1[3], s);
	
endmodule

module mux2to1_5bit (
	output [4:0] out,
	input [4:0] i0, i1,
	input s
);

	mux2to1 mux0 (out[0], i0[0], i1[0], s);
	mux2to1 mux1 (out[1], i0[1], i1[1], s);
	mux2to1 mux2 (out[2], i0[2], i1[2], s);
	mux2to1 mux3 (out[3], i0[3], i1[3], s);
	mux2to1 mux4 (out[4], i0[4], i1[4], s);
	
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

	not (s_not, s);

	and (and0, i0, s_not);
	and (and1, i1, s);

	or(out, and0, and1);

endmodule