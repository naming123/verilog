module top_FIR_filter_synthesis (
    output reg signed [23:0] y_out_direct_d,
    output reg signed [23:0] y_out_trans_d,
    output reg [7:0] addr_in_d,
    output reg [7:0] addr_out_d,

    input signed [13:0] x_in_direct_q,
    input signed [13:0] x_in_trans_q,

    input clk, reset,
    input signed [13:0] c0, c1, c2, c3, c4
);

    wire signed [13:0] x_in_direct, x_in_trans;
    wire signed [23:0] y_out_direct, y_out_trans;
    wire [7:0] addr_in, addr_out;

    reg signed [13:0] x_in_direct_tmp, x_in_trans_tmp;
    reg [7:0] cnt;

    assign x_in_direct = x_in_direct_tmp;
    assign x_in_trans  = x_in_trans_tmp;

    assign addr_in  = cnt;
    assign addr_out = cnt - 8'd7;

    always @(posedge clk) begin
        if (!reset) begin
            y_out_direct_d  <= 24'd0;
            y_out_trans_d   <= 24'd0;
            addr_in_d       <= 8'd0;
            addr_out_d      <= 8'd0;
            x_in_direct_tmp <= 14'd0;
            x_in_trans_tmp  <= 14'd0;
            cnt             <= 8'd0;
        end
        else begin
            y_out_direct_d  <= y_out_direct;
            y_out_trans_d   <= y_out_trans;
            addr_in_d       <= addr_in;
            addr_out_d      <= addr_out;
            x_in_direct_tmp <= x_in_direct_q;
            x_in_trans_tmp  <= x_in_trans_q;
            cnt             <= cnt + 8'd1;
        end
    end

    direct_FIR_filter DIRECT_FIR_FILTER (
        .direct_out(y_out_direct),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4),
        .in(x_in_direct),
        .clk(clk),
        .reset(reset)
    );

    trans_FIR_filter TRANS_FIR_FILTER (
        .trans_out(y_out_trans),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4),
        .in(x_in_trans),
        .clk(clk),
        .reset(reset)
    );

endmodule


module direct_FIR_filter (
    output reg signed [23:0] direct_out,
    input signed [13:0] c0, c1, c2, c3, c4,
    input signed [13:0] in,
    input clk, reset
);

    reg signed [13:0] x0, x1, x2, x3, x4;

    wire signed [22:0] mul0, mul1, mul2, mul3, mul4;
    wire signed [23:0] sum_out;

    multiplier_roundoff mul_0 (.mul_out_roundoff(mul0), .in(x0), .c(c0));
    multiplier_roundoff mul_1 (.mul_out_roundoff(mul1), .in(x1), .c(c1));
    multiplier_roundoff mul_2 (.mul_out_roundoff(mul2), .in(x2), .c(c2));
    multiplier_roundoff mul_3 (.mul_out_roundoff(mul3), .in(x3), .c(c3));
    multiplier_roundoff mul_4 (.mul_out_roundoff(mul4), .in(x4), .c(c4));

    assign sum_out =
        {{1{mul0[22]}}, mul0} +
        {{1{mul1[22]}}, mul1} +
        {{1{mul2[22]}}, mul2} +
        {{1{mul3[22]}}, mul3} +
        {{1{mul4[22]}}, mul4};

    always @(posedge clk) begin
        if (!reset) begin
            x0 <= 14'd0;
            x1 <= 14'd0;
            x2 <= 14'd0;
            x3 <= 14'd0;
            x4 <= 14'd0;
            direct_out <= 24'd0;
        end
        else begin
            x0 <= in;
            x1 <= x0;
            x2 <= x1;
            x3 <= x2;
            x4 <= x3;
            direct_out <= sum_out;
        end
    end

endmodule


module trans_FIR_filter (
    output reg signed [23:0] trans_out,
    input signed [13:0] c0, c1, c2, c3, c4,
    input signed [13:0] in,
    input clk, reset
);

    reg signed [13:0] x0;
    reg signed [23:0] y1, y2, y3, y4;

    wire signed [22:0] mul0, mul1, mul2, mul3, mul4;

    wire signed [23:0] mul0_ext, mul1_ext, mul2_ext, mul3_ext, mul4_ext;
    wire signed [23:0] sum0, sum1, sum2, sum3;

    multiplier_roundoff mul_0 (.mul_out_roundoff(mul0), .in(x0), .c(c0));
    multiplier_roundoff mul_1 (.mul_out_roundoff(mul1), .in(x0), .c(c1));
    multiplier_roundoff mul_2 (.mul_out_roundoff(mul2), .in(x0), .c(c2));
    multiplier_roundoff mul_3 (.mul_out_roundoff(mul3), .in(x0), .c(c3));
    multiplier_roundoff mul_4 (.mul_out_roundoff(mul4), .in(x0), .c(c4));

    assign mul0_ext = {{1{mul0[22]}}, mul0};
    assign mul1_ext = {{1{mul1[22]}}, mul1};
    assign mul2_ext = {{1{mul2[22]}}, mul2};
    assign mul3_ext = {{1{mul3[22]}}, mul3};
    assign mul4_ext = {{1{mul4[22]}}, mul4};

    assign sum3 = mul3_ext + y4;
    assign sum2 = mul2_ext + y3;
    assign sum1 = mul1_ext + y2;
    assign sum0 = mul0_ext + y1;

    always @(posedge clk) begin
        if (!reset) begin
            x0 <= 14'd0;
            y1 <= 24'd0;
            y2 <= 24'd0;
            y3 <= 24'd0;
            y4 <= 24'd0;
            trans_out <= 24'd0;
        end
        else begin
            x0 <= in;

            y4 <= mul4_ext;
            y3 <= sum3;
            y2 <= sum2;
            y1 <= sum1;

            trans_out <= sum0;
        end
    end

endmodule


module multiplier_roundoff (
    output signed [22:0] mul_out_roundoff,
    input signed [13:0] in,
    input signed [13:0] c
);

    wire signed [27:0] mul_out;

    assign mul_out = in * c;
    assign mul_out_roundoff = mul_out[27:5] + mul_out[4];

endmodule