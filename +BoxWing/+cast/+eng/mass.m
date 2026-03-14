clear; clc;
% Data
T_ref = 374500;       % N
W_ref = 7277;         % kg
L_ref = 4.50;         % m
D_ref = 3.00;         % m Fan diameter
BPR_ref = 9.3;        
MTOM_kg = 327503.3;  
g = 9.80665;
W_N = MTOM_kg * g;    % total weight
TW_ratio = 0.226;     
n_engines = 2;        
T_total_req = W_N * TW_ratio;   % require thurst
T_req_per_eng = T_total_req / n_engines; % thurst per engine

% raymer
SF = T_req_per_eng / T_ref;
W_scaled = W_ref * (SF)^1.1;
D_scaled = D_ref * (SF)^0.5;
L_scaled = L_ref * (SF)^0.4;

% Nacelle
W_nacelle = 0.30 * W_scaled;
W_total_propulsion = W_scaled + W_nacelle;

% result
fprintf('Required Thrust per Engine: %.2f kN\n', T_req_per_eng/1000);
fprintf('Scaling Factor (SF):%.4f\n', SF);
fprintf('Scaled Engine Mass:%.2f kg\n', W_scaled);
fprintf('Scaled Engine Length:%.2f m\n', L_scaled);
fprintf('Scaled Engine Diameter:%.2f m\n', D_scaled);
fprintf('Total Propulsion Mass: %.2f kg\n', W_total_propulsion);
