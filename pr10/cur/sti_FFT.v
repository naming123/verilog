`timescale 1ns/10ps
module sti_FFT;

	reg clk, rstn;
    reg [32-1:0] mat_in [0:511];
	reg [32-1:0] mat_out [0:511];
	reg [32-1:0] out_mat;
	reg [32-1:0] in;

    wire [32-1:0] out;
	
	
	top_FFT FFT(.out(out), .in(in), .clk(clk), .rstn(rstn));
	
	initial
	begin
		clk = 1;
		rstn = 0;
		#12
		rstn = 1;
		#5248 $stop;
	end
	
	always #5 clk = ~clk;
	
    integer i=0, j=0;

	initial
	begin		
		$readmemh("C:/Users/smoh/Desktop/26-1/Verilog/pr10/ref/input_FFT.txt", mat_in);
		begin
			#(20);
			for (i=0; i<512; i=i+1)
			begin
				in = mat_in[i];
				#(10);
			end
		end
	end

	
	integer err = 0;	
	initial
	begin		
		$readmemh("C:/Users/smoh/Desktop/26-1/Verilog/pr10/ref/output_FFT.txt", mat_out);
		begin
			#(120); //change if needed
			for (j=0; j<512; j=j+1)
			begin
				out_mat <= mat_out[j];
				if (out_mat != out) err = err + 1;
				#(10);
			end
		end
	end

endmodule