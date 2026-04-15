module ripple_carry_adder_22bit (
	output [22:0] sum,
	input [21:0] a, b,
	input c_in, clk, rstn
);

	wire c_in_q;
	wire [21:0] a_q, b_q;
	wire [22:0] sum_d;

	fulladd22_gate FA (.sum(sum_d), .a(a_q), .b(b_q), .c_in(c_in_q));
	DFF_input DFF_in (.a_q(a_q), .b_q(b_q), .c_in_q(c_in_q), .a(a), .b(b), .c_in(c_in), .clk(clk), .rstn(rstn));
	DFF_output DFF_out (.sum(sum), .sum_d(sum_d), .clk(clk), .rstn(rstn));
	
endmodule

module fulladd22_gate (
	output [22:0] sum,
	input [21:0] a, b,
	input c_in
);

	wire [21:0] c_out;

	fulladd_gate fa00 (sum[0],  c_out[0],  a[0],  b[0],  c_in);
	fulladd_gate fa01 (sum[1],  c_out[1],  a[1],  b[1],  c_out[0]);
	fulladd_gate fa02 (sum[2],  c_out[2],  a[2],  b[2],  c_out[1]);
	fulladd_gate fa03 (sum[3],  c_out[3],  a[3],  b[3],  c_out[2]);
	fulladd_gate fa04 (sum[4],  c_out[4],  a[4],  b[4],  c_out[3]);
	fulladd_gate fa05 (sum[5],  c_out[5],  a[5],  b[5],  c_out[4]);
	fulladd_gate fa06 (sum[6],  c_out[6],  a[6],  b[6],  c_out[5]);
	fulladd_gate fa07 (sum[7],  c_out[7],  a[7],  b[7],  c_out[6]);
	fulladd_gate fa08 (sum[8],  c_out[8],  a[8],  b[8],  c_out[7]);
	fulladd_gate fa09 (sum[9],  c_out[9],  a[9],  b[9],  c_out[8]);
	fulladd_gate fa10 (sum[10], c_out[10], a[10], b[10], c_out[9]);
	fulladd_gate fa11 (sum[11], c_out[11], a[11], b[11], c_out[10]);
	fulladd_gate fa12 (sum[12], c_out[12], a[12], b[12], c_out[11]);
	fulladd_gate fa13 (sum[13], c_out[13], a[13], b[13], c_out[12]);
	fulladd_gate fa14 (sum[14], c_out[14], a[14], b[14], c_out[13]);
	fulladd_gate fa15 (sum[15], c_out[15], a[15], b[15], c_out[14]);
	fulladd_gate fa16 (sum[16], c_out[16], a[16], b[16], c_out[15]);
	fulladd_gate fa17 (sum[17], c_out[17], a[17], b[17], c_out[16]);
	fulladd_gate fa18 (sum[18], c_out[18], a[18], b[18], c_out[17]);
	fulladd_gate fa19 (sum[19], c_out[19], a[19], b[19], c_out[18]);
	fulladd_gate fa20 (sum[20], c_out[20], a[20], b[20], c_out[19]);
	fulladd_gate fa21 (sum[21], sum[22],   a[21], b[21], c_out[20]);

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

module DFF_input (
	output reg [21:0] a_q, b_q,
	output reg c_in_q,
	input [21:0] a, b,
	input c_in, clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn) begin
			a_q    <= 0;
			b_q    <= 0;
			c_in_q <= 0;
		end
		else begin
			a_q    <= a;
			b_q    <= b;
			c_in_q <= c_in;
		end
	end
endmodule

module DFF_output (
	output reg [22:0] sum,
	input [22:0] sum_d,
	input clk, rstn
);
	
	always @(posedge clk) 
	begin
		if (!rstn)
			sum <= 0;
		else
			sum <= sum_d;
	end
endmodule