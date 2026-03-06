clear clc
% data
MTOW = 327503.3;          
S = 422.5;              
AR = 10.0;  
g = 9.81;
W_N = MTOW * g;
cd0 = 0.022;
cl_to = 1.2;
e = 1.80;
T_OEI = 363027;

% OEI take-off
delta_cd0_to = 0.02;         
cd_to = (cd0 + delta_cd0_to) + (cl_to^2 / (pi * AR * e));
ld_to = cl_to / cd_to;
gamma = (T_OEI * 0.95 / W_N) - (1 / ld_to);

% OEI cruise
ld_cruise = 22.89; 
sigma = ( (W_N / ld_cruise) / T_OEI )^(1 / 0.7);


% result
 fprintf('take-off gradient radian: %.2f\n', gamma);
 fprintf('cruise density: %.4e kg/N/s\n', sigma);
