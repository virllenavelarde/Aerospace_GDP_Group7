%landing field length constraint using Corke landing-parameter correlation.
%returns maximum allowable W/S given required landing field length, sigma, and CLmax,landing.
function WS_Max_LFL = LFL(obj)  % returns [Pa]
    % requirement
    sL_m  = obj.TLAR.GroundRunLanding;   % [m]  %check this in ADP and TLAR
    sL_ft = sL_m * SI.ft;               % [ft]

    % landing CLmax
    CLmax_land = obj.CL_max + obj.Delta_Cl_ld;

    % airport density ratio sigma (ISA sea level by default)
    hAirport = 0;
    dT = 0;
    [~,~,~,~,~,~,sigma] = cast.atmos(hAirport, dT);

    % Corke landing parameter correlation
    LP = (sL_ft - 400) / 118;

    % Corke gives W/S in lb/ft^2: (W/S)_lbft2 = sigma * CLmax_land * LP
    WS_lbft2 = (sigma .* CLmax_land) .* LP;

    % convert lb/ft^2 -> Pa (N/m^2)
    WS_Max_LFL = WS_lbft2 / SI.lbft;
end
