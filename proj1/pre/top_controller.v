module top_controller (
	output reg done,
	input start, clk, rstn 
);
	
	wire [10-1:0] addr_A;
	wire [8-1:0] addr_B;
	wire [10-1:0] addr_C;
	wire [8-1:0] A, B0, B1, B2, B3;
	wire [21-1:0] MAC_out, C0, C1, C2, C3;
	wire NWRT_C, NCE_C, sel;

	reg [13-1:0] cnt;
	reg [21-1:0] MAC_out_tmp, C1_d_1, C2_d_1, C2_d_2, C3_d_1, C3_d_2, C3_d_3;
	reg NWRT_C_tmp, NCE_C_tmp;

	assign addr_A = {cnt[12:8], cnt[4:0]};
	assign addr_B = {cnt[4:0], cnt[7:5]};
	assign addr_C = {cnt[12:5]-1'b1, cnt[1:0]-2'b10};
	assign sel = (cnt[4:0] == 5'd1);
	assign MAC_out = MAC_out_tmp;
	assign NWRT_C = NWRT_C_tmp;
	assign NCE_C = NCE_C_tmp;

	// Input matrix
	rflp1024x8mx2 MEM_A (.DO(A), .DIN(8'b0), .RA(addr_A[9:2]), .CA(addr_A[1:0]), .NWRT(1'b1), .NCE(1'b0), .CLK(clk));
	rflp256x32mx2 MEM_B (.DO({B0, B1, B2, B3}), .DIN(32'b0), .RA(addr_B[7:2]), .CA(addr_B[1:0]), .NWRT(1'b1), .NCE(1'b0), .CLK(clk));

	// Output matrix
	rflp1024x21mx2 MEM_C (.DO(), .DIN(MAC_out), .RA(addr_C[9:2]), .CA(addr_C[1:0]), .NWRT(NWRT_C), .NCE(NCE_C), .CLK(clk));

	// Computation Unit
	MAC MAC0 (.MAC_out(C0), .A(A), .B(B0), .sel(sel), .clk(clk));
	MAC MAC1 (.MAC_out(C1), .A(A), .B(B1), .sel(sel), .clk(clk));
	MAC MAC2 (.MAC_out(C2), .A(A), .B(B2), .sel(sel), .clk(clk));
	MAC MAC3 (.MAC_out(C3), .A(A), .B(B3), .sel(sel), .clk(clk));

	// Counter for address control
	always @ (posedge clk) begin
		if (!rstn) begin
			cnt <= 13'bx;
		end
		else begin
			if (start) begin
				done <= 1'b0;
				cnt <= 13'b0;
			end
			else if (cnt == 13'h1FFF) begin
				done <= 1'b1;
				cnt <= cnt + 1;
			end
			else begin
				done <= 1'b0;
				cnt <= cnt + 1;
			end
		end
	end

	// Assign NWRT_C, NCE_C
	always @ (*) begin
		if (cnt[4:0] >= 3'd2 && cnt[4:0] <= 3'd5) begin
			NWRT_C_tmp = 1'b0;
			NCE_C_tmp = 1'b0;
		end
		else begin
			NWRT_C_tmp = 1'b1;
			NCE_C_tmp = 1'b1;
		end
	end

	// Write in SRAM C
	always @ (posedge clk) begin
		C1_d_1 <= C1;
		C2_d_1 <= C2;
		C2_d_2 <= C2_d_1;
		C3_d_1 <= C3;
		C3_d_2 <= C3_d_1;
		C3_d_3 <= C3_d_2;

		case (cnt[1:0])
			2'b01 : MAC_out_tmp <= C0;
			2'b10 : MAC_out_tmp <= C1_d_1;
			2'b11 : MAC_out_tmp <= C2_d_2;
			2'b00 : MAC_out_tmp <= C3_d_3;
			default: MAC_out_tmp <= 21'bx;
		endcase
	end
endmodule

module MAC (
	output wire [21-1:0] MAC_out,
	input [8-1:0] A, B,
	input sel, clk
);
	wire [16-1:0] mul_out;
	wire [21-1:0] sum_out, mux_out;

	reg [21-1:0] sum_out_d;

	assign mul_out = A * B;
	assign sum_out = mux_out + mul_out;
	assign mux_out = sel ? 1'b0 : sum_out_d;
	assign MAC_out = sum_out_d;

	always @ (posedge clk) begin
		sum_out_d <= sum_out;
	end
	
endmodule