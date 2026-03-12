function [obj, out] = Size(obj)
%SIZE  Iteratively size the boxwing until MTOM converges.
%
%  Convergence: OEM + Payload + BlockFuel = MTOM
%
%  OEM  = all mass objects EXCEPT 'Fuel Front Wing', 'Fuel Rear Wing',
%         and 'Payload'  
delta    = inf;
iter     = 0;
MAX_ITER = 50;

fprintf('  Iter |   MTOM (t) |  OEM (t) | Fuel (t) |  delta (kg)\n');
fprintf('  -----|------------|----------|----------|------------\n');

while delta > 1 && iter < MAX_ITER
    iter = iter + 1;

    %% Constraint analysis → WS and SLS T/W
    [obj.ThrustToWeightRatio, obj.WingLoading] = Boxwing.ConstraintAnalysis(obj);

    %% Size wing and thrust
    obj.WingArea  = obj.MTOM * 9.81 / obj.WingLoading;
    obj.Thrust    = obj.ThrustToWeightRatio * obj.MTOM * 9.81;

    obj.FrontWingArea    = obj.WingArea * 0.50;
    obj.RearWingArea     = obj.WingArea * 0.50;
    obj.TotalLiftingArea = obj.WingArea;

    %% Build geometry and get all mass objects
    [~, BWMass] = Boxwing.BuildGeometry(obj);

    %% Update aero polar (uses current AR)
    Boxwing.UpdateAero(obj);

    %% Mission analysis
    [BlockFuel, TripFuel, ResFuel, Mf_TOC, ~] = ...
        Boxwing.MissionAnalysis(obj, obj.TLAR.Range, obj.MTOM);

    %% OEM filter using cellfun (works reliably on struct arrays)
    %  Extract all names as a cell array of strings
    allNames  = cellfun(@(x) x, {BWMass.Name}, 'UniformOutput', false);

    isFuel    = cellfun(@(n) strcmp(n,'Fuel Front Wing') || ...
                             strcmp(n,'Fuel Rear Wing'), allNames);
    isPay     = cellfun(@(n) strcmp(n,'Payload'), allNames);
    isOEM     = ~isFuel & ~isPay;

    obj.OEM = sum([BWMass(isOEM).m]);

    %% MTOM closure (free convergence — NOT pinned)
    mtom_new = obj.OEM + obj.TLAR.Payload + BlockFuel;
    delta    = abs(obj.MTOM - mtom_new);
    obj.MTOM = mtom_new;

    obj.Mf_Fuel = BlockFuel / obj.MTOM;
    obj.Mf_TOC  = Mf_TOC;
    obj.Mf_Ldg  = (obj.MTOM - TripFuel) / obj.MTOM;
    obj.Mf_res  = ResFuel / obj.MTOM;

    fprintf('  %4d | %10.1f | %8.1f | %8.1f | %11.1f\n', ...
            iter, obj.MTOM/1e3, obj.OEM/1e3, BlockFuel/1e3, delta);
end

if iter >= MAX_ITER
    fprintf('  WARNING: max iterations (%d), delta=%.1f kg\n', MAX_ITER, delta);
else
    fprintf('  Converged in %d iterations.\n\n', iter);
end

out           = struct();
out.BlockFuel = BlockFuel;
out.OEM       = obj.OEM;
out.MTOM      = obj.MTOM;
end
