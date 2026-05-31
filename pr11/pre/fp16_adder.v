module FP16_adder_sync (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] c,
    input clk, rst_n
);
    wire [15:0] a_q, b_q, c_q;

    DFF_16bit DFF_a_in (.q(a_q), .d(a), .clk(clk), .rst_n(rst_n));
    DFF_16bit DFF_b_in (.q(b_q), .d(b), .clk(clk), .rst_n(rst_n));

    int_fp_add fp16_add_sync (.a(a_q), .b(b_q), .c(c_q), .clk(clk), .rst_n(rst_n));

    DFF_16bit DFF_c_in (.q(c), .d(c_q), .clk(clk), .rst_n(rst_n));

endmodule

module int_fp_add (
    input         clk,
    input         rst_n,
    input         mode,
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] c
    );

    wire [10:0] adder_input_1,adder_input_2,aligned_small,adder_output;
    wire if_sub,a_sign, b_sign, c_sign,c1;
    wire [15:0] normalized_out;

    // only used in INT8 MAC mode
    wire [4:0] higher_add,higher_a,higher_b;

    wire [15:0] result;
    reg [14:0] bigger, smaller;
    reg a_larger_b;

    reg [14:0] bigger_reg, smaller_reg;
    reg [10:0] adder_output_reg;
    wire [14:0] bigger_tmp, smaller_tmp;
    wire [10:0] adder_output_tmp;

    assign a_sign        = a[15];
    assign b_sign        = b[15];
    assign if_sub        = (a_sign == b_sign) ? 1'b0 : 1'b1;
    assign c_sign        = a_larger_b ? a_sign : b_sign;
    assign higher_a      = (mode == 1'b0) ? a[15:11] : 5'b0;
    assign higher_b      = (mode == 1'b0) ? b[15:11] : 5'b0;
    assign adder_input_1 = (mode==1'b0) ? a[10:0] :{1'b1,bigger[9:0]};
    assign adder_input_2 = (mode==1'b0) ? b[10:0] : (if_sub ? ~aligned_small + 1'b1 : aligned_small);
    assign c             = (mode == 1'b0) ? {higher_add,adder_output} : result;

    //compare two number regardless sign
    always @(*) begin
        if (a[14:0] > b[14:0]) begin
            bigger = a[14:0];
            smaller = b[14:0];
            a_larger_b = 1'b1;
        end else begin 
            bigger = b[14:0];
            smaller = a[14:0];
            a_larger_b = 1'b0;
        end 
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bigger_reg <= 15'b0;
            smaller_reg <= 15'b0;
            adder_output_reg <= 11'b0;
        end else begin
            bigger_reg <= bigger;
            smaller_reg <= smaller;
            adder_output_reg <= adder_output;
        end
    end
    assign bigger_tmp = bigger_reg[14:0];
    assign smaller_tmp = smaller_reg[14:0];
    assign adder_output_tmp = adder_output_reg[10:0];


    // align small number
    alignment u1(bigger_tmp,smaller_tmp,aligned_small);

    cla_nbit #(.n(11)) u2(adder_input_1,adder_input_2,1'b0,adder_output,c1);

    // This 5 bit adder only used in INT8 MAC mode
    cla_5bit u3(higher_a,higher_b,c1,higher_add,c2);

    add_normalizer u4(c_sign,bigger[14:10],adder_output_tmp,result,c1,if_sub);


endmodule

module alignment (
	input  [14:0] bigger, 
	input  [14:0] smaller,
	output [10:0] aligned_small
	);

	wire c1;
	wire [4:0] bigger_exponent, smaller_exponent,shift_bits;

	assign bigger_exponent  = bigger  [14:10];
	assign smaller_exponent = smaller [14:10];
	assign aligned_small    = ({1'b1,smaller[9:0]} >> shift_bits);

	cla_5bit u1(bigger_exponent,~smaller_exponent+1'b1,1'b0,shift_bits,c1);

endmodule

module add_normalizer (
    input             sign,
    input      [ 4:0] exponent,
    input      [10:0] mantissa_add,
    output reg [15:0] result,
    input             if_carray,
    input             if_sub
    );

    reg [4:0] number_of_zero_lead;
    reg [10:0] norm_mantissa_add;
    reg [9:0] mantissa_tmp;

    wire [4:0] shift_left_exp;
    wire c1;

    always @ (*) begin
        if (mantissa_add[10:4] == 7'b0000_001) begin
            number_of_zero_lead = 5'd6;
            norm_mantissa_add   = (mantissa_add << 4'd6);
        end else if (mantissa_add[10:5] == 6'b0000_01) begin 
            number_of_zero_lead = 5'd5;
            norm_mantissa_add   = (mantissa_add << 4'd5);
        end else if (mantissa_add[10:6] == 5'b0000_1) begin
            number_of_zero_lead = 5'd4;
            norm_mantissa_add   = (mantissa_add << 4'd4);
        end else if (mantissa_add[10:7] == 4'b0001) begin
            number_of_zero_lead = 5'd3;
            norm_mantissa_add   = (mantissa_add << 4'd3);
        end else if (mantissa_add[10:8] == 3'b001) begin
            number_of_zero_lead = 5'd2;
            norm_mantissa_add   = (mantissa_add << 4'd2);
        end else if (mantissa_add[10:9] == 2'b01) begin
            number_of_zero_lead = 5'd1;
            norm_mantissa_add   = (mantissa_add << 4'd1);
        end else begin 
            number_of_zero_lead = 5'd0;
            norm_mantissa_add   = mantissa_add[10:0];
        end 
    end

    always @(*) begin
        result[15]        = sign;
        if (!if_sub) begin 
            result[14:10] = if_carray ? exponent + 1'b1 : exponent;
            result[9:0]   = if_carray ? mantissa_add[10:1] : mantissa_add[9:0];
        end else begin 
            result[14:10] = shift_left_exp;
            result[9:0]   = norm_mantissa_add[9:0];
        end 
    end

    cla_5bit u1(exponent,~number_of_zero_lead+1'b1,1'b0,shift_left_exp,c1);

endmodule

module cla_11bit (
  input   [11-1:0] a,
  input   [11-1:0] b,
  input           ci,
  output  [11-1:0] s,
  output          co
  );

  wire [11-1:0] g;
  wire [11-1:0] p;
  wire [  11:0] c;

  assign c[0] = ci;
  assign co   = c[11];

  genvar i;

  generate
    for (i = 0; i < 11; i = i + 1) begin : addbit
      assign s[i] = a[i] ^ b[i] ^ c[i];
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] | b[i];
      assign c[i + 1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

endmodule

module cla_5bit (
  input   [5-1:0] a,
  input   [5-1:0] b,
  input           ci,
  output  [5-1:0] s,
  output          co
  );

  wire [5-1:0] g;
  wire [5-1:0] p;
  wire [  5:0] c;

  assign c[0] = ci;
  assign co   = c[5];

  genvar i;

  generate
    for (i = 0; i < 5; i = i + 1) begin : addbit
      assign s[i] = a[i] ^ b[i] ^ c[i];
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] | b[i];
      assign c[i + 1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

endmodule

module cla_nbit #(
    parameter n = 4
) (
  input   [n-1:0] a,
  input   [n-1:0] b,
  input           ci,
  output  [n-1:0] s,
  output          co
  );

  wire [n-1:0] g;
  wire [n-1:0] p;
  wire [  n:0] c;

  assign c[0] = ci;
  assign co   = c[n];

  genvar i;

  generate
    for (i = 0; i < n; i = i + 1) begin : addbit
      assign s[i] = a[i] ^ b[i] ^ c[i];
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] | b[i];
      assign c[i + 1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

endmodule

module DFF_16bit(
    output reg [16-1:0] q,
    input [16-1:0] d,
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
