`timescale 1 ns / 1 ps
module stimulus_rca_28bit_2stage;

	wire    [28:0]  sum_pipe;
	reg     [27:0]  a, b;
	reg             clk;
	reg             rstn;

	reg     [27:0]  mat_a [0:99];
	reg     [27:0]  mat_b [0:99];
	reg     [28:0]  mat_sum [0:99];
	reg     [28:0]  mat_sum_cmp;
	
	integer i;
	integer k;
	integer err;

	ripple_carry_adder_28b_2stage ADD0(.sum(sum_pipe), .a(a), .b(b), .c_in(1'b0), .clk(clk), .rstn(rstn));

	always #5 clk <= ~clk;

	initial	begin
		clk <= 1; rstn <= 0;
		#12 rstn <=1;
		#1050 $stop;
	end

	initial begin
		$readmemh("a_input_28b.txt", mat_a);
		$readmemh("b_input_28b.txt", mat_b);

		i = 0;
		#(20);
		for(i = 0; i < 100; i = i + 1) begin
			a = mat_a[i];
			b = mat_b[i];
			#(10);
		end
	end

	initial begin
		$readmemh("sum_output_29b.txt", mat_sum);

		k = 0;
		err = 0;
		#(40);
		for(k = 0; k < 100; k = k + 1) begin
			mat_sum_cmp = mat_sum[k];			
			#(2);
			if(sum_pipe != mat_sum_cmp) begin
				err = err + 1;
			end
			#(8);
		end
		$stop;
	end

	endmodule