%Ceiling  Wing-loading limit from level-flight ceiling condition.
%
% Corke-style: W/S = CL * q, with q = 0.5*rho*(M*a)^2
% Returns WSmax at the chosen ceiling altitude (usually cruise altitude or Alt_max).
%
% Output:
%   WSmax_ceiling_lbft2  [lb/ft^2]

    % Choose altitude for "ceiling" check:
    % Option A: use max altitude requirement 
function WSmax_SI = Ceiling(obj) % returns [Pa]
    % altitude for ceiling check
    if ~isempty(obj.TLAR.Alt_max)
        h = obj.TLAR.Alt_max;
    else
        h = obj.TLAR.Alt_cruise;
    end

    M  = obj.TLAR.M_c;
    dT = 0;

    [rho, a, ~, ~, ~, ~, ~] = cast.atmos(h, dT);
    V = M * a;
    q = 0.5 * rho * V^2;

    % use ADP hyperparameter if available
    CLc = 1.0;
    if isprop(obj,'CL_ceiling') && ~isempty(obj.CL_ceiling) && isfinite(obj.CL_ceiling)
        CLc = obj.CL_ceiling;
    end

    WSmax_SI = CLc * q;
end

