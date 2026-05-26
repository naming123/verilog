clear all;
clc;

N = 8;     % N-point
%%%%%% This matlab is for generating 64 (N-points) vector
real_bit = 16;
real_fraction = 15;
imag_bit = 16;
imag_fraction = 15;

tr_bit = 16; %twiddle factor real bit
tr_fraction = 14; %twiddle factor real fraction
ti_bit = 16; %twiddle factor imaginary bit
ti_fraction = 14; %twiddle factor imaginary fraction

bt_bit = 1;%butterfly truncation bit 
tw_bit = 14; %twiddle product truncation bit

% twiddle factor gen
for n=1:(N/2)
    W(n) = exp((-2*(n-1)*i*pi)/N);
    W_real(n) = real(W(n));
    W_imag(n) = imag(W(n));
    
    W_re(n) = floor(W_real(n)*2^tr_fraction+0.5);       % (tr_bit.tr_fraction)
    W_im(n) = floor(W_imag(n)*2^ti_fraction+0.5);       % (ti_bit.ti_fraction)
end

input = zeros(64,N); % 64 vectors(64*N values)
input_re = zeros(64,N);
input_im = zeros(64,N);
in_re = zeros(64,N);
in_im = zeros(64,N);
FFT = zeros(64,N);

for k=1:64
    % input gen
    input(k,:) = complex(rand(1,N)-0.5, rand(1,N)-0.5);  % random data : from -1 to 1 for single 16points

    input_re(k,:) = real(input(k,:));
    input_im(k,:) = imag(input(k,:));

    in_re(k,:) = floor(input_re(k,:)*2^real_fraction+0.5);       % (real_bit.real_fraction)
    in_im(k,:) = floor(input_im(k,:)*2^imag_fraction+0.5);       % (imag_bit.imag_fraction)
    

    % stage 1
    for n=1:4
        Gr(1,n) = floor((in_re(k,n) + in_re(k,n+4))/2^bt_bit);  % [16:0] -> [16:1]
        Gi(1,n) = floor((in_im(k,n) + in_im(k,n+4))/2^bt_bit);  % [16:0] -> [16:1]
        G2r_temp(n) = floor((in_re(k,n) - in_re(k,n+4))/2^bt_bit);  % [16:0] -> [16:1]
        G2i_temp(n) = floor((in_im(k,n) - in_im(k,n+4))/2^bt_bit);  % [16:0] -> [16:1]

        Gr(2,n) = floor((W_re(n) * G2r_temp(n) - W_im(n) * G2i_temp(n))/2^tw_bit);
        Gi(2,n) = floor((W_re(n) * G2i_temp(n) + W_im(n) * G2r_temp(n))/2^tw_bit);
    end
    
    % stage 2
    for n=1:2
        Pr(1,n) = floor((Gr(1,n) + Gr(1,n+2))/2^bt_bit);
        Pi(1,n) = floor((Gi(1,n) + Gi(1,n+2))/2^bt_bit);
        P2r_temp(n) = floor((Gr(1,n) - Gr(1,n+2))/2^bt_bit);
        P2i_temp(n) = floor((Gi(1,n) - Gi(1,n+2))/2^bt_bit);

        Pr(2,n) = floor((W_re(2*n-1) * P2r_temp(n) - W_im(2*n-1) * P2i_temp(n))/2^tw_bit);
        Pi(2,n) = floor((W_re(2*n-1) * P2i_temp(n) + W_im(2*n-1) * P2r_temp(n))/2^tw_bit);
    end

    for n=1:2
        Pr(3,n) = floor((Gr(2,n) + Gr(2,n+2))/2^bt_bit);
        Pi(3,n) = floor((Gi(2,n) + Gi(2,n+2))/2^bt_bit);
        P4r_temp(n) = floor((Gr(2,n) - Gr(2,n+2))/2^bt_bit);
        P4i_temp(n) = floor((Gi(2,+n) - Gi(2,n+2))/2^bt_bit);

        Pr(4,n) = floor((W_re(2*n-1) * P4r_temp(n) - W_im(2*n-1) * P4i_temp(n))/2^tw_bit);
        Pi(4,n) = floor((W_re(2*n-1) * P4i_temp(n) + W_im(2*n-1) * P4r_temp(n))/2^tw_bit);
    end
    for n=1:4
        Xr(k,2*n-1) = floor((Pr(n,1) + Pr(n,2))/2);
        Xi(k,2*n-1) = floor((Pi(n,1) + Pi(n,2))/2);
        Xr(k,2*n) = floor((Pr(n,1) - Pr(n,2))/2);
        Xi(k,2*n) = floor((Pi(n,1) - Pi(n,2))/2);
    end
    

    % output gen
    for n=1:N
        X(k,n) = (Xr(k,n)/2^(tw_bit-2))+i*(Xi(k,n)/2^(tw_bit-2));
    end
    
    % FFT ref
    FFT_temp = fft(input(k,:),N);
    FFT(k,:) = bitrevorder(FFT_temp);
end

% input vec
for i=1:64
    for j=1:N
        if (in_re(i,j) < 0)
            inr_temp(i,j) = in_re(i,j) + 2^real_bit;
        else
            inr_temp(i,j) = in_re(i,j);
        end
        
        if(in_im(i,j) < 0)
            ini_temp(i,j) = in_im(i,j) + 2^imag_bit;
        else
            ini_temp(i,j) = in_im(i,j);
        end
        
        in_temp(N*(i-1)+j) = inr_temp(i,j)*2^imag_bit + ini_temp(i,j);
    end
end

input_FFT = fopen(sprintf( 'input_FFT.txt'), 'w');
for n=1:N * 64
    fprintf(input_FFT, '%X\n', in_temp(n));
end

% twiddle vec
for i=1:N /2
    if (W_re(i) < 0)
        wr_temp(i) = W_re(i) + 2^tr_bit;
    else
        wr_temp(i) = W_re(i);
    end

    if(W_im(i) < 0)
        wi_temp(i) = W_im(i) + 2^ti_bit;
    else
        wi_temp(i) = W_im(i);
    end

    W_temp(i) = wr_temp(i)*2^ti_bit + wi_temp(i);
end

W_FFT = fopen(sprintf( 'Twiddle_Factor.txt'), 'w');
for i=1:N /2 
    fprintf(W_FFT, '%X\n', W_temp(i));
end

% output vec
for i=1:64
    for j=1:N
        if (Xr(i,j) < 0)
            Xr_temp(i,j) = Xr(i,j) + 2^real_bit;%may have to be changed
        else
            Xr_temp(i,j) = Xr(i,j);
        end
        
        if(Xi(i,j) < 0)
            Xi_temp(i,j) = Xi(i,j) + 2^imag_bit;%may have to be changed
        else
            Xi_temp(i,j) = Xi(i,j);
        end
        
        X_temp(N*(i-1)+j) = Xr_temp(i,j)*2^imag_bit + Xi_temp(i,j);
    end
end

output_FFT = fopen(sprintf( 'output_FFT.txt'), 'w');
for n=1:N * 64
    fprintf(output_FFT, '%X\n', X_temp(n));
end

% max(Xr)
% max(Xi)

fclose('all');