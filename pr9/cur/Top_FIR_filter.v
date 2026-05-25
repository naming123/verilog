module FIR_memory_folded (
	input clk160, clk20, reset, 
	input signed [14-1:0] c0, c1, c2, c3, c4, c5, c6, c7
);

	wire [8-1:0] addr_in, addr_out;
	wire signed [14-1:0] x_in_folded;
	wire signed [24-1:0] y_out_folded;
	
	// -------------------------------------------------------------------------
	// 1. 메모리 인스턴스 포트 매핑 수정
	// 에러 로그 분석 결과, 메모리 내부 포트가 (.포트명) 방식이 아니라 
	// 위치 지정 방식이나 다른 포트명을 사용할 가능성이 커서 규격을 맞췄습니다.
	// -------------------------------------------------------------------------
	rflp256x14mx4 INPUT_MEM (
		.NWRT(1'b1), 
		.NCE(1'b0), 
		.CLK(clk20), 
		.DIN(14'b0), 
		.CA(addr_in[1:0]), 
		.RA(addr_in[7:2]), 
		.DO(x_in_folded)
	);

	rflp256x24mx4 OUTPUT_MEM (
		.NWRT(1'b0), 
		.NCE(1'b0), 
		.CLK(clk20), 
		.DIN(y_out_folded), 
		.CA(addr_out[1:0]), 
		.RA(addr_out[7:2]), 
		.DO() // 출력은 필요 없으므로 비워둠
	);

	// -------------------------------------------------------------------------
	// 2. 하위 필터 인스턴스 수정 (clk100 포트 에러 해결)
	// 상위의 clk160, clk20 신호를 하위 모듈 포트명에 정확히 1:1 매칭
	// -------------------------------------------------------------------------
	folded_FIR_filter FOLDED_FIR_FILTER (
		.folded_out(y_out_folded), 
		.in(x_in_folded), 
		.c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7), 
		.clk160(clk160),   // 이 부분 이름이 clk100으로 되어 있던 것을 수정
		.clk20(clk20), 
		.reset(reset)
	);

	// 주소 제어용 카운터 (20MHz 도메인)
	reg [8-1:0] cnt;

	assign addr_in = cnt;
	assign addr_out = cnt - 3'd7; 

	always @ (posedge clk20) begin
		if (!reset) begin
			cnt <= 8'b0;
		end
		else begin
			cnt <= cnt + 1;
		end
	end

endmodule

// -------------------------------------------------------------------------
// 3. 하위 folded_FIR_filter 모듈 (포트 정보 확인용)
// -------------------------------------------------------------------------
module folded_FIR_filter (
	output reg signed [24-1:0] folded_out,
	input signed [14-1:0] in,
	input signed [14-1:0] c0, c1, c2, c3, c4, c5, c6, c7,
	input clk160, clk20, reset
);
	
	reg signed [14-1:0] shift_reg [0:7];
	
	wire signed [22-1:0] sum_out, mux_out;
	wire signed [28-1:0] mul_out_reg; 
	wire signed [22-1:0] mul_out;     

	reg signed [14-1:0] x_mux_out, x_d;
	reg signed [14-1:0] c_mux_out, c_d;
	reg signed [24-1:0] sum_out_d;    
	reg [3-1:0] cnt8;                 

	// Slower Clock Domain (20MHz)
	always @ (posedge clk20) begin
		if (!reset) begin
			shift_reg[0] <= 14'b0; shift_reg[1] <= 14'b0; shift_reg[2] <= 14'b0; shift_reg[3] <= 14'b0;
			shift_reg[4] <= 14'b0; shift_reg[5] <= 14'b0; shift_reg[6] <= 14'b0; shift_reg[7] <= 14'b0;
		end
		else begin
			shift_reg[0] <= in;
			shift_reg[1] <= shift_reg[0];
			shift_reg[2] <= shift_reg[1];
			shift_reg[3] <= shift_reg[2];
			shift_reg[4] <= shift_reg[3];
			shift_reg[5] <= shift_reg[4];
			shift_reg[6] <= shift_reg[5];
			shift_reg[7] <= shift_reg[6];
		end
	end

	// Faster Clock Domain (160MHz)
	always @ (posedge clk160) begin
		if (!reset) begin
			cnt8 <= 3'b0;
		end
		else begin
			cnt8 <= cnt8 + 1'b1;
		end
	end

	// Input MUX
	always @ (*) begin
		case (cnt8)
			3'd0    : x_mux_out <= shift_reg[0];
			3'd1    : x_mux_out <= shift_reg[1];
			3'd2    : x_mux_out <= shift_reg[2];
			3'd3    : x_mux_out <= shift_reg[3];
			3'd4    : x_mux_out <= shift_reg[4];
			3'd5    : x_mux_out <= shift_reg[5];
			3'd6    : x_mux_out <= shift_reg[6];
			3'd7    : x_mux_out <= shift_reg[7];
			default : x_mux_out <= 14'b0;
		endcase
	end

	always @ (posedge clk160) begin
		if (!reset) x_d <= 14'b0;
		else        x_d <= x_mux_out;
	end

	// Coefficient MUX
	always @ (*) begin
		case (cnt8)
			3'd0    : c_mux_out <= c0;
			3'd1    : c_mux_out <= c1;
			3'd2    : c_mux_out <= c2;
			3'd3    : c_mux_out <= c3;
			3'd4    : c_mux_out <= c4;
			3'd5    : c_mux_out <= c5;
			3'd6    : c_mux_out <= c6;
			3'd7    : c_mux_out <= c7;
			default : c_mux_out <= 14'b0;
		endcase
	end
	
	always @ (posedge clk160) begin
		if (!reset) c_d <= 14'b0;
		else        c_d <= c_mux_out;
	end

	// Multiplier & Round-off (28-bit -> 22-bit)
	assign mul_out_reg = c_d * x_d;
	assign mul_out = mul_out_reg[27:6] + mul_out_reg[5];

	// Accumulator
	assign mux_out = (cnt8 == 3'd1) ? 24'b0 : sum_out_d;
	assign sum_out = mul_out + mux_out;

	always @ (posedge clk160) begin
		if (!reset) begin
			sum_out_d <= 24'b0;
		end
		else begin
			sum_out_d <= sum_out;
		end
	end

	// Output Register
	always @ (posedge clk160) begin
		if (!reset) begin
			folded_out <= 24'b0;
		end
		else if (cnt8 == 3'd0) begin
			folded_out <= sum_out_d;
		end
	end

endmodule