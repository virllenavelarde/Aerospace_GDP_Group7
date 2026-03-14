%input = obj, ws 
%output = TW required
%take off climb gradient (OEI)

function TW = TOCG(obj, WS, mode)
% mode: "AEO" or "OEI_2nd"
if nargin < 3, mode = "OEI_2nd"; end

    alt = 0;
    [rho,~] = cast.atmos(alt,0);

    CLmax_TO = obj.CL_max + obj.Delta_Cl_to;
    Vs = sqrt( 2*WS ./ (rho * CLmax_TO) );

    % Use a reasonable V2 rule (keep your 1.25 if you want)
    V  = 1.20 * Vs;
    q  = 0.5 * rho .* V.^2;

    % Use takeoff-config drag model (DO NOT use cruise AeroPolar here)
    CD0 = obj.CD_TO;
    eTO = obj.e;              % ok as placeholder (or make e_TO)
    
    AR = obj.AR();
    % Force AR to be a scalar for this subconstraint
    if isempty(AR) || ~all(isfinite(AR(:))) || any(AR(:) <= 0)
        AR = obj.AR_target;
    else
        AR = AR(1);  % take the first element if it's a vector
    end

    DoverW = q.*CD0./WS + WS./(q*pi*AR*eTO);

    switch mode
        case "AEO"
            G = obj.TLAR.TOCG_AEO_gearUp;
            G = sanitizeG(G, 0.03);
            TW = DoverW + G;
        case "OEI_2nd"
            % If TLAR doesn't have this yet, fallback
            if isprop(obj.TLAR,'TOCG_OEI_gearUp')
                G = obj.TLAR.TOCG_OEI_gearUp;
            else
                G = 0.024;
            end
            G = sanitizeG(G, 0.024);
            OEI_factor = 0.5;
            TW = (DoverW + G) ./ OEI_factor;

        otherwise
            error("Unknown TOCG mode: %s", mode);
    end
end

function g = sanitizeG(g, fallback)
g = double(g);
if isempty(g) || any(~isfinite(g(:)))
    g = fallback;
else
    g = g(1);   % force scalar
end
end
