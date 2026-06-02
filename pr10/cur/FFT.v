module top_FFT (
    output reg [31:0] out,
    input  [31:0] in,
    input  clk, rstn
);

    // =====================
    // Global counter
    // =====================
    reg [3:0] cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) cnt <= 0;
        else       cnt <= cnt + 1;
    end

    // =====================
    // STAGE 1: 4-DFF shift register + butterfly + W8 twiddle
    // =====================
    reg [31:0] shift1_0, shift1_1, shift1_2, shift1_3;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shift1_0 <= 0; shift1_1 <= 0;
            shift1_2 <= 0; shift1_3 <= 0;
        end else begin
            shift1_0 <= in;
            shift1_1 <= shift1_0;
            shift1_2 <= shift1_1;
            shift1_3 <= shift1_2;
        end
    end

    // sel1: high when x[4..7] arriving (cnt[2] = 1)
    wire sel1 = cnt[2];

    wire [31:0] bfu1_C1, bfu1_C2;
    butterfly_unit BFU1 (
        .C1(bfu1_C1), .C2(bfu1_C2),
        .A(shift1_3), .B(in)
    );

    // W8 twiddle counter (counts 0~3 during sel1)
    reg [1:0] tw1_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) tw1_cnt <= 0;
        else if (sel1) tw1_cnt <= tw1_cnt + 1;
        else tw1_cnt <= 0;
    end

    wire [31:0] tw1_T;
    assign tw1_T = (tw1_cnt == 2'd0) ? {16'h4000, 16'h0000} :  // W8^0
                   (tw1_cnt == 2'd1) ? {16'h2D41, 16'hD2BF} :  // W8^1
                   (tw1_cnt == 2'd2) ? {16'h0000, 16'hC000} :  // W8^2
                                       {16'hD2BF, 16'hD2BF} ;  // W8^3

    wire [31:0] cm1_out;
    complex_multiplier CM1 (.O(cm1_out), .C(bfu1_C2), .T(tw1_T));

    // Stage1 outputs: g1=bfu1_C1, g2'=cm1_out (when sel1=1)
    // When sel1=0: pass shift1_3 to next stage
    wire [31:0] stage1_g1  = sel1 ? bfu1_C1 : shift1_3;
    wire [31:0] stage1_g2p = cm1_out; // only valid when sel1=1

    // =====================
    // STAGE 2: 2-DFF shift register + butterfly + W4 twiddle
    // Two parallel paths: g1 path (p1,p2) and g2' path (p3,p4)
    // =====================
    reg [31:0] shift2_g1_0, shift2_g1_1;
    reg [31:0] shift2_g2_0, shift2_g2_1;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shift2_g1_0 <= 0; shift2_g1_1 <= 0;
            shift2_g2_0 <= 0; shift2_g2_1 <= 0;
        end else begin
            shift2_g1_0 <= stage1_g1;
            shift2_g1_1 <= shift2_g1_0;
            shift2_g2_0 <= stage1_g2p;
            shift2_g2_1 <= shift2_g2_0;
        end
    end

    // sel2: butterfly active every other 2 cycles (cnt[1])
    wire sel2 = cnt[1];

    wire [31:0] bfu2_C1, bfu2_C2;
    butterfly_unit BFU2 (
        .C1(bfu2_C1), .C2(bfu2_C2),
        .A(shift2_g1_1), .B(stage1_g1)
    );

    wire [31:0] bfu3_C1, bfu3_C2;
    butterfly_unit BFU3 (
        .C1(bfu3_C1), .C2(bfu3_C2),
        .A(shift2_g2_1), .B(stage1_g2p)
    );

    // W4 twiddle
    reg tw2_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) tw2_cnt <= 0;
        else if (sel2) tw2_cnt <= tw2_cnt + 1;
        else tw2_cnt <= 0;
    end

    wire [31:0] tw2_T;
    assign tw2_T = tw2_cnt ? {16'h0000, 16'hC000} :  // W4^1
                              {16'h4000, 16'h0000} ;  // W4^0

    wire [31:0] cm2_out, cm3_out;
    complex_multiplier CM2 (.O(cm2_out), .C(bfu2_C2), .T(tw2_T));
    complex_multiplier CM3 (.O(cm3_out), .C(bfu3_C2), .T(tw2_T));

    // Stage2 outputs
    wire [31:0] stage2_p1  = sel2 ? bfu2_C1 : shift2_g1_1;
    wire [31:0] stage2_p2p = cm2_out;
    wire [31:0] stage2_p3  = sel2 ? bfu3_C1 : shift2_g2_1;
    wire [31:0] stage2_p4p = cm3_out;

    // =====================
    // STAGE 3: 1-DFF shift register + butterfly (no twiddle)
    // Two parallel paths
    // =====================
    reg [31:0] shift3_p1, shift3_p2, shift3_p3, shift3_p4;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shift3_p1 <= 0; shift3_p2 <= 0;
            shift3_p3 <= 0; shift3_p4 <= 0;
        end else begin
            shift3_p1 <= stage2_p1;
            shift3_p2 <= stage2_p2p;
            shift3_p3 <= stage2_p3;
            shift3_p4 <= stage2_p4p;
        end
    end

    wire sel3 = cnt[0];

    wire [31:0] bfu4_C1, bfu4_C2;
    wire [31:0] bfu5_C1, bfu5_C2;
    wire [31:0] bfu6_C1, bfu6_C2;
    wire [31:0] bfu7_C1, bfu7_C2;

    butterfly_unit BFU4 (.C1(bfu4_C1), .C2(bfu4_C2), .A(shift3_p1), .B(stage2_p1));
    butterfly_unit BFU5 (.C1(bfu5_C1), .C2(bfu5_C2), .A(shift3_p2), .B(stage2_p2p));
    butterfly_unit BFU6 (.C1(bfu6_C1), .C2(bfu6_C2), .A(shift3_p3), .B(stage2_p3));
    butterfly_unit BFU7 (.C1(bfu7_C1), .C2(bfu7_C2), .A(shift3_p4), .B(stage2_p4p));

    // Stage3 mux output
    // Output order: X[0],X[4],X[2],X[6],X[1],X[5],X[3],X[7]
    // X[0]=p1[0]+p1[1], X[4]=p1[0]-p1[1]  -> bfu4
    // X[2]=p2'[0]+p2'[1], X[6]=p2'[0]-p2'[1] -> bfu5
    // X[1]=p3[0]+p3[1], X[5]=p3[0]-p3[1]  -> bfu6
    // X[3]=p4'[0]+p4'[1], X[7]=p4'[0]-p4'[1] -> bfu7

    // Output MUX: rotate through 4 butterfly pairs, 2 outputs each
    reg [2:0] out_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) out_cnt <= 0;
        else out_cnt <= out_cnt + 1;
    end

    reg [31:0] out_reg;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) out_reg <= 0;
        else begin
            case (out_cnt[2:1])
                2'd0: out_reg <= out_cnt[0] ? bfu4_C2 : bfu4_C1;
                2'd1: out_reg <= out_cnt[0] ? bfu5_C2 : bfu5_C1;
                2'd2: out_reg <= out_cnt[0] ? bfu6_C2 : bfu6_C1;
                2'd3: out_reg <= out_cnt[0] ? bfu7_C2 : bfu7_C1;
            endcase
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) out <= 0;
        else out <= out_reg;
    end

endmodule