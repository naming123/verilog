clear all;
clc;


a_bit = 16;
a_frac = 15;

b_bit = 16;
b_frac = 15;

c_bit = 16;
c_frac = 14;

t_bit = 16;
t_frac = 14;


a = zeros(1024,1);
b = zeros(1024,1);
c = zeros(1024,1);
t = zeros(1024,1);

for k=1:1024
    % input gen
    a(k) = complex(rand(1)-0.5, rand(1)-0.5);  % random data : from -0.5 to 0.5 for single 8points
    b(k) = complex(rand(1)-0.5, rand(1)-0.5);  % random data : from -0.5 to 0.5 for single 8points
    c(k) = complex(rand(1)-0.5, rand(1)-0.5);  % random data : from -0.5 to 0.5 for single 8points
    t(k) = complex(rand(1)-0.5, rand(1)-0.5);  % random data : from -0.5 to 0.5 for single 8points
    
    a_re(k) = floor(real(a(k))*2^a_frac+0.5); %% integer value (rounded actual should be divided by 2**a_frac)
    a_im(k) = floor(imag(a(k))*2^a_frac+0.5);
    
    b_re(k) = floor(real(b(k))*2^b_frac+0.5);
    b_im(k) = floor(imag(b(k))*2^b_frac+0.5);
    
        
    c_re(k) = floor(real(c(k))*2^c_frac+0.5); 
    c_im(k) = floor(imag(c(k))*2^c_frac+0.5);
    
    t_re(k) = floor(real(t(k))*2^t_frac+0.5);
    t_im(k) = floor(imag(t(k))*2^t_frac+0.5);
    
    c1_re(k) =floor((a_re(k) + b_re(k))/2); % (a + b) >> 1
    c1_im(k) =floor((a_im(k) + b_im(k))/2); 
    
    c2_re(k) =floor((a_re(k) - b_re(k))/2); % (a - b) >> 1
    c2_im(k) =floor((a_im(k) - b_im(k))/2);
    
    o_re(k) = floor((c_re(k) * t_re(k) - c_im(k) * t_im(k))/(2^t_frac)); % or = (cr*tr - ci*ti) << t_frac
    o_im(k) = floor((c_re(k) * t_im(k) + c_im(k) * t_re(k))/(2^t_frac)); % oi = (cr*ti - ci*tr) << t_frac
    
   

end
%%input vectors
% % arai vector
for i=1:1024
    if (a_re(i) < 0 )
        ar_temp(i) = a_re(i) + 2^a_bit;         % for sign extension
    else
        ar_temp(i) = a_re(i);
    end
    
    if (a_im(i) < 0 )
        ai_temp(i) = a_im(i) + 2^a_bit;
    else
        ai_temp(i) = a_im(i);
    end
    a_temp(i) = ar_temp(i) * 2^a_bit + ai_temp(i) ;
end

ArAi = fopen(sprintf( 'ArAi.txt'), 'w');
for i=1:1024
    fprintf(ArAi, '%X\n', a_temp(i));
end

% % brbi vector
for i=1:1024
    if (b_re(i) < 0 )
        br_temp(i) = b_re(i) + 2^b_bit;
    else
        br_temp(i) = b_re(i);
    end
    
    if (b_im(i) < 0 )
        bi_temp(i) = b_im(i) + 2^b_bit;
    else
        bi_temp(i) = b_im(i);
    end
    b_temp(i) = br_temp(i) * 2^b_bit + bi_temp(i) ;
end
BrBi = fopen(sprintf( 'BrBi.txt'), 'w');
for i=1:1024
    fprintf(BrBi, '%X\n', b_temp(i));
end
% % crci vector
for i=1:1024
    if (c_re(i) < 0 )
        cr_temp(i) = c_re(i) + 2^c_bit;
    else
        cr_temp(i) = c_re(i);
    end
    
    if (c_im(i) < 0 )
        ci_temp(i) = c_im(i) + 2^c_bit;
    else
        ci_temp(i) = c_im(i);
    end
    c_temp(i) = cr_temp(i) * 2^c_bit + ci_temp(i) ;
end
CrCi = fopen(sprintf( 'CrCi.txt'), 'w');
for i=1:1024
    fprintf(CrCi, '%X\n', c_temp(i));
end
% % trti vector
for i=1:1024
    if (t_re(i) < 0 )
        tr_temp(i) = t_re(i) + 2^t_bit;
    else
        tr_temp(i) = t_re(i);
    end
    
    if (t_im(i) < 0 )
        ti_temp(i) = t_im(i) + 2^t_bit;
    else
        ti_temp(i) = t_im(i);
    end
    t_temp(i) = tr_temp(i) * 2^t_bit + ti_temp(i) ;
