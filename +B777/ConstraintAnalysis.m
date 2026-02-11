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
    WS = linspace(4000, 9000, 300); %
    WS = WS(:).'; % make column vector for consistency

    % ---- Call take-off constraint (returns T/W curve) ----
    TW_to = toRow(B777.geom.subconstraint.TOL(obj, WS), numel(WS), 'TOL');
    TW_roc = toRow(B777.geom.subconstraint.ROC(obj, WS), numel(WS), 'ROC');
    TW_tocg = toRow(B777.geom.subconstraint.TOCG(obj, WS), numel(WS), 'TOCG');
    TW_macs = toRow(B777.geom.subconstraint.MACS(obj, WS), numel(WS), 'MACS');

    %envelope
    TW_env = max([TW_to; TW_roc; TW_tocg; TW_macs], [], 1); %take max across constraints for each W/S

    %vertical (each MUST become scalar lb/ft^2)
    WSmax_lfl      = B777.geom.subconstraint.LFL(obj);      WSmax_lfl      = min(WSmax_lfl(:));
    WSmax_approach = B777.geom.subconstraint.Approach(obj); WSmax_approach = min(WSmax_approach(:));
    WSmax_ceiling  = B777.geom.subconstraint.Ceiling(obj);  WSmax_ceiling  = min(WSmax_ceiling(:));

    WSmax_all = min([WSmax_lfl, WSmax_approach, WSmax_ceiling]);  % <-- scalar

    %feasible region
    feasible = (WS .* SI.lbft) <= WSmax_all;   % 1xN <= scalar
    TW_env_feas = TW_env; 
    TW_env_feas(~feasible) = NaN; %mask infeasible points for plotting

    % ---- preliminary design point ----
    WS_target_lbft2 = 0.9 *WSmax_all;  % 90% of alloable WS
    WS_target = WS_target_lbft2 / SI.lbft; % convert to SI for interpolation

    TW_target = interp1(WS, TW_env_feas, WS_target, 'linear');

    % If TW_target is NaN (outside feasible region), fall back to first finite point
    if ~isfinite(TW_target)
        idx = find(isfinite(TW_env), 1, 'first');
        WS_target = WS(idx);
        TW_target = TW_env(idx);
        WS_target_lbft2 = WS_target * SI.lbft; % convert back to lb/ft^2 for reporting
    end

    % ---- Write results back ----
    WingLoading = WS_target;
    ThrustToWeightRatio = TW_target;

    obj.WingLoading = WingLoading;
    obj.ThrustToWeightRatio = ThrustToWeightRatio;


     % ---- Plot for sanity ----
    figure(101); clf; hold on; grid on; %reuse 1 fig

    plot(WS .* SI.lbft, TW_to, ...
    'LineWidth', 2, 'DisplayName', 'Take-off Field Length');
    plot(WS .* SI.lbft, TW_roc, ...
    'LineWidth', 2, 'DisplayName', 'Rate of Climb');
    plot(WS .* SI.lbft, TW_tocg, ...
    'LineWidth', 2, 'DisplayName', 'Take-off Climb Gradient');
    plot(WS .* SI.lbft, TW_macs, ...
    'LineWidth', 2, 'DisplayName', 'Mach Number at Ceiling');

    plot(WS .* SI.lbft, TW_env, ...
    'k--','LineWidth', 2, 'DisplayName', 'Constraint Envelope', 'Color', 'k', 'LineStyle', '--');
    plot(WS .* SI.lbft, TW_env_feas, ...
    'k-','LineWidth', 2, 'DisplayName', 'Constraint Envelope (feasible)', 'Color', 'k', 'LineStyle', '--');
    
    xline(WSmax_lfl,      ':', 'LineWidth', 2, 'DisplayName', 'LFL limit');
    xline(WSmax_approach, ':', 'LineWidth', 2, 'DisplayName', 'Approach limit');
    xline(WSmax_ceiling,  ':', 'LineWidth', 2, 'DisplayName', 'Ceiling limit');
    xline(WSmax_all,      '-', 'LineWidth', 2, 'DisplayName', 'WS max (min)');

    plot(WS_target_lbft2, ThrustToWeightRatio, ...
        'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Design point');

    xlabel('W/S [lb/ft^2]'); ylabel('T/W [-]');
    ylabel('T/W [-]');
    title('Constraint Digram');
    legend('show', 'location', 'best');
end


function y = toRow(x, n, name)
%TOROW Force output to be 1xN row vector. Throw a helpful error if not.
    if isscalar(x)
        y = repmat(x, 1, n);  % scalar -> 1xN
        return;
    end
    y = x(:).';               % vector -> 1xN
    if numel(y) ~= n
        error('Subconstraint %s returned %d elements, expected %d.', name, numel(y), n);
    end
end

