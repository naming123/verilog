module CSM_RCA_22bit (
	output [44-1:0] mul,
	input [22-1:0] a, b,
	input clk, rstn
);
	wire [22-1:0] a_q, b_q;
	wire [44-1:0] mul_d;
	DFF_22bit DFF_a_in (.q(a_q), .d(a), .clk(clk), .rstn(rstn));
	DFF_22bit DFF_b_in (.q(b_q), .d(b), .clk(clk), .rstn(rstn));
	DFF_44bit DFF_mul_out (.q(mul), .d(mul_d), .clk(clk), .rstn(rstn));

	multiplier_rca MUL_22_22_RCA (.mul(mul_d), .a(a_q), .b(b_q), .clk(clk), .rstn(rstn));

endmodule

module multiplier_rca (
 	output [44-1:0] mul,
 	input [22-1:0] a, b
	input clk, rstn
);
 	
 	// #1: Partial Product
 	wire [21-1:0] x0;
 	wire [22-1:0] x[1:21];
	...
 	Carry_Save_Adder_22bit CSA19 (.sum(pp_sum[19]), .c_out(c_out[19]), .mul_out(mul[20]), .a({1'b0, pp_sum[18]}), .b(x[20]), .c_in(c_out[18]));

	// ── Pipeline cut ──────────────────────────────────────
	wire [21-1:0] pp_sum19_q;
	wire [22-1:0] c_out19_q;
	wire [22-1:0] x21_q;
	DFF_21bit DFF_pp_sum19 (.q(pp_sum19_q), .d(pp_sum[19]), .clk(clk), .rstn(rstn));
	DFF_22bit DFF_c_out19  (.q(c_out19_q),  .d(c_out[19]),  .clk(clk), .rstn(rstn));
	DFF_22bit DFF_x21      (.q(x21_q),      .d(x[21]),      .clk(clk), .rstn(rstn));
	// ──────────────────────────────────────────────────────

 	//critical path
	Carry_Save_Adder_22bit CSA20 (.sum(pp_sum[20]), .c_out(c_out[20]), .mul_out(mul[21]), .a({1'b0, pp_sum19_q}), .b(x21_q),   .c_in(c_out19_q));

 	// #3: Vector Merging Adder
 	FA_22bit VMA00 (.sum(mul[43:22]), .a({1'b0, pp_sum[20]}), .b(c_out[20]), .c_in(1'b0));

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
// 22bit * 1bit
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

module FA_22bit (
	output [22-1:0] sum,
	input [22-1:0] a, b, 
	input c_in
);
	wire [21:0] c_out;

	FA_1bit FA00 (.sum(sum[0]),  .c_out(c_out[0]),  .a(a[0]),  .b(b[0]),  .c_in(c_in));
	FA_1bit FA01 (.sum(sum[1]),  .c_out(c_out[1]),  .a(a[1]),  .b(b[1]),  .c_in(c_out[0]));
	FA_1bit FA02 (.sum(sum[2]),  .c_out(c_out[2]),  .a(a[2]),  .b(b[2]),  .c_in(c_out[1]));
	FA_1bit FA03 (.sum(sum[3]),  .c_out(c_out[3]),  .a(a[3]),  .b(b[3]),  .c_in(c_out[2]));
	FA_1bit FA04 (.sum(sum[4]),  .c_out(c_out[4]),  .a(a[4]),  .b(b[4]),  .c_in(c_out[3]));
	FA_1bit FA05 (.sum(sum[5]),  .c_out(c_out[5]),  .a(a[5]),  .b(b[5]),  .c_in(c_out[4]));
	FA_1bit FA06 (.sum(sum[6]),  .c_out(c_out[6]),  .a(a[6]),  .b(b[6]),  .c_in(c_out[5]));
	FA_1bit FA07 (.sum(sum[7]),  .c_out(c_out[7]),  .a(a[7]),  .b(b[7]),  .c_in(c_out[6]));
	FA_1bit FA08 (.sum(sum[8]),  .c_out(c_out[8]),  .a(a[8]),  .b(b[8]),  .c_in(c_out[7]));
	FA_1bit FA09 (.sum(sum[9]),  .c_out(c_out[9]),  .a(a[9]),  .b(b[9]),  .c_in(c_out[8]));
	FA_1bit FA10 (.sum(sum[10]), .c_out(c_out[10]), .a(a[10]), .b(b[10]), .c_in(c_out[9]));
	FA_1bit FA11 (.sum(sum[11]), .c_out(c_out[11]), .a(a[11]), .b(b[11]), .c_in(c_out[10]));
	FA_1bit FA12 (.sum(sum[12]), .c_out(c_out[12]), .a(a[12]), .b(b[12]), .c_in(c_out[11]));
	FA_1bit FA13 (.sum(sum[13]), .c_out(c_out[13]), .a(a[13]), .b(b[13]), .c_in(c_out[12]));
	FA_1bit FA14 (.sum(sum[14]), .c_out(c_out[14]), .a(a[14]), .b(b[14]), .c_in(c_out[13]));
	FA_1bit FA15 (.sum(sum[15]), .c_out(c_out[15]), .a(a[15]), .b(b[15]), .c_in(c_out[14]));
	FA_1bit FA16 (.sum(sum[16]), .c_out(c_out[16]), .a(a[16]), .b(b[16]), .c_in(c_out[15]));
	FA_1bit FA17 (.sum(sum[17]), .c_out(c_out[17]), .a(a[17]), .b(b[17]), .c_in(c_out[16]));
	FA_1bit FA18 (.sum(sum[18]), .c_out(c_out[18]), .a(a[18]), .b(b[18]), .c_in(c_out[17]));
	FA_1bit FA19 (.sum(sum[19]), .c_out(c_out[19]), .a(a[19]), .b(b[19]), .c_in(c_out[18]));
	FA_1bit FA20 (.sum(sum[20]), .c_out(c_out[20]), .a(a[20]), .b(b[20]), .c_in(c_out[19]));
	FA_1bit FA21 (.sum(sum[21]), .c_out(c_out[21]), .a(a[21]), .b(b[21]), .c_in(c_out[20]));

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
module DFF_21bit (
	output reg [21-1:0] q,
	input [21-1:0] d,
	input clk, rstn
);
	always @(posedge clk)
	begin
		if (!rstn) q <= 0;
		else       q <= d;
	end
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