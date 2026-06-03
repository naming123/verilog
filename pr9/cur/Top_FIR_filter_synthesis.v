module Top_FIR_filter_synthesis (
    input clk160, clk20, reset,
    input signed [14-1:0] in,
    input signed [14-1:0] c0, c1, c2, c3, c4, c5, c6, c7,
    output signed [24-1:0] out
);

    // 입출력 DFF 인터페이스
    reg signed [14-1:0] in_dff;
    reg signed [24-1:0] out_dff;
    wire signed [24-1:0] folded_out_wire;
    always @(posedge clk20 or posedge reset) begin
        if (reset) begin
            in_dff <= 14'b0;
            out_dff <= 24'b0;
        end else begin
            in_dff <= in;
            out_dff <= folded_out_wire;
        end
    end

    // 필터 연산 모듈 인스턴스 (메모리 대신 DFF 입력 연결)

    folded_FIR_filter FOLDED_FIR_FILTER (
        .folded_out(folded_out_wire),
        .in(in_dff),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .clk160(clk160),
        .clk20(clk20),
        .reset(reset)
    );

    assign out = out_dff;

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
   
   // reg signed [14-1:0] shift_reg [0:7];
   reg signed [14-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
   
   wire signed [24-1:0] sum_out, mux_out;
   wire signed [28-1:0] mul_out_reg; 
   wire signed [22-1:0] mul_out;     

   reg signed [14-1:0] x_mux_out, x_d;
   reg signed [14-1:0] c_mux_out, c_d;
   reg signed [24-1:0] sum_out_d;    
   reg [3-1:0] cnt8;                 

   // Slower Clock Domain (20MHz)
   always @ (posedge clk20) begin
      if (!reset) begin
         x0 <= 14'b0; x1 <= 14'b0; x2 <= 14'b0; x3 <= 14'b0;
         x4 <= 14'b0; x5 <= 14'b0; x6 <= 14'b0; x7 <= 14'b0;
      end
      else begin
         x0 <= in;
         x1 <= x0;
         x2 <= x1;
         x3 <= x2;
         x4 <= x3;
         x5 <= x4;
         x6 <= x5;
         x7 <= x6;
      end
   end

   // Faster Clock Domain (160MHz)
   always @ (posedge clk160) begin
      if (!reset) begin
         cnt8 <= 3'd4;
      end
      else begin
         cnt8 <= cnt8 + 1'b1;
      end
   end

   // Input MUX
   always @ (*) begin
      case (cnt8)
         3'd0    : x_mux_out <= x0;
         3'd1    : x_mux_out <= x1;
         3'd2    : x_mux_out <= x2;
         3'd3    : x_mux_out <= x3;
         3'd4    : x_mux_out <= x4;
         3'd5    : x_mux_out <= x5;
         3'd6    : x_mux_out <= x6;
         3'd7    : x_mux_out <= x7;
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
   assign mul_out = mul_out_reg[26:5] + mul_out_reg[4];

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
      // else if (cnt8 == 3'd1) begin
      else if (cnt8 == 3'd1) begin
         folded_out <= sum_out_d;
      end
   end

endmodule