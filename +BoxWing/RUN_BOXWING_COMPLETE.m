%% BOXWING FREIGHTER — COMPLETE SIZING AND ANALYSIS


clear; clc; close all;

%%0. Setup 
fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║   BOXWING FREIGHTER — COMPREHENSIVE SIZING ANALYSIS        ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

% Ensure project root is in path
projectRoot = pwd;
addpath(projectRoot);
clear classes;


%  PART 1 — BASELINE SIZING


%% Instantiate Boxwing ADP and set TLAR
ADP = BoxWing.B777.ADP();
ADP.TLAR = BoxWing.cast.TLAR.Boxwing();
ADP.Engine = BoxWing.cast.eng.TurboFan.GE90(1.0, ADP.TLAR.Alt_cruise, ADP.TLAR.M_c);

%% Fuselage geometry
ADP.CockpitLength = 6.5;
ADP.CabinRadius   = 2.93;
ADP.CabinLength   = 70.0 - ADP.CockpitLength - ADP.CabinRadius*2*1.48;

L_f = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
ADP.FrontWingPos = 0.40 * L_f;
ADP.RearWingPos  = 0.90 * L_f;

ADP.V_HT = 0;
ADP.V_VT = 0.05;

%% Set hyperparameters — Case B: front=64.9 m, rear=54.9 m (rear = front - 10)
% EffectiveSpan = (64.9 + 54.9) / 2 = 59.9 m
% S = 59.9^2 / 10 = 358 m²  →  front wing MAC ≈ 4.8 m
% The 10 m offset matches the original geometry (connector angles inward
% from front tip to rear tip, consistent with the planform drawing).
ADP.FrontWingSpan   = 64.9;              % [m]  ICAO Cat E limit
ADP.RearWingSpan    = ADP.FrontWingSpan - 10;  % [m]  = 54.9 m
ADP.ConnectorHeight = 8;                 % [m]
ADP.AR_target       = 10.0;             % fixed AR throughout
ADP.updateDerivedProps();

%% Class-I estimates
ADP.MTOM    = 3.0 * ADP.TLAR.Payload;
ADP.Mf_Fuel = 0.28;
ADP.Mf_res  = 0.04;
ADP.Mf_Ldg  = 0.75;
ADP.Mf_TOC  = 0.98;

%% Initialize aerodynamic polar
BoxWing.B777.UpdateAero(ADP);

%% ═══════
%  SIZING LOOP

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   BASELINE SIZING (Front=%.1f m, Rear=%.1f m, AR=%.1f)\n', ADP.FrontWingSpan, ADP.RearWingSpan, ADP.AR_target);
fprintf('═══════════════════════════════════════════════════════════\n\n');
[ADP, sizing_out] = BoxWing.B777.Size(ADP);
ac = BoxWing.B777.liftingSurfaceAC(ADP);

%% Build final geometry
[BoxGeom, BoxMass] = BoxWing.B777.BuildGeometry(ADP);

%% Print key results
fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║              BASELINE SIZING RESULTS                       ║\n');
fprintf('╠════════════════════════════════════════════════════════════╣\n');
fprintf('║  MTOM          : %7.1f t                                ║\n', ADP.MTOM/1e3);
fprintf('║  OEM           : %7.1f t  (%4.1f%%)                    ║\n', ADP.OEM/1e3, ADP.OEM/ADP.MTOM*100);
fprintf('║  Block Fuel    : %7.1f t  (%4.1f%%)                    ║\n', sizing_out.BlockFuel/1e3, ADP.Mf_Fuel*100);
fprintf('║  Payload       : %7.1f t                                ║\n', ADP.TLAR.Payload/1e3);
fprintf('║  Wing Area     : %7.1f m2                               ║\n', ADP.WingArea);
fprintf('║  Eff. Span     : %7.1f m                                ║\n', ADP.EffectiveSpan);
fprintf('║  Aspect Ratio  : %7.2f                                  ║\n', ADP.AR());
fprintf('║  T/W           : %7.3f                                  ║\n', ADP.ThrustToWeightRatio);
fprintf('║  W/S           : %7.0f N/m2                             ║\n', ADP.WingLoading);
fprintf('╠════════════════════════════════════════════════════════════╣\n');
fprintf('║  CD0           : %7.4f                                  ║\n', ADP.AeroPolar.CD(0));
fprintf('║  CD (CL=0.5)   : %7.4f                                  ║\n', ADP.AeroPolar.CD(0.5));
fprintf('║  L/D cruise    : %7.1f                                  ║\n', ADP.CL_cruise / ADP.AeroPolar.CD(ADP.CL_cruise));
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');


