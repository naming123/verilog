`timescale 1ns / 1ps
module sti_fp8_adder_DFF;

wire [7:0] sum;
reg [7:0]  a, b;
reg        clk, rstn;

reg [7:0] mat_sum [0:99];
reg [7:0] mat_sum_cmp;
reg [7:0] mat_a [0:99];
reg [7:0] mat_b [0:99];

fp8_adder_DFF adder0(.sum(sum), .a(a), .b(b), .clk(clk), .rstn(rstn));

integer i;
integer err;

initial
    clk = 1'b1;

always
    #5 clk = ~clk;

initial
begin
        rstn = 1'b0;
    #0  rstn = 1'b1;

	$readmemh("C:/Users/smoh/Desktop/26-1/Verilog/pr11/cur/a_input_adder.txt",    mat_a);
    $readmemh("C:/Users/smoh/Desktop/26-1/Verilog/pr11/cur/b_input_adder.txt",    mat_b);
    $readmemh("C:/Users/smoh/Desktop/26-1/Verilog/pr11/cur/sum_output.txt", mat_sum);

	i = 0;
	err = 0;
	#(10);

	for(i=0 ; i<101 ; i=i+1)
    begin
        a = mat_a[i];
        b = mat_b[i];
        mat_sum_cmp = mat_sum[i-1];
        #(2)
        if(sum != mat_sum_cmp) err = err + 1;
        #(8);
    end
    #(20)
    $stop;
end

endmodule
