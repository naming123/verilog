`timescale 1ns/10ps

// =================================================================
// 1. ? ?? ? ??? ????? (????? ?? ??? ???)
// =================================================================
module FIR_memory_folded (
    input clk160, clk20, reset,
    input signed [13:0] c0, input signed [13:0] c1,
    input signed [13:0] c2, input signed [13:0] c3,
    input signed [13:0] c4, input signed [13:0] c5,
    input signed [13:0] c6, input signed [13:0] c7
);

    wire [7:0] addr_in, addr_out;
    wire signed [13:0] x_in_folded;
    wire signed [23:0] y_out_folded;

    rflp_sim_14bit INPUT_MEM (
        .CLK(clk20), .RESET(reset), .ADDR(addr_in), .DO(x_in_folded)
    );
    
    rflp_sim_24bit OUTPUT_MEM (
        .CLK(clk20), .RESET(reset), .ADDR(addr_out), .DIN(y_out_folded)
    );
    
    folded_FIR_filter FOLDED_FIR_FILTER (
        .folded_out(y_out_folded), 
        .in(x_in_folded), 
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .clk100(clk160), .reset(reset)
    );

    reg [7:0] cnt;
    reg [7:0] addr_in_r, addr_out_r;

    assign addr_in  = addr_in_r;
    assign addr_out = addr_out_r;

    always @(posedge clk20) begin
        if (!reset) begin
            cnt        <= 8'h0;
            addr_in_r  <= 8'h0;
            addr_out_r <= 8'h0;
        end
        else begin
            cnt        <= cnt + 1'b1;
            addr_in_r  <= cnt;
            
            // ? ?????? #(1040) ?? ? ??? i=1 ?? ???? 
            // ???? OUTPUT_MEM ??? ?? ?? ????? ?? ??? ??? ??
            addr_out_r <= cnt - 8'd13; 
        end
    end

endmodule


// =================================================================
// 2. 8-Tap Folded FIR Filter (???/??? ?? ?? ??)
// =================================================================
module folded_FIR_filter (
    output reg signed [24-1:0] folded_out, 
    input signed [14-1:0] in,              
    input signed [13:0] c0, input signed [13:0] c1,
    input signed [13:0] c2, input signed [13:0] c3,
    input signed [13:0] c4, input signed [13:0] c5,
    input signed [13:0] c6, input signed [13:0] c7,
    input clk100, reset
);
    
    reg signed [14-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
    reg signed [14-1:0] x_mux_out, x_d;
    reg signed [13:0]   c_mux_out, c_d;     
    
    wire signed [28-1:0] mul_out_reg;        
    wire signed [24-1:0] mul_out;          
    wire signed [24-1:0] sum_out;
    reg  signed [24-1:0] sum_out_d;

    reg [3-1:0] cnt100; 

    // ?? ??? ???? ?????
    always @ (posedge clk100) begin
        if (!reset) begin
            x0 <= 14'b0; x1 <= 14'b0; x2 <= 14'b0; x3 <= 14'b0;
            x4 <= 14'b0; x5 <= 14'b0; x6 <= 14'b0; x7 <= 14'b0;
        end
        else if (cnt100 == 3'd7) begin 
            x0 <= in;
            x1 <= x0; x2 <= x1; x3 <= x2;
            x4 <= x3; x5 <= x4; x6 <= x5; x7 <= x6;
        end
    end

    // 160MHz ???
    always @ (posedge clk100) begin
        if (!reset) cnt100 <= 3'b0;
        else        cnt100 <= cnt100 + 1'b1;
    end

    // Input ??? ?? MUX
    always @ (*) begin
        case (cnt100)
            3'd0    : x_mux_out = x0;
            3'd1    : x_mux_out = x1;
            3'd2    : x_mux_out = x2;
            3'd3    : x_mux_out = x3;
            3'd4    : x_mux_out = x4;
            3'd5    : x_mux_out = x5;
            3'd6    : x_mux_out = x6;
            3'd7    : x_mux_out = x7;
            default : x_mux_out = 14'b0;
        endcase
    end

    // ?? ?? MUX
    always @ (*) begin
        case (cnt100)
            3'd0    : c_mux_out = c0;
            3'd1    : c_mux_out = c1;
            3'd2    : c_mux_out = c2;
            3'd3    : c_mux_out = c3;
            3'd4    : c_mux_out = c4;
            3'd5    : c_mux_out = c5;
            3'd6    : c_mux_out = c6;
            3'd7    : c_mux_out = c7;
            default : c_mux_out = 14'b0;
        endcase
    end
    
    // ????? ???? (Stage 1)
    always @ (posedge clk100) begin
        if (!reset) begin
            x_d <= 14'b0;
            c_d <= 14'b0;                    
        end
        else begin
            x_d <= x_mux_out;
            c_d <= c_mux_out;
        end
    end

    // ??? 28?? ?? ?? ?? ??
    assign mul_out_reg = c_d * x_d;
    
    // 20-bit signed ?? ??? ???? ??
    wire signed [20-1:0] mul_round; 
    assign mul_round = mul_out_reg[25:6] + mul_out_reg[5];
    
    // ?? ??? ?? 24-bit Sign Extension ?? ?? (?? 1 ??)
    assign mul_out   = {{4{mul_round[19]}}, mul_round};

    // ?? ??? ?? ?? (?? 2 ??: ?? 1, ?? 0)
    wire signed [24-1:0] fb_mux;
    assign fb_mux  = (cnt100 == 3'd1) ? 24'b0 : sum_out_d; 
    assign sum_out = mul_out + fb_mux;

    always @ (posedge clk100) begin
        if (!reset) sum_out_d <= 24'b0;
        else        sum_out_d <= sum_out;
    end

    always @ (posedge clk100) begin
        if (!reset)              folded_out <= 24'b0;
        else if (cnt100 == 3'd0) folded_out <= sum_out;   
    end

endmodule