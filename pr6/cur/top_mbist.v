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
    reg [13-1:0] cnt_tmp;
    reg [44-1:0] data_in_tmp;

    assign CA   = cnt_tmp[2:0];
    assign RA   = cnt_tmp[9:3];
    assign NWRT = cnt_tmp[10];
    assign NCE  = NCE_tmp;
    assign data_in = data_in_tmp;	

    always @ (posedge clk) begin
        if (!rstn)
            cnt_tmp <= 13'b0;
        else begin
            if (MBIST_start) begin
                NCE_tmp    <= 1'b0;
                MBIST_done <= 1'b0;
                cnt_tmp    <= 13'b0;
            end
            else if (cnt_tmp == 13'h1FFF) begin
                MBIST_done <= 1'b1;
                cnt_tmp    <= cnt_tmp + 1;
            end
            else begin
                MBIST_done <= 1'b0;
                cnt_tmp    <= cnt_tmp + 1;
            end
        end
    end

    always @ (*) begin
        case (cnt_tmp[12:11])
            2'b00 : data_in_tmp = 44'h0_0000_0000_0000;
            2'b01 : data_in_tmp = 44'hF_FFFF_FFFF_FFFF;
            2'b10 : data_in_tmp = 44'h5_5555_5555_5555;
            2'b11 : data_in_tmp = 44'hA_AAAA_AAAA_AAAA;
            default: data_in_tmp = 44'h0_0000_0000_0000;
        endcase
    end

endmodule