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
%      x=1;
%      for l = 1:32
%          for k = 1:32
%              for i = 1:16
%                  for j = 1:16
%                      vector_temp(1, x) = input_image_512x512((i+16*(l-1)),(j+16*(k-1)));
%                      x= x+1;
%                  end  
%              end
%          end
%      end


%      input_vector = fopen(sprintf( 'image_in_%d.txt',image_number), 'w');
% 
%      for i = 1 : (512*512)
%          fprintf(input_vector, '%s', dec2hex(vector_temp(1,i),2));
%          if(mod(i,16)==0)
%              fprintf(input_vector, '\n');
%          else
% 
%          end
%      end
     
     
     
     %-------------------------Generation of DCT Bases Vector Matrix ----------------------
    
     %---------------------Quatization bit setup-----------------------------
     
     % The number of bits for DCT Coefficient Quantization
     % You can "adjust this number" to improve the qualities of images
     C_quantization_bit =  10;
     T = func_DCT_Coefficient_quant(C_quantization_bit);
     
     % If you want to check the coefficient value in hex format, please use this and open the txt file.
%      filter_coef = fopen('./filt_coeff_T.txt','w');
%      for k = 1:16
%          fprintf(filter_coef,'%x \n',T(k,1)*2^(C_quantization_bit-1));
%      end



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
    
     
     %--------------------------- 12BIT QUANTIZATION -----------------------------
     M = char(zeros(1,16));
     for l = 1:32
        for k = 1:32   
            for i = 1:16
                for j = 1:16
                    pixel = Block_DCT_final(16 * (l - 1) + i , 16 * (k - 1) + j);
                    if i==1 && j==1
                        val = dec2bin(pixel/2,12);
                        M(1,1:4) = val(1);
                        M(1,5:16) = val(1:12);
                        Block_DCT_final(16 * (l - 1) + i , 16 * (k - 1) + j) = double(typecast(uint16(bin2dec(char(M))),'int16')*2);
                    elseif pixel*2 < -128
                        val = dec2bin(pixel*2,12);
                        val = val(5:16);
                        M(1,1:4) = val(1);
                        M(1,5:16) = val(1:12);
                        Block_DCT_final(16 * (l - 1) + i , 16 * (k - 1) + j) = double(typecast(uint16(bin2dec(char(M))),'int16')/2);
                    else 
                        val = dec2bin(pixel*2,12);
                        M(1,1:4) = val(1);
                        M(1,5:16) = val(1:12);
                        Block_DCT_final(16 * (l - 1) + i , 16 * (k - 1) + j) = double(typecast(uint16(bin2dec(char(M))),'int16')/2);

                    end
                end
            end
        end
     end     
     
     %-------------------------Generation of DCT Bases Vector Matrix ----------------------
     
     % Quantization coefficient after DCT operation (Not used for DCT)
     % (1,1) value (16) should be changed according to the truncation point
     
     Q=[ 16	 14	 11	 11	 10	 13	 16	 20	 24	 32	 40	 46	 51	 56	 61 61
        14	 13	 12	 12	 12	 15	 18	 21	 25	 37	 49	 52	 56	 57	 58 58
        12	 12	 12	 13	 14	 17	 19	 23	 26	 42	 58	 59	 60	 58	 55 55
        13	 13	 13	 14	 15	 18	 22	 27	 33	 45	 58	 61	 65	 60	 56 56
        14	 14	 13	 15	 16	 20	 24	 32	 40	 49	 57	 63	 69	 63	 56 56
        14	 15	 15	 17	 19	 23	 27	 36	 46	 59	 72	 73	 75	 67	 59 59
        14	 16	 17	 20	 22	 26	 29	 40	 51	 69	 87	 84	 80	 71	 62 62
        16	 18	 20	 25	 30	 36	 43	 51	 60	 79	 98	 95	 92	 81	 70 70
        18	 20	 22	 30	 37	 47	 56	 62	 68	 89	109	106	103	 90	 77 77
        21	 25	 29	 37	 46	 53	 60	 67	 75	 91	107	107	108	 96	 85 85
        24	 30	 35	 45	 55	 60	 64	 73	 81	 93	104	109	113	103	 92 92
        37	 43	 50	 58	 67	 71	 76	 84	 92	102	113	115	117	107	 97 97
        49	 57	 64	 71	 78	 83	 87	 95	103	112	121	121	120	111	101 101
        61	 69	 78	 82	 87	 90	 93	100	108	109	111	111	112	106	100 100
        72	 82	 92	 94	 95	 97	 98	105	112	106	100	102	103	101	99 99
        72	 82	 92	 94	 95	 97	 98	105	112	106	100	102	103	101	99 99];
     
     Q_pre=[ 16	 14	 11	 11	 10	 13	 16	 20	 24	 32	 40	 46	 51	 56	 61 61
            14	 13	 12	 12	 12	 15	 18	 21	 25	 37	 49	 52	 56	 57	 58 58
            12	 12	 12	 13	 14	 17	 19	 23	 26	 42	 58	 59	 60	 58	 55 55
            13	 13	 13	 14	 15	 18	 22	 27	 33	 45	 58	 61	 65	 60	 56 56
            14	 14	 13	 15	 16	 20	 24	 32	 40	 49	 57	 63	 69	 63	 56 56
            14	 15	 15	 17	 19	 23	 27	 36	 46	 59	 72	 73	 75	 67	 59 59
            14	 16	 17	 20	 22	 26	 29	 40	 51	 69	 87	 84	 80	 71	 62 62
            16	 18	 20	 25	 30	 36	 43	 51	 60	 79	 98	 95	 92	 81	 70 70
            18	 20	 22	 30	 37	 47	 56	 62	 68	 89	109	106	103	 90	 77 77
            21	 25	 29	 37	 46	 53	 60	 67	 75	 91	107	107	108	 96	 85 85
            24	 30	 35	 45	 55	 60	 64	 73	 81	 93	104	109	113	103	 92 92
            37	 43	 50	 58	 67	 71	 76	 84	 92	102	113	115	117	107	 97 97
            49	 57	 64	 71	 78	 83	 87	 95	103	112	121	121	120	111	101 101
            61	 69	 78	 82	 87	 90	 93	100	108	109	111	111	112	106	100 100
            72	 82	 92	 94	 95	 97	 98	105	112	106	100	102	103	101	99 99
            72	 82	 92	 94	 95	 97	 98	105	112	106	100	102	103	101	99 99];

     %--------------------------- Quantization after DCT ----------------------------     
     for i=1:m/16
         for j=1:n/16
             Block_DCT = Block_DCT_final((16*i-15):16*i,(16*j-15):16*j);
             Block_r = round(Q_pre.\Block_DCT);
             Image_tran((16*i-15):16*i,(16*j-15):16*j) = Block_r;
         end
     end
     %      
     %--------------------------- ENTROPY ENCODING ----------------------------------
     ZigZag_Order = uint16([ 1	17	2	3	18	33	49	34	19	4	5	20	35	50	65	81
                            66	51	36	21	6	7	22	37	52	67	82	97	113	98	83	68
                            53	38	23	8	9	24	39	54	69	84	99	114	129	145	130	115
                            100	85	70	55	40	25	10	11	26	41	56	71	86	101	116	131
                            146	161	177	162	147	132	117	102	87	72	57	42	27	12	13	28
                            43	58	73	88	103	118	133	148	163	178	193	209	194	179	164	149
                            134	119	104	89	74	59	44	29	14	15	30	45	60	75	90	105
                            120	135	150	165	180	195	210	225	241	226	211	196	181	166	151	136
                            121	106	91	76	61	46	31	16	32	47	62	77	92	107	122	137
                            152	167	182	197	212	227	242	243	228	213	198	183	168	153	138	123
                            108	93	78	63	48	64	79	94	109	124	139	154	169	184	199	214
                            229	244	245	230	215	200	185	170	155	140	125	110	95	80	96	111
                            126	141	156	171	186	201	216	231	246	247	232	217	202	187	172	157
                            142	127	112	128	143	158	173	188	203	218	233	248	249	234	219	204
                            189	174	159	144	160	175	190	205	220	235	250	251	236	221	206	191
                            176	192	207	222	237	252	253	238	223	208	224	239	254	255	240	256
                            ]);
     
     % Break 8x8 block into columns
     Single_column_quantized_image=im2col(Image_tran, [16 16],'distinct');
     
     %--------------------------- zigzag ----------------------------------
     
     % using the MatLab Matrix indexing power (specially the ':' operator) rather than any function
     ZigZaged_Single_Column_Image=Single_column_quantized_image(ZigZag_Order,:);
     
     %---------------------- Run Level Coding -----------------------------
     % construct Run Level Pair from ZigZaged_Single_Column_Image
     run_level_pairs=int16([]);
     
     for block_index=1:1024    %block by block - total 1024 blocks (16x16) in the 512x512 image
         single_block_image_vector(1:256)=0;
         for Temp_Vector_Index=1:256
             single_block_image_vector(Temp_Vector_Index) = ZigZaged_Single_Column_Image(Temp_Vector_Index, block_index);  %select 1 block sequentially from the ZigZaged_Single_Column_Image
         end
         non_zero_value_index_array = find(single_block_image_vector~=0); % index array of next non-zero entry in a block
         
         if isempty(find(single_block_image_vector~=0)) == 1
             non_zero_value_index_array(1) = 0;
         else

         end
         
         number_of_non_zero_entries = length(non_zero_value_index_array);  % # of non-zero entries in a block
         
         % Case 1: if first ac coefficient has no leading zeros then encode first coefficient
         
         if non_zero_value_index_array(1)==0
             run_level_pairs=cat(1,run_level_pairs);
         elseif non_zero_value_index_array(1)==1
             run=0;
             run_level_pairs=cat(1,run_level_pairs, run, single_block_image_vector(non_zero_value_index_array(1)));
         end
         
         % Case 2: loop through each non-zero entry
         for i=2:number_of_non_zero_entries
             % check # of leading zeros (run)
             run=non_zero_value_index_array(i)-non_zero_value_index_array(i-1)-1;
             run_level_pairs=cat(1, run_level_pairs, run, single_block_image_vector(non_zero_value_index_array(i)));
         end
         
         % Case 3: "End of Block" mark insertion
         run_level_pairs=cat(1, run_level_pairs, 255, 255);
     end

     %--------%--------%--------%--------%--------%--------%--------%--------%--%
     %---------%---- End of 2D DCT, Quantization, Entropy Encoding%-------------%
     %--------%--------%--------%--------%--------%--------%--------%--------%--%
     
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%%%%  After the Transformation  %%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%   Assume lossless entropy coding   %%%%%%%%%%%%%%
     %%%%%%%%   Assume lossless communication channel   %%%%%%%%%%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%     For the image restoration    %%%%%%%%%%%%%%%%
     %%%%      Multiplication with Quantization Matrix         %%%%
     %%%%%%%%%%%%    2-D IDCT Matrix Multiplication   %%%%%%%%%%%%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
     %--------%--------%--------%--------%--------%--------%--------%--------%--%
     %--------- START of Entropy Decoding, Dequantization, 2D IDCT -------------%
     %--------%--------%--------%--------%--------%--------%--------%--------%--%
     
     %---------------------- Run Level Decoding ---------------------------
     % construct  ZigZaged_Single_Column_Image from Run Level Pair
     
     c=[];
     for i=1:2:size(run_level_pairs) % loop through run_level_pairs
         % Case 1 & Cae 2
         % concatenate zeros according to 'run' value
         if run_level_pairs(i)<255 % only end of block should have 255 value
             zero_count=0;
             zero_count=run_level_pairs(i);
             for l=1:zero_count    % concatenation of zeros accouring to zero_count
                 c=cat(1,c,0);   % single zero concatenation
             end
             c=cat(1,c,run_level_pairs(i+1)); % concatenate single'level' i.e., a non zero value
             
             % Case 3: End of Block decoding
         else
             number_of_trailing_zeros= 256-mod(size(c),256);
             for l= 1:number_of_trailing_zeros    % concatenate as much zeros as needed to fill a block
                 c=cat(1,c,0);
             end
         end
     end
     
     %-----  prepare the ZigZaged_Single_Column_Image vector --------------
     ZigZaged_Single_Column_Image = zeros(256,1024);
     for i=1:1024
         for j=1:256
             ZigZaged_Single_Column_Image(j,i)=c(256*(i-1)+j);
         end
     end
    
    
    % Finding the reverse zigzag order (16x16 matrix)
    reverse_zigzag_order = zeros(16,16);
    for k = 1:(size(ZigZag_Order,1)*size(ZigZag_Order,2)) 
        reverse_zigzag_order(k) = find(ZigZag_Order==k);
    end

    %--------------------------- reverse zigzag --------------------------
    %reverse zigzag procedure using the matrix indexing capability of MatLab (specially the ':' operator)
    Single_column_quantized_image = ZigZaged_Single_Column_Image(reverse_zigzag_order,:);
    %---------------------------------------------------------------------
    

    %image matrix construction from image column
    Image_tran = col2im(Single_column_quantized_image,   [16 16],   [m n],   'distinct');


    %  Allocate the array for Image restore
    Image_restore = zeros(256,256);

    for i=1:m/16
        for j=1:n/16
            Block_temp = Image_tran((16*i-15):16*i,(16*j-15):16*j);
            Block_rq = Q.*Block_temp;
            Block_IDCT = T'*Block_rq*T;
            Image_restore((16*i-15):16*i,(16*j-15):16*j) = Block_IDCT;
        end
    end


    for i=1:m
        for j=1:n
            if Image_restore(i,j) > 255
               Image_restore(i,j) = 255;
            end

            if Image_restore(i,j) < 0
               Image_restore(i,j) = 0;
            end

        end
    end

    %------------------------Generate the output Image--------------------------    

    output_file_name = sprintf( 'image_out_%d.tif',image_number);
    imwrite(uint8(Image_restore),output_file_name,'tif');


    %-------------------------Calculate the PSNR--------------------------------
    MSE = 0;

    for row = 1:m
      for col = 1:n
        MSE = MSE + (input_image_512x512(row, col) - Image_restore(row, col)) ^ 2;
      end
    end

    MSE = MSE / (m * n);
    PSNR(1,image_number) = 10 * log10 ((255^2) / MSE);
    


    %-------------------------Show the output image -----------------------------------
     subplot(4,4,image_number*2);
     imshow(Image_restore./255);
     title ( sprintf('Restored image #%d \n PSNR : %d',image_number,PSNR(image_number)) );
 
end