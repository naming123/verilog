`timescale 1ns/10ps
module sti_FIR_filter;

	reg clk, reset;

	reg [25:0] sig_mat [0:255];
	reg [25:0] out_mat;

	reg [25:0] TRAN_out;
	reg [25:0] DIRE_out;
 
	wire    [13:0] c0 = 14'h3aa4;
	wire    [13:0] c1 = 14'h1433;
	wire    [13:0] c2 = 14'he37;
	wire    [13:0] c3 = 14'h1a57;
	wire    [13:0] c4 = 14'h917;
	wire    [13:0] c5 = 14'h2c1d;
	
	top_FIR_filter FIR(clk, reset, c0, c1, c2, c3, c4, c5 );
	
	integer err=0;

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
			for (i=0; i<256; i=i+1)
			begin
				out_mat <= sig_mat[i];
				DIRE_out <= FIR.DIRECT_OUTPUT_MEM.array[i];
				TRAN_out <= FIR.TRANS_OUTPUT_MEM.array[i];
				if((TRAN_out != out_mat) || (DIRE_out != out_mat)) err = err + 1;
				#(10);
			end
			$stop;
		end
	end

endmodule
	
	

