module sqrt_csa_22bit_2stage (
	output [23-1:0] sum,
	input [22-1:0] a, b,
	input c_in, clk, rstn
);
	
	//DFF_input
	wire [22-1:0] a_q, b_q;
	wire c_in_q;
	
	DFF_22bit DFF_in_0(.q(a_q), .d(a), .clk(clk), .rstn(rstn));
	DFF_22bit DFF_in_1(.q(b_q), .d(b), .clk(clk), .rstn(rstn));
	DFF_1bit  DFF_in_2(.q(c_in_q), .d(c_in), .clk(clk), .rstn(rstn));

	wire [23-1:0] sum_d;

	//Stage_1 : 4-bit FA
	wire c_out_1;
	wire [4-1:0] sum_d_pipe_1;

	FA_4bit FA4_1_0(.sum(sum_d_pipe_1), .c_out(c_out_1),
	                .a(a_q[3:0]), .b(b_q[3:0]), .c_in(c_in_q));

	DFF_4bit DFF_1_0(.q(sum_d[3:0]), .d(sum_d_pipe_1), .clk(clk), .rstn(rstn));

	//Stage_2 : 4-bit FA w/ 5-bit MUX + 1bit pipe  (bits [8:4], 5비트)
	wire [4-1:0] sum0_2_pipe, sum1_2_pipe, sum0_2, sum1_2;
	wire c_out_2_0_pipe, c_out_2_1_pipe;
	wire c_out_2_0, c_out_2_1, c_out_2_s;
	wire a_q_pipe_2, b_q_pipe_2;  // bit[8] 파이프

	FA_4bit FA4_2_0(.sum(sum0_2_pipe), .c_out(c_out_2_0_pipe),
	                .a(a_q[7:4]), .b(b_q[7:4]), .c_in(1'b0));
	FA_4bit FA4_2_1(.sum(sum1_2_pipe), .c_out(c_out_2_1_pipe),
	                .a(a_q[7:4]), .b(b_q[7:4]), .c_in(1'b1));

	DFF_4bit DFF_2_0(.q(sum0_2),    .d(sum0_2_pipe),    .clk(clk), .rstn(rstn));
	DFF_4bit DFF_2_1(.q(sum1_2),    .d(sum1_2_pipe),    .clk(clk), .rstn(rstn));
	DFF_1bit DFF_2_2(.q(c_out_2_0), .d(c_out_2_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_2_3(.q(c_out_2_1), .d(c_out_2_1_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_2_4(.q(a_q_pipe_2), .d(a_q[8]),        .clk(clk), .rstn(rstn));
	DFF_1bit DFF_2_5(.q(b_q_pipe_2), .d(b_q[8]),        .clk(clk), .rstn(rstn));

	wire [5-1:0] sum0_2_full, sum1_2_full;
	wire c_out_2_0_full, c_out_2_1_full;

	FA_1bit FA1_2_0(.sum(sum0_2_full[4]), .c_out(c_out_2_0_full),
	                .a(a_q_pipe_2), .b(b_q_pipe_2), .c_in(c_out_2_0));
	FA_1bit FA1_2_1(.sum(sum1_2_full[4]), .c_out(c_out_2_1_full),
	                .a(a_q_pipe_2), .b(b_q_pipe_2), .c_in(c_out_2_1));
	assign sum0_2_full[3:0] = sum0_2;
	assign sum1_2_full[3:0] = sum1_2;

	mux2to1_6bit M6_2_0(.out({c_out_2_s, sum_d[8:4]}),
	                    .i0({c_out_2_0_full, sum0_2_full}),
	                    .i1({c_out_2_1_full, sum1_2_full}), .s(c_out_1));

	//Stage_3 : 4-bit FA w/ 7-bit MUX + 2bit pipe  (bits [14:9], 6비트)
	wire [4-1:0] sum0_3_pipe, sum1_3_pipe, sum0_3, sum1_3;
	wire c_out_3_0_pipe, c_out_3_1_pipe;
	wire c_out_3_0, c_out_3_1, c_out_3_s;
	wire [2-1:0] a_q_pipe_3, b_q_pipe_3;  // bits[14:13] 파이프

	FA_4bit FA4_3_0(.sum(sum0_3_pipe), .c_out(c_out_3_0_pipe),
	                .a(a_q[12:9]), .b(b_q[12:9]), .c_in(1'b0));
	FA_4bit FA4_3_1(.sum(sum1_3_pipe), .c_out(c_out_3_1_pipe),
	                .a(a_q[12:9]), .b(b_q[12:9]), .c_in(1'b1));

	DFF_4bit DFF_3_0(.q(sum0_3),    .d(sum0_3_pipe),    .clk(clk), .rstn(rstn));
	DFF_4bit DFF_3_1(.q(sum1_3),    .d(sum1_3_pipe),    .clk(clk), .rstn(rstn));
	DFF_1bit DFF_3_2(.q(c_out_3_0), .d(c_out_3_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_3_3(.q(c_out_3_1), .d(c_out_3_1_pipe), .clk(clk), .rstn(rstn));
	DFF_2bit DFF_3_4(.q(a_q_pipe_3), .d(a_q[14:13]),    .clk(clk), .rstn(rstn));
	DFF_2bit DFF_3_5(.q(b_q_pipe_3), .d(b_q[14:13]),    .clk(clk), .rstn(rstn));

	wire [6-1:0] sum0_3_full, sum1_3_full;
	wire c_out_3_0_full, c_out_3_1_full;

	FA_2bit FA2_3_0(.sum(sum0_3_full[5:4]), .c_out(c_out_3_0_full),
	                .a(a_q_pipe_3), .b(b_q_pipe_3), .c_in(c_out_3_0));
	FA_2bit FA2_3_1(.sum(sum1_3_full[5:4]), .c_out(c_out_3_1_full),
	                .a(a_q_pipe_3), .b(b_q_pipe_3), .c_in(c_out_3_1));
	assign sum0_3_full[3:0] = sum0_3;
	assign sum1_3_full[3:0] = sum1_3;

	mux2to1_7bit M7_3_0(.out({c_out_3_s, sum_d[14:9]}),
	                    .i0({c_out_3_0_full, sum0_3_full}),
	                    .i1({c_out_3_1_full, sum1_3_full}), .s(c_out_2_s));

	//Stage_4 : 4-bit FA w/ 8-bit MUX + 3bit pipe  (bits [21:15], 7비트)
	wire [4-1:0] sum0_4_pipe, sum1_4_pipe, sum0_4, sum1_4;
	wire c_out_4_0_pipe, c_out_4_1_pipe;
	wire c_out_4_0, c_out_4_1;
	wire [3-1:0] a_q_pipe_4, b_q_pipe_4;  // bits[21:19] 파이프

	FA_4bit FA4_4_0(.sum(sum0_4_pipe), .c_out(c_out_4_0_pipe),
	                .a(a_q[18:15]), .b(b_q[18:15]), .c_in(1'b0));
	FA_4bit FA4_4_1(.sum(sum1_4_pipe), .c_out(c_out_4_1_pipe),
	                .a(a_q[18:15]), .b(b_q[18:15]), .c_in(1'b1));

	DFF_4bit DFF_4_0(.q(sum0_4),    .d(sum0_4_pipe),    .clk(clk), .rstn(rstn));
	DFF_4bit DFF_4_1(.q(sum1_4),    .d(sum1_4_pipe),    .clk(clk), .rstn(rstn));
	DFF_1bit DFF_4_2(.q(c_out_4_0), .d(c_out_4_0_pipe), .clk(clk), .rstn(rstn));
	DFF_1bit DFF_4_3(.q(c_out_4_1), .d(c_out_4_1_pipe), .clk(clk), .rstn(rstn));
	DFF_3bit DFF_4_4(.q(a_q_pipe_4), .d(a_q[21:19]),    .clk(clk), .rstn(rstn));
	DFF_3bit DFF_4_5(.q(b_q_pipe_4), .d(b_q[21:19]),    .clk(clk), .rstn(rstn));

	wire [7-1:0] sum0_4_full, sum1_4_full;
	wire c_out_4_0_full, c_out_4_1_full;

	FA_3bit FA3_4_0(.sum(sum0_4_full[6:4]), .c_out(c_out_4_0_full),
	                .a(a_q_pipe_4), .b(b_q_pipe_4), .c_in(c_out_4_0));
	FA_3bit FA3_4_1(.sum(sum1_4_full[6:4]), .c_out(c_out_4_1_full),
	                .a(a_q_pipe_4), .b(b_q_pipe_4), .c_in(c_out_4_1));
	assign sum0_4_full[3:0] = sum0_4;
	assign sum1_4_full[3:0] = sum1_4;

	// 마지막 스테이지: c_out_4_X_full 이 sum_d[22]
	mux2to1_8bit M8_4_0(.out(sum_d[22:15]),
	                    .i0({c_out_4_0_full, sum0_4_full}),
	                    .i1({c_out_4_1_full, sum1_4_full}), .s(c_out_3_s));

	//DFF_output
	DFF_23bit DFF_out(.q(sum), .d(sum_d), .clk(clk), .rstn(rstn));
	
endmodule

module DFF_22bit (
	output reg [22-1:0] q,
	input [22-1:0] d,
	input clk, rstn
);
	always @(posedge clk)
	begin
		if (!rstn) q <= 0;
		else       q <= d;
	end
endmodule

module DFF_23bit (
	output reg [23-1:0] q,
	input [23-1:0] d,
	input clk, rstn
);
	always @(posedge clk)
	begin
		if (!rstn) q <= 0;
		else       q <= d;
	end
endmodule
