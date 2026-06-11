clear all
M = fopen('image_in_3.txt');
M_2 = char(zeros(16384,32));
for i = 1:16384
    a = fgetl(M);
    M_2(i,32-size(a,2)+1:32) = a;
end

img512x512 = zeros(512,512);
 for l = 1:32
     for k = 1:32
         for i = 1:16
             for j = 1:16
                 img512x512(i+16*(l-1),j+16*(k-1)) = double(typecast(uint16(hex2dec(char(M_2(i + 16*(k-1) + 16*32*(l-1), j*2-1:j*2)))),'uint16'));
             end
         end
     end
 end

 imshow(img512x512/256)