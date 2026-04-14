`timescale 1 ns / 1 ps
module stimulus_CSM_22bit;

	wire    [43:0]  mul_out_rca, mul_out_csa;
	reg     [21:0]  a, b;
	reg             clk, rstn;

	reg     [21:0]  mat_a_input      [0:99];
	reg     [21:0]  mat_b_input      [0:99];
	reg     [43:0]  mat_mult_output  [0:99];
	reg     [43:0]  mat_out;

	integer i, k, err_rca, err_csa;

	CSM_RCA_22bit      MULT0   (.mul(mul_out_rca), .a(a), .b(b), .clk(clk), .rstn(rstn));
	CSM_SRCSA_22bit    MULT1   (.mul(mul_out_csa), .a(a), .b(b), .clk(clk), .rstn(rstn));
	// 두개 한번에하는 코드

	always #5 clk <= ~clk;

	initial	begin
		clk <= 1; rstn <= 0;
		#12
		rstn <= 1;
		#1050 $stop;
	end

	initial	begin
		$readmemh("a_input.txt", mat_a_input);
		$readmemh("b_input.txt", mat_b_input);
		i = 0;
		#(20);

		for(i = 0; i < 100; i = i + 1)
		begin
			a = mat_a_input[i];
			b = mat_b_input[i];
			#(10);
		end

	end

	initial	begin
		$readmemh("mult_output.txt", mat_mult_output);
		err_rca = 0;
        err_csa = 0;
		k = 0;module multiplier_srcsa_DFF (
	output [44-1:0] mul,
	input [22-1:0] a, b,
	input clk, rstn
);
	wire [22-1:0] a_q, b_q;
	wire [44-1:0] mul_d;
	DFF_22bit DFF_a_in (.q(a_q), .d(a), .clk(clk), .rstn(rstn));
	DFF_22bit DFF_b_in (.q(b_q), .d(b), .clk(clk), .rstn(rstn));
	DFF_44bit DFF_mul_out (.q(mul), .d(mul_d), .clk(clk), .rstn(rstn));

	multiplier_srcsa MUL_22_22_SRCSA (.mul(mul_d), .a(a_q), .b(b_q));
endmodule

module multiplier_srcsa (
	output [44-1:0] mul,
	input [22-1:0] a, b
);
	
	// #1: Partial Product
	wire [21-1:0] x0;
	wire [22-1:0] x[1:21];
	Partial_Product PP_b_0  (.x({x0, mul[0]}), .a(a), .b(b[0]));
	Partial_Product PP_b_1  (.x(x[1]),  .a(a), .b(b[1]));
	Partial_Product PP_b_2  (.x(x[2]),  .a(a), .b(b[2]));
	Partial_Product PP_b_3  (.x(x[3]),  .a(a), .b(b[3]));
	Partial_Product PP_b_4  (.x(x[4]),  .a(a), .b(b[4]));
	Partial_Product PP_b_5  (.x(x[5]),  .a(a), .b(b[5]));
	Partial_Product PP_b_6  (.x(x[6]),  .a(a), .b(b[6]));
	Partial_Product PP_b_7  (.x(x[7]),  .a(a), .b(b[7]));
	Partial_Product PP_b_8  (.x(x[8]),  .a(a), .b(b[8]));
	Partial_Product PP_b_9  (.x(x[9]),  .a(a), .b(b[9]));
	Partial_Product PP_b_10 (.x(x[10]), .a(a), .b(b[10]));
	Partial_Product PP_b_11 (.x(x[11]), .a(a), .b(b[11]));
	Partial_Product PP_b_12 (.x(x[12]), .a(a), .b(b[12]));
	Partial_Product PP_b_13 (.x(x[13]), .a(a), .b(b[13]));
	Partial_Product PP_b_14 (.x(x[14]), .a(a), .b(b[14]));
	Partial_Product PP_b_15 (.x(x[15]), .a(a), .b(b[15]));
	Partial_Product PP_b_16 (.x(x[16]), .a(a), .b(b[16]));
	Partial_Product PP_b_17 (.x(x[17]), .a(a), .b(b[17]));
	Partial_Product PP_b_18 (.x(x[18]), .a(a), .b(b[18]));
	Partial_Product PP_b_19 (.x(x[19]), .a(a), .b(b[19]));
	Partial_Product PP_b_20 (.x(x[20]), .a(a), .b(b[20]));
	Partial_Product PP_b_21 (.x(x[21]), .a(a), .b(b[21]));

	// #2: Carry Save Adder
	wire [22-1:0] c_out[0:20];
	wire [21-1:0] pp_sum[0:20];
	Carry_Save_Adder_22bit CSA00 (.sum(pp_sum[0]),  .c_out(c_out[0]),  .mul_out(mul[1]),  .a({1'b0, x0}),          .b(x[1]),  .c_in(22'b0));
	Carry_Save_Adder_22bit CSA01 (.sum(pp_sum[1]),  .c_out(c_out[1]),  .mul_out(mul[2]),  .a({1'b0, pp_sum[0]}),   .b(x[2]),  .c_in(c_out[0]));
	Carry_Save_Adder_22bit CSA02 (.sum(pp_sum[2]),  .c_out(c_out[2]),  .mul_out(mul[3]),  .a({1'b0, pp_sum[1]}),   .b(x[3]),  .c_in(c_out[1]));
	Carry_Save_Adder_22bit CSA03 (.sum(pp_sum[3]),  .c_out(c_out[3]),  .mul_out(mul[4]),  .a({1'b0, pp_sum[2]}),   .b(x[4]),  .c_in(c_out[2]));
	Carry_Save_Adder_22bit CSA04 (.sum(pp_sum[4]),  .c_out(c_out[4]),  .mul_out(mul[5]),  .a({1'b0, pp_sum[3]}),   .b(x[5]),  .c_in(c_out[3]));
	Carry_Save_Adder_22bit CSA05 (.sum(pp_sum[5]),  .c_out(c_out[5]),  .mul_out(mul[6]),  .a({1'b0, pp_sum[4]}),   .b(x[6]),  .c_in(c_out[4]));
	Carry_Save_Adder_22bit CSA06 (.sum(pp_sum[6]),  .c_out(c_out[6]),  .mul_out(mul[7]),  .a({1'b0, pp_sum[5]}),   .b(x[7]),  .c_in(c_out[5]));
	Carry_Save_Adder_22bit CSA07 (.sum(pp_sum[7]),  .c_out(c_out[7]),  .mul_out(mul[8]),  .a({1'b0, pp_sum[6]}),   .b(x[8]),  .c_in(c_out[6]));
	Carry_Save_Adder_22bit CSA08 (.sum(pp_sum[8]),  .c_out(c_out[8]),  .mul_out(mul[9]),  .a({1'b0, pp_sum[7]}),   .b(x[9]),  .c_in(c_out[7]));
	Carry_Save_Adder_22bit CSA09 (.sum(pp_sum[9]),  .c_out(c_out[9]),  .mul_out(mul[10]), .a({1'b0, pp_sum[8]}),   .b(x[10]), .c_in(c_out[8]));
	Carry_Save_Adder_22bit CSA10 (.sum(pp_sum[10]), .c_out(c_out[10]), .mul_out(mul[11]), .a({1'b0, pp_sum[9]}),   .b(x[11]), .c_in(c_out[9]));
	Carry_Save_Adder_22bit CSA11 (.sum(pp_sum[11]), .c_out(c_out[11]), .mul_out(mul[12]), .a({1'b0, pp_sum[10]}),  .b(x[12]), .c_in(c_out[10]));
	Carry_Save_Adder_22bit CSA12 (.sum(pp_sum[12]), .c_out(c_out[12]), .mul_out(mul[13]), .a({1'b0, pp_sum[11]}),  .b(x[13]), .c_in(c_out[11]));
	Carry_Save_Adder_22bit CSA13 (.sum(pp_sum[13]), .c_out(c_out[13]), .mul_out(mul[14]), .a({1'b0, pp_sum[12]}),  .b(x[14]), .c_in(c_out[12]));
	Carry_Save_Adder_22bit CSA14 (.sum(pp_sum[14]), .c_out(c_out[14]), .mul_out(mul[15]), .a({1'b0, pp_sum[13]}),  .b(x[15]), .c_in(c_out[13]));
	Carry_Save_Adder_22bit CSA15 (.sum(pp_sum[15]), .c_out(c_out[15]), .mul_out(mul[16]), .a({1'b0, pp_sum[14]}),  .b(x[16]), .c_in(c_out[14]));
	Carry_Save_Adder_22bit CSA16 (.sum(pp_sum[16]), .c_out(c_out[16]), .mul_out(mul[17]), .a({1'b0, pp_sum[15]}),  .b(x[17]), .c_in(c_out[15]));
	Carry_Save_Adder_22bit CSA17 (.sum(pp_sum[17]), .c_out(c_out[17]), .mul_out(mul[18]), .a({1'b0, pp_sum[16]}),  .b(x[18]), .c_in(c_out[16]));
	Carry_Save_Adder_22bit CSA18 (.sum(pp_sum[18]), .c_out(c_out[18]), .mul_out(mul[19]), .a({1'b0, pp_sum[17]}),  .b(x[19]), .c_in(c_out[17]));
	Carry_Save_Adder_22bit CSA19 (.sum(pp_sum[19]), .c_out(c_out[19]), .mul_out(mul[20]), .a({1'b0, pp_sum[18]}),  .b(x[20]), .c_in(c_out[18]));
	Carry_Save_Adder_22bit CSA20 (.sum(pp_sum[20]), .c_out(c_out[20]), .mul_out(mul[21]), .a({1'b0, pp_sum[19]}),  .b(x[21]), .c_in(c_out[19]));

	// #3: Vector Merging Adder
	SRCSA_22bit VMA00 (.sum(mul[43:22]), .a({1'b0, pp_sum[20]}), .b(c_out[20]), .c_in(1'b0));

endmodule

module Carry_Save_Adder_22bit (
	output [21-1:0] sum, 
	output [22-1:0] c_out,
	output mul_out,
	input [22-1:0] a, b, c_in
);
	
	FA_1bit FA_CSA00 (.sum(mul_out),  .c_out(c_out[0]),  .a(a[0]),  .b(b[0]),  .c_in(c_in[0]));
	FA_1bit FA_CSA01 (.sum(sum[0]),   .c_out(c_out[1]),  .a(a[1]),  .b(b[1]),  .c_in(c_in[1]));
	FA_1bit FA_CSA02 (.sum(sum[1]),   .c_out(c_out[2]),  .a(a[2]),  .b(b[2]),  .c_in(c_in[2]));
	FA_1bit FA_CSA03 (.sum(sum[2]),   .c_out(c_out[3]),  .a(a[3]),  .b(b[3]),  .c_in(c_in[3]));
	FA_1bit FA_CSA04 (.sum(sum[3]),   .c_out(c_out[4]),  .a(a[4]),  .b(b[4]),  .c_in(c_in[4]));
	FA_1bit FA_CSA05 (.sum(sum[4]),   .c_out(c_out[5]),  .a(a[5]),  .b(b[5]),  .c_in(c_in[5]));
	FA_1bit FA_CSA06 (.sum(sum[5]),   .c_out(c_out[6]),  .a(a[6]),  .b(b[6]),  .c_in(c_in[6]));
	FA_1bit FA_CSA07 (.sum(sum[6]),   .c_out(c_out[7]),  .a(a[7]),  .b(b[7]),  .c_in(c_in[7]));
	FA_1bit FA_CSA08 (.sum(sum[7]),   .c_out(c_out[8]),  .a(a[8]),  .b(b[8]),  .c_in(c_in[8]));
	FA_1bit FA_CSA09 (.sum(sum[8]),   .c_out(c_out[9]),  .a(a[9]),  .b(b[9]),  .c_in(c_in[9]));
	FA_1bit FA_CSA10 (.sum(sum[9]),   .c_out(c_out[10]), .a(a[10]), .b(b[10]), .c_in(c_in[10]));
	FA_1bit FA_CSA11 (.sum(sum[10]),  .c_out(c_out[11]), .a(a[11]), .b(b[11]), .c_in(c_in[11]));
	FA_1bit FA_CSA12 (.sum(sum[11]),  .c_out(c_out[12]), .a(a[12]), .b(b[12]), .c_in(c_in[12]));
	FA_1bit FA_CSA13 (.sum(sum[12]),  .c_out(c_out[13]), .a(a[13]), .b(b[13]), .c_in(c_in[13]));
	FA_1bit FA_CSA14 (.sum(sum[13]),  .c_out(c_out[14]), .a(a[14]), .b(b[14]), .c_in(c_in[14]));
	FA_1bit FA_CSA15 (.sum(sum[14]),  .c_out(c_out[15]), .a(a[15]), .b(b[15]), .c_in(c_in[15]));
	FA_1bit FA_CSA16 (.sum(sum[15]),  .c_out(c_out[16]), .a(a[16]), .b(b[16]), .c_in(c_in[16]));
	FA_1bit FA_CSA17 (.sum(sum[16]),  .c_out(c_out[17]), .a(a[17]), .b(b[17]), .c_in(c_in[17]));
	FA_1bit FA_CSA18 (.sum(sum[17]),  .c_out(c_out[18]), .a(a[18]), .b(b[18]), .c_in(c_in[18]));
	FA_1bit FA_CSA19 (.sum(sum[18]),  .c_out(c_out[19]), .a(a[19]), .b(b[19]), .c_in(c_in[19]));
	FA_1bit FA_CSA20 (.sum(sum[19]),  .c_out(c_out[20]), .a(a[20]), .b(b[20]), .c_in(c_in[20]));
	FA_1bit FA_CSA21 (.sum(sum[20]),  .c_out(c_out[21]), .a(a[21]), .b(b[21]), .c_in(c_in[21]));
	
endmodule

module Partial_Product (
	output [22-1:0] x,
	input [22-1:0] a,
	input b
);
	
	and PP00 (x[0],  a[0],  b);
	and PP01 (x[1],  a[1],  b);
	and PP02 (x[2],  a[2],  b);
	and PP03 (x[3],  a[3],  b);
	and PP04 (x[4],  a[4],  b);
	and PP05 (x[5],  a[5],  b);
	and PP06 (x[6],  a[6],  b);
	and PP07 (x[7],  a[7],  b);
	and PP08 (x[8],  a[8],  b);
	and PP09 (x[9],  a[9],  b);
	and PP10 (x[10], a[10], b);
	and PP11 (x[11], a[11], b);
	and PP12 (x[12], a[12], b);
	and PP13 (x[13], a[13], b);
	and PP14 (x[14], a[14], b);
	and PP15 (x[15], a[15], b);
	and PP16 (x[16], a[16], b);
	and PP17 (x[17], a[17], b);
	and PP18 (x[18], a[18], b);
	and PP19 (x[19], a[19], b);
	and PP20 (x[20], a[20], b);
	and PP21 (x[21], a[21], b);
	
endmodule

module SRCSA_22bit (
	output [21:0] sum,
	input [21:0] a, b,
	input c_in
);
	// Stage_1 : FA 3bit (bits [2:0])
	wire c_out_1;
	FA_3bit FA3_1_0 (.sum(sum[2:0]), .c_out(c_out_1), .a(a[2:0]), .b(b[2:0]), .c_in(1'b0));

	// Stage_2 : FA w/ MUX 3bit (bits [5:3])
	wire [2:0] s_mux4_0, s_mux4_1;
	wire c_out_2_0, c_out_2_1, c_out_2_s;
	FA_3bit FA3_2_0 (.sum(s_mux4_0), .c_out(c_out_2_0), .a(a[5:3]), .b(b[5:3]), .c_in(1'b0));
	FA_3bit FA3_2_1 (.sum(s_mux4_1), .c_out(c_out_2_1), .a(a[5:3]), .b(b[5:3]), .c_in(1'b1));
	mux2to1_4bit M4_2_0 (.out({c_out_2_s, sum[5:3]}), .i0({c_out_2_0, s_mux4_0}), .i1({c_out_2_1, s_mux4_1}), .s(c_out_1));

	// Stage_3 : FA w/ MUX 4bit (bits [9:6])
	wire [3:0] s_mux5_0, s_mux5_1;
	wire c_out_3_0, c_out_3_1, c_out_3_s;
	FA_4bit FA4_3_0 (.sum(s_mux5_0), .c_out(c_out_3_0), .a(a[9:6]), .b(b[9:6]), .c_in(1'b0));
	FA_4bit FA4_3_1 (.sum(s_mux5_1), .c_out(c_out_3_1), .a(a[9:6]), .b(b[9:6]), .c_in(1'b1));
	mux2to1_5bit M5_3_0 (.out({c_out_3_s, sum[9:6]}), .i0({c_out_3_0, s_mux5_0}), .i1({c_out_3_1, s_mux5_1}), .s(c_out_2_s));

	// Stage_4 : FA w/ MUX 5bit (bits [14:10])
	wire [4:0] s_mux6_0, s_mux6_1;
	wire c_out_4_0, c_out_4_1, c_out_4_s;
	FA_5bit FA5_4_0 (.sum(s_mux6_0), .c_out(c_out_4_0), .a(a[14:10]), .b(b[14:10]), .c_in(1'b0));
	FA_5bit FA5_4_1 (.sum(s_mux6_1), .c_out(c_out_4_1), .a(a[14:10]), .b(b[14:10]), .c_in(1'b1));
	mux2to1_6bit M6_4_0 (.out({c_out_4_s, sum[14:10]}), .i0({c_out_4_0, s_mux6_0}), .i1({c_out_4_1, s_mux6_1}), .s(c_out_3_s));

	// Stage_5 : FA w/ MUX 7bit (bits [21:15])
	wire [6:0] s_mux8_0, s_mux8_1;
	wire c_out_5_0, c_out_5_1;
	FA_7bit FA7_5_0 (.sum(s_mux8_0), .c_out(c_out_5_0), .a(a[21:15]), .b(b[21:15]), .c_in(1'b0));
	FA_7bit FA7_5_1 (.sum(s_mux8_1), .c_out(c_out_5_1), .a(a[21:15]), .b(b[21:15]), .c_in(1'b1));
	mux2to1_7bit M7_5_0 (.out(sum[21:15]), .i0(s_mux8_0), .i1(s_mux8_1), .s(c_out_4_s));

endmodule

module FA_3bit (
	output [2:0] sum,
	output c_out,
	input [2:0] a, b,
	input c_in
);
	wire [1:0] c_out_3bit;
	FA_1bit fa00 (.sum(sum[0]), .c_out(c_out_3bit[0]), .a(a[0]), .b(b[0]), .c_in(c_in));
	FA_1bit fa01 (.sum(sum[1]), .c_out(c_out_3bit[1]), .a(a[1]), .b(b[1]), .c_in(c_out_3bit[0]));
	FA_1bit fa02 (.sum(sum[2]), .c_out(c_out),         .a(a[2]), .b(b[2]), .c_in(c_out_3bit[1]));
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
	FA_1bit fa03 (.sum(sum[3]), .c_out(c_out),         .a(a[3]), .b(b[3]), .c_in(c_out_4bit[2]));
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
	FA_1bit fa04 (.sum(sum[4]), .c_out(c_out),         .a(a[4]), .b(b[4]), .c_in(c_out_5bit[3]));
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
	FA_1bit fa06 (.sum(sum[6]), .c_out(c_out),         .a(a[6]), .b(b[6]), .c_in(c_out_7bit[5]));
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

module DFF_22bit (
	output reg [22-1:0] q,
	input [22-1:0] d,
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

module DFF_44bit (
	output reg [44-1:0] q,
	input [44-1:0] d,
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
		#(30);

		for(k = 0; k < 100; k = k + 1) begin
			mat_out <= mat_mult_output[k];
			#(2);
			if((mul_out_rca != mat_out))
				err_rca = err_rca + 1;
			if((mul_out_csa != mat_out))
				err_csa = err_csa + 1;
			#(8);
		end
        $stop;
	end

endmodule