%% ── DOC Calculation ─────────────────────────────────────────────────────
fleet_size = 6;
SAF_ratio  = 1.0;
T_max_K   = 1832; % ADP.Engine.T_Static / 1000;

[DOC_total, DOC_breakdown, no_landings, total_init, labour, V_max] = BoxWing.script.DOC( ...
    ADP.MTOM / 1e3, ...
    ADP.OEM, ...
    sizing_out.BlockFuel, ...
    fleet_size, ...
    SAF_ratio, ...
    ADP.TLAR.M_c, ...
    T_max_K);

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    DOC RESULTS                             ║\n');
fprintf('╠════════════════════════════════════════════════════════════╣\n');
fprintf('║  Crew cost        : %7.2f M$/season                    ║\n', DOC_breakdown.crew/1e6);
fprintf('║  Fuel cost        : %7.2f M$/season                    ║\n', DOC_breakdown.fuel/1e6);
fprintf('║  Landing fees     : %7.2f M$/season                    ║\n', DOC_breakdown.landing/1e6);
fprintf('║  Parking fees     : %7.2f M$/season                    ║\n', DOC_breakdown.parking/1e6);
fprintf('║  Navigation       : %7.2f M$/season                    ║\n', DOC_breakdown.navigation/1e6);
fprintf('║  Maintenance      : %7.2f M$/season                    ║\n', DOC_breakdown.maintenance/1e6);
fprintf('║  Depreciation     : %7.2f M$/season                    ║\n', DOC_breakdown.depreciation/1e6);
fprintf('║  Interest         : %7.2f M$/season                    ║\n', DOC_breakdown.interest/1e6);
fprintf('║  Insurance        : %7.2f M$/season                    ║\n', DOC_breakdown.insurance/1e6);
fprintf('╠════════════════════════════════════════════════════════════╣\n');
fprintf('║  TOTAL DOC        : %7.2f M$/season                    ║\n', DOC_total/1e6);
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

%% ── Climate Impact ──────────────────────────────────────────────────────
s_ref = 422.5;
[ATR100, climate_bd] = BoxWing.cast.eng.Engine_code(ADP.MTOM, ADP.OEM, s_ref, ADP.AR_target, ADP.TLAR.Range, ADP.TLAR.M_c);

fprintf('║  ATR100 (total)   : %.4e K                          ║\n', ATR100);
fprintf('║    CO2            : %.4e K                          ║\n', climate_bd.ATR_CO2);
fprintf('║    NOx            : %.4e K                          ║\n', climate_bd.ATR_NOx);
fprintf('║    AIC/contrails  : %.4e K                          ║\n', climate_bd.ATR_AIC);
fprintf('║    H2O            : %.4e K                          ║\n', climate_bd.ATR_H2O);


%  PART 2 — GEOMETRY VISUALIZATION


cgX = @(m) sum([m.m] .* cellfun(@(x)x(1),{m.X})) / sum([m.m]);
x_cg = cgX(BoxMass);

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   GEOMETRY PLOT (Figure 1)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

