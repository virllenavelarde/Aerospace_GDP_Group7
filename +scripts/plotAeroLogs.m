%% scripts/PlotAeroLogs.m
% Loads AeroLogs_All.mat (or individual logs) and plots polar + key points.
clear; clc; close all;

% ---------- LOAD ----------
% Preferred: one file containing LogTW and LogBW
if exist("AeroLogs_All.mat","file")
    D = load("AeroLogs_All.mat");   % expects LogTW, LogBW
else
    % fallback: load separate files if you saved separately
    D = struct();
    if exist("AeroLog_TubeWing.mat","file"); tmp = load("AeroLog_TubeWing.mat"); D.LogTW = tmp.LogTW; end
    if exist("AeroLog_BoxWing.mat","file");  tmp = load("AeroLog_BoxWing.mat");  D.LogBW = tmp.LogBW; end
end

haveTW = isfield(D,"LogTW");
haveBW = isfield(D,"LogBW");

assert(haveTW || haveBW, "No logs found. Save AeroLogs_All.mat or AeroLog_*.mat first.");

% Convenience list
Logs = {};
if haveTW, Logs{end+1} = D.LogTW; end
if haveBW, Logs{end+1} = D.LogBW; end

%% ---------- SETTINGS ----------
doOverlayCompare = true;   % compare configs on same axes
doSeparate       = true;   % individual figures per config

%% ---------- PER-CONFIG PLOTS ----------
if doSeparate
    for k = 1:numel(Logs)
        L = Logs{k};
        if ~isfield(L,"Polar"); continue; end

        CL = L.Polar.CL;
        CD = L.Polar.CD;
        LD = L.Polar.LD;

        CD0 = L.CD0;
        CDi = CD - CD0;

        % Key points
        CLc = L.Cruise.CL;  CDc = L.Cruise.CD;  LDc = L.Cruise.LD;
        CLm = L.MaxLD.CL;   CDm = L.MaxLD.CD;   LDm = L.MaxLD.LD;
        CLmax = NaN;
        if isfield(L,"CL_max_clean"), CLmax = L.CL_max_clean; end

        % --- 1) Drag Polar ---
        figure(10+k); clf; grid on; hold on;
        plot(CL, CD, 'LineWidth', 2);
        if isfinite(CLc), plot(CLc, CDc, 'ko', 'MarkerFaceColor','k'); end
        plot(CLm, CDm, 'ks', 'MarkerFaceColor','k');
        if isfinite(CLmax)
            CDmax = interp1(CL, CD, CLmax, "linear", NaN);
            if isfinite(CDmax), plot(CLmax, CDmax, 'kd', 'MarkerFaceColor','k'); end
        end
        xlabel('C_L'); ylabel('C_D');
        title(sprintf('%s: Drag Polar', L.Config));
        legendStr = {'Polar'};
        if isfinite(CLc), legendStr{end+1} = sprintf('Cruise (CL=%.2f, CD=%.3f)', CLc, CDc); end
        legendStr{end+1} = sprintf('Max L/D (CL=%.2f)', CLm);
        if isfinite(CLmax), legendStr{end+1} = sprintf('CL_{max}=%.2f', CLmax); end
        legend(legendStr, 'Location','best');

        % --- 2) L/D vs CL ---
        figure(20+k); clf; grid on; hold on;
        plot(CL, LD, 'LineWidth', 2);
        if isfinite(CLc), plot(CLc, LDc, 'ko', 'MarkerFaceColor','k'); end
        plot(CLm, LDm, 'ks', 'MarkerFaceColor','k');
        if isfinite(CLmax)
            LDmaxClean = interp1(CL, LD, CLmax, "linear", NaN);
            if isfinite(LDmaxClean), plot(CLmax, LDmaxClean, 'kd', 'MarkerFaceColor','k'); end
        end
        xlabel('C_L'); ylabel('L/D');
        title(sprintf('%s: Efficiency', L.Config));
        legendStr = {'L/D'};
        if isfinite(CLc), legendStr{end+1} = sprintf('Cruise (L/D=%.1f)', LDc); end
        legendStr{end+1} = sprintf('Max L/D=%.1f', LDm);
        if isfinite(CLmax), legendStr{end+1} = sprintf('CL_{max}=%.2f', CLmax); end
        legend(legendStr, 'Location','best');

        % --- 3) Induced drag proxy CDi vs CL ---
        figure(30+k); clf; grid on; hold on;
        plot(CL, CDi, 'LineWidth', 2);
        if isfinite(CLc)
            plot(CLc, (CDc - CD0), 'ko', 'MarkerFaceColor','k');
        end
        plot(CLm, (CDm - CD0), 'ks', 'MarkerFaceColor','k');
        yline(0,'k:');
        xlabel('C_L'); ylabel('C_{Di} = C_D - C_{D0}');
        title(sprintf('%s: Induced Drag Proxy', L.Config));
        legendStr = {'C_{Di}(proxy)'};
        if isfinite(CLc), legendStr{end+1} = 'Cruise'; end
        legendStr{end+1} = 'Max L/D';
        legend(legendStr,'Location','best');

        % --- Print quick summary in command window ---
        fprintf('\n=== %s ===\n', L.Config);
        fprintf('MTOM: %.1f t | S: %.1f m^2 | b: %.1f m | AR: %.2f | W/S: %.1f lb/ft^2\n', ...
            L.MTOM_t, L.S_m2, L.b_m, L.AR, L.WS_lbft2);
        fprintf('CD0=%.4f | k(ind-fit)=%.4g\n', L.CD0, L.k_ind);
        if isfinite(CLc)
            fprintf('Cruise: CL=%.3f CD=%.4f L/D=%.2f CDi=%.4f\n', ...
                CLc, CDc, LDc, CDc - CD0);
        end
        fprintf('Max L/D: CL=%.3f CD=%.4f L/D=%.2f CDi=%.4f\n', ...
            CLm, CDm, LDm, CDm - CD0);
    end
