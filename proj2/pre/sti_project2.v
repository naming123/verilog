module sti_project2;

reg clk;
reg reset;

initial
begin
	clk <= 1;
	reset <= 0;
	#12
	reset <= 1;
end

always #5 clk <= ~clk;

top_memory_test_v7 TEST(clk,reset); // define input & output ports of your top module by youself 

initial	$readmemh("image_in_5.txt", TEST.MEM_IN.SRAM_syn.SRAM32768x64.Mem); //input image, check the path of memory location (module instance)

integer f;
integer i;
initial
begin
	f = $fopen("DCT_image_5.txt","w"); //output image, this is the output file that finished 2D-DCT operations.

	#327920; //change if you need

	for (i = 0; i<32768; i=i+1)
	begin
		//$display("DATA %b", TEST.MEM_OUT.SRAM_syn2.SRAM32768x96.Mem[i]); //check the path of memory location (module instance)
		$fwrite(f,"%b\n",   TEST.MEM_OUT.SRAM_syn2.SRAM32768x96.Mem[i]); //check the path of memory location (module instance)
	end
   
	#100
	$fclose(f);  
	$finish;
end


endmodule
