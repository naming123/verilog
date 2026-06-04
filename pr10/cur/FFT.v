module top_FFT (
    output reg [31:0] out,
    input  [31:0] in,
    input  clk, rstn
);

    // =====================
    // Counter
    // =====================
    reg [3:0] cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) cnt <= 0;
        else       cnt <= cnt + 1;
    end

    wire sel1 = cnt[2];
    wire sel2 = cnt[1];
    wire sel3 = cnt[0];

    // =====================
    // W8 twiddle counter
    // =====================
    reg [1:0] tw1_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)     tw1_cnt <= 0;
        else if (sel1) tw1_cnt <= tw1_cnt + 1;
        else           tw1_cnt <= 0;
    end

    wire [31:0] tw1_T;
    assign tw1_T = (tw1_cnt == 2'd0) ? {16'h4000, 16'h0000} :
                   (tw1_cnt == 2'd1) ? {16'h2D41, 16'hD2BF} :
                   (tw1_cnt == 2'd2) ? {16'h0000, 16'hC000} :
                                       {16'hD2BF, 16'hD2BF} ;

    // =====================
    // W4 twiddle counter
    // =====================
    reg tw2_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)     tw2_cnt <= 0;
        else if (sel2) tw2_cnt <= tw2_cnt + 1;
        else           tw2_cnt <= 0;
    end

    wire [31:0] tw2_T;
    assign tw2_T = tw2_cnt ? {16'h0000, 16'hC000} :
                              {16'h4000, 16'h0000} ;

    // =====================
    // STAGE 1: 4-DFF shift register
    // sel1=0: shift_reg <- in,     out = shift_reg[3]
    // sel1=1: shift_reg <- C2*W8,  out = C1
    // =====================
    reg [31:0] s1r0, s1r1, s1r2, s1r3;

    wire [31:0] bfu1_C1, bfu1_C2;
    butterfly_unit BFU1 (.C1(bfu1_C1), .C2(bfu1_C2), .A(s1r3), .B(in));

    wire [31:0] cm1_out;
    complex_multiplier CM1 (.O(cm1_out), .C(bfu1_C2), .T(tw1_T));

    wire [31:0] s1_out    = sel1 ? bfu1_C1 : s1r3;
    wire [31:0] s1_reg_in = sel1 ? cm1_out : in;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s1r0 <= 0; s1r1 <= 0; s1r2 <= 0; s1r3 <= 0;
        end else begin
            s1r0 <= s1_reg_in;
            s1r1 <= s1r0;
            s1r2 <= s1r1;
            s1r3 <= s1r2;
        end
    end

    // =====================
    // STAGE 2: 2-DFF shift register
    // sel2=0: shift_reg <- s1_out,  out = shift_reg[1]
    // sel2=1: shift_reg <- C2*W4,   out = C1
    // =====================
    reg [31:0] s2r0, s2r1;

    wire [31:0] bfu2_C1, bfu2_C2;
    butterfly_unit BFU2 (.C1(bfu2_C1), .C2(bfu2_C2), .A(s2r1), .B(s1_out));

    wire [31:0] cm2_out;
    complex_multiplier CM2 (.O(cm2_out), .C(bfu2_C2), .T(tw2_T));

    wire [31:0] s2_out    = sel2 ? bfu2_C1 : s2r1;
    wire [31:0] s2_reg_in = sel2 ? cm2_out : s1_out;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s2r0 <= 0; s2r1 <= 0;
        end else begin
            s2r0 <= s2_reg_in;
            s2r1 <= s2r0;
        end
    end

    // =====================
    // STAGE 3: 1-DFF shift register (no twiddle)
    // sel3=0: shift_reg <- s2_out,  out = shift_reg[0]
    // sel3=1: shift_reg <- C2,      out = C1
    // =====================
    reg [31:0] s3r0;

    wire [31:0] bfu3_C1, bfu3_C2;
    butterfly_unit BFU3 (.C1(bfu3_C1), .C2(bfu3_C2), .A(s3r0), .B(s2_out));

    wire [31:0] s3_out    = sel3 ? bfu3_C1 : s3r0;
    wire [31:0] s3_reg_in = sel3 ? bfu3_C2 : s2_out;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) s3r0 <= 0;
        else       s3r0 <= s3_reg_in;
    end

    reg [31:0] out_r1, out_r2, out_r3;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            out_r1 <= 0; out_r2 <= 0; out_r3 <= 0; out <= 0;
        end else begin
            out_r1 <= s3_out;
            out_r2 <= out_r1;
            out_r3 <= out_r2;
            out    <= out_r3;
        end
    end

endmodule