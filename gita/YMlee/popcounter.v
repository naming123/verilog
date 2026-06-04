
module popcounter (
    input wire [7:0] src,
    input clk,
    input rst_n,

    output wire [1:0] best_idx,
    output wire [3:0] best_cnt
);

    reg [7:0] src_q;
    reg [3:0] cnt_q;

    DFF_8bit dff0 (
        .q(src_q),
        .d(src),
        .clk(clk),
        .rst_n(rst_n)
    );

    best_candidate_4 u_popcounter (
        .mask0(src),
        .mask1(src),
        .mask2(src),
        .mask3(src),
        .clk(clk),
        .rst_n(rst_n),

        .best_idx(best_idx),
        .best_cnt(best_cnt)
    );

    DFF_4bit dff1 (
        .q(cnt_q),
        .d(best_cnt),
        .clk(clk),
        .rst_n(rst_n)
    );
endmodule


module best_candidate_4 (
    input wire [7:0] mask0,
    input wire [7:0] mask1,
    input wire [7:0] mask2,
    input wire [7:0] mask3,
    input clk,
    input rst_n,

    output wire [1:0] best_idx,
    output wire [3:0] best_cnt
);

wire [3:0] cnt0;
wire [3:0] cnt1;
wire [3:0] cnt2;
wire [3:0] cnt3;

popcount8 u0 (
    .in(mask0),
    .count(cnt0)
);

popcount8 u1 (
    .in(mask1),
    .count(cnt1)
);

popcount8 u2 (
    .in(mask2),
    .count(cnt2)
);

popcount8 u3 (
    .in(mask3),
    .count(cnt3)
);

wire [3:0] stage1_cnt0;
wire [1:0] stage1_idx0;

wire [3:0] stage1_cnt1;
wire [1:0] stage1_idx1;

max2 cmp0 (
    .a_cnt(cnt0),
    .a_idx(2'd0),

    .b_cnt(cnt1),
    .b_idx(2'd1),

    .max_cnt(stage1_cnt0),
    .max_idx(stage1_idx0)
);

max2 cmp1 (
    .a_cnt(cnt2),
    .a_idx(2'd2),

    .b_cnt(cnt3),
    .b_idx(2'd3),

    .max_cnt(stage1_cnt1),
    .max_idx(stage1_idx1)
);

max2 cmp2 (
    .a_cnt(stage1_cnt0),
    .a_idx(stage1_idx0),

    .b_cnt(stage1_cnt1),
    .b_idx(stage1_idx1),

    .max_cnt(best_cnt),
    .max_idx(best_idx)
);

endmodule

module max2 (
    input  wire [3:0] a_cnt,
    input  wire [1:0] a_idx,

    input  wire [3:0] b_cnt,
    input  wire [1:0] b_idx,

    output wire [3:0] max_cnt,
    output wire [1:0] max_idx
);

assign max_cnt = (a_cnt >= b_cnt) ? a_cnt : b_cnt;
assign max_idx = (a_cnt >= b_cnt) ? a_idx : b_idx;

endmodule

module popcount8 (
    input  wire [7:0] in,
    output wire [3:0] count
);

assign count =
      in[0]
    + in[1]
    + in[2]
    + in[3]
    + in[4]
    + in[5]
    + in[6]
    + in[7];

endmodule

module DFF_8bit(
    output reg [7:0] q,
    input [7:0] d,
    input clk, rst_n
);
    always @(posedge clk)
    begin
        if (!rst_n)
            q <= 0;
        else
            q <= d;
    end
endmodule

module DFF_4bit(
    output reg [3:0] q,
    input [3:0] d,
    input clk, rst_n
);
    always @(posedge clk)
    begin
        if (!rst_n)
            q <= 0;
        else
            q <= d;
    end
endmodule
