`timescale 1ns/10ps
module stimulus_Top_memory_control;

	reg clk;
	reg rstn;
	wire [55:0] out;
	reg [56-1:0] mat_output [0:511];
	reg [56-1:0] mat_out; 
	
	initial	begin
		clk <= 1;
		rstn <= 0;
		#10
		rstn <= 1;
		#41010 $stop;
	end
	
	always #5 clk <= ~clk;
	
	top_memory_ctrl TOP_MEM_TEST(out, clk, rstn);

	integer i = 0;
	integer err = 0;
	
	initial $readmemh("input.txt", TOP_MEM_TEST.memory0.array);
	initial $readmemh("output.txt", mat_output);
	
	initial	begin
    #(20540);
		for(i = 0; i < 512; i = i + 1)
		begin
			mat_out <= mat_output[i];
			#(10);
			if(out != mat_out) err = err + 1;
			#(30);
		end
	end
	
	
endmodule