`timescale 1 ns / 1 ps
module stimulus_CSM_22bit;

	wire    [43:0]  mul_out_rca, mul_out_srcsa;
	reg     [21:0]  a, b;
	reg             clk, rstn;

	reg     [21:0]  mat_a_input      [0:99];
	reg     [21:0]  mat_b_input      [0:99];
	reg     [43:0]  mat_mult_output  [0:99];
	reg     [43:0]  mat_out;

	integer i, k, err_rca, err_srcsa;

	CSM_RCA_22bit      MULT0   (.mul(mul_out_rca), .a(a), .b(b), .clk(clk), .rstn(rstn));
	CSM_SRCSA_22bit    MULT1   (.mul(mul_out_srcsa), .a(a), .b(b), .clk(clk), .rstn(rstn));

	always #5 clk <= ~clk;

	initial	begin
		clk <= 1; rstn <= 0;
		#12
		rstn <= 1;
		#1050 $stop;
	end

	initial	begin
		$readmemh("C:/Users/oaz/Desktop/osm/verilog/pr5/cur/a_input.txt", mat_a_input);
		$readmemh("C:/Users/oaz/Desktop/osm/verilog/pr5/cur/b_input.txt", mat_b_input);
		i = 0;
		#(20);

		for(i = 0; i < 100; i = i + 1)
		begin
			a = mat_a_input[i];
			b = mat_b_input[i];
			#(10);
		end

	end

	initial	begin
		$readmemh("C:/Users/oaz/Desktop/osm/verilog/pr5/cur/mult_output.txt", mat_mult_output);
		err_rca = 0;
        err_srcsa = 0;
		k = 0;
		#(30);

		for(k = 0; k < 100; k = k + 1) begin
			mat_out <= mat_mult_output[k];
			#(2);
			if((mul_out_rca != mat_out))
				err_rca = err_rca + 1;
			if((mul_out_srcsa != mat_out))
				err_srcsa = err_srcsa + 1;
			#(8);
		end
        $stop;
	end

endmodule
