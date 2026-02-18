function fuel_burn_analysis()
    % basic profile
    ac.MTOW = 319000;           % kg
    ac.OEW = 129000;            % kg
    ac.payload = 92000;         % kg
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
    mission.M = 0.85;           
    
    % climate profile
    g = 9.81;
    alt_m = mission.alt_cruise * 0.3048; % ft to meter
    [~, a_cruise, P_cruise, rho_cruise] = atmosisa(alt_m);
    V_cruise = mission.M * a_cruise;     
    delta = P_cruise / 101325;     

    % loiter profile
    mission.alt_loiter = 1500;  % ft
    mission.time_loiter = 30;   % minutes

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

    % Loiter Calculation
    alt_m_loiter = mission.alt_loiter * 0.3048;
    [~, ~, P_loiter, rho_loiter] = atmosisa(alt_m_loiter);
    delta_loiter = P_loiter / 101325;
    
    % Loiter condition: max L/D (CL_loiter = sqrt(CD0/k))
    CL_loiter = sqrt(ac.CD0 / ac.k);
    CD_loiter = ac.CD0 + ac.k * CL_loiter^2;
    L_over_D_loiter = CL_loiter / CD_loiter;

    V_loiter = sqrt((W_end * g) / (0.5 * rho_loiter * ac.S * CL_loiter));
    Thrust_loiter = (W_end * g) / L_over_D_loiter;
    SFC_loiter = eng.SFC_A + eng.SFC_B * ((Thrust_loiter / 2) / (delta_loiter * eng.Fn0));
    t_loiter_sec = mission.time_loiter * 60;
    W_end_loiter = W_end / exp(t_loiter_sec * g * SFC_loiter / L_over_D_loiter);
    loiter_fuel_burn = W_end - W_end_loiter;
    
    total_fuel_burn = W_start - W_end + loiter_fuel_burn;

    fprintf('input range:          %d nm\n', mission.range_nm);
    fprintf('cruise alttitude:     %d ft (M%.2f)\n', mission.alt_cruise, mission.M);
    fprintf('L/D:   %.2f\n', L_over_D);
    fprintf('SFC:   %.4e kg/N/s\n', SFC);
    fprintf('loiter fuel burn:     %.2f kg\n', loiter_fuel_burn);
    fprintf('fuel consumption:     %.2f kg\n', total_fuel_burn);
end
