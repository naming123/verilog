module top_mbist (
   output reg MBIST_done,
   output [44-1:0] data_out, 
   input MBIST_start, clk, rstn
);
   
    wire NWRT, NCE;
    wire [44-1:0] data_in;
    wire [7-1:0] RA;
    wire [3-1:0] CA;

    rflp1024x44mx3 memory(.DO(data_out), .DIN(data_in), .RA(RA), .CA(CA), .NWRT(NWRT), .NCE(NCE), .CLK(clk));
    
    reg NCE_tmp;
    reg [13-1:0] state_counter;
    reg [44-1:0] data_in_tmp;

    assign CA   = state_counter[2:0];
    assign RA   = state_counter[9:3];
    assign NWRT = state_counter[10];
    assign NCE  = NCE_tmp;
    assign data_in = data_in_tmp;
    
    wire [9:0] ADDR;
    assign ADDR = {RA, CA};  

    always @ (posedge clk) begin
        if (!rstn)
            state_counter <= 13'b0;
        else begin
            if (MBIST_start) begin
                NCE_tmp    <= 1'b0;
                MBIST_done <= 1'b0;
                state_counter    <= 13'b0;
            end
            else if (state_counter == 13'h1FFF) begin
                MBIST_done <= 1'b1;
                state_counter    <= state_counter + 1;
            end
            else begin
                MBIST_done <= 1'b0;
                state_counter    <= state_counter + 1;
            end
        end
    end

    always @ (*) begin
        case (state_counter[12:11])
            2'b00 : data_in_tmp = 44'h0_0000_0000_0; 
            2'b01 : data_in_tmp = 44'hF_FFFF_FFFF_F;
            2'b10 : data_in_tmp = 44'h5_5555_5555_5;
            2'b11 : data_in_tmp = 44'hA_AAAA_AAAA_A;
            default: data_in_tmp = 44'h0_0000_0000_0;
        endcase
    end

endmodule