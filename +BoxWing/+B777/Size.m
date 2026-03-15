function [obj, out] = Size(obj,verbose)
%SIZE  Iteratively size the boxwing until MTOM converges.
%
%  Convergence: OEM + Payload + BlockFuel = MTOM
%
%  OEM  = all mass objects EXCEPT 'Fuel Front Wing', 'Fuel Rear Wing',
%         and 'Payload'  
if nargin < 2
    verbose = true;   % default: show output when called normally
end

delta    = inf;
iter     = 0;
MAX_ITER = 50;

if verbose
    fprintf('  Iter |   MTOM (t) |  OEM (t) | Fuel (t) |  delta (kg)\n');
    fprintf('  -----|------------|----------|----------|------------\n');
end

while delta > 1 && iter < MAX_ITER
    iter = iter + 1;

    %% Constraint analysis → WS and SLS T/W
    % [obj.ThrustToWeightRatio, obj.WingLoading] = BoxWing.B777.ConstraintAnalysis(obj);
    % [obj.ThrustToWeightRatio, obj.WingLoading] = ConstraintAnalysis(obj);
    % Landing field constraint → W/S
    rho_sl  = 1.225;
    V_stall = obj.TLAR.V_app / 1.30;
    WS_land = 0.5 * rho_sl * V_stall^2 * obj.CL_max;
    WS      = min(WS_land / obj.Mf_Ldg, 8500);   % clamp to freighter range [N/m²]

    % Cruise drag → T/W, lapsed to SLS
    [rho_c, a_c] = BoxWing.cast.atmos(obj.TLAR.Alt_cruise);
    q_c     = 0.5 * rho_c * (obj.TLAR.M_c * a_c)^2;
    CL_c    = WS / q_c;
    CD_c    = obj.CD0 + CL_c^2 / (pi * obj.e * obj.AR());
    TW_cr   = (q_c * CD_c / WS) * 1.10;          % +10% margin
    lapse   = (rho_c / rho_sl)^0.75;
    TW      = TW_cr / lapse;

    obj.WingLoading         = WS;
    obj.ThrustToWeightRatio = TW;
    %% Size wing and thrust
    AR_min           = 5.0;
    WingArea_max     = obj.EffectiveSpan^2 / AR_min;
    obj.WingArea     = min(obj.WingArea, WingArea_max);
    % obj.WingArea  = obj.MTOM * 9.81 / obj.WingLoading;
    obj.WingLoading  = obj.MTOM * 9.81 / obj.WingArea;  % keep consistent
    
    obj.Thrust    = obj.ThrustToWeightRatio * obj.MTOM * 9.81;
    obj.FrontWingArea    = obj.WingArea * 0.50;
    obj.RearWingArea     = obj.WingArea * 0.50;
    obj.TotalLiftingArea = obj.WingArea;
    obj.FrontWingArea = obj.WingArea * 0.50;

    %% Build geometry and get all mass objects
    [~, BWMass] = BoxWing.B777.BuildGeometry(obj);

    %% Update aero polar (uses current AR)
    BoxWing.B777.UpdateAero(obj);

    %% Mission analysis
    [BlockFuel, TripFuel, ResFuel, Mf_TOC, ~] = ...
        BoxWing.B777.MissionAnalysis(obj, obj.TLAR.Range, obj.MTOM);

    %% OEM filter using cellfun (works reliably on struct arrays)
    %  Extract all names as a cell array of strings
    allNames  = cellfun(@(x) x, {BWMass.Name}, 'UniformOutput', false);

    isFuel    = cellfun(@(n) strcmp(n,'Fuel Front Wing') || ...
                             strcmp(n,'Fuel Rear Wing'), allNames);
    isPay     = cellfun(@(n) strcmp(n,'Payload'), allNames);
    isOEM     = ~isFuel & ~isPay;

    obj.OEM = sum([BWMass(isOEM).m]);

    %% MTOM closure (free convergence — NOT pinned)
    relax = 0.3; % relaxation factor to prevent divergence
    mtom_new = obj.OEM + obj.TLAR.Payload + BlockFuel;
    delta    = abs(obj.MTOM - mtom_new);
    obj.MTOM = (1 - relax) * obj.MTOM + relax * mtom_new;

    obj.Mf_Fuel = BlockFuel / obj.MTOM;
    obj.Mf_TOC  = Mf_TOC;
    obj.Mf_Ldg  = (obj.MTOM - TripFuel) / obj.MTOM;
    obj.Mf_res  = ResFuel / obj.MTOM;

    if verbose
        fprintf('  %4d | %10.1f | %8.1f | %8.1f | %11.1f\n', ...
                iter, obj.MTOM/1e3, obj.OEM/1e3, BlockFuel/1e3, delta);
    end
end

if verbose
    if iter >= MAX_ITER
        fprintf('  WARNING: max iterations (%d), delta=%.1f kg\n', MAX_ITER, delta);
    else
        fprintf('  Converged in %d iterations.\n\n', iter);
    end
end
out           = struct();
out.BlockFuel = BlockFuel;
out.OEM       = obj.OEM;
out.MTOM      = obj.MTOM;
end
