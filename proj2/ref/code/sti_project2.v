`timescale 1ns / 10ps
module sti_project2;

reg clk;
reg rstn;


Top top(clk, rstn); // define input & output ports of your top module by youself 


always #5 clk <= ~clk;

initial begin
	clk = 1; rstn = 0;
	#10
	rstn = 1;
end

initial	$readmemh("image_in_3.txt", top.MEM_IN.array); //input image, check the path of memory rocation (module instance)


integer i;
integer fp;

initial begin
	fp = $fopen("DCT_image_3.txt","w"); //output image, this is the output file that finished 2D-DCT operations.

	#164210; //change if you need

	for (i = 0; i<16384; i=i+1)	begin
		$display("DATA %b", top.MEM_OUT.array[i]); //check the path of memory rocation (module instance)
		$fwrite(fp,"%b\n", top.MEM_OUT.array[i]); //check the path of memory rocation (module instance)
	end
   
	#100
	$fclose(fp);  




	$finish;
end


endmodule
