module Butterfly (
	output signed [24-1:0] C1, C2, 
	input signed [24-1:0] A, B
);
	wire signed [12-1:0] Ar, Ai, Br, Bi;
	wire signed [13-1:0] C1r, C1i, C2r, C2i;

	assign Ar = A[23:12];
	assign Ai = A[11:0];
	assign Br = B[23:12];
	assign Bi = B[11:0];

	assign C1r = Ar + Br;
	assign C1i = Ai + Bi;
	assign C2r = Ar - Br;
	assign C2i = Ai - Bi;

	assign C1 = {C1r[12:1], C1i[12:1]};
	assign C2 = {C2r[12:1], C2i[12:1]};

endmodule
