%n=[0.91503  -0.33485   -0.22495];

% sag alone
%n=[1 0 0];

% sag_cor
%n=[0.866 -0.5 0];

% first stc 
n=[0.998 -0.0384 -0.0506];
inplane=-0.0035;
 
% sag_trans
%n=[0.866 0 -0.5];

%n=[0.852869 -0.173648  -0.492404];

% sag_trans 5
%n=[0.996195 0 -0.087156];

b=asin(n(2))
a=atan2(n(3),n(1))

%pixdim=[3.5 3.5 3.5];
pixdim=[1 1 1];

ca=cos(a); sa=sin(a);
cb=cos(b); sb=sin(b);
ci=cos(inplane); si=sin(inplane);

R1=[0 0 -pixdim(3); pixdim(1) 0 0; 0 -pixdim(2) 0];
R2=[cb -sb 0; sb cb 0 ; 0 0 1]; % Right rule for sag_cor alone
R3=[ca 0 -sa; 0 1 0; sa 0 ca]; % Right rule for sag_trans alone
R4=[ci -si 0; si ci 0; 0 0 1];

RC=R3*R2*R4*R1


  