figure(1); clf;
set(gcf, 'Color', 'w', 'Position', [100 100 1200 600]);
BoxWing.cast.draw(BoxGeom, BoxMass);
hold on;
plot(x_cg, 0, 'rx', 'MarkerSize', 20, 'LineWidth', 3);
text(x_cg, -2, sprintf('CG: x=%.1f m', x_cg), ...
     'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
axis equal; grid on;
xlabel('X — Fuselage axis (m)', 'FontSize', 12);
ylabel('Y — Span (m)', 'FontSize', 12);
title(sprintf('Boxwing Freighter — Top View  |  MTOM=%.0f t  |  Fuel=%.0f t  |  Span=%.0f m', ...
      ADP.MTOM/1e3, sizing_out.BlockFuel/1e3, ADP.EffectiveSpan), 'FontSize', 14);
ylim([-0.55 0.55] * ADP.EffectiveSpan);


%  PART 2b — CONSTRAINT DIAGRAM (Figure 101)


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   CONSTRAINT DIAGRAM (Figure 101)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

try
    BoxWing.B777.ConstraintAnalysis(ADP, true);   % draws Figure 101
catch ME
    fprintf('  [WARNING] Constraint diagram failed: %s\n\n', ME.message);
end


%  PART 3 — MASS BREAKDOWN


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   MASS BREAKDOWN (Figure 2)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

figure(2); clf;
set(gcf, 'Color', 'w', 'Position', [100 100 900 700]);
allNames = cellfun(@(x) x, {BoxMass.Name}, 'UniformOutput', false);
allMass  = [BoxMass.m] / 1e3;

% Color code: structure (blue), systems (green), fuel (orange), payload (red)
colors = repmat([0.3 0.5 0.8], length(allNames), 1);
for i = 1:length(allNames)
    name = allNames{i};
    if contains(name, 'Fuel', 'IgnoreCase', true)
        colors(i,:) = [0.9 0.6 0.1];
    elseif strcmp(name, 'Payload')
        colors(i,:) = [0.9 0.3 0.3];
    elseif contains(name, {'Systems','Avionics','Hydraulics','Electrical','APU',...
                           'Cargo','Ice','Fire','Tank','Operator','Wiring'})
        colors(i,:) = [0.3 0.7 0.4];
    end
end
bh = barh(allMass, 0.7);
set(bh, 'FaceColor', 'flat');
bh.CData = colors;
set(gca, 'YTick', 1:length(allNames), 'YTickLabel', allNames, 'FontSize', 9);
xlabel('Mass (tonnes)', 'FontSize', 12);
title(sprintf('Boxwing — Component Mass Breakdown  |  OEM=%.0ft  Fuel=%.0ft  Payload=%.0ft', ...
      ADP.OEM/1e3, sizing_out.BlockFuel/1e3, ADP.TLAR.Payload/1e3), 'FontSize', 12);
grid on;
xlim([0 max(allMass)*1.15]);
legend({'Structure','Systems','Fuel','Payload'}, 'Location', 'southeast');


%  PART 4 — MISSION ANALYSIS

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   MISSION ANALYSIS\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

[BlockFuel, TripFuel, ResFuel, Mf_TOC, MissionTime, cruise_FL] = ...
    BoxWing.B777.MissionAnalysis(ADP, ADP.TLAR.Range, ADP.MTOM);

fprintf('Design Range:    %.0f NM\n', ADP.TLAR.Range * SI.Nmile);
fprintf('Trip Fuel:       %.1f t\n', TripFuel/1e3);
fprintf('Reserve Fuel:    %.1f t\n', ResFuel/1e3);
fprintf('Block Fuel:      %.1f t\n', BlockFuel/1e3);
fprintf('Mission Time:    %.1f hr\n', MissionTime/3600);
fprintf('Cruise FL:       FL%.0f\n', cruise_FL);
fprintf('\n');

%  PART 4b — LIFT DISTRIBUTION

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   LIFT DISTRIBUTION (Figure 4)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

dist_BW = BoxWing.B777.liftDistribution(ADP);
W_cr = ADP.MTOM * 9.81 * ADP.Mf_TOC;
y_centroid = dist_BW.BM_cruise / (W_cr / 2);

fprintf('BW root BM cruise  = %.3e N·m\n', dist_BW.BM_cruise);
fprintf('Lift centroid      = %.2f m from root (%.1f%% semi-span)\n', ...
        y_centroid, y_centroid / (ADP.EffectiveSpan/2) * 100);


%  PART 5 — TRADE STUDY: SPAN vs MTOM & FUEL
% AR and WingArea are FIXED at the baseline values.
% Only span varies - explores how wing structural mass and trim drag change with span at constant aerodynamic loading.


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   TRADE STUDY: Wing Span Sweep (fixed AR=%.1f, S=%.0f m²)\n', ...
        ADP.AR_target, ADP.WingArea);
