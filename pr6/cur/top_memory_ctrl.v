module top_memory_ctrl (
    output [44-1:0] out,
    input clk, rstn
);
    wire [7-1:0] RA;
    wire [3-1:0] CA;
    wire [44-1:0] memory_in, memory_out;
    wire NWRT, NCE;

    rflp1024x44mx3 memory(.DO(memory_out), .DIN(memory_in), .RA(RA), .CA(CA), .NWRT(NWRT), .NCE(NCE), .CLK(clk));

    reg [12-1:0] cnt;
    reg [22-1:0] Mul_a, Mul_b;
    wire [44-1:0] Mul_out;
    reg [44-1:0] memory_in_tmp;
    reg start;

    // ??: cnt ?? 10??
    assign RA = cnt[11:5];
    assign CA = cnt[4:2];
    assign memory_in = memory_in_tmp;

    // ??? ???:
    // cnt[1:0]=00: NCE=0, NWRT=1 ? Read ??
    // cnt[1:0]=01: NCE=0, NWRT=1 ? Data stable ? A,B ??
    // cnt[1:0]=10: NCE=0, NWRT=0 ? Write (product)
    // cnt[1:0]=11: NCE=1, NWRT=1 ? idle
    assign NWRT = ~(cnt[1] & ~cnt[0]);   // 10? ?? 0 (write)
    assign NCE  =  (cnt[1] &  cnt[0]);   // 11? ?? 1 (disabled)

    always @ (posedge clk) begin
        if (!rstn) begin
            start <= 1'b0;
            cnt   <= 12'b0;
        end
        else begin
            if (!start) begin
                cnt   <= 12'b0;
                start <= 1'b1;
            end
            else begin
                cnt <= cnt + 1;

                // cnt=01: memory_out? ??? ??? ??
                if (cnt[1:0] == 2'b01) begin
                    Mul_a <= memory_out[43:22];
                    Mul_b <= memory_out[21:0];
                end
                // cnt=10: ?? ??? write ??
                else if (cnt[1:0] == 2'b10) begin
                    memory_in_tmp <= Mul_out;
                end
            end
        end
    end

    assign Mul_out = Mul_a * Mul_b;
    assign out = memory_in_tmp;

endmodule