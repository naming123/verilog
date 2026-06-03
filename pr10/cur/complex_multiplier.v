module complex_multiplier (
    output [31:0] O,
    input  [31:0] C,
    input  [31:0] T
);
    wire signed [15:0] Cr, Ci, Tr, Ti;
    wire signed [32:0] Or_full, Oi_full;

    assign Cr = C[31:16];
    assign Ci = C[15:0];
    assign Tr = T[31:16];
    assign Ti = T[15:0];

    assign Or_full = Cr * Tr - Ci * Ti;
    assign Oi_full = Cr * Ti + Ci * Tr;

    assign O = {Or_full[29:14], Oi_full[29:14]};

endmodule