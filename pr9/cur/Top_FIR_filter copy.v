// =====================================================================
// FIR_memory_folded_fixed.v
//
// Three fixes vs. the original:
//   (A) folded_out is captured at cnt8==1, not cnt8==0, so the c7 term
//       that arrives in sum_out_d at the cnt8 0->1 edge is actually
//       observed.
//   (B) shift_reg lives in the clk160 domain with a shift-enable that
//       fires only at the end of each FIR round (cnt8==7). This kills
//       the mid-round-shift race regardless of clk20/clk160 phase.
//   (C) mux_out widened to 24-bit so the accumulator path keeps the
//       full sum_out_d width (no MSB truncation).
// =====================================================================

module FIR_memory_folded (
    input clk160, clk20, reset,
    input signed [13:0] c0, c1, c2, c3, c4, c5, c6, c7
);
    wire [7:0]         addr_in, addr_out;
    wire signed [13:0] x_in_folded;
    wire signed [23:0] y_out_folded;

    rflp256x14mx4 INPUT_MEM (
        .NWRT(1'b1), .NCE(1'b0), .CLK(clk20),
        .DIN(14'b0), .CA(addr_in[1:0]), .RA(addr_in[7:2]), .DO(x_in_folded)
    );
    rflp256x24mx4 OUTPUT_MEM (
        .NWRT(1'b0), .NCE(1'b0), .CLK(clk20),
        .DIN(y_out_folded), .CA(addr_out[1:0]), .RA(addr_out[7:2]), .DO()
    );

    folded_FIR_filter FOLDED_FIR_FILTER (
        .folded_out(y_out_folded), .in(x_in_folded),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .clk160(clk160), .clk20(clk20), .reset(reset)
    );

    reg [7:0] cnt;
    initial   cnt = 8'b0;                 // guarantee a known start
    assign addr_in  = cnt;
    assign addr_out = cnt - 8'd7;

    always @ (posedge clk20) begin
        if (!reset) cnt <= 8'b0;
        else        cnt <= cnt + 1;
    end
endmodule

// ---------------------------------------------------------------------
module folded_FIR_filter (
    output reg signed [23:0] folded_out,
    input  signed     [13:0] in,
    input  signed     [13:0] c0, c1, c2, c3, c4, c5, c6, c7,
    input                    clk160, clk20, reset
);
    reg signed [13:0] shift_reg [0:7];
    reg        [2:0]  cnt8;

    // ---- cnt8 ------------------------------------------------------
    always @ (posedge clk160) begin
        if (!reset) cnt8 <= 3'b0;
        else        cnt8 <= cnt8 + 1'b1;
    end

    // ---- (B) round-aligned shift register --------------------------
    wire shift_en = (cnt8 == 3'd7);    // fire once per 8 clk160 cycles
    integer k;
    always @ (posedge clk160) begin
        if (!reset) begin
            for (k=0; k<8; k=k+1) shift_reg[k] <= 14'sd0;
        end else if (shift_en) begin
            shift_reg[0] <= in;
            shift_reg[1] <= shift_reg[0]; shift_reg[2] <= shift_reg[1];
            shift_reg[3] <= shift_reg[2]; shift_reg[4] <= shift_reg[3];
            shift_reg[5] <= shift_reg[4]; shift_reg[6] <= shift_reg[5];
            shift_reg[7] <= shift_reg[6];
        end
    end

    // ---- input / coefficient MUX -----------------------------------
    reg signed [13:0] x_mux_out, x_d;
    reg signed [13:0] c_mux_out, c_d;

    always @ (*) begin
        case (cnt8)
            3'd0: x_mux_out = shift_reg[0]; 3'd1: x_mux_out = shift_reg[1];
            3'd2: x_mux_out = shift_reg[2]; 3'd3: x_mux_out = shift_reg[3];
            3'd4: x_mux_out = shift_reg[4]; 3'd5: x_mux_out = shift_reg[5];
            3'd6: x_mux_out = shift_reg[6]; 3'd7: x_mux_out = shift_reg[7];
            default: x_mux_out = 14'sd0;
        endcase
    end
    always @ (posedge clk160) begin
        if (!reset) x_d <= 14'sd0; else x_d <= x_mux_out;
    end

    always @ (*) begin
        case (cnt8)
            3'd0: c_mux_out = c0; 3'd1: c_mux_out = c1;
            3'd2: c_mux_out = c2; 3'd3: c_mux_out = c3;
            3'd4: c_mux_out = c4; 3'd5: c_mux_out = c5;
            3'd6: c_mux_out = c6; 3'd7: c_mux_out = c7;
            default: c_mux_out = 14'sd0;
        endcase
    end
    always @ (posedge clk160) begin
        if (!reset) c_d <= 14'sd0; else c_d <= c_mux_out;
    end

    // ---- multiplier + round-half-up ---------------------------------
    wire signed [27:0] mul_out_reg = c_d * x_d;
    wire signed [21:0] mul_out     = mul_out_reg[27:6] + mul_out_reg[5];

    // ---- (C) accumulator path, all 24-bit ---------------------------
    reg  signed [23:0] sum_out_d;
    wire signed [23:0] mux_out = (cnt8 == 3'd1) ? 24'sd0 : sum_out_d;
    wire signed [23:0] sum_out = {{2{mul_out[21]}}, mul_out} + mux_out;

    always @ (posedge clk160) begin
        if (!reset) sum_out_d <= 24'sd0;
        else        sum_out_d <= sum_out;
    end

    // ---- (A) capture the complete sum -------------------------------
    // sum_out_d holds  c0..c7  during the cnt8==1 cycle (it was just
    // latched at the previous edge that took cnt8 from 0 to 1).
    always @ (posedge clk160) begin
        if (!reset)             folded_out <= 24'sd0;
        else if (cnt8 == 3'd1)  folded_out <= sum_out_d;
    end
endmodule