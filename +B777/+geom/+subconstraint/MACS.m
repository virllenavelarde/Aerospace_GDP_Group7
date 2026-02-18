function TW_alt = MACS(obj, WS_SI)
%MACS Cruise thrust-to-weight requirement (drag polar)
% Input:
%   WS_SI : wing loading [N/m^2] (vector)
% Output:
%   TW_alt: required T/W at cruise altitude (vector same size as WS_SI)

    % --- Ensure WS is a row vector ---
    WS_SI = WS_SI(:).';   % 1xN

    % --- Cruise condition ---
    M  = obj.TLAR.M_c;
    h  = obj.TLAR.Alt_cruise;     % must be scalar [m]
    dT = 0;                       % ISA at cruise (keep consistent with spec)

    [rho, a, ~, ~, ~, ~, ~] = cast.atmos(h, dT);
    V = M * a;
    q = 0.5 * rho * V^2;          % scalar [Pa]

    % --- Aero params ---
    CD0 = obj.CD0;
    e   = obj.e;

    % --- Aspect ratio: use sized geometry if available, else assumed ---
    AR = [];
    if ~isempty(obj.Span) && ~isempty(obj.WingArea) && all(isfinite([obj.Span obj.WingArea])) ...
            && obj.WingArea > 0
        AR = obj.AR();  % Span^2 / WingArea
    end

    if isempty(AR) || ~isfinite(AR) || AR <= 0
        % Try AeroPolar first, else fallback
        if ~isempty(obj.AeroPolar) && isprop(obj.AeroPolar,'AR') && ~isempty(obj.AeroPolar.AR)
            AR = obj.AeroPolar.AR;
        else
            AR = 9.5;   % fallback assumption (set to your hyperparameter default)
        end
    end

    % --- MACS equation ---
    if isprop(obj,'AeroPolar') && ~isempty(obj.AeroPolar)
        CL = WS_SI ./ q;
        CD = obj.AeroPolar.CD(CL);
        TW_alt = CD ./ CL;
    else
        TW_alt = (q * CD0 ./ WS_SI) + (WS_SI ./ (q * pi * AR * e));
    end
end
