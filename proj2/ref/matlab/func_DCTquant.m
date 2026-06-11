%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%   DCT Coefficient Quantization Function  %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Block_quant = func_DCTquant(Block, num_bin, num_int)

for i = 1:16
   for j = 1:16
       if(abs(floor(Block(i,j))/(2^num_int))>0.5)
           'You enter wrong num_int value';
           break;
       else
       if Block(i,j)>=0
               if num_bin >= num_int
                   Block_quant(i,j) = floor(Block(i,j)*(2^(num_bin-num_int)))/(2^(num_bin-num_int));
               else
                   Block_quant(i,j) = floor(Block(i,j)/(2^(num_int-num_bin)))*(2^(num_int-num_bin));
               end
       else
               if num_bin >= num_int
                   Block_quant(i,j) = floor(Block(i,j)*(2^(num_bin-num_int)))/(2^(num_bin-num_int));
               else
                   Block_quant(i,j) = floor(Block(i,j)/(2^(num_int-num_bin)))*(2^(num_int-num_bin));
               end
       end
       end
   end
end
