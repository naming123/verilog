`timescale 1ns/10ps
module sti_FIR_filter;

	reg clk, reset;

	reg [23:0] sig_mat [0:255];
	reg [23:0] out_mat;

	reg [23:0] TRANS_out;
	reg [23:0] DIRECT_out;
 
	wire    [13:0] c0 = 14'h983;
	wire    [13:0] c1 = 14'h32b4;
	wire    [13:0] c2 = 14'h107d;
	wire    [13:0] c3 = 14'h327f;
	wire    [13:0] c4 = 14'h19c7;
	
	top_FIR_filter FIR(clk, reset, c0, c1, c2, c3, c4);
	
	integer err_direct = 0;
	integer err_trans = 0;

	initial
	begin
		clk = 1;
		reset = 0;
		#10
		reset = 1;
	end
	
	always #5 clk = ~clk;
	
	initial $readmemh("input_vector_hex.txt", FIR.DIRECT_INPUT_MEM.array); //check the path of memory rocation (module instance)
	initial $readmemh("input_vector_hex.txt", FIR.TRANS_INPUT_MEM.array);  //check the path of memory rocation (module instance)

	integer i=0;	
	initial
	begin		
		$readmemh("output_vector_hex.txt", sig_mat);
		begin
			#(110);
			for (i=0; i<252; i=i+1)
			begin
				out_mat <= sig_mat[i];
				DIRECT_out <= FIR.DIRECT_OUTPUT_MEM.array[i];
				TRANS_out <= FIR.TRANS_OUTPUT_MEM.array[i];
				if(DIRECT_out != out_mat) err_direct = err_direct + 1;
                if(TRANS_out != out_mat) err_trans = err_trans + 1;
				#(10);
			end
			$stop;
		end
	end

endmodule