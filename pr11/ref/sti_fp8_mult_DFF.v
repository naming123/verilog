`timescale 1ns / 1ps
module sti_fp8_mult_DFF;

wire [7:0] result;
reg [7:0]  a, b;
reg        clk, rstn;

reg [7:0] mat_result [0:99];
reg [7:0] mat_result_cmp;
reg [7:0] mat_a [0:99];
reg [7:0] mat_b [0:99];

fp8_mult_DFF mult0(.result(result), .a(a), .b(b), .clk(clk), .rstn(rstn));

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

	$readmemh("a_input_mult.txt",    mat_a);
    $readmemh("b_input_mult.txt",    mat_b);
    $readmemh("mult_output.txt", mat_result);

	i = 0;
	err = 0;
	#(10);

	for(i=0 ; i<101 ; i=i+1)
    begin
        a = mat_a[i];
        b = mat_b[i];
        mat_result_cmp = mat_result[i-1];
        #(2)
        if(result != mat_result_cmp) err = err + 1;
        #(8);
    end
    #(20)
    $stop;
end

endmodule