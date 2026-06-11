  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%   Result of 2D - DCT Quantization Function  %%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Block_quant = func_DCTquant_trunc(Block)%%12bit

for i = 1:16
   for j = 1:16
       if (i==1) && (j==1)
           Block_quant(i,j) = floor(Block(i,j)/2)*2; %% change it respect to the truncation point
       else
           Block_quant(i,j) = floor(Block(i,j)*2)/2;
       end
   end
end

