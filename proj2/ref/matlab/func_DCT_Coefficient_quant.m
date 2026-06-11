%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%   DCT Coefficient Quantization Function  %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  T_quant = func_DCT_Coefficient_quant(num_bin)
%% num_bin : The DCT Quantization bit allocation 
%% Each DCT coefficients
a = 1/sqrt(8)*cos( 1*pi/32);
b = 1/sqrt(8)*cos( 2*pi/32);
c = 1/sqrt(8)*cos( 3*pi/32);
d = 1/sqrt(8)*cos( 4*pi/32);
e = 1/sqrt(8)*cos( 5*pi/32);
f = 1/sqrt(8)*cos( 6*pi/32);
g = 1/sqrt(8)*cos( 7*pi/32);
h = 1/sqrt(8)*cos( 8*pi/32);
i = 1/sqrt(8)*cos( 9*pi/32);
j = 1/sqrt(8)*cos(10*pi/32);
k = 1/sqrt(8)*cos(11*pi/32);
l = 1/sqrt(8)*cos(12*pi/32);
m = 1/sqrt(8)*cos(13*pi/32);
n = 1/sqrt(8)*cos(14*pi/32);
o = 1/sqrt(8)*cos(15*pi/32);
%coefficient matrix
  T=[   h	h	h	h	h	h	h	h	h	h	h	h	h	h	h	h
        a	c	e	g	i	k	m	o	-o	-m	-k	-i	-g	-e	-c	-a
        b	f	j	n	-n	-j	-f	-b	-b	-f	-j	-n	n	j	f	b
        c	i	o	-k	-e	-a	-g	-m	m	g	a	e	k	-o	-i	-c
        d	l	-l	-d	-d	-l	l	d	d	l	-l	-d	-d	-l	l	d
        e	o	-g	-c	-m	i	a	k	-k	-a	-i	m	c	g	-o	-e
        f	-n	-b	-j	j	b	n	-f	-f	n	b	j	-j	-b	-n	f
        g	-k	-c	o	a	m	-e	-i	i	e	-m	-a	-o	c	k	-g
        h	-h	-h	h	h	-h	-h	h	h	-h	-h	h	h	-h	-h	h
        i	-e	-m	a	-o	-c	k	g	-g	-k	c	o	-a	m	e	-i
        j	-b	n	f	-f	-n	b	-j	-j	b	-n	-f	f	n	-b	j
        k	-a	i	m	-c	g	o	-e	e	-o	-g	c	-m	-i	a	-k
        l	-d	d	-l	-l	d	-d	l	l	-d	d	-l	-l	d	-d	l
        m	-g	a	-e	k	o	-i	c	-c	i	-o	-k	e	-a	g	-m
        n	-j	f	-b	b	-f	j	-n	-n	j	-f	b	-b	f	-j	n
        o	-m	k	-i	g	-e	c	-a	a	-c	e	-g	i	-k	m	-o
];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Change from Decimal to Binary number %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
for i = 1:16
   for j = 1:16
       T_bi(i,j,:) = func_Dec2Bin_mag(T(i,j), num_bin);
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Again Change from Binary to Decimal number %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
for i = 1:16
   for j = 1:16
       num_int = 0;
       T_quant(i,j) = func_Bin2Dec_mag(T_bi(i,j,:), num_int, num_bin);
   end
end
