module top_memory_ctrl (
	output [56-1:0] out,
	input clk, rstn
);
	wire [6-1:0] RA;
	wire [3-1:0] CA;
	wire [56-1:0] memory_in, memory_out;
	wire NWRT, NCE;

	rflp512x56mx3 memory0(.DO(memory_out), .DIN(memory_in), .RA(RA), .CA(CA), .NWRT(NWRT), .NCE(NCE), .CLK(clk));

	reg [11-1:0] cnt;
	reg [28-1:0] Mul_a, Mul_b;
	reg [56-1:0] Mul_out;
	reg [56-1:0] memory_in_tmp;
	reg start;

	assign RA = cnt[10:5];
	assign CA = cnt[4:2];
	assign memory_in = memory_in_tmp;

	// Define NWRT, NCE
	assign NWRT = ~(cnt[0] | cnt[1]);
	assign NCE = cnt[0] ^ cnt[1];

	// Read, write memory
	always @ (posedge clk) begin
		if (!rstn) begin
			start <= 1'b0;
		end
		else begin
			if (!start) begin
				cnt <= 11'b0;
				start <= 1'b1;
			end
			else begin
				cnt <= cnt + 1;
				if (cnt[1:0] == 2'b01) begin
					Mul_a <= memory_out[55:28];
					Mul_b <= memory_out[27:0];
				end
				else if (cnt[1:0] == 2'b11) begin
					memory_in_tmp <= Mul_out;
				end
			end
		end
	end	

	// Multiply
	assign Mul_out = Mul_a * Mul_b;

	// Assign out
	assign out = memory_out;

endmodule
