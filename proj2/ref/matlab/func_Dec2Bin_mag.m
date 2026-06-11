function [bi,n] = func_Dec2Bin_mag(dec, num_bin)
%Convert a decimal number to a binary number with the 'num_bin' digits
%	[b, n] = d2b(dec, num_bin)
%	'b' is the converted binary number, and 'n' is the position 
%	of floating point.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N = num_bin;
bin = zeros(1,N);
%%%%%%%%%%%%%%%%% Sign Bit Assign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% assign a sign bit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (dec > 0)
  sign = 0;
else
  sign = 1;
end
%%%%%%%%%%%%%%%%% Assign the sign bit to the MSB %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bin(N) = sign;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% separate integer and float part %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
value = abs(dec);
integer = floor(value);
float = value - integer;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%       First set the interger part      %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i = 0;
tbin = zeros(1, N);
temp = integer;
while (temp > 1)
  i = i + 1;
  q = floor(temp/2);
  tbin(i) = temp - q*2;
  temp = q;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Consider the case when the interger part is Zero %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if i == 0
  if temp == 1
    NumInt = 1;
    tbin(NumInt) = 1;
  else
    NumInt = 0;
  end
else
  NumInt = i+1;
  tbin(NumInt) = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% When only the interger part is changed to the binary number %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if N <= NumInt
  for i = 1:N-1
    bin(N-i) = tbin(NumInt+1-i);
  end
  b = bin;
  n = N;
%  b = 0;
%  n = -1;
  %break;
else
  for i = 1:NumInt
    bin(N-i) = tbin(NumInt+1-i);
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% convert float part %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P_term = 0;
for k = 1:N-1-NumInt
    P_term = P_term + power(2, -k);
end
decis_num = P_term;
for i = 1:N-1-NumInt
  temp = float - power(2, -i);
  decis_num = decis_num - power(2, -i);
  if (temp >= 0)
    bin(N-NumInt-i) = 1;
    float = temp;
  elseif (abs(temp) <= (float-decis_num))
    bin(N-NumInt-i) = 1;
    float = 0;
  else
    bin(N-NumInt-i) = 0;
  end
end
%%%  Consider the round off case ...  map to the nearest number !!
%m = N-1-NumInt;
%if(abs(float - power(2,-m)) <= float)
%    bin(N-NumInt-m) = 1;
%else
%    bin(N-NumInt-m) = 0;
%end
bi(1:N) = bin(N:-1:1);
n = NumInt+1;
