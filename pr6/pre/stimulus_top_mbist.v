`timescale 1ns/10ps

module stimulus_top_mbist;

	wire MBIST_done;
	wire [56-1:0] data_out;
	reg MBIST_start, clk, rstn;

	top_mbist MBIST(.clk(clk), .rstn(rstn), .MBIST_start(MBIST_start), .MBIST_done(MBIST_done), .data_out(data_out));

	always #5 clk <= ~clk;

	initial begin
		clk <= 1; rstn <= 0; MBIST_start <= 0;
		#10
		rstn <= 1;
		MBIST_start <= 1;
		#10
		MBIST_start <= 0;
	end

endmodule
