function WSmax_ceiling_lbft2 = Ceiling(obj)
%Ceiling  Wing-loading limit from level-flight ceiling condition.
%
% Corke-style: W/S = CL * q, with q = 0.5*rho*(M*a)^2
% Returns WSmax at the chosen ceiling altitude (usually cruise altitude or Alt_max).
%
% Output:
%   WSmax_ceiling_lbft2  [lb/ft^2]

    % Choose altitude for "ceiling" check:
    % Option A: use max altitude requirement
    if ~isempty(obj.TLAR.Alt_max)
        h = obj.TLAR.Alt_max;         % [m]
    else
        h = obj.TLAR.Alt_cruise;      % [m] fallback
    end

    % Choose Mach for ceiling check
    M = obj.TLAR.M_c;                 % [-]

    % Choose CL used for ceiling sizing (Corke suggests ~1.0 to 1.5)
    CL_ceiling = 1.0;                 % [-] set as a hyperparameter if you want

    % ISA conditions
    dT = 0;

    % Atmosphere
    [rho, a, ~, ~, ~, ~, ~] = cast.atmos(h, dT);

    % Dynamic pressure at that altitude and Mach
    V = M * a;
    q = 0.5 * rho * V^2;              % [Pa] = [N/m^2]

    % W/S in SI then convert to lb/ft^2
    WSmax_SI = CL_ceiling * q;        % [Pa]
    WSmax_ceiling_lbft2 = WSmax_SI * SI.lbft;
end
