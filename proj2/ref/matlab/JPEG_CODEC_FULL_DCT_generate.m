clear all
close all
clc

for image_number = 1:8 %-------------"Change this number" to test many different images------
    %---------------------------- Get the Image data Input ----------------------------------
    input_image_512x512 = double( imread( sprintf( 'image_in_%d.tif',image_number ),'tiff' ) );
    [m,n] = size(input_image_512x512);
    m = floor(m/8)*8;
    n = floor(n/8)*8;
     
     %------------------------------------ show input image -----------------------------------
     subplot(4,4,image_number*2-1);
     imshow(input_image_512x512./255);
     title ( sprintf('Original image #%d \n size : %dx%d', image_number, m, n) );
     %-----------------------------------------------------------------------------------------    
     
     %------------------------------------generate input text file -----------------------------------
     x=1;
     for l = 1:32
         for k = 1:32
             for i = 1:16
                 for j = 1:16
                     vector_temp(1, x) = input_image_512x512((i+16*(l-1)),(j+16*(k-1)));
                     x= x+1;
                 end
             end
         end
     end


     input_vector = fopen(sprintf( 'image_in_%d.txt',image_number), 'w');

     for i = 1 : (512*512)
         fprintf(input_vector, '%s', dec2hex(vector_temp(1,i)));
         if(mod(i,16)==0)
             fprintf(input_vector, '\n');
         else

         end
     end
     
     
     
     %-------------------------Generation of DCT Bases Vector Matrix ----------------------
    
     %---------------------Quatization bit setup-----------------------------
     
     % The number of bits for DCT Coefficient Quantization
     % You can "adjust this number" to improve the qualities of images
     C_quantization_bit =  10;
     T = func_DCT_Coefficient_quant(C_quantization_bit);
     
     % If you want to check the coefficient value in hex format, please use this and open the txt file.
     filter_coef = fopen('./filt_coeff_T.txt','w');
     for k = 1:16
         fprintf(filter_coef,'%x \n',T(k,1)*2^(C_quantization_bit-1));
     end



     %--------------------------- DCT OPERATION ---------------------------
     
     %---------------------Quatization bit setup-----------------------------
     % The number of bits for Result of 1D-DCT Quantization
     % You can "adjust this number" to improve the qualities of images.
     Result_1D_DCT_quantization_bit = 12;
     
     % The number of integer bits for Result of 1D-DCT
     num_int = 12;
     
     %--------------------------- DCT OPERATION -----------------------------
     Image_tran = zeros(m,n);
     
     for i=1:m/16
         for j=1:n/16
             Block_temp = input_image_512x512((16*i-15):16*i,(16*j-15):16*j);
             Block_DCT_1D_temp = T*Block_temp';
             Block_DCT_1D_quant((16*i-15):16*i,(16*j-15):16*j) = func_DCTquant(Block_DCT_1D_temp, Result_1D_DCT_quantization_bit, num_int);   % result of 1D DCT for debugging
             Block_DCT_2D_temp = T*Block_DCT_1D_quant((16*i-15):16*i,(16*j-15):16*j)';
             Block_DCT_2D_quant((16*i-15):16*i,(16*j-15):16*j) = (Block_DCT_2D_temp); % result of 2D DCT for debugging
             Block_DCT_final((16*i-15):16*i,(16*j-15):16*j) = func_DCTquant_trunc(Block_DCT_2D_quant((16*i-15):16*i,(16*j-15):16*j));
         end
     end
     
     maximum_temp = 0;
     minimum_temp = 0;
     input_vector = fopen(sprintf( 'DCT_image_%d.txt',image_number), 'w');
        for l = 1:32
            for k = 1:32   
                for i = 1:16
                    for j = 1:16
                        pixel = Block_DCT_final(16 * (l - 1) + i , 16 * (k - 1) + j);
                        if i==1 && j==1
%                             if(pixel>=2048)
%                                 pixel = 2047;
%                             end    
                            val_1 = dec2bin(pixel/2,12);
                            fprintf(input_vector, '%12s\n',val_1);
                        elseif pixel*2 < -128
                            if(pixel<=-1024)
                                pixel = -1024;
%                                 disp('underflow')
                            end
                            val_2 = dec2bin(pixel*2,12);
                            val_3 = val_2(5:16);
                            fprintf(input_vector, '%12s\n',val_3);
                        else 
                            if(pixel>1023)
                                pixel=1023;
%                                 disp('overflow')
                            end

                            val = dec2bin(pixel*2,12);
                            fprintf(input_vector, '%12s\n',val);

                        end
                    end
                end
            end
        end
end