fprintf('   Front span swept 55–65 m, rear = front - 10 m\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Front span swept 55–65 m; rear always = front - 10 m
% EffectiveSpan = (front + rear) / 2 = front - 5 m
FrontSpans = 55:2:65;   % [m]

% Fixed wing area from baseline
S_baseline = ADP.WingArea;

mtoms = zeros(size(FrontSpans));
fuels = zeros(size(FrontSpans));
oems  = zeros(size(FrontSpans));
areas = zeros(size(FrontSpans));
ARs   = zeros(size(FrontSpans));
EffSpans = zeros(size(FrontSpans));

fprintf('Testing %d configurations, front span %.0f–%.0f m (rear = front - 10 m)...\n', ...
        length(FrontSpans), min(FrontSpans), max(FrontSpans));
fprintf('Wing area fixed at %.1f m²  (AR varies with effective span)\n\n', S_baseline);

Spans = FrontSpans;   % alias used by plotting and export below

for i = 1:length(FrontSpans)
    b_front_i = FrontSpans(i);
    b_rear_i  = b_front_i - 10;                % rear always 10 m shorter than front
    b_eff_i   = (b_front_i + b_rear_i) / 2;   % effective span = front - 5 m
    EffSpans(i) = b_eff_i;

    fprintf('  [%2d/%2d] Front=%.0f m, Rear=%.0f m, Eff=%.1f m ... ', ...
            i, length(FrontSpans), b_front_i, b_rear_i, b_eff_i);

    ADPi = BoxWing.B777.ADP();
    ADPi.TLAR            = BoxWing.cast.TLAR.Boxwing();
    ADPi.Engine          = BoxWing.cast.eng.TurboFan.GE90(1.0, ADPi.TLAR.Alt_cruise, ADPi.TLAR.M_c);
    ADPi.CockpitLength   = ADP.CockpitLength;
    ADPi.CabinRadius     = ADP.CabinRadius;
    ADPi.CabinLength     = ADP.CabinLength;
    ADPi.V_HT            = 0;
    ADPi.V_VT            = 0.05;
    ADPi.ConnectorHeight = ADP.ConnectorHeight;

    % Span: rear = front - 10 m
    ADPi.FrontWingSpan = b_front_i;
    ADPi.RearWingSpan  = b_rear_i;

    % Fix AR so WingArea = S_baseline regardless of span
    % AR_eff = b_eff^2 / S_baseline  →  S = b_eff^2 / AR_eff = S_baseline
    ADPi.AR_target = b_eff_i^2 / S_baseline;

    ADPi.updateDerivedProps();

    % Fresh MTOM seed
    ADPi.MTOM    = 3.0 * ADPi.TLAR.Payload;
    ADPi.Mf_Fuel = 0.28;
    ADPi.Mf_res  = 0.04;
    ADPi.Mf_Ldg  = 0.75;
    ADPi.Mf_TOC  = 0.98;

    try
        ADPi = BoxWing.B777.Size(ADPi, false);   % silent

        mtoms(i) = ADPi.MTOM;
        fuels(i) = ADPi.Mf_Fuel * ADPi.MTOM;
        oems(i)  = ADPi.OEM;
        areas(i) = ADPi.WingArea;
        ARs(i)   = ADPi.AR();

        fprintf('MTOM=%.0f t, Fuel=%.0f t, AR=%.2f, S=%.0f m²\n', ...
            mtoms(i)/1e3, fuels(i)/1e3, ARs(i), areas(i));
    catch ME
        fprintf('FAILED: %s\n', ME.message);
        mtoms(i) = NaN; fuels(i) = NaN;
        oems(i)  = NaN; areas(i) = NaN; ARs(i) = NaN;
    end
end

fprintf('\nTrade study complete.\n\n');

%% Plot trade study results
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   TRADE STUDY PLOTS (Figure 3)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

figure(3); clf;
set(gcf, 'Color', 'w', 'Position', [100 100 1200 900]);
tt = tiledlayout(3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile(1);
plot(EffSpans, mtoms/1e3, '-s', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.4 0.6 1.0]);
grid on; xlabel('Effective Span [m]', 'FontSize', 11); ylabel('MTOM [t]', 'FontSize', 11);
title('MTOM vs Effective Span', 'FontSize', 12, 'FontWeight', 'bold');

nexttile(2);
plot(EffSpans, fuels/1e3, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.9 0.5 0.1], 'MarkerFaceColor', [1.0 0.7 0.3]);
grid on; xlabel('Effective Span [m]', 'FontSize', 11); ylabel('Block Fuel [t]', 'FontSize', 11);
title('Block Fuel vs Effective Span', 'FontSize', 12, 'FontWeight', 'bold');

