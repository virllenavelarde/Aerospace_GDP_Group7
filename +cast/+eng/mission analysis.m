function total_fuel_burn = fuel_burn_analysis(ac.payload, mission.M)
    % basic profile
    ac.MTOW = 319000;           % kg
    ac.OEW = 129000;            % kg
    % ac.payload = 92000;         % kg
    ac.S = 443;                 % m^2
    ac.AR = 9.5;               
    ac.e = 0.85;                
    ac.CD0 = 0.015;            
    ac.k = 1 / (pi * ac.AR * ac.e); % Induced drag factor

    % engine profile: Trent XWB-84
    % SFC = SFC_A + SFC_B * (Fn / (delta * Fn0))
    eng.Fn0 = 374500;          
    eng.SFC_A = 1.41e-5;        % kg/N/s
    eng.SFC_B = 0.48e-5;        % kg/N/s

    % mission profile
    mission.range_nm = 4700;    % nm
    mission.alt_cruise = 35000; % ft
    % mission.M = 0.85;           
    
    % climate profile
    g = 9.81;
    alt_m = mission.alt_cruise * 0.3048; % ft to meter
    [~, a_cruise, P_cruise, rho_cruise] = atmosisa(alt_m);
    V_cruise = mission.M * a_cruise;     
    delta = P_cruise / 101325;           

    % Breguet Range Iteration
    W_start = (ac.OEW + ac.payload) * 1.12; 
    
    % L/D
    CL = (W_start * g) / (0.5 * rho_cruise * V_cruise^2 * ac.S);
    CD = ac.CD0 + ac.k * CL^2;
    L_over_D = CL / CD;

    % thurst and SFC
    Thrust_total = (W_start * g) / L_over_D;
    Fn_per_eng = Thrust_total / 2; 

    % the real SFC
    SFC = eng.SFC_A + eng.SFC_B * (Fn_per_eng / (delta * eng.Fn0));

    % breguet equation
    % Range = (V/g/SFC) * (L/D) * ln(W_start / W_end)
    range_m = mission.range_nm * 1852;
    weight_ratio = exp((range_m * g * SFC) / (V_cruise * L_over_D));
    W_end = W_start / weight_ratio;
    
    total_fuel_burn = W_start - W_end;

    fprintf('input range:          %d nm\n', mission.range_nm);
    fprintf('cruise alttitude:     %d ft (M%.2f)\n', mission.alt_cruise, mission.M);
    fprintf('L/D:   %.2f\n', L_over_D);
    fprintf('SFC:   %.4e kg/N/s\n', SFC);
    fprintf('fuel consumption:     %.2f kg\n', total_fuel_burn);
end
