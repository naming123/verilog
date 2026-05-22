`timescale 1ns/10ps
module sti_FIR_filter;



	wire [12:0] c0 = 13'h4c2;
	wire [12:0] c1 = 13'h195a;
	wire [12:0] c2 = 13'h83f;
	wire [12:0] c3 = 13'h193f;
	wire [12:0] c4 = 13'hce3;

	reg clk100, reset, clk20;

	reg [21:0] sig_mat [0:255];
	reg [21:0] out_mat;
	reg [21:0] out;

	Top_FIR_filter FIR(clk100, clk20, reset, c0, c1, c2, c3, c4);
	
	initial
	begin
		clk100 = 1;
		clk20 = 1; 
		reset = 0;
		#42//change the timing if needed
		reset = 1;
	end
	
	always #5 clk100 = ~clk100;
	always #25 clk20 = ~clk20;
	
	initial $readmemh("input_vector_hex.txt", FIR.FOLDED_INPUT_MEM.array); //check the path of memory rocation (module instance)

	integer i=0;	
	integer err=0;
	initial
	begin		
		$readmemh("output_vector_hex.txt", sig_mat);
		begin
			#(600);//change the timing if needed
			for (i=0; i<252; i=i+1)
			begin
				out_mat <= sig_mat[i];
				out <= FIR.FOLDED_OUTPUT_MEM.array[i];
				if(out != out_mat) err = err + 1;
				#(50);				
			end
			$stop;
		end
	end
endmodule