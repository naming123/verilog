module carry_select_adder_20b_2stage (
	output [21-1:0] sum,
	input [20-1:0] a, b,
	input c_in, clk, rstn
);

	wire [20-1:0] a_q, b_q;
    wire [5-1:0] c0, c1;
    wire [4-1:0] c;
    wire [16-1:0] sum_d0, sum_d1;
    wire [21-1:0] sum_d;
	wire [8-1:0] sum_d_pipe;
	wire [12-1:0] sum_d0_pipe, sum_d1_pipe;
	wire [3-1:0] c0_pipe, c1_pipe;
	wire c_in_q, c_pipe;

    DFF_20bit DFF0(.q(a_q), .d(a), .clk(clk), .rstn(rstn));
    DFF_20bit DFF1(.q(b_q), .d(b), .clk(clk), .rstn(rstn));
	DFF_1bit DFF2(.q(c_in_q), .d(c_in), .clk(clk), .rstn(rstn));

    //Stage_0_4bit
    full_adder_4b STAGE_0_FA0(.sum(sum_d_pipe[3:0]), .c_out(c[0]), .a(a_q[3:0]), .b(b_q[3:0]), .c_in(c_in_q));

	DFF_4bit STAGE_0_DFF0(.q(sum_d[3:0]), .d(sum_d_pipe[3:0]), .clk(clk), .rstn(rstn));

    //Stage_1_4bit
    full_adder_4b STAGE_1_FA0(.sum(sum_d0[3:0]), .c_out(c0[0]), .a(a_q[7:4]), .b(b_q[7:4]), .c_in(1'b0));
    full_adder_4b STAGE_1_FA1(.sum(sum_d1[3:0]), .c_out(c1[0]), .a(a_q[7:4]), .b(b_q[7:4]), .c_in(1'b1));

    mux_2to1_4b STAGE_1_M0(.out(sum_d_pipe[7:4]), .i0(sum_d0[3:0]), .i1(sum_d1[3:0]), .sel(c[0]));
    mux_2to1_1b STAGE_1_M1(.out(c_pipe), .i0(c0[0]), .i1(c1[0]), .sel(c[0]));

	DFF_4bit STAGE_1_DFF0(.q(sum_d[7:4]), .d(sum_d_pipe[7:4]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_1_DFF1(.q(c[1]), .d(c_pipe), .clk(clk), .rstn(rstn));

    //Stage_2_4bit
    full_adder_4b STAGE_2_FA0(.sum(sum_d0[7:4]), .c_out(c0[1]), .a(a_q[11:8]), .b(b_q[11:8]), .c_in(1'b0));
    full_adder_4b STAGE_2_FA1(.sum(sum_d1[7:4]), .c_out(c1[1]), .a(a_q[11:8]), .b(b_q[11:8]), .c_in(1'b1));

	DFF_4bit STAGE_2_DFF0(.q(sum_d0_pipe[3:0]), .d(sum_d0[7:4]), .clk(clk), .rstn(rstn));
	DFF_4bit STAGE_2_DFF1(.q(sum_d1_pipe[3:0]), .d(sum_d1[7:4]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_2_DFF2(.q(c0_pipe[0]), .d(c0[1]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_2_DFF3(.q(c1_pipe[0]), .d(c1[1]), .clk(clk), .rstn(rstn));

    mux_2to1_4b STAGE_2_M0(.out(sum_d[11:8]), .i0(sum_d0_pipe[3:0]), .i1(sum_d1_pipe[3:0]), .sel(c[1]));
    mux_2to1_1b STAGE_2_M1(.out(c[2]), .i0(c0_pipe[0]), .i1(c1_pipe[0]), .sel(c[1]));

    //Stage_3_4bit
    full_adder_4b STAGE_3_FA0(.sum(sum_d0[11:8]), .c_out(c0[2]), .a(a_q[15:12]), .b(b_q[15:12]), .c_in(1'b0));
    full_adder_4b STAGE_3_FA1(.sum(sum_d1[11:8]), .c_out(c1[2]), .a(a_q[15:12]), .b(b_q[15:12]), .c_in(1'b1));

	DFF_4bit STAGE_3_DFF0(.q(sum_d0_pipe[7:4]), .d(sum_d0[11:8]), .clk(clk), .rstn(rstn));
	DFF_4bit STAGE_3_DFF1(.q(sum_d1_pipe[7:4]), .d(sum_d1[11:8]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_3_DFF2(.q(c0_pipe[1]), .d(c0[2]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_3_DFF3(.q(c1_pipe[1]), .d(c1[2]), .clk(clk), .rstn(rstn));

    mux_2to1_4b STAGE_3_M0(.out(sum_d[15:12]), .i0(sum_d0_pipe[7:4]), .i1(sum_d1_pipe[7:4]), .sel(c[2]));
    mux_2to1_1b STAGE_3_M1(.out(c[3]), .i0(c0_pipe[1]), .i1(c1_pipe[1]), .sel(c[2]));

    //Stage_4_4bit (마지막: a[19:16], b[19:16])
    full_adder_4b STAGE_4_FA0(.sum(sum_d0[15:12]), .c_out(c0[3]), .a(a_q[19:16]), .b(b_q[19:16]), .c_in(1'b0));
    full_adder_4b STAGE_4_FA1(.sum(sum_d1[15:12]), .c_out(c1[3]), .a(a_q[19:16]), .b(b_q[19:16]), .c_in(1'b1));

	DFF_4bit STAGE_4_DFF0(.q(sum_d0_pipe[11:8]), .d(sum_d0[15:12]), .clk(clk), .rstn(rstn));
	DFF_4bit STAGE_4_DFF1(.q(sum_d1_pipe[11:8]), .d(sum_d1[15:12]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_4_DFF2(.q(c0_pipe[2]), .d(c0[3]), .clk(clk), .rstn(rstn));
	DFF_1bit STAGE_4_DFF3(.q(c1_pipe[2]), .d(c1[3]), .clk(clk), .rstn(rstn));

    mux_2to1_4b STAGE_4_M0(.out(sum_d[19:16]), .i0(sum_d0_pipe[11:8]), .i1(sum_d1_pipe[11:8]), .sel(c[3]));
    mux_2to1_1b STAGE_4_M1(.out(sum_d[20]), .i0(c0_pipe[2]), .i1(c1_pipe[2]), .sel(c[3]));

    DFF_21bit DFF3(.q(sum), .d(sum_d), .clk(clk), .rstn(rstn));
	
endmodule

// ─── 신규 DFF 모듈 ────────────────────────────────────

module DFF_20bit (
    output reg [20-1:0] q,
    input      [20-1:0] d,
    input               clk, rstn
);
    always@(posedge clk) begin
        if(!rstn) q <= 20'b0;
        else      q <= d;
    end
endmodule

module DFF_21bit (
    output reg [21-1:0] q,
    input      [21-1:0] d,
    input               clk, rstn
);
    always@(posedge clk) begin
        if(!rstn) q <= 21'b0;
        else      q <= d;
    end
endmodule

// ─── 기존 모듈 그대로 유지 ────────────────────────────

module full_adder (
    output sum, c_out,
    input  a, b, c_in
);
wire s1, c1, s2;
xor(s1, a, b);
and(c1, a, b);
xor(  sum, s1, c_in);
and(   s2, s1, c_in);
xor(c_out, s2,   c1);
endmodule

module full_adder_4b (
    output [4-1:0] sum,
    output c_out,
    input  [4-1:0] a, b,
    input  c_in
);
wire [3-1:0] c;
full_adder f00(.sum(sum[0]), .c_out(c[0]),  .a(a[0]), .b(b[0]), .c_in(c_in));
full_adder f01(.sum(sum[1]), .c_out(c[1]),  .a(a[1]), .b(b[1]), .c_in(c[0]));
full_adder f02(.sum(sum[2]), .c_out(c[2]),  .a(a[2]), .b(b[2]), .c_in(c[1]));
full_adder f03(.sum(sum[3]), .c_out(c_out), .a(a[3]), .b(b[3]), .c_in(c[2]));
endmodule

module mux_2to1_1b (
    output reg out,
    input      i0, i1,
    input      sel
);
always@(*) begin
    if(sel==0) out <= i0;
    else       out <= i1;
end
endmodule

module mux_2to1_4b (
    output reg [4-1:0] out,
    input      [4-1:0] i0, i1,
    input              sel
);
always@(*) begin
    if(sel==0) out <= i0;
    else       out <= i1;
end
endmodule

module DFF_1bit (
    output reg q,
    input      d,
    input      clk, rstn
);
    always@(posedge clk) begin
        if(!rstn) q <= 1'b0;
        else      q <= d;
    end
endmodule

module DFF_4bit (
    output reg [4-1:0] q,
    input      [4-1:0] d,
    input              clk, rstn
);
    always@(posedge clk) begin
        if(!rstn) q <= 4'b0;
        else      q <= d;
    end
endmodule