function [obj, out] = Size(obj, verbose)
%SIZE  Iteratively size the boxwing until MTOM converges.
%
%  Convergence: OEM + Payload + BlockFuel = MTOM

if nargin < 2
    verbose = true;
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
    rho_sl  = 1.225;
    V_stall = obj.TLAR.V_app / 1.30;
    WS_land = 0.5 * rho_sl * V_stall^2 * obj.CL_max;
    WS      = min(WS_land / obj.Mf_Ldg, 8500);

    [rho_c, a_c] = BoxWing.cast.atmos(obj.TLAR.Alt_cruise);
    q_c   = 0.5 * rho_c * (obj.TLAR.M_c * a_c)^2;
    CL_c  = WS / q_c;
    CD_c  = obj.CD0 + CL_c^2 / (pi * obj.e * obj.AR());
    TW_cr = (q_c * CD_c / WS) * 1.10;
    lapse = (rho_c / rho_sl)^0.75;
    TW    = TW_cr / lapse;

    obj.WingLoading         = WS;
    obj.ThrustToWeightRatio = TW;

    %% Size wing and thrust (AR floor)
    AR_min       = 5.0;
    WingArea_max = obj.EffectiveSpan^2 / AR_min;
    obj.WingArea = min(obj.MTOM * 9.81 / obj.WingLoading, WingArea_max);

    obj.WingLoading      = obj.MTOM * 9.81 / obj.WingArea;  % keep consistent
    obj.Thrust           = obj.ThrustToWeightRatio * obj.MTOM * 9.81;
    obj.FrontWingArea    = obj.WingArea * 0.50;
    obj.RearWingArea     = obj.WingArea * 0.50;
    obj.TotalLiftingArea = obj.WingArea;

    %% Build geometry and masses
    [~, BWMass] = BoxWing.B777.BuildGeometry(obj);

    %% Compute REAL CG from mass breakdown
    all_x = cellfun(@(x) x(1), {BWMass.X});
    all_m = [BWMass.m];
    x_cg  = sum(all_m .* all_x) / sum(all_m);

    %% Compute CL_cruise at current MTOM before building polar
    obj.CL_cruise = (obj.MTOM * 9.81 * obj.Mf_TOC) / (q_c * obj.WingArea);

    %% Update aero polar — pass real CG so trim drag is correct
    BoxWing.B777.UpdateAero(obj, x_cg);

    %% Mission analysis
    [BlockFuel, TripFuel, ResFuel, Mf_TOC, ~] = ...
        BoxWing.B777.MissionAnalysis(obj, obj.TLAR.Range, obj.MTOM);

    %% OEM
    allNames = cellfun(@(x) x, {BWMass.Name}, 'UniformOutput', false);
    isFuel   = cellfun(@(n) strcmp(n,'Fuel Front Wing') || ...
                            strcmp(n,'Fuel Rear Wing'), allNames);
    isPay    = cellfun(@(n) strcmp(n,'Payload'), allNames);
    obj.OEM  = sum([BWMass(~isFuel & ~isPay).m]);

    %% MTOM closure
    relax    = 0.3;
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

out.BlockFuel = BlockFuel;
out.OEM       = obj.OEM;
out.MTOM      = obj.MTOM;
end