end

%% ---------- OVERLAY COMPARISON (TW vs BW) ----------
if doOverlayCompare && numel(Logs) >= 2
    % assume first is TW and second is BW (based on how you saved); otherwise still works
    L1 = Logs{1}; L2 = Logs{2};
    if isfield(L1,"Polar") && isfield(L2,"Polar")

        % Use their own CL grids (don’t assume same length)
        CL1 = L1.Polar.CL; CD1 = L1.Polar.CD; LD1 = L1.Polar.LD;
        CL2 = L2.Polar.CL; CD2 = L2.Polar.CD; LD2 = L2.Polar.LD;

        % --- CD vs CL ---
        figure(101); clf; grid on; hold on;
        plot(CL1, CD1, 'LineWidth', 2);
        plot(CL2, CD2, 'LineWidth', 2);
        xlabel('C_L'); ylabel('C_D');
        title('Compare Drag Polars');
        legend(L1.Config, L2.Config, 'Location','best');

        % --- L/D vs CL ---
        figure(102); clf; grid on; hold on;
        plot(CL1, LD1, 'LineWidth', 2);
        plot(CL2, LD2, 'LineWidth', 2);
        xlabel('C_L'); ylabel('L/D');
        title('Compare Efficiency');
        legend(L1.Config, L2.Config, 'Location','best');

        % --- CDi proxy vs CL ---
        figure(103); clf; grid on; hold on;
        plot(CL1, CD1 - L1.CD0, 'LineWidth', 2);
        plot(CL2, CD2 - L2.CD0, 'LineWidth', 2);
        yline(0,'k:');
        xlabel('C_L'); ylabel('C_{Di} (proxy)');
        title('Compare Induced Drag Proxy');
        legend(L1.Config, L2.Config, 'Location','best');
    end
end

%% ---------- SPAN TRADE STUDY (optional) ----------
% If you saved SpanTradeStudy_Log.mat (Spans, mtoms, fuels, SpanLog)
if exist("SpanTradeStudy_Log.mat","file")
    S = load("SpanTradeStudy_Log.mat");

    figure(201); clf; grid on; hold on;
    plot(S.Spans, S.mtoms/1e3, '-o', 'LineWidth', 2);
    xlabel('Span [m]'); ylabel('MTOM [t]');
    title('Span Trade Study: MTOM vs Span');

    figure(202); clf; grid on; hold on;
    plot(S.Spans, S.fuels/1e3, '-o', 'LineWidth', 2);
    xlabel('Span [m]'); ylabel('Fuel [t]');
    title('Span Trade Study: Fuel vs Span');

    % Optional: L/Dmax vs span (if SpanLog has MaxLD)
    if isfield(S,"SpanLog") && numel(S.SpanLog) == numel(S.Spans) && isfield(S.SpanLog(1),"MaxLD")
        LDmax = arrayfun(@(x) x.MaxLD.LD, S.SpanLog);
        figure(203); clf; grid on; hold on;
        plot(S.Spans, LDmax, '-o', 'LineWidth', 2);
        xlabel('Span [m]'); ylabel('Max L/D');
        title('Span Trade Study: Max L/D vs Span');
    end
end
