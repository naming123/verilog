module top_controller (
    output reg done,
    input start, clk, rstn 
);
    
    wire [12-1:0] addr_A;
    wire [10-1:0] addr_B;
    wire [12-1:0] addr_C;
    wire [8-1:0] A, B0, B1, B2, B3;
    wire [22-1:0] MAC_out, C0, C1, C2, C3;
    wire NWRT_C, NCE_C, sel;

    reg [16-1:0] cnt;
    reg [22-1:0] MAC_out_tmp, C1_d_1, C2_d_1, C2_d_2, C3_d_1, C3_d_2, C3_d_3;
    reg NWRT_C_tmp, NCE_C_tmp;

    assign addr_A = {cnt[15:10], cnt[5:0]};
    assign addr_B = {cnt[5:0], cnt[9:6]};
    assign addr_C = {cnt[15:6]-1'b1, cnt[1:0]-2'b10};
    assign sel = (cnt[5:0] == 6'd1);
    assign MAC_out = MAC_out_tmp;
    assign NWRT_C = NWRT_C_tmp;
    assign NCE_C = NCE_C_tmp;

    rflp4096x8mx4 MEM_A (.DO(A), .DIN(8'b0), .RA(addr_A[11:2]), .CA(addr_A[1:0]), .NWRT(1'b1), .NCE(1'b0), .CLK(clk));
    rflp1024x32mx4 MEM_B (.DO({B0, B1, B2, B3}), .DIN(32'b0), .RA(addr_B[9:2]), .CA(addr_B[1:0]), .NWRT(1'b1), .NCE(1'b0), .CLK(clk));
    rflp4096x22mx4 MEM_C (.DO(), .DIN(MAC_out), .RA(addr_C[11:2]), .CA(addr_C[1:0]), .NWRT(NWRT_C), .NCE(NCE_C), .CLK(clk));

    MAC MAC0 (.MAC_out(C0), .A(A), .B(B0), .sel(sel), .clk(clk));
    MAC MAC1 (.MAC_out(C1), .A(A), .B(B1), .sel(sel), .clk(clk));
    MAC MAC2 (.MAC_out(C2), .A(A), .B(B2), .sel(sel), .clk(clk));
    MAC MAC3 (.MAC_out(C3), .A(A), .B(B3), .sel(sel), .clk(clk));

    always @ (posedge clk) begin
        if (!rstn) begin
            cnt <= 16'h0;
        end
        else begin
            if (start) begin
                done <= 1'b0;
                cnt <= 16'b0;
            end
            else if (cnt == 16'hFFFF) begin
                done <= 1'b1;
                cnt <= cnt + 1;
            end
            else begin
                done <= 1'b0;
                cnt <= cnt + 1;
            end
        end
    end

    always @ (*) begin
        if (cnt[5:0] >= 6'd2 && cnt[5:0] <= 6'd5) begin
            NWRT_C_tmp = 1'b0;
            NCE_C_tmp = 1'b0;
        end
        else begin
            NWRT_C_tmp = 1'b1;
            NCE_C_tmp = 1'b1;
        end
    end

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
            default: MAC_out_tmp <= 22'bx;
        endcase
    end
endmodule

