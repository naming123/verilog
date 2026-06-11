function decimal = func_Bin2Dec_mag(Bin_data, num_int, num_bin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%  Convert a binary number to a decimal number when the %%%%%%%%%%%%%%
%%%%%%  When the Data format is sign and Magnitude %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%	d = b2d(bin, num_int, num_bin)             %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%	'num_int' indicates the number of digits greater than 0.   %%%%%%%%
%%%%%%	'num_bin' is the total number of binary digits.   %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%%%%%% Reordering to fit in the program %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bin = Bin_data (num_bin:-1:1);

NumInt = num_int;
N = num_bin;
dec = 0;
sign = bin(N);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%   First convert the integer part   %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if N > NumInt 
  for i = 1:NumInt
    if (bin(N-1-(NumInt-i)) == 1)
      dec = dec + power(2, i-1);
    end
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%   When the number is pure interger   %%%%%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
  for i = 1:N-1
    if (bin(i) == 1)
      dec = dec + power(2, i-1);
    end
  end
  if (sign == 1)
    decimal = -dec;
  else
    decimal = dec;
  end
%   break;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Later, convert the floating point part %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:N-NumInt-1
  if (bin(N-NumInt-i) == 1)
    dec = dec + power(2, -i);
  end
end
if (sign == 1)
  decimal = -dec;
else
  decimal = dec;
end