row     = 64;
column  = 64;
bits    =  8;
num_of_MAC = 4;

a = randi([0, 2^bits-1], [row,column]);
b = randi([0, 2^bits-1], [row,column]);
c = a*b;

f00 = fopen('./vec_a.txt','w');
    for i=1:column
        for j=1:row
            fprintf(f00, '%X \n', a(i,j));
        end
    end
fclose(f00);

f01 = fopen('./vec_b.txt','w');
    for i=1:column
        for j=0:((row/num_of_MAC)-1)
            for k=1:num_of_MAC
                fprintf(f01, '%02X', b(i, num_of_MAC*j+k));
            end
            fprintf(f01, '\n');z
        end
    end
fclose(f01);

f02 = fopen('./vec_c.txt','w');
    for i=1:column
        for j=1:row
            fprintf(f02, '%X \n', c(i,j));
        end
    end
fclose(f02);