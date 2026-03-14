function WS_Max_Vapp = Approach(obj)
    % Spec requirement
    Vapp = obj.TLAR.V_app;   % [m/s] in TLAR
    Vstall = Vapp/1.3;

    % Landing CLmax
    CLmax_land = obj.CL_max + obj.Delta_Cl_ld;

    % Atmosphere (ISA, sea level)
    hAirport = 0; dT = 0;
    [rho,~,~,~,~,~,~] = cast.atmos(hAirport, dT);  % rho [kg/m^3]

    % W/S in SI (N/m^2)
    WS_SI = 0.5 * rho * Vstall^2 * CLmax_land;

    % Convert to lb/ft^2 for your constraint diagram
    WS_Max_Vapp = WS_SI * SI.lbft;  % Pa -> lb/ft^2
end