nexttile(3);
plot(EffSpans, oems/1e3, '-d', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.3 0.7 0.4], 'MarkerFaceColor', [0.5 0.9 0.6]);
grid on; xlabel('Effective Span [m]', 'FontSize', 11); ylabel('OEM [t]', 'FontSize', 11);
title('OEM vs Effective Span', 'FontSize', 12, 'FontWeight', 'bold');

nexttile(4);
plot(EffSpans, areas, '-^', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.7 0.3 0.7], 'MarkerFaceColor', [0.9 0.5 0.9]);
yline(S_baseline, 'k--', 'LineWidth', 1.5);
grid on; xlabel('Effective Span [m]', 'FontSize', 11); ylabel('Wing Area [m²]', 'FontSize', 11);
title(sprintf('Wing Area vs Span  (fixed at %.0f m²)', S_baseline), 'FontSize', 12, 'FontWeight', 'bold');

nexttile(5);
plot(EffSpans, ARs, '-v', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [1.0 0.4 0.4]);
grid on; xlabel('Effective Span [m]', 'FontSize', 11); ylabel('Aspect Ratio [-]', 'FontSize', 11);
title('AR vs Effective Span  (S fixed, AR varies)', 'FontSize', 12, 'FontWeight', 'bold');

nexttile(6);
plot(EffSpans, (fuels./mtoms)*100, '-p', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.5 0.5 0.5], 'MarkerFaceColor', [0.7 0.7 0.7]);
grid on; xlabel('Effective Span [m]', 'FontSize', 11); ylabel('Fuel Fraction [% MTOM]', 'FontSize', 11);
title('Fuel Fraction vs Effective Span', 'FontSize', 12, 'FontWeight', 'bold');

title(tt, sprintf('Boxwing — Span Trade Study  (S=%.0f m² fixed, AR varies)', S_baseline), ...
      'FontSize', 14, 'FontWeight', 'bold');


%  PART 6 — OPTIMUM SPAN IDENTIFICATION

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   OPTIMUM SPAN ANALYSIS\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

[mtom_min, idx_mtom] = min(mtoms);
span_opt_mtom = EffSpans(idx_mtom);
[fuel_min, idx_fuel] = min(fuels);
span_opt_fuel = EffSpans(idx_fuel);

fprintf('Minimum MTOM:       %.1f t  at  eff. span = %.1f m  (front=%.0f, rear=%.0f, AR=%.2f)\n', ...
    mtom_min/1e3, span_opt_mtom, FrontSpans(idx_mtom), FrontSpans(idx_mtom)-10, ARs(idx_mtom));
fprintf('Minimum Block Fuel: %.1f t  at  eff. span = %.1f m  (front=%.0f, rear=%.0f, AR=%.2f)\n', ...
    fuel_min/1e3, span_opt_fuel, FrontSpans(idx_fuel), FrontSpans(idx_fuel)-10, ARs(idx_fuel));
fprintf('\n');

figure(3);
nexttile(1); hold on;
plot(span_opt_mtom, mtom_min/1e3, 'r*', 'MarkerSize', 15, 'LineWidth', 2);
text(span_opt_mtom, mtom_min/1e3, sprintf(' ← Min MTOM\n   (%.1f m)', span_opt_mtom), ...
     'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');

nexttile(2); hold on;
plot(span_opt_fuel, fuel_min/1e3, 'r*', 'MarkerSize', 15, 'LineWidth', 2);
text(span_opt_fuel, fuel_min/1e3, sprintf(' ← Min Fuel\n   (%.1f m)', span_opt_fuel), ...
     'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');


