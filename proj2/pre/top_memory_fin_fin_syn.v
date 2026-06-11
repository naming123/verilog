module top_memory_fin_fin_syn (
	output [96-1:0] DCT_out,
	input [64-1:0] DCT_in,
	input clk, reset
);

	wire [16-1:0] addr_in, addr_out;

	// SRAM32768x64 MEM_IN (.NWRT(1'b1), .DIN(), .RA(addr_in[14:4]), .CA(addr_in[3:0]), .NCE(!reset), .CK(clk), .DO(DCT_in));
	// SRAM32768x96 MEM_OUT (.NWRT(1'b0), .DIN(DCT_out), .RA(addr_out[14:4]), .CA(addr_out[3:0]), .NCE(!reset), .CK(clk), .DO());

	// Counter
	reg [16-1:0] cnt;

	assign addr_in = cnt;
	assign addr_out = cnt - 5'd22;

	always @ (posedge clk) begin
		if (!reset) begin
			cnt <= 16'b0;
		end
		else begin
			cnt <= cnt + 1;
		end
	end

	// Input DFF
	wire [64-1:0] DCT_in_d;

	DFF_64 DFF_IN (.q(DCT_in_d), .d(DCT_in), .clk(clk), .reset(reset));

	// DCT_row
	wire [72-1:0] DCT_row_out;

	DCT_row DCT_row (.out(DCT_row_out), .in(DCT_in_d));

	// TPmem
	wire [72-1:0] DCT_col_in, DCT_col_in_d;

	TPmem_lowest_1 TP1 (.i_data(DCT_row_out), .clk(clk), .reset(reset), .o_data(DCT_col_in));

	// DCT_col
	wire [72-1:0] DCT_col_out;

	DFF_72 DFF_inter (.q(DCT_col_in_d), .d(DCT_col_in), .clk(clk), .reset(reset));
	DCT_col DCT_col (.out(DCT_col_out), .in(DCT_col_in_d), .dc(cnt[2:0]));

	// TPmem
	wire [72-1:0] TPmem2_out;
	wire [96-1:0] DCT_out_tmp;

	TPmem_lowest_2 TP2 (.i_data(DCT_col_out), .clk(clk), .reset(reset), .o_data(TPmem2_out));
	assign DCT_out_tmp = {TPmem2_out, 24'b0};

	// Output DFF
	DFF_96 DFF_OUT (.q(DCT_out), .d(DCT_out_tmp), .clk(clk), .reset(reset));

endmodule

module DCT_row (
	output [72-1:0] out,
	input [64-1:0] in
);
	
	wire signed [9-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
	wire signed [20-1:0] z0, z1, z2, z3, z4, z5, z6;
	wire signed [10-1:0] add0, add1, add2, add3, sub0, sub1, sub2, sub3;
	wire signed [11-1:0] p03, p12, m03, m12, sum01, sub13, sub02, sub23;
	wire signed [12-1:0] pp, mm, pm1, pm2, pm3;

	assign x0 = {1'b0, in[63:56]}; //(9.0)
	assign x1 = {1'b0, in[55:48]};
	assign x2 = {1'b0, in[47:40]};
	assign x3 = {1'b0, in[39:32]};
	assign x4 = {1'b0, in[31:24]};
	assign x5 = {1'b0, in[23:16]};
	assign x6 = {1'b0, in[15:8]};
	assign x7 = {1'b0, in[7:0]};
	
	assign add0 = x0 + x7;
	assign add1 = x1 + x6;
	assign add2 = x2 + x5;
	assign add3 = x3 + x4;
	assign sub0 = x0 - x7;
	assign sub1 = x1 - x6;
	assign sub2 = x2 - x5;
	assign sub3 = x3 - x4;

	assign p03 = add0 + add3;
	assign p12 = add1 + add2;
	assign m03 = add0 - add3;
	assign m12 = add1 - add2;

	assign pp = p03 + p12;
	assign mm = p03 - p12;

	assign sum01 = sub0 + sub1;
	assign sub13 = sub1 - sub3;
	assign sub02 = sub0 - sub2;
	assign sub23 = sub2 - sub3;

	assign pm1 = sub1 + sub2 - sub3;
	assign pm2 = sub0 + sub1 - sub3;
	assign pm3 = sub0 - sub2 + sub3;

	assign z0 = (pp << 6) - (pp << 4) - (pp << 2) + pp;
	assign z4 = (mm << 6) - (mm << 4) - (mm << 2)/* + mm*/;
	assign z2 = (m03 << 6) + (m12 << 5) - (m12 << 3) - (m03 << 2)/* - (m03)*/;
	assign z1 = (sum01 << 6) + (sub2 << 5) - (sub13 << 4) + ((sub1 + sub2 - sub3) << 2)/* - (sub0 - sub1)*/;
	assign z3 = (sub02 << 6) - (sub3 << 5) - (sum01 << 4) + ((sub0 + sub1 - sub3) << 2)/* + (sub0 + sub2)*/;
	assign z5 = - (sub13 << 6) + (sub0 << 5) + (sub23 << 4) + ((sub0 - sub2 + sub3) << 2)/* + (sub1 + sub2)*/;
	
	assign out = {z0[17:9] + z0[8], z1[17:9], z2[17:9], z3[17:9], z4[17:9], z5[17:9], 9'b0, 9'b0};

endmodule

module DCT_col (
	output reg [72-1:0] out,
    input [72-1:0] in,
    input [3-1:0] dc
);
   
	wire signed [9-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
    wire signed [21-1:0] z0, z1, z2, z3, z4, z5;
	wire signed [10-1:0] add0, add1, add2, add3, sub0, sub1, sub2, sub3;
	wire signed [11-1:0] p03, p12, m03, m12, sum01, sub13, sub02, sub23;
	wire signed [12-1:0] pp, mm, pm1, pm2, pm3;
	wire [72-1:0] out0, out1, out2, out3, out4, out5;
 
    assign x0 = in[71:63];
    assign x1 = in[62:54];
    assign x2 = in[53:45];
    assign x3 = in[44:36];
    assign x4 = in[35:27];
    assign x5 = in[26:18];
    assign x6 = in[17:9];
    assign x7 = in[8:0];

	assign add0 = x0 + x7;
	assign add1 = x1 + x6;
	assign add2 = x2 + x5;
	assign add3 = x3 + x4;
	assign sub0 = x0 - x7;
	assign sub1 = x1 - x6;
	assign sub2 = x2 - x5;
	assign sub3 = x3 - x4;

	assign p03 = add0 + add3;
	assign p12 = add1 + add2;
	assign m03 = add0 - add3;
	assign m12 = add1 - add2;

	assign pp = p03 + p12;
	assign mm = p03 - p12;

	assign sum01 = sub0 + sub1;
	assign sub13 = sub1 - sub3;
	assign sub02 = sub0 - sub2;
	assign sub23 = sub2 - sub3;

	assign pm1 = sub1 + sub2 - sub3;
	assign pm2 = sub0 + sub1 - sub3;
	assign pm3 = sub0 - sub2 + sub3;

	assign z0 = pp - (pp << 2) - (pp << 4) + (pp << 6);
	assign z4 = /*(p03 - p12) */- (mm << 2) - (mm << 4) + (mm << 6);
	assign z2 = /*- (m03) */- (m03 << 2) + (m03 << 6) - (m12 << 3) + (m12 << 5);

	assign z1 = (sum01 << 6) + (sub2 << 5) - (sub13 << 4) + (pm1 << 2)/* - (sub0 - sub1)*/;
	assign z3 = (sub02 << 6) - (sub3 << 5) - (sum01 << 4) + (pm2 << 2)/* + (sub0 + sub2)*/;
	assign z5 = - (sub13 << 6) + (sub0 << 5) + (sub23 << 4) + (pm3 << 2)/* + (sub1 + sub2)*/;

	wire signed [12-1:0] g0, g1;

	Glitch G0_col (.out(g0), .in(z0[15:3]));
	Glitch G1_col (.out(g1), .in(z1[15:3]));

	assign out0 = {z0[16:5], g1, z2[14:3]+z2[2], z3[14:3]+z3[2], z4[14:3]+z4[2], z5[14:3]+z5[2]};
	assign out1 = {g0, g1, z2[14:3]+z2[2], z3[14:3]+z3[2], z4[14:3]+z4[2], z5[14:3]+z5[2]};
	assign out2 = {g0, g1, z2[14:3]+z2[2], z3[14:3]+z3[2], z4[14:3]+z4[2], z5[14:3]+z5[2]};
	assign out3 = {g0, g1, z2[14:3]+z2[2], z3[14:3]+z3[2], z4[14:3]+z4[2], z5[14:3]+z5[2]};
	assign out4 = {g0, g1, z2[14:3]+z2[2], z3[14:3]+z3[2], z4[14:3]+z4[2], 12'b0};
	assign out5 = {g0, g1, 12'b0, 12'b0, 12'b0, 12'b0};

	always @ (*) begin
		case (dc)
			3'd4 : out = out0; 
			3'd5 : out = out1; 
			3'd6 : out = out2; 
			3'd7 : out = out3; 
			3'd0 : out = out4; 
			3'd1 : out = out5; 
			3'd2 : out = 72'b0; 
			3'd3 : out = 72'b0; 
			default : out = 72'b0; 
		endcase
	end

endmodule

module Glitch (
	output signed [12-1:0] out,
	input signed [13-1:0] in
);

	assign out = (in >= 2048) ? 12'b0111_1111_1111 : ((in < -2048) ? 12'b1000_0000_0000 : in[11:0]);

endmodule

module DFF_64 (
	output reg [64-1:0] q,
	input [64-1:0] d,
	input clk, reset
);

	always @ (posedge clk) begin
		if (!reset) begin
			q <= 64'b0;
		end
		else begin
			q <= d;
		end
	end

endmodule

module DFF_72 (
	output reg [72-1:0] q,
	input [72-1:0] d,
	input clk, reset
);

	always @ (posedge clk) begin
		if (!reset) begin
			q <= 72'b0;
		end
		else begin
			q <= d;
		end
	end

endmodule

module DFF_96 (
	output reg [96-1:0] q,
	input [96-1:0] d,
	input clk, reset
);

	always @ (posedge clk) begin
		if (!reset) begin
			q <= 96'b0;
		end
		else begin
			q <= d;
		end
	end

endmodule

module TPmem_lowest_1
#( parameter BW = 9 )

(  input [8*BW-1:0] i_data,
   input clk, reset,
   output reg [8*BW-1:0] o_data
);

reg [4-1:0] cnt;
reg [8*BW-1:0] array [8-1:0];
reg [8*BW-1:0] data_out;

wire [8*BW-1:0] col [8-1:0];
wire [3-1:0] index = cnt[2:0];

always @ (posedge clk) begin
    if(!reset) begin
    	cnt <= 4'd14;
        o_data <= 0;
    end
    else begin
    	cnt <= cnt + 4'b1;
        o_data <= data_out;
    end
end

always @ (*) begin 
    if (cnt[3] == 1'b1) begin
        data_out = col[index]; 
    end
    else begin
        data_out = array[index];
    end
end

always @ (posedge clk) begin
    if(!reset) begin
		array[7] <= {BW{8'b0}};
    	array[6] <= {BW{8'b0}};
    	array[5] <= {BW{8'b0}};
    	array[4] <= {BW{8'b0}};
    	array[3] <= {BW{8'b0}};
    	array[2] <= {BW{8'b0}};
    	array[1] <= {BW{8'b0}};
    	array[0] <= {BW{8'b0}};
    end
    else begin
        if (cnt[3] == 1'b0) begin
            array[index] <= i_data;
        end
        else begin
            case(index)
            3'b000 : begin
                array[0][8*BW-1:7*BW] <= i_data[8*BW-1:7*BW];
                array[1][8*BW-1:7*BW] <= i_data[7*BW-1:6*BW];
                array[2][8*BW-1:7*BW] <= i_data[6*BW-1:5*BW];
                array[3][8*BW-1:7*BW] <= i_data[5*BW-1:4*BW];
                array[4][8*BW-1:7*BW] <= i_data[4*BW-1:3*BW];
                array[5][8*BW-1:7*BW] <= i_data[3*BW-1:2*BW];
                array[6][8*BW-1:7*BW] <= i_data[2*BW-1:1*BW];
                array[7][8*BW-1:7*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b001 : begin
                array[0][7*BW-1:6*BW] <= i_data[8*BW-1:7*BW];
                array[1][7*BW-1:6*BW] <= i_data[7*BW-1:6*BW];
                array[2][7*BW-1:6*BW] <= i_data[6*BW-1:5*BW];
                array[3][7*BW-1:6*BW] <= i_data[5*BW-1:4*BW];
                array[4][7*BW-1:6*BW] <= i_data[4*BW-1:3*BW];
                array[5][7*BW-1:6*BW] <= i_data[3*BW-1:2*BW];
                array[6][7*BW-1:6*BW] <= i_data[2*BW-1:1*BW];
                array[7][7*BW-1:6*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b010 : begin
                array[0][6*BW-1:5*BW] <= i_data[8*BW-1:7*BW];
                array[1][6*BW-1:5*BW] <= i_data[7*BW-1:6*BW];
                array[2][6*BW-1:5*BW] <= i_data[6*BW-1:5*BW];
                array[3][6*BW-1:5*BW] <= i_data[5*BW-1:4*BW];
                array[4][6*BW-1:5*BW] <= i_data[4*BW-1:3*BW];
                array[5][6*BW-1:5*BW] <= i_data[3*BW-1:2*BW];
                array[6][6*BW-1:5*BW] <= i_data[2*BW-1:1*BW];
                array[7][6*BW-1:5*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b011 : begin
                array[0][5*BW-1:4*BW] <= i_data[8*BW-1:7*BW];
                array[1][5*BW-1:4*BW] <= i_data[7*BW-1:6*BW];
                array[2][5*BW-1:4*BW] <= i_data[6*BW-1:5*BW];
                array[3][5*BW-1:4*BW] <= i_data[5*BW-1:4*BW];
                array[4][5*BW-1:4*BW] <= i_data[4*BW-1:3*BW];
                array[5][5*BW-1:4*BW] <= i_data[3*BW-1:2*BW];
                array[6][5*BW-1:4*BW] <= i_data[2*BW-1:1*BW];
                array[7][5*BW-1:4*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b100 : begin
                array[0][4*BW-1:3*BW] <= i_data[8*BW-1:7*BW];
                array[1][4*BW-1:3*BW] <= i_data[7*BW-1:6*BW];
                array[2][4*BW-1:3*BW] <= i_data[6*BW-1:5*BW];
                array[3][4*BW-1:3*BW] <= i_data[5*BW-1:4*BW];
                array[4][4*BW-1:3*BW] <= i_data[4*BW-1:3*BW];
                array[5][4*BW-1:3*BW] <= i_data[3*BW-1:2*BW];
                array[6][4*BW-1:3*BW] <= i_data[2*BW-1:1*BW];
                array[7][4*BW-1:3*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b101 : begin
                array[0][3*BW-1:2*BW] <= i_data[8*BW-1:7*BW];
                array[1][3*BW-1:2*BW] <= i_data[7*BW-1:6*BW];
                array[2][3*BW-1:2*BW] <= i_data[6*BW-1:5*BW];
                array[3][3*BW-1:2*BW] <= i_data[5*BW-1:4*BW];
                array[4][3*BW-1:2*BW] <= i_data[4*BW-1:3*BW];
                array[5][3*BW-1:2*BW] <= i_data[3*BW-1:2*BW];
                array[6][3*BW-1:2*BW] <= i_data[2*BW-1:1*BW];
                array[7][3*BW-1:2*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b110 : begin
                array[0][2*BW-1:1*BW] <= i_data[8*BW-1:7*BW];
                array[1][2*BW-1:1*BW] <= i_data[7*BW-1:6*BW];
                array[2][2*BW-1:1*BW] <= i_data[6*BW-1:5*BW];
                array[3][2*BW-1:1*BW] <= i_data[5*BW-1:4*BW];
                array[4][2*BW-1:1*BW] <= i_data[4*BW-1:3*BW];
                array[5][2*BW-1:1*BW] <= i_data[3*BW-1:2*BW];
                array[6][2*BW-1:1*BW] <= i_data[2*BW-1:1*BW];
                array[7][2*BW-1:1*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b111 : begin
                array[0][1*BW-1:0*BW] <= i_data[8*BW-1:7*BW];
                array[1][1*BW-1:0*BW] <= i_data[7*BW-1:6*BW];
                array[2][1*BW-1:0*BW] <= i_data[6*BW-1:5*BW];
                array[3][1*BW-1:0*BW] <= i_data[5*BW-1:4*BW];
                array[4][1*BW-1:0*BW] <= i_data[4*BW-1:3*BW];
                array[5][1*BW-1:0*BW] <= i_data[3*BW-1:2*BW];
                array[6][1*BW-1:0*BW] <= i_data[2*BW-1:1*BW];
                array[7][1*BW-1:0*BW] <= i_data[1*BW-1:0*BW];
            end
            endcase
        end
    end
end


assign col[0] = {{array[0][8*BW-1:7*BW]},{array[1][8*BW-1:7*BW]},{array[2][8*BW-1:7*BW]},{array[3][8*BW-1:7*BW]},{array[4][8*BW-1:7*BW]},{array[5][8*BW-1:7*BW]},{array[6][8*BW-1:7*BW]},{array[7][8*BW-1:7*BW]}}; 
assign col[1] = {{array[0][7*BW-1:6*BW]},{array[1][7*BW-1:6*BW]},{array[2][7*BW-1:6*BW]},{array[3][7*BW-1:6*BW]},{array[4][7*BW-1:6*BW]},{array[5][7*BW-1:6*BW]},{array[6][7*BW-1:6*BW]},{array[7][7*BW-1:6*BW]}}; 
assign col[2] = {{array[0][6*BW-1:5*BW]},{array[1][6*BW-1:5*BW]},{array[2][6*BW-1:5*BW]},{array[3][6*BW-1:5*BW]},{array[4][6*BW-1:5*BW]},{array[5][6*BW-1:5*BW]},{array[6][6*BW-1:5*BW]},{array[7][6*BW-1:5*BW]}}; 
assign col[3] = {{array[0][5*BW-1:4*BW]},{array[1][5*BW-1:4*BW]},{array[2][5*BW-1:4*BW]},{array[3][5*BW-1:4*BW]},{array[4][5*BW-1:4*BW]},{array[5][5*BW-1:4*BW]},{array[6][5*BW-1:4*BW]},{array[7][5*BW-1:4*BW]}}; 
assign col[4] = {{array[0][4*BW-1:3*BW]},{array[1][4*BW-1:3*BW]},{array[2][4*BW-1:3*BW]},{array[3][4*BW-1:3*BW]},{array[4][4*BW-1:3*BW]},{array[5][4*BW-1:3*BW]},{array[6][4*BW-1:3*BW]},{array[7][4*BW-1:3*BW]}}; 
assign col[5] = {{array[0][3*BW-1:2*BW]},{array[1][3*BW-1:2*BW]},{array[2][3*BW-1:2*BW]},{array[3][3*BW-1:2*BW]},{array[4][3*BW-1:2*BW]},{array[5][3*BW-1:2*BW]},{array[6][3*BW-1:2*BW]},{array[7][3*BW-1:2*BW]}}; 
assign col[6] = {{array[0][2*BW-1:1*BW]},{array[1][2*BW-1:1*BW]},{array[2][2*BW-1:1*BW]},{array[3][2*BW-1:1*BW]},{array[4][2*BW-1:1*BW]},{array[5][2*BW-1:1*BW]},{array[6][2*BW-1:1*BW]},{array[7][2*BW-1:1*BW]}};
assign col[7] = {{array[0][1*BW-1:0*BW]},{array[1][1*BW-1:0*BW]},{array[2][1*BW-1:0*BW]},{array[3][1*BW-1:0*BW]},{array[4][1*BW-1:0*BW]},{array[5][1*BW-1:0*BW]},{array[6][1*BW-1:0*BW]},{array[7][1*BW-1:0*BW]}};

endmodule

module TPmem_lowest_2
#( parameter BW = 12 )

(  input [6*BW-1:0] i_data,
   input clk, reset,
   output reg [6*BW-1:0] o_data
);

reg [4-1:0] cnt;
reg [6*BW-1:0] array [6-1:0];
reg [6*BW-1:0] data_out;

wire [6*BW-1:0] col [6-1:0];
wire [3-1:0] index = cnt[2:0];

always @ (posedge clk) begin
    if(!reset) begin
    	cnt <= 4'd4;
        o_data <= 0;
    end
    else begin
    	cnt <= cnt + 4'b1;
        o_data <= data_out;
    end
end

always @ (*) begin 
    if (index >= 3'd6) begin
        data_out = {BW{6'b0}}; 
    end
    else if (cnt[3] == 1'b1) begin
        data_out = col[index];
    end
    else begin
        data_out = array[index];
    end
end

always @ (posedge clk) begin
    if(!reset) begin
    	array[5] <= {BW{6'b0}};
    	array[4] <= {BW{6'b0}};
    	array[3] <= {BW{6'b0}};
    	array[2] <= {BW{6'b0}};
    	array[1] <= {BW{6'b0}};
    	array[0] <= {BW{6'b0}};
    end
    else begin
        if (cnt[3] == 1'b0) begin
            array[index] <= i_data;
        end
        else begin
            case(index)
            3'b000 : begin
                array[0][6*BW-1:5*BW] <= i_data[6*BW-1:5*BW];
                array[1][6*BW-1:5*BW] <= i_data[5*BW-1:4*BW];
                array[2][6*BW-1:5*BW] <= i_data[4*BW-1:3*BW];
                array[3][6*BW-1:5*BW] <= i_data[3*BW-1:2*BW];
                array[4][6*BW-1:5*BW] <= i_data[2*BW-1:1*BW];
                array[5][6*BW-1:5*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b001 : begin
                array[0][5*BW-1:4*BW] <= i_data[6*BW-1:5*BW];
                array[1][5*BW-1:4*BW] <= i_data[5*BW-1:4*BW];
                array[2][5*BW-1:4*BW] <= i_data[4*BW-1:3*BW];
                array[3][5*BW-1:4*BW] <= i_data[3*BW-1:2*BW];
                array[4][5*BW-1:4*BW] <= i_data[2*BW-1:1*BW];
                array[5][5*BW-1:4*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b010 : begin
                array[0][4*BW-1:3*BW] <= i_data[6*BW-1:5*BW];
                array[1][4*BW-1:3*BW] <= i_data[5*BW-1:4*BW];
                array[2][4*BW-1:3*BW] <= i_data[4*BW-1:3*BW];
                array[3][4*BW-1:3*BW] <= i_data[3*BW-1:2*BW];
                array[4][4*BW-1:3*BW] <= i_data[2*BW-1:1*BW];
                array[5][4*BW-1:3*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b011 : begin
                array[0][3*BW-1:2*BW] <= i_data[6*BW-1:5*BW];
                array[1][3*BW-1:2*BW] <= i_data[5*BW-1:4*BW];
                array[2][3*BW-1:2*BW] <= i_data[4*BW-1:3*BW];
                array[3][3*BW-1:2*BW] <= i_data[3*BW-1:2*BW];
                array[4][3*BW-1:2*BW] <= i_data[2*BW-1:1*BW];
                array[5][3*BW-1:2*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b100 : begin
                array[0][2*BW-1:1*BW] <= i_data[6*BW-1:5*BW];
                array[1][2*BW-1:1*BW] <= i_data[5*BW-1:4*BW];
                array[2][2*BW-1:1*BW] <= i_data[4*BW-1:3*BW];
                array[3][2*BW-1:1*BW] <= i_data[3*BW-1:2*BW];
                array[4][2*BW-1:1*BW] <= i_data[2*BW-1:1*BW];
                array[5][2*BW-1:1*BW] <= i_data[1*BW-1:0*BW];
            end
            3'b101 : begin
                array[0][1*BW-1:0*BW] <= i_data[6*BW-1:5*BW];
                array[1][1*BW-1:0*BW] <= i_data[5*BW-1:4*BW];
                array[2][1*BW-1:0*BW] <= i_data[4*BW-1:3*BW];
                array[3][1*BW-1:0*BW] <= i_data[3*BW-1:2*BW];
                array[4][1*BW-1:0*BW] <= i_data[2*BW-1:1*BW];
                array[5][1*BW-1:0*BW] <= i_data[1*BW-1:0*BW];
            end
            endcase
        end
    end
end


assign col[0] = {{array[0][6*BW-1:5*BW]},{array[1][6*BW-1:5*BW]},{array[2][6*BW-1:5*BW]},{array[3][6*BW-1:5*BW]},{array[4][6*BW-1:5*BW]},{array[5][6*BW-1:5*BW]}}; 
assign col[1] = {{array[0][5*BW-1:4*BW]},{array[1][5*BW-1:4*BW]},{array[2][5*BW-1:4*BW]},{array[3][5*BW-1:4*BW]},{array[4][5*BW-1:4*BW]},{array[5][5*BW-1:4*BW]}}; 
assign col[2] = {{array[0][4*BW-1:3*BW]},{array[1][4*BW-1:3*BW]},{array[2][4*BW-1:3*BW]},{array[3][4*BW-1:3*BW]},{array[4][4*BW-1:3*BW]},{array[5][4*BW-1:3*BW]}}; 
assign col[3] = {{array[0][3*BW-1:2*BW]},{array[1][3*BW-1:2*BW]},{array[2][3*BW-1:2*BW]},{array[3][3*BW-1:2*BW]},{array[4][3*BW-1:2*BW]},{array[5][3*BW-1:2*BW]}}; 
assign col[4] = {{array[0][2*BW-1:1*BW]},{array[1][2*BW-1:1*BW]},{array[2][2*BW-1:1*BW]},{array[3][2*BW-1:1*BW]},{array[4][2*BW-1:1*BW]},{array[5][2*BW-1:1*BW]}}; 
assign col[5] = {{array[0][1*BW-1:0*BW]},{array[1][1*BW-1:0*BW]},{array[2][1*BW-1:0*BW]},{array[3][1*BW-1:0*BW]},{array[4][1*BW-1:0*BW]},{array[5][1*BW-1:0*BW]}}; 

endmodule