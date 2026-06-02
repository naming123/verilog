module butterfly_unit (
    output [31:0] C1, C2,
    input  [31:0] A, B
);
    wire signed [15:0] Ar, Ai, Br, Bi;
    wire signed [16:0] C1r, C1i, C2r, C2i;

    assign Ar = A[31:16];
    assign Ai = A[15:0];
    assign Br = B[31:16];
    assign Bi = B[15:0];

    assign C1r = Ar + Br;
    assign C1i = Ai + Bi;
    assign C2r = Ar - Br;
    assign C2i = Ai - Bi;

    assign C1 = {C1r[16:1], C1i[16:1]};
    assign C2 = {C2r[16:1], C2i[16:1]};

endmodule