module top_controller_synthesis (
	output reg [10-1:0] addr_A_d,
	output reg [8-1:0] addr_B_d,
	output reg [10-1:0] addr_C_d,
	output reg [21-1:0] MAC_out_d,
	output reg NWRT_C_d, NCE_C_d,
	output reg done,
	input [8-1:0] A_q,
	input [32-1:0] B_q,
	input start, clk, rstn
);

	wire [10-1:0] addr_A;
	wire [8-1:0] addr_B;
	wire [10-1:0] addr_C;
	wire [8-1:0] A;
	wire [32-1:0] B;
	wire [21-1:0] MAC_out, C0, C1, C2, C3;
	wire NWRT_C, NCE_C, sel;

	reg [13-1:0] cnt;
	reg [8-1:0] A_tmp;
	reg [32-1:0] B_tmp;
	reg [21-1:0] MAC_out_tmp;
	reg [21-1:0] C1_d_1, C2_d_1, C2_d_2, C3_d_1, C3_d_2, C3_d_3;
	reg NWRT_C_tmp, NCE_C_tmp;

	assign addr_A = {cnt[12:8], cnt[4:0]};
	assign addr_B = {cnt[4:0], cnt[7:5]};
	assign addr_C = {cnt[12:5]-1'b1, cnt[1:0]-2'b10};
	assign sel = (cnt[4:0] == 5'd1);
	assign MAC_out = MAC_out_tmp;
	assign NWRT_C = NWRT_C_tmp;
	assign NCE_C = NCE_C_tmp;
	assign A = A_tmp;
	assign B = B_tmp;

	// DFF for synthesis
	always @ (posedge clk) begin
		if (!rstn) begin
			A_tmp <= 0;
			B_tmp <= 0;
			addr_A_d <= 0;
			addr_B_d <= 0;
			addr_C_d <= 0;
			MAC_out_d <= 0;
			NWRT_C_d <= 0;
			NCE_C_d <= 0;
		end
		else begin
			A_tmp <= A_q;
			B_tmp <= B_q;
			addr_A_d <= addr_A;
			addr_B_d <= addr_B;
			addr_C_d <= addr_C;
			MAC_out_d <= MAC_out;
			NWRT_C_d <= NWRT_C;
			NCE_C_d <= NCE_C;
		end
	end

	// Computation Unit
	MAC MAC0 (.MAC_out(C0), .A(A), .B(B[31:24]), .sel(sel), .clk(clk));
	MAC MAC1 (.MAC_out(C1), .A(A), .B(B[23:16]), .sel(sel), .clk(clk));
	MAC MAC2 (.MAC_out(C2), .A(A), .B(B[15:8]), .sel(sel), .clk(clk));
	MAC MAC3 (.MAC_out(C3), .A(A), .B(B[7:0]), .sel(sel), .clk(clk));

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