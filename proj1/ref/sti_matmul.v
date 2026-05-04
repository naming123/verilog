`timescale 1ns / 10ps
module sti_matmul;

	reg [22-1:0] mat_output [0:4096-1];
	reg [22-1:0] mat_out;
	reg [22-1:0] out;
	reg clk;
	reg rstn;
	reg start;

	wire done;

	top_controller Utop_controller(.done(done), .start(start), .clk(clk), .rstn(rstn));

	initial	$readmemh("vec_a.txt", Utop_controller.MEM_A.array);
	initial	$readmemh("vec_b.txt", Utop_controller.MEM_B.array);
	initial $readmemh("vec_c.txt", mat_output);

    always #5 clk <= ~clk;
	
	initial begin
		clk = 1; rstn = 0; start = 0;
		#10
		rstn = 1;
		#10 start = 1;
		#10 start = 0;
	end

	integer i = 0;
	integer err = 0;

	always @(posedge clk) begin
		if(done) begin
			for(i = 0; i < 4096; i = i + 1) begin
				#(10);
				mat_out <= mat_output[i];
				out     <= Utop_controller.MEM_C.array[i];
				if(out != mat_out) err = err + 1;
			end
			#10 $stop;
		end
	end

endmodule