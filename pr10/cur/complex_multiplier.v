`timescale 1ns/10ps

module sti_complex_multiplier;

	wire [32-1:0]	out;

	reg [32-1:0] sig_C [0:1023];
	reg [32-1:0] sig_O [0:1023];
	reg [32-1:0] sig_T [0:1023];
	
	reg [32-1:0] C;
	reg [32-1:0] O_ans;
	reg [32-1:0] T;

	complex_multiplier CM0(.O(out), .C(C), .T(T));
	
	initial
	begin
		$readmemh("CrCi.txt", sig_C);
		$readmemh("TrTi.txt", sig_T);
		$readmemh("OrOi.txt", sig_O);
	end
	
	integer i=0;
	integer err = 0;	
	initial
	begin		
		for (i=0; i<1024; i=i+1)
		begin
			C = sig_C[i];
			T = sig_T[i];
			O_ans = sig_O[i];
			#(10);
			if(out != O_ans) err = err + 1;
		end
	end


endmodule