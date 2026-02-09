%function [ThrustToWeightRatio,WingLoading] = ConstraintAnalysis(obj)

%% estimate T/W and W/S from constraint analysis
% for now just setting to those of B777

%refer to cork 54/406
%first estimation


% ---------------------- TODO -----------------------
% --------- update with constraint analysis ---------
%obj.ThrustToWeightRatio = (513e3*2)/(347815*9.81);
%obj.WingLoading = (347815*9.81)/(473.3*cosd(31.6));
% obj.WingLoading = (347815*9.81)/436.8;

% set Wing Area and Thrust
%SweepQtrChord = real(acosd(0.75.*obj.Mstar./obj.TLAR.M_c)); % quarter chord sweep angle
%obj.WingArea = obj.MTOM*9.81/obj.WingLoading/cosd(SweepQtrChord);
%obj.Thrust = obj.ThrustToWeightRatio * obj.MTOM * 9.81;


%end

function [ThrustToWeightRatio, WingLoading] = ConstraintAnalysis(obj)
% ConstraintAnalysis  Builds (for now) the TOFL constraint curve and picks a
% preliminary design point.

    % ---- Wing loading grid (SI: N/m^2) ----
    WS = linspace(4000, 9000, 300);

    % ---- Call take-off constraint (returns T/W curve) ----
    TW_to = B777.geom.subconstraint.TOL(obj, WS);

    % ---- Plot for sanity ----
    figure; hold on; grid on;
    plot(WS .* SI.lbft, TW_to, 'LineWidth', 2);  
    xlabel('W/S [lb/ft^2]');
    ylabel('T/W [-]');
    title('Take-off Length Constraint (Corke)');

    % ---- preliminary design point ----
    WS_target = 7000;  % N/m^2 (example)
    TW_target = interp1(WS, TW_to, WS_target, 'linear');

    % If TW_target is NaN (outside feasible region), fall back to first finite point
    if ~isfinite(TW_target)
        idx = find(isfinite(TW_to), 1, 'first');
        WS_target = WS(idx);
        TW_target = TW_to(idx);
    end

    % ---- Write results back ----
    WingLoading = WS_target;
    ThrustToWeightRatio = TW_target;

    obj.WingLoading = WingLoading;
    obj.ThrustToWeightRatio = ThrustToWeightRatio;

end

