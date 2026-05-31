module FP16_sync (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] c,
    input clk, rst_n
);
    wire [15:0] a_q, b_q, c_q;

    DFF_16bit DFF_a_in (.q(a_q), .d(a), .clk(clk), .rst_n(rst_n));
    DFF_16bit DFF_b_in (.q(b_q), .d(b), .clk(clk), .rst_n(rst_n));

    fp16_mul fp16_sync (.a(a_q), .b(b_q), .c(c_q), .clk(clk), .rst_n(rst_n), .error(1'b0));

    DFF_16bit DFF_c_in (.q(c), .d(c_q), .clk(clk), .rst_n(rst_n));

endmodule

module fp16_mul (
    input         clk,
    input         rst_n,
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] c,
    output        error // valid in fp16 mode
    );

    wire [15:0] c_tmp;
    wire        c_sign,a_zero,b_zero;
    wire [4:0] sum_exponent, biased_sum_exponent;
    wire [15:0] multiplier_input1,multiplier_input2;

    wire [31:0] multiplier_output;
    wire [14:0] normalized_out;
    wire [21:0] mantissa_prod;
    wire c1,c2,underflow,overflow;

    assign overflow = (c1 && c2 && ~biased_sum_exponent[4]) ? 1'b1 :1'b0;
    assign underflow = (~c1 && ~c2 && biased_sum_exponent[4]) ? 1'b1:1'b0;

    assign a_zero = ~(|a);
    assign b_zero = ~(|b);
    assign c_sign = a[15] ^ b[15];

    assign multiplier_input1 =  (a[7]==1'b0) ? {9'b0, a[6:0]} : {9'b0, ~a[6:0]+1'b1};
    assign multiplier_input2 =  (b[7]==1'b0) ? {9'b0, b[6:0]} : {9'b0, ~b[6:0]+1'b1};
    assign c = (a[7]^b[7] == 1'b0) ? multiplier_output[15:0] : {1'b1,~multiplier_output[14:0]+1'b1};

    assign c_tmp = (~error) ? {c_sign,normalized_out} : (underflow ? {c_sign,15'b0000_0000_0000_000} : {c_sign,5'b1111_1,10'b0000_0000_00});

    assign error = overflow | underflow;


    reg [31:0] multiplier_output_tmp;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplier_output_tmp <= 32'b0;
        end else begin
            multiplier_output_tmp <= multiplier_output;
        end
    end

    assign mantissa_prod = multiplier_output_tmp[21:0];
    mul16x16 u1(clk,rst_n,multiplier_input1,multiplier_input2,multiplier_output);


    cla_5bit u2(a[14:10],b[14:10],1'b0,sum_exponent,c1); // add exponent
    cla_5bit u3(sum_exponent, 5'b10001,1'b0,biased_sum_exponent,c2); // minus bias
    mul_normalizer u4(biased_sum_exponent,mantissa_prod,normalized_out);

endmodule

module mul16x16(
    input clk,
    input rst_n,
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] c);

    wire [63:0] tmp1,tmp2;
    wire [23:0] result1;
    wire [23:0] result2;
    wire co1,co2,co3;


	// one stage pipline
	reg [63:0] tmp1_reg;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tmp1_reg <= 64'b0;
        end else begin
            tmp1_reg <= tmp1;
        end
    end
    assign tmp2 = tmp1_reg;


    mul8x8 u1(a[15:8],b[15:8],tmp1[63:48]);
    mul8x8 u2(a[7:0] ,b[15:8],tmp1[47:32]);
    mul8x8 u3(a[15:8],b[ 7:0],tmp1[31:16]);
    mul8x8 u4(a[7:0] ,b[ 7:0],tmp1[15:0]);

    cla_24bit u5({tmp2[63:48],8'b0} ,{8'b0,tmp2[47:32]} ,1'b0 ,result1 ,co1);
    cla_24bit u6({8'b0,tmp2[31:16]} ,{16'b0,tmp2[15:8]} ,co1  ,result2 ,co2);
    cla_24bit u7(result1            ,result2            ,co2  ,c[31:8] ,co3);

    assign c[7:0] = tmp2[7:0];

endmodule

module mul8x8(
	input  [ 7:0] a,
	input  [ 7:0] b,
	output [15:0] c
);

	wire [31:0] tmp1;
	wire [11:0] result1;
	wire [11:0] result2;
	wire co1,co2,co3;

	mul4x4 u1(a[7:4],b[7:4],tmp1[31:24]);
	mul4x4 u2(a[3:0],b[7:4],tmp1[23:16]);
	mul4x4 u3(a[7:4],b[3:0],tmp1[15:8]);
	mul4x4 u4(a[3:0],b[3:0],tmp1[7:0]);

    cla_12bit u5({tmp1[31:24],4'b0} ,{4'b0,tmp1[23:16]} ,1'b0 ,result1 ,co1);
	cla_12bit u6({4'b0,tmp1[15:8]}  ,{8'b0,tmp1[7:4]}   ,co1  ,result2 ,co2);
	cla_12bit u7(result1			 ,result2			 ,co2  ,c[15:4] ,co3);

	assign c[3:0] = tmp1[3:0];

endmodule

module mul4x4(
	input  [3:0] a,
	input  [3:0] b,
	output [7:0] c
	);

	wire [15:0] tmp1;
	wire [ 5:0] result1;
	wire [ 5:0] result2;
	wire 		co1,co2,co3;

	mul2x2 u1(a[3:2],b[3:2],tmp1[15:12]);
	mul2x2 u2(a[1:0],b[3:2],tmp1[11:8]);
	mul2x2 u3(a[3:2],b[1:0],tmp1[7:4]);
	mul2x2 u4(a[1:0],b[1:0],tmp1[3:0]);

    cla_6bit u5({tmp1[15:12],2'b0},{2'b0,tmp1[11:8]},1'b0	,result1	,co1);
	cla_6bit u6({2'b0,tmp1[7:4]}  ,{4'b0,tmp1[3:2]} ,co1 	,result2	,co2);
	cla_6bit u7(result1		   ,result2			 ,co2 	,c[7:2] 	,co3);

	assign c[1:0] = tmp1[1:0];

endmodule

module mul2x2(
	input  [1:0] a,
	input  [1:0] b,
	output [3:0] c
	);

	wire [3:0] tmp;
	
	assign tmp[0] = a[0] & b[0];
	assign tmp[1] = (a[1]&b[0]) ^ (a[0]&b[1]);
	assign tmp[2] = (a[0]&b[1]) & (a[1]&b[0]) ^ (a[1]&b[1]);
	assign tmp[3] = (a[0]&b[1]) & (a[1]&b[0]) & (a[1]&b[1]);
	assign c 	  = {tmp[3],tmp[2],tmp[1],tmp[0]};

endmodule

module cla_24bit(
  input   [24-1:0] a,
  input   [24-1:0] b,
  input           ci,
  output  [24-1:0] s,
  output          co
  );

wire [24-1:0] g;
  wire [24-1:0] p;
  wire [  24:0] c;

  assign c[0] = ci;
  assign co   = c[24];

  genvar i;

  generate
    for (i = 0; i < 24; i = i + 1) begin : addbit
      assign s[i] = a[i] ^ b[i] ^ c[i];
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] | b[i];
      assign c[i + 1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

endmodule

module cla_12bit(
  input   [12-1:0] a,
  input   [12-1:0] b,
  input           ci,
  output  [12-1:0] s,
  output          co
  );

wire [12-1:0] g;
  wire [12-1:0] p;
  wire [  12:0] c;

  assign c[0] = ci;
  assign co   = c[12];

  genvar i;

  generate
    for (i = 0; i < 12; i = i + 1) begin : addbit
      assign s[i] = a[i] ^ b[i] ^ c[i];
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] | b[i];
      assign c[i + 1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

endmodule

module cla_6bit(
  input   [6-1:0] a,
  input   [6-1:0] b,
  input           ci,
  output  [6-1:0] s,
  output          co
  );

wire [6-1:0] g;
  wire [6-1:0] p;
  wire [  6:0] c;

  assign c[0] = ci;
  assign co   = c[6];

  genvar i;

  generate
    for (i = 0; i < 6; i = i + 1) begin : addbit
      assign s[i] = a[i] ^ b[i] ^ c[i];
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] | b[i];
      assign c[i + 1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

endmodule

module cla_5bit(
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

module mul_normalizer (
	input  [ 4:0] exponent,
	input  [21:0] mantissa_prod,
	output [14:0] result
);

	wire [4:0] result_exponent;
	wire [9:0] result_mantissa;

	assign result_exponent = (mantissa_prod[21]) ? (exponent + 1'b1): exponent;
	assign result_mantissa = (mantissa_prod[21]) ? mantissa_prod[20:11]:mantissa_prod[19:10];
	assign result 		   = {result_exponent,result_mantissa};

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
