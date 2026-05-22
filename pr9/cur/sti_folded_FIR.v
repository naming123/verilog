`timescale 1ns/10ps
module sti_folded_FIR;

    wire [13:0] c0 = 14'h8f6;
	wire [13:0] c1 = 14'h3571;
	wire [13:0] c2 = 14'hb85;
	wire [13:0] c3 = 14'h2fef;
	wire [13:0] c4 = 14'h108c;
	wire [13:0] c5 = 14'h2e89;
	wire [13:0] c6 = 14'h10cc;
	wire [13:0] c7 = 14'h2d9a;

	reg clk160, reset, clk20;

	reg [23:0] sig_mat [0:255];
	reg [23:0] out_mat;

    reg [23:0] FIR_out;
	
	FIR_memory_folded FIR(clk160, clk20, reset, c0, c1, c2, c3, c4, c5, c6, c7);
	
	initial
	begin
		clk160 = 1;
		clk20 = 1;
		reset = 0;
		#42//change the timing if needed
		reset = 1;
	end
	
	always #5 clk160 = ~clk160;
	always #40 clk20 = ~clk20;
	
	initial $readmemh("C:/Users/oaz/Desktop/osm/verilog/pr9/cur/input_vector_hex.txt", FIR.INPUT_MEM.array); //check the path of memory location (module instance)

	integer i=0;	
	integer err=0;
	initial
	begin		
		$readmemh("C:/Users/oaz/Desktop/osm/verilog/pr9/cur/output_vector_hex.txt", sig_mat);
		wait(reset == 1'b1)
		begin
			#(1040);//change the timing if needed
			for (i=0; i<249; i=i+1)
			begin
				out_mat = sig_mat[i];
                FIR_out <= FIR.OUTPUT_MEM.array[i];
				#(80);
				if(FIR_out != out_mat) err = err + 1;
			end
			$stop;
		end
	end
endmodule