%  PART 7 — SUMMARY TABLE

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   SUMMARY TABLE\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('%-25s | %-12s | %-12s | %-12s\n', 'Parameter', 'Baseline', 'Min MTOM', 'Min Fuel');
fprintf('%s\n', repmat('-', 1, 70));
fprintf('%-25s | %10.1f m | %10.1f m | %10.1f m\n', 'Eff. Span',   ADP.EffectiveSpan,  span_opt_mtom,         span_opt_fuel);
fprintf('%-25s | %10.1f m | %10.1f m | %10.1f m\n', 'Front Span',  ADP.FrontWingSpan,  FrontSpans(idx_mtom),  FrontSpans(idx_fuel));
fprintf('%-25s | %10.1f m | %10.1f m | %10.1f m\n', 'Rear Span',   ADP.RearWingSpan,   FrontSpans(idx_mtom)-10, FrontSpans(idx_fuel)-10);
fprintf('%-25s | %10.1f t | %10.1f t | %10.1f t\n', 'MTOM',        ADP.MTOM/1e3,       mtom_min/1e3,          mtoms(idx_fuel)/1e3);
fprintf('%-25s | %10.1f t | %10.1f t | %10.1f t\n', 'Block Fuel',  sizing_out.BlockFuel/1e3, fuels(idx_mtom)/1e3, fuel_min/1e3);
fprintf('%-25s | %10.1f t | %10.1f t | %10.1f t\n', 'OEM',         ADP.OEM/1e3,        oems(idx_mtom)/1e3,    oems(idx_fuel)/1e3);
fprintf('%-25s | %10.1f m2| %10.1f m2| %10.1f m2\n','Wing Area',   ADP.WingArea,       areas(idx_mtom),       areas(idx_fuel));
fprintf('%-25s | %10.2f   | %10.2f   | %10.2f\n',   'Aspect Ratio',ADP.AR(),           ARs(idx_mtom),         ARs(idx_fuel));
fprintf('%s\n\n', repmat('-', 1, 70));


%  PART 8 — EXPORT RESULTS

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   EXPORTING RESULTS\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Remove axes toolbars before saving (prevents "axes toolbar" warning)
figs_to_clean = [1, 2, 3, 101];
for fnum = figs_to_clean
    if ishandle(fnum)
        axList = findall(figure(fnum), 'Type', 'axes');
        for ax = axList'
            try; ax.Toolbar.Visible = 'off'; catch; end
        end
    end
end

saveas(figure(1), 'Boxwing_Geometry.png');
saveas(figure(2), 'Boxwing_MassBreakdown.png');
if ishandle(3) && isvalid(figure(3))
    saveas(figure(3), 'Boxwing_TradeStudy.png');
else
    warning('Figure 3 (trade study) not available — skipping save.');
end
if ishandle(101)
    saveas(figure(101), 'Boxwing_ConstraintDiagram.png');
end

fprintf('Figures saved:\n');
fprintf('  • Boxwing_Geometry.png\n');
fprintf('  • Boxwing_MassBreakdown.png\n');
fprintf('  • Boxwing_TradeStudy.png\n');
fprintf('  • Boxwing_ConstraintDiagram.png\n\n');

T = table(FrontSpans', FrontSpans'-10, EffSpans', mtoms'/1e3, fuels'/1e3, oems'/1e3, areas', ARs', ...
          'VariableNames', {'FrontSpan_m','RearSpan_m','EffSpan_m','MTOM_t','BlockFuel_t','OEM_t','WingArea_m2','AspectRatio'});
writetable(T, 'Boxwing_TradeStudy.csv');
fprintf('Trade study data saved: Boxwing_TradeStudy.csv\n\n');


%  DONE

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                  ANALYSIS COMPLETE                         ║\n');
fprintf('╠════════════════════════════════════════════════════════════╣\n');
fprintf('║  All results displayed in Figures 1–3 and saved to disk.   ║\n');
fprintf('║  Trade study data exported to Boxwing_TradeStudy.csv       ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');