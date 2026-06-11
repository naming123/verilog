module TPmem_16x16
#( parameter BW = 8 )

(  input        [16*BW-1:0]	i_data,
   input	   	            i_enable,
   input 	   	            i_clk,
   input	   	            i_Reset,
   output reg   [16*BW-1:0] o_data,
   output reg	            o_en
);

reg [5-1:0]         counter;
reg [16*BW-1:0]     array   [16-1:0];
reg [16*BW-1:0]     data_out;

wire [16*BW-1:0]    col     [16-1:0];
wire [4-1:0]        index = counter[4-1:0] ;

wire [16*BW-1:0]    w_data;
wire	            w_en;

always@(posedge i_clk) begin
    if(~i_Reset) begin
    counter <= 5'b0;
    o_data  <= {BW{16'b0}};
    o_en    <= 1'b0; 
    end
    else    begin
	o_data  <= w_data ;
	o_en    <= w_en ;
        if(i_enable) 
        counter     <= counter + 5'b1;
        else begin    
            if(counter[4]==1'b1)
	    counter     <= counter + 5'b1;
    	    else    
    	    counter <= counter ;
    	    end
    end
end

always@(posedge i_clk) begin
    if(~i_Reset) begin
	array[15] <= {BW{16'b0}};
	array[14] <= {BW{16'b0}};
	array[13] <= {BW{16'b0}};
	array[12] <= {BW{16'b0}};
	array[11] <= {BW{16'b0}};
	array[10] <= {BW{16'b0}};
	array[ 9] <= {BW{16'b0}};
	array[ 8] <= {BW{16'b0}};
	array[ 7] <= {BW{16'b0}};
	array[ 6] <= {BW{16'b0}};
	array[ 5] <= {BW{16'b0}};
	array[ 4] <= {BW{16'b0}};
	array[ 3] <= {BW{16'b0}};
	array[ 2] <= {BW{16'b0}};
	array[ 1] <= {BW{16'b0}};
	array[ 0] <= {BW{16'b0}};
    end
    else    begin
	if(i_enable) begin
	array[index] <= i_data ;
	end
    end
end

assign col[ 0] = {{array[0][16*BW-1:15*BW]},{array[1][16*BW-1:15*BW]},{array[2][16*BW-1:15*BW]},{array[3][16*BW-1:15*BW]},{array[4][16*BW-1:15*BW]},{array[5][16*BW-1:15*BW]},{array[6][16*BW-1:15*BW]},{array[7][16*BW-1:15*BW]},{array[8][16*BW-1:15*BW]},{array[9][16*BW-1:15*BW]},{array[10][16*BW-1:15*BW]},{array[11][16*BW-1:15*BW]},{array[12][16*BW-1:15*BW]},{array[13][16*BW-1:15*BW]},{array[14][16*BW-1:15*BW]},{array[15][16*BW-1:15*BW]}} ; 
assign col[ 1] = {{array[0][15*BW-1:14*BW]},{array[1][15*BW-1:14*BW]},{array[2][15*BW-1:14*BW]},{array[3][15*BW-1:14*BW]},{array[4][15*BW-1:14*BW]},{array[5][15*BW-1:14*BW]},{array[6][15*BW-1:14*BW]},{array[7][15*BW-1:14*BW]},{array[8][15*BW-1:14*BW]},{array[9][15*BW-1:14*BW]},{array[10][15*BW-1:14*BW]},{array[11][15*BW-1:14*BW]},{array[12][15*BW-1:14*BW]},{array[13][15*BW-1:14*BW]},{array[14][15*BW-1:14*BW]},{array[15][15*BW-1:14*BW]}} ; 
assign col[ 2] = {{array[0][14*BW-1:13*BW]},{array[1][14*BW-1:13*BW]},{array[2][14*BW-1:13*BW]},{array[3][14*BW-1:13*BW]},{array[4][14*BW-1:13*BW]},{array[5][14*BW-1:13*BW]},{array[6][14*BW-1:13*BW]},{array[7][14*BW-1:13*BW]},{array[8][14*BW-1:13*BW]},{array[9][14*BW-1:13*BW]},{array[10][14*BW-1:13*BW]},{array[11][14*BW-1:13*BW]},{array[12][14*BW-1:13*BW]},{array[13][14*BW-1:13*BW]},{array[14][14*BW-1:13*BW]},{array[15][14*BW-1:13*BW]}} ; 
assign col[ 3] = {{array[0][13*BW-1:12*BW]},{array[1][13*BW-1:12*BW]},{array[2][13*BW-1:12*BW]},{array[3][13*BW-1:12*BW]},{array[4][13*BW-1:12*BW]},{array[5][13*BW-1:12*BW]},{array[6][13*BW-1:12*BW]},{array[7][13*BW-1:12*BW]},{array[8][13*BW-1:12*BW]},{array[9][13*BW-1:12*BW]},{array[10][13*BW-1:12*BW]},{array[11][13*BW-1:12*BW]},{array[12][13*BW-1:12*BW]},{array[13][13*BW-1:12*BW]},{array[14][13*BW-1:12*BW]},{array[15][13*BW-1:12*BW]}} ; 
assign col[ 4] = {{array[0][12*BW-1:11*BW]},{array[1][12*BW-1:11*BW]},{array[2][12*BW-1:11*BW]},{array[3][12*BW-1:11*BW]},{array[4][12*BW-1:11*BW]},{array[5][12*BW-1:11*BW]},{array[6][12*BW-1:11*BW]},{array[7][12*BW-1:11*BW]},{array[8][12*BW-1:11*BW]},{array[9][12*BW-1:11*BW]},{array[10][12*BW-1:11*BW]},{array[11][12*BW-1:11*BW]},{array[12][12*BW-1:11*BW]},{array[13][12*BW-1:11*BW]},{array[14][12*BW-1:11*BW]},{array[15][12*BW-1:11*BW]}} ; 
assign col[ 5] = {{array[0][11*BW-1:10*BW]},{array[1][11*BW-1:10*BW]},{array[2][11*BW-1:10*BW]},{array[3][11*BW-1:10*BW]},{array[4][11*BW-1:10*BW]},{array[5][11*BW-1:10*BW]},{array[6][11*BW-1:10*BW]},{array[7][11*BW-1:10*BW]},{array[8][11*BW-1:10*BW]},{array[9][11*BW-1:10*BW]},{array[10][11*BW-1:10*BW]},{array[11][11*BW-1:10*BW]},{array[12][11*BW-1:10*BW]},{array[13][11*BW-1:10*BW]},{array[14][11*BW-1:10*BW]},{array[15][11*BW-1:10*BW]}} ; 
assign col[ 6] = {{array[0][10*BW-1: 9*BW]},{array[1][10*BW-1: 9*BW]},{array[2][10*BW-1: 9*BW]},{array[3][10*BW-1: 9*BW]},{array[4][10*BW-1: 9*BW]},{array[5][10*BW-1: 9*BW]},{array[6][10*BW-1: 9*BW]},{array[7][10*BW-1: 9*BW]},{array[8][10*BW-1: 9*BW]},{array[9][10*BW-1: 9*BW]},{array[10][10*BW-1: 9*BW]},{array[11][10*BW-1: 9*BW]},{array[12][10*BW-1: 9*BW]},{array[13][10*BW-1: 9*BW]},{array[14][10*BW-1: 9*BW]},{array[15][10*BW-1: 9*BW]}} ;
assign col[ 7] = {{array[0][ 9*BW-1: 8*BW]},{array[1][ 9*BW-1: 8*BW]},{array[2][ 9*BW-1: 8*BW]},{array[3][ 9*BW-1: 8*BW]},{array[4][ 9*BW-1: 8*BW]},{array[5][ 9*BW-1: 8*BW]},{array[6][ 9*BW-1: 8*BW]},{array[7][ 9*BW-1: 8*BW]},{array[8][ 9*BW-1: 8*BW]},{array[9][ 9*BW-1: 8*BW]},{array[10][ 9*BW-1: 8*BW]},{array[11][ 9*BW-1: 8*BW]},{array[12][ 9*BW-1: 8*BW]},{array[13][ 9*BW-1: 8*BW]},{array[14][ 9*BW-1: 8*BW]},{array[15][ 9*BW-1: 8*BW]}} ;
assign col[ 8] = {{array[0][ 8*BW-1: 7*BW]},{array[1][ 8*BW-1: 7*BW]},{array[2][ 8*BW-1: 7*BW]},{array[3][ 8*BW-1: 7*BW]},{array[4][ 8*BW-1: 7*BW]},{array[5][ 8*BW-1: 7*BW]},{array[6][ 8*BW-1: 7*BW]},{array[7][ 8*BW-1: 7*BW]},{array[8][ 8*BW-1: 7*BW]},{array[9][ 8*BW-1: 7*BW]},{array[10][ 8*BW-1: 7*BW]},{array[11][ 8*BW-1: 7*BW]},{array[12][ 8*BW-1: 7*BW]},{array[13][ 8*BW-1: 7*BW]},{array[14][ 8*BW-1: 7*BW]},{array[15][ 8*BW-1: 7*BW]}} ; 
assign col[ 9] = {{array[0][ 7*BW-1: 6*BW]},{array[1][ 7*BW-1: 6*BW]},{array[2][ 7*BW-1: 6*BW]},{array[3][ 7*BW-1: 6*BW]},{array[4][ 7*BW-1: 6*BW]},{array[5][ 7*BW-1: 6*BW]},{array[6][ 7*BW-1: 6*BW]},{array[7][ 7*BW-1: 6*BW]},{array[8][ 7*BW-1: 6*BW]},{array[9][ 7*BW-1: 6*BW]},{array[10][ 7*BW-1: 6*BW]},{array[11][ 7*BW-1: 6*BW]},{array[12][ 7*BW-1: 6*BW]},{array[13][ 7*BW-1: 6*BW]},{array[14][ 7*BW-1: 6*BW]},{array[15][ 7*BW-1: 6*BW]}} ; 
assign col[10] = {{array[0][ 6*BW-1: 5*BW]},{array[1][ 6*BW-1: 5*BW]},{array[2][ 6*BW-1: 5*BW]},{array[3][ 6*BW-1: 5*BW]},{array[4][ 6*BW-1: 5*BW]},{array[5][ 6*BW-1: 5*BW]},{array[6][ 6*BW-1: 5*BW]},{array[7][ 6*BW-1: 5*BW]},{array[8][ 6*BW-1: 5*BW]},{array[9][ 6*BW-1: 5*BW]},{array[10][ 6*BW-1: 5*BW]},{array[11][ 6*BW-1: 5*BW]},{array[12][ 6*BW-1: 5*BW]},{array[13][ 6*BW-1: 5*BW]},{array[14][ 6*BW-1: 5*BW]},{array[15][ 6*BW-1: 5*BW]}} ; 
assign col[11] = {{array[0][ 5*BW-1: 4*BW]},{array[1][ 5*BW-1: 4*BW]},{array[2][ 5*BW-1: 4*BW]},{array[3][ 5*BW-1: 4*BW]},{array[4][ 5*BW-1: 4*BW]},{array[5][ 5*BW-1: 4*BW]},{array[6][ 5*BW-1: 4*BW]},{array[7][ 5*BW-1: 4*BW]},{array[8][ 5*BW-1: 4*BW]},{array[9][ 5*BW-1: 4*BW]},{array[10][ 5*BW-1: 4*BW]},{array[11][ 5*BW-1: 4*BW]},{array[12][ 5*BW-1: 4*BW]},{array[13][ 5*BW-1: 4*BW]},{array[14][ 5*BW-1: 4*BW]},{array[15][ 5*BW-1: 4*BW]}} ; 
assign col[12] = {{array[0][ 4*BW-1: 3*BW]},{array[1][ 4*BW-1: 3*BW]},{array[2][ 4*BW-1: 3*BW]},{array[3][ 4*BW-1: 3*BW]},{array[4][ 4*BW-1: 3*BW]},{array[5][ 4*BW-1: 3*BW]},{array[6][ 4*BW-1: 3*BW]},{array[7][ 4*BW-1: 3*BW]},{array[8][ 4*BW-1: 3*BW]},{array[9][ 4*BW-1: 3*BW]},{array[10][ 4*BW-1: 3*BW]},{array[11][ 4*BW-1: 3*BW]},{array[12][ 4*BW-1: 3*BW]},{array[13][ 4*BW-1: 3*BW]},{array[14][ 4*BW-1: 3*BW]},{array[15][ 4*BW-1: 3*BW]}} ; 
assign col[13] = {{array[0][ 3*BW-1: 2*BW]},{array[1][ 3*BW-1: 2*BW]},{array[2][ 3*BW-1: 2*BW]},{array[3][ 3*BW-1: 2*BW]},{array[4][ 3*BW-1: 2*BW]},{array[5][ 3*BW-1: 2*BW]},{array[6][ 3*BW-1: 2*BW]},{array[7][ 3*BW-1: 2*BW]},{array[8][ 3*BW-1: 2*BW]},{array[9][ 3*BW-1: 2*BW]},{array[10][ 3*BW-1: 2*BW]},{array[11][ 3*BW-1: 2*BW]},{array[12][ 3*BW-1: 2*BW]},{array[13][ 3*BW-1: 2*BW]},{array[14][ 3*BW-1: 2*BW]},{array[15][ 3*BW-1: 2*BW]}} ; 
assign col[14] = {{array[0][ 2*BW-1: 1*BW]},{array[1][ 2*BW-1: 1*BW]},{array[2][ 2*BW-1: 1*BW]},{array[3][ 2*BW-1: 1*BW]},{array[4][ 2*BW-1: 1*BW]},{array[5][ 2*BW-1: 1*BW]},{array[6][ 2*BW-1: 1*BW]},{array[7][ 2*BW-1: 1*BW]},{array[8][ 2*BW-1: 1*BW]},{array[9][ 2*BW-1: 1*BW]},{array[10][ 2*BW-1: 1*BW]},{array[11][ 2*BW-1: 1*BW]},{array[12][ 2*BW-1: 1*BW]},{array[13][ 2*BW-1: 1*BW]},{array[14][ 2*BW-1: 1*BW]},{array[15][ 2*BW-1: 1*BW]}} ;
assign col[15] = {{array[0][ 1*BW-1: 0*BW]},{array[1][ 1*BW-1: 0*BW]},{array[2][ 1*BW-1: 0*BW]},{array[3][ 1*BW-1: 0*BW]},{array[4][ 1*BW-1: 0*BW]},{array[5][ 1*BW-1: 0*BW]},{array[6][ 1*BW-1: 0*BW]},{array[7][ 1*BW-1: 0*BW]},{array[8][ 1*BW-1: 0*BW]},{array[9][ 1*BW-1: 0*BW]},{array[10][ 1*BW-1: 0*BW]},{array[11][ 1*BW-1: 0*BW]},{array[12][ 1*BW-1: 0*BW]},{array[13][ 1*BW-1: 0*BW]},{array[14][ 1*BW-1: 0*BW]},{array[15][ 1*BW-1: 0*BW]}} ;

always@(*) begin
    if(counter[4]==1'b1) begin
    data_out = col[index] ;
    end
    else    begin
    data_out = {BW{16'b0}}; 
    end
end

assign w_en = counter[4] ;
assign w_data = data_out ; 

endmodule
