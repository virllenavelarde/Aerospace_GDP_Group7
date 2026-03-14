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

function [ThrustToWeightRatio, WingLoading] = ConstraintAnalysis(obj, doPlot)
if nargin < 2, doPlot = true; end
% ConstraintAnalysis  Builds constraint curves and selects a design point.
%
% Feasible region (as shaded here): between TOL (blue) and feasible envelope (black),
% and only for W/S <= WSmax_all.

    % ---- Wing loading grid (SI: N/m^2) ----
    WSmin = obj.WS_min;
    WSmax = obj.WS_max;
    WS = linspace(WSmin, WSmax, 300);
    WS = WS(:).';  % row

    % ---- Subconstraints (T/W vs W/S) ----
    TW_to   = toRow(B777.geom.subconstraint.TOL(obj, WS),  numel(WS), 'TOL');
    TW_roc  = toRow(B777.geom.subconstraint.ROC(obj, WS),  numel(WS), 'ROC');
    TW_tocg = toRow(B777.geom.subconstraint.TOCG(obj, WS), numel(WS), 'TOCG');
    TW_macs = toRow(B777.geom.subconstraint.MACS(obj, WS), numel(WS), 'MACS');

    TW_stack = [TW_to; TW_roc; TW_tocg; TW_macs];
    TW_env   = max(TW_stack, [], 1);

    % ---- Vertical constraints (max W/S) ----
    WSmax_lfl      = min(B777.geom.subconstraint.LFL(obj),      [], 'all');
    WSmax_approach = min(B777.geom.subconstraint.Approach(obj), [], 'all');
    WSmax_ceiling  = min(B777.geom.subconstraint.Ceiling(obj),  [], 'all');
    WSmax_all      = min([WSmax_lfl, WSmax_approach, WSmax_ceiling]);

    % ---- Feasible masking (by W/S vertical limits) ----
    feasible = WS <= WSmax_all;
    TW_env_feas = TW_env;
    TW_env_feas(~feasible) = NaN;

    % If feasible region is empty, expand WS grid downward so you can see stuff
    if ~any(feasible)
        fprintf("[ConstraintAnalysis] WARNING: feasible region empty (WSmax_all < WSmin). Expanding WS grid.\n");
        WSmin2 = max(500, 0.7*WSmax_all);   % keep sane
        WS = linspace(WSmin2, WSmax, 400);
        WS = WS(:).';

        TW_to   = toRow(B777.geom.subconstraint.TOL(obj, WS),  numel(WS), 'TOL');
        TW_roc  = toRow(B777.geom.subconstraint.ROC(obj, WS),  numel(WS), 'ROC');
        TW_tocg = toRow(B777.geom.subconstraint.TOCG(obj, WS, AEO), numel(WS), 'TOCG');
        TW_macs = toRow(B777.geom.subconstraint.MACS(obj, WS), numel(WS), 'MACS');

        TW_env = max([TW_to; TW_roc; TW_tocg; TW_macs], [], 1);

        feasible = WS <= WSmax_all;
        TW_env_feas = TW_env;
        TW_env_feas(~feasible) = NaN;
    end

    % ---- Pick design point (your heuristic) ----
    WS_target = 0.9 * WSmax_all;
    WS_target = min(max(WS_target, min(WS)), max(WS));  % clamp to grid

    finiteMask = isfinite(TW_env_feas);
    if nnz(finiteMask) >= 2
        TW_target = interp1(WS(finiteMask), TW_env_feas(finiteMask), WS_target, 'linear', 'extrap');
    else
        fprintf("[ConstraintAnalysis] WARNING: not enough finite feasible points. Using overall envelope.\n");
        finiteMask2 = isfinite(TW_env);
        if nnz(finiteMask2) < 2
            error("[ConstraintAnalysis] All TW curves are NaN/Inf. Check subconstraints outputs.");
        end
        TW_target = interp1(WS(finiteMask2), TW_env(finiteMask2), WS_target, 'linear', 'extrap');
    end

    % ---- Output ----
    WingLoading        = WS_target;
    ThrustToWeightRatio = TW_target;

    % NOTE: These only "stick" if obj is a handle class. If obj is a value class,
    % the caller should assign the returned outputs (which you already do in size()).
    obj.WingLoading         = WingLoading;
    obj.ThrustToWeightRatio = ThrustToWeightRatio;

    % ---- Plot ----
    if doPlot
        figure(101); clf;
        ax = axes('Parent', gcf);
        hold(ax,'on'); grid(ax,'on');

        WS_lbft = WS .* SI.lbft;

        % Axis limits first (so the patch uses correct bounds)
        xlim(ax, [min(WS_lbft), 1.2*WSmax_all*SI.lbft]);

        TW_for_ylim = TW_env(isfinite(TW_env));
        if isempty(TW_for_ylim), TW_for_ylim = 0.3; end
        ylim(ax, [0, 1.15*max(TW_for_ylim)]);

        % --- Shade region BETWEEN TOL (blue) and feasible envelope (black) ---
        idx = feasible & isfinite(TW_env_feas) & isfinite(TW_to);
        xF = WS_lbft(idx);
        yTop = TW_env_feas(idx);
        yBot = TW_to(idx);

        % keep only points where top is actually above bottom
        good = (yTop >= yBot);
        xF = xF(good); yTop = yTop(good); yBot = yBot(good);

        if numel(xF) >= 2
            p = patch(ax, ...
                [xF, fliplr(xF)], ...
                [yBot, fliplr(yTop)], ...
                [0.85 1.0 0.85], ...
                'EdgeColor','none', ...
                'FaceAlpha',0.25, ...
                'DisplayName','Feasible region');
            uistack(p,'bottom');  % ensure it stays behind lines
        end

        % Curves
        plot(ax, WS_lbft, TW_to,   'LineWidth',2,'DisplayName','TOL');
        plot(ax, WS_lbft, TW_roc,  'LineWidth',2,'DisplayName','ROC');
        plot(ax, WS_lbft, TW_tocg, 'LineWidth',2,'DisplayName','TOCG');
        plot(ax, WS_lbft, TW_macs, 'LineWidth',2,'DisplayName','MACS');

        plot(ax, WS_lbft, TW_env,      'k--','LineWidth',2,'DisplayName','Envelope');
        if any(isfinite(TW_env_feas))
            plot(ax, WS_lbft, TW_env_feas, 'k-','LineWidth',2,'DisplayName','Envelope (feasible)');
        end

        % Vertical limits
        xline(ax, WSmax_lfl      * SI.lbft, ':','LineWidth',2,'DisplayName','LFL limit');
        xline(ax, WSmax_approach * SI.lbft, ':','LineWidth',2,'DisplayName','Approach limit');
        xline(ax, WSmax_ceiling  * SI.lbft, ':','LineWidth',2,'DisplayName','Ceiling limit');
        xline(ax, WSmax_all      * SI.lbft, '-','LineWidth',2,'DisplayName','WS max');

        % Design point
        plot(ax, WingLoading*SI.lbft, ThrustToWeightRatio, 'ko', ...
            'MarkerFaceColor','k','DisplayName','Design point');

        xlabel(ax,'W/S [lb/ft^2]');
        ylabel(ax,'T/W [-]');
        title(ax,'Constraint Diagram');
        legend(ax,'show','Location','best');
        drawnow;
    end
end

function y = toRow(x, n, name)
%TOROW Force output to be 1xN row vector. Throw a helpful error if not.
    if isscalar(x)
        y = repmat(x, 1, n);
        return;
    end
    y = x(:).';
    if numel(y) ~= n
        error('Subconstraint %s returned %d elements, expected %d.', name, numel(y), n);
    end
end