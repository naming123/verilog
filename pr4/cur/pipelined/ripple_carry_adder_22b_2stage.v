module ripple_carry_adder_22b_2stage (
	output [23-1:0] sum,
	input [22-1:0] a, b,
	input c_in, clk, rstn
);

	//Stage_1 : 11-bit FA_LSB

	wire [22-1:0] a_q, b_q;
	wire c_in_q;
	DFF_11bit DFF_a_in_lsb (.q(a_q[11-1:0]), .d(a[11-1:0]), .clk(clk), .rstn(rstn));
	DFF_11bit DFF_b_in_lsb (.q(b_q[11-1:0]), .d(b[11-1:0]), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_c_in_in (.q(c_in_q), .d(c_in), .clk(clk), .rstn(rstn));

	wire c_out;
	wire [23-1:0] sum_d;
	FA_11bit FA11_01_LSB (.sum({c_out, sum_d[10:0]}), .a(a_q[10:0]), .b(b_q[10:0]), .c_in(c_in_q));

	wire [11-1:0] sum_d_pipe;
	wire c_out_q;
	DFF_11bit DFF_sum_pipe (.q(sum_d_pipe), .d(sum_d[11-1:0]), .clk(clk), .rstn(rstn));
	DFF_11bit DFF_sum_out_lsb (.q(sum[11-1:0]), .d(sum_d_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_c_out_pipe (.q(c_out_q), .d(c_out), .clk(clk), .rstn(rstn));

	//Stage_2 : 11-bit FA_MSB

	wire [10:0] a_q_pipe, b_q_pipe;
	DFF_11bit DFF_a_in_msb (.q(a_q[22-1:11]), .d(a[22-1:11]), .clk(clk), .rstn(rstn));
	DFF_11bit DFF_a_in_msb_pipe (.q(a_q_pipe), .d(a_q[22-1:11]), .clk(clk), .rstn(rstn));
	DFF_11bit DFF_b_in_msb (.q(b_q[22-1:11]), .d(b[22-1:11]), .clk(clk), .rstn(rstn));
	DFF_11bit DFF_b_in_msb_pipe (.q(b_q_pipe), .d(b_q[22-1:11]), .clk(clk), .rstn(rstn));

	FA_11bit FA11_02_MSB (.sum(sum_d[22:11]), .a(a_q_pipe), .b(b_q_pipe), .c_in(c_out_q));

	DFF_12bit DFF_sum_out_msb (.q(sum[23-1:11]), .d(sum_d[23-1:11]), .clk(clk), .rstn(rstn));
	
endmodule

module FA_11bit (
	output [11:0] sum,
	input [10:0]a, b, 
	input c_in
);

	wire [9:0] c_out;

	fulladd_gate fa00 (sum[0], c_out[0], a[0], b[0], c_in);
	fulladd_gate fa01 (sum[1], c_out[1], a[1], b[1], c_out[0]);
	fulladd_gate fa02 (sum[2], c_out[2], a[2], b[2], c_out[1]);
	fulladd_gate fa03 (sum[3], c_out[3], a[3], b[3], c_out[2]);
	fulladd_gate fa04 (sum[4], c_out[4], a[4], b[4], c_out[3]);
	fulladd_gate fa05 (sum[5], c_out[5], a[5], b[5], c_out[4]);
	fulladd_gate fa06 (sum[6], c_out[6], a[6], b[6], c_out[5]);
	fulladd_gate fa07 (sum[7], c_out[7], a[7], b[7], c_out[6]);
	fulladd_gate fa08 (sum[8], c_out[8], a[8], b[8], c_out[7]);
	fulladd_gate fa09 (sum[9], c_out[9], a[9], b[9], c_out[8]);
	fulladd_gate fa10 (sum[10], sum[11], a[10], b[10], c_out[9]);

endmodule

module fulladd_gate (
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

module DFF_11bit (
	output reg [11-1:0] q,
	input [11-1:0] d,
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

module DFF_12bit (
	output reg [12-1:0] q,
	input [12-1:0] d,
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