end
TrTi = fopen(sprintf( 'TrTi.txt'), 'w');
for i=1:1024
    fprintf(TrTi, '%X\n', t_temp(i));
end
%%ouput vectors
% % oroi vector
for i=1:1024
    if (o_re(i) < 0 )
        or_temp(i) = o_re(i) + 2^t_bit; %may have to be changed check!!
    else
        or_temp(i) = o_re(i);
    end
    
    if (o_im(i) < 0 )
        oi_temp(i) = o_im(i) + 2^t_bit;
    else
        oi_temp(i) = o_im(i);
    end
    o_temp(i) = or_temp(i) * 2^t_bit + oi_temp(i) ;
end
OrOi = fopen(sprintf( 'OrOi.txt'), 'w');
for i=1:1024
    fprintf(OrOi, '%X\n', o_temp(i));
end
% % c1rc1i vector
for i=1:1024
    if (c1_re(i) < 0 )
        c1r_temp(i) = c1_re(i) + 2^c_bit;%may have to be changed check!!
    else
        c1r_temp(i) = c1_re(i);
    end
    
    if (c1_im(i) < 0 )
        c1i_temp(i) = c1_im(i) + 2^c_bit;
    else
        c1i_temp(i) = c1_im(i);
    end
    c1_temp(i) = c1r_temp(i) * 2^c_bit + c1i_temp(i) ;
end
C1rC1i = fopen(sprintf( 'C1rC1i.txt'), 'w');
for i=1:1024
    fprintf(C1rC1i, '%X\n', c1_temp(i));
end
% % c2rc2i vector
for i=1:1024
    if (c2_re(i) < 0 )
        c2r_temp(i) = c2_re(i) + 2^c_bit;
    else
        c2r_temp(i) = c2_re(i);
    end
    
    if (c2_im(i) < 0 )
        c2i_temp(i) = c2_im(i) + 2^c_bit;
    else
        c2i_temp(i) = c2_im(i);
    end
    c2_temp(i) = c2r_temp(i) * 2^c_bit + c2i_temp(i) ;
end
C2rC2i = fopen(sprintf( 'C2rC2i.txt'), 'w');
for i=1:1024
    fprintf(C2rC2i, '%X\n', c2_temp(i));
end
% % input vec
% for i=1:64
%     for j=1:16
%         if (in_re(i,j) < 0)
%             inr_temp(i,j) = in_re(i,j) + 2^real_bit;
%         else
%             inr_temp(i,j) = in_re(i,j);
%         end
%         
%         if(in_im(i,j) < 0)
%             ini_temp(i,j) = in_im(i,j) + 2^imag_bit;
%         else
%             ini_temp(i,j) = in_im(i,j);
%         end
%         
%         in_temp(16*(i-1)+j) = inr_temp(i,j)*2^imag_bit + ini_temp(i,j);
%     end
% end
% 
% input_FFT = fopen(sprintf( 'input_FFT.txt'), 'w');
% for n=1:1024
%     fprintf(input_FFT, '%X\n', in_temp(n));
% end
% 
% % twiddle vec
% for i=1:8
%     if (W_re(i) < 0)
%         wr_temp(i) = W_re(i) + 2^tr_bit;
%     else
%         wr_temp(i) = W_re(i);
%     end
% 
%     if(W_im(i) < 0)
%         wi_temp(i) = W_im(i) + 2^ti_bit;
%     else
%         wi_temp(i) = W_im(i);
%     end
% 
%     W_temp(i) = wr_temp(i)*2^ti_bit + wi_temp(i);
% end
% 
% W_FFT = fopen(sprintf( 'Twiddle_Factor.txt'), 'w');
% for i=1:8
%     fprintf(W_FFT, '%X\n', W_temp(i));
% end
% 
% % output vec
% for i=1:64
%     for j=1:16
%         if (Xr(i,j) < 0)
%             Xr_temp(i,j) = Xr(i,j) + 2^real_bit;%may have to be changed
%         else
%             Xr_temp(i,j) = Xr(i,j);
%         end
%         
%         if(Xi(i,j) < 0)
%             Xi_temp(i,j) = Xi(i,j) + 2^imag_bit;%may have to be changed
%         else
%             Xi_temp(i,j) = Xi(i,j);
%         end
%         
%         X_temp(16*(i-1)+j) = Xr_temp(i,j)*2^imag_bit + Xi_temp(i,j);
%     end
% end
% 
% output_FFT = fopen(sprintf( 'output_FFT.txt'), 'w');
% for n=1:1024
%     fprintf(output_FFT, '%X\n', X_temp(n));
% end
% 
% % max(Xr)
% % max(Xi)
% 
% fclose('all');