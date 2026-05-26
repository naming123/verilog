module Twiddle_Factor (
	output signed [24-1:0] out, 
	input signed [24-1:0] C, T
);
	
	wire signed [12-1:0] Cr, Ci, Tr, Ti;
	wire signed [25-1:0] Or, Oi;

	assign Cr = C[23:12];
	assign Ci = C[11:0];
	assign Tr = T[23:12];
	assign Ti = T[11:0];

	assign Or = Cr * Tr - Ci * Ti;
	assign Oi = Cr * Ti + Ci * Tr;

	assign out = {Or[21:10], Oi[21:10]};

endmodule
