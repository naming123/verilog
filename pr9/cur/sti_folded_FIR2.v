`timescale 1ns/10ps
module sti_folded_FIR_shifted;
    wire [13:0] c0=14'h8f6, c1=14'h3571, c2=14'hb85,  c3=14'h2fef;
    wire [13:0] c4=14'h108c,c5=14'h2e89, c6=14'h10cc, c7=14'h2d9a;
    reg clk160, reset, clk20;
    reg [23:0] sig_mat [0:255];
    reg [23:0] out_mat, FIR_out;
    FIR_memory_folded FIR(clk160, clk20, reset, c0,c1,c2,c3,c4,c5,c6,c7);

    initial begin clk160=1; clk20=1; reset=0; #42 reset=1; end
    always #5  clk160 = ~clk160;
    always #40 clk20  = ~clk20;

    initial $readmemh("input_vector_hex.txt", FIR.INPUT_MEM.array);

    integer i, err=0, first_err=-1;
    initial begin
        $readmemh("output_vector_hex_shifted.txt", sig_mat);
        wait(reset == 1'b1);
        #(1040);
        for (i=0; i<60; i=i+1) begin
            out_mat = sig_mat[i];
            FIR_out = FIR.OUTPUT_MEM.array[i];
            #(80);
            $display("i=%0d  DUT=%h  EXP=%h  %s", i, FIR_out, out_mat,
                     (FIR_out===out_mat) ? "ok" : "MISMATCH");
            if (FIR_out !== out_mat) begin
                err = err + 1; if (first_err<0) first_err = i;
            end
        end
        $display("\n==== %0d mismatches in first 60 (first at i=%0d) ====", err, first_err);
        $finish;
    end
endmodule