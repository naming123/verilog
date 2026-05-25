module fp16_mul_synthesis (
    input             clk,
    input             rst_n,
    input      [15:0] a_q,
    input      [15:0] b_q,
    output reg [15:0] c_d,
    output reg        error_d
);

    // 합성 경계 격리를 위한 내부 레지스터 및 와이어
    reg  [15:0] a_reg, b_reg;
    wire [15:0] c_out;
    wire        error_out;

    // 1. 입력단 레지스터링 (Input Boundary DFF)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'b0;
            b_reg <= 16'b0;
        end else begin
            a_reg <= a_q;
            b_reg <= b_q;
        end
    end

    // 2. 실제 연산 모듈 인스턴스화
    // (합성 시 `PIPELINE` 매크로를 정의하여 타이밍 성능을 제어할 수 있습니다)
    fp16_mul U_FP16_MUL (
    `ifdef PIPLINE
        .clk(clk),
        .rst_n(rst_n),
    `endif
        .a(a_reg),
        .b(b_reg),
        .c(c_out),
        .error(error_out)
    );

    // 3. 출력단 레지스터링 (Output Boundary DFF)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_d     <= 16'b0;
            error_d <= 1'b0;
        end else begin
            c_d     <= c_out;
            error_d <= error_out;
        end
    end

endmodule

module fp16_mul (
`ifdef PIPLINE
    input         clk,
    input         rst_n,
`endif
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

    
`ifdef PIPLINE

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

`else 

    assign mantissa_prod = multiplier_output[21:0];
    mul16x16 u1(multiplier_input1,multiplier_input2,multiplier_output);

`endif
    
    cla_nbit #(.n(5)) u2(a[14:10],b[14:10],1'b0,sum_exponent,c1); // add exponent
    cla_nbit #(.n(5)) u3(sum_exponent, 5'b10001,1'b0,biased_sum_exponent,c2); // minus bias
    mul_normalizer u4(biased_sum_exponent,mantissa_prod,normalized_out);

endmodule

module mul16x16(
`ifdef PIPLINE
    input clk,
    input rst_n,
`endif
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] c);

    wire [63:0] tmp1,tmp2;
    wire [23:0] result1;
    wire [23:0] result2;
    wire co1,co2,co3;

`ifdef PIPLINE
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

`else 
	assign tmp2 = tmp1;

`endif

    mul8x8 u1(a[15:8],b[15:8],tmp1[63:48]);
    mul8x8 u2(a[7:0] ,b[15:8],tmp1[47:32]);
    mul8x8 u3(a[15:8],b[ 7:0],tmp1[31:16]);
    mul8x8 u4(a[7:0] ,b[ 7:0],tmp1[15:0]);

    cla_nbit #(.n(24)) u5({tmp2[63:48],8'b0} ,{8'b0,tmp2[47:32]} ,1'b0 ,result1 ,co1);
    cla_nbit #(.n(24)) u6({8'b0,tmp2[31:16]} ,{16'b0,tmp2[15:8]} ,co1  ,result2 ,co2);
    cla_nbit #(.n(24)) u7(result1            ,result2            ,co2  ,c[31:8] ,co3);

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

	cla_nbit #(.n(12)) u5({tmp1[31:24],4'b0} ,{4'b0,tmp1[23:16]} ,1'b0 ,result1 ,co1);
	cla_nbit #(.n(12)) u6({4'b0,tmp1[15:8]}  ,{8'b0,tmp1[7:4]}   ,co1  ,result2 ,co2);
	cla_nbit #(.n(12)) u7(result1			 ,result2			 ,co2  ,c[15:4] ,co3);

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

	cla_nbit #(.n(6)) u5({tmp1[15:12],2'b0},{2'b0,tmp1[11:8]},1'b0	,result1	,co1);
	cla_nbit #(.n(6)) u6({2'b0,tmp1[7:4]}  ,{4'b0,tmp1[3:2]} ,co1 	,result2	,co2);
	cla_nbit #(.n(6)) u7(result1		   ,result2			 ,co2 	,c[7:2] 	,co3);

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