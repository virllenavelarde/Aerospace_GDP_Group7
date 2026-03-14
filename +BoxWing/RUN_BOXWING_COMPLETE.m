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
% ADP.TLAR = cast.TLAR.BoxWing();  % Top-Level Aircraft Requirements
ADP.TLAR = BoxWing.cast.TLAR.Boxwing();  % Top-Level Aircraft Requirements
% Initialise engine (GE90-like, rubberised later in Size.m)
ADP.Engine = BoxWing.cast.eng.TurboFan.GE90(1.0, ADP.TLAR.Alt_cruise, ADP.TLAR.M_c);
%% Set boxwing-specific parameters
% Fuselage geometry
ADP.CockpitLength = 6.5;
ADP.CabinRadius   = 2.93;
ADP.CabinLength   = 70.0 - ADP.CockpitLength - ADP.CabinRadius*2*1.48;

L_f = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
ADP.FrontWingPos = 0.40 * L_f;   % 35% fuselage station
ADP.RearWingPos  = 0.90 * L_f;   % 65% fuselage station

% Boxwing configuration (no conventional tail)
ADP.V_HT = 0;   % no horizontal tail
ADP.V_VT = 0.05;   %  vertical tail

%% Set hyperparameters (design variables)
ADP.FrontWingSpan = 60;   % [m] — will vary in trade study
ADP.RearWingSpan  = 50;   % [m]
ADP.ConnectorHeight = 8;  % [m] vertical gap between wings

ADP.updateDerivedProps();  % calculate total area, effective span, AR

%% Class-I estimates (initial guesses)
ADP.MTOM    = 3.0 * ADP.TLAR.Payload;   % initial guess: 3× payload
ADP.Mf_Fuel = 0.28;                     % fuel fraction guess
ADP.Mf_res  = 0.04;                     % reserve fuel fraction
ADP.Mf_Ldg  = 0.75;                     % landing mass fraction
ADP.Mf_TOC  = 0.98;                     % top-of-climb mass fraction

%% Initialize aerodynamic polar
BoxWing.B777.UpdateAero(ADP);

%% ═══════
%  SIZING LOOP

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   BASELINE SIZING (Span = %.0f m)\n', ADP.FrontWingSpan);
fprintf('═══════════════════════════════════════════════════════════\n\n');

[ADP, sizing_out] = BoxWing.B777.Size(ADP);

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
fprintf('║  L/D cruise    : %7.1f                                  ║\n', ADP.LD_c);
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

%  PART 2 — GEOMETRY VISUALIZATION


% Helper function: safe CG calculation
cgX = @(m) sum([m.m] .* cellfun(@(x)x(1),{m.X})) / sum([m.m]);
x_cg = cgX(BoxMass);

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   GEOMETRY PLOT (Figure 1)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

figure(1); clf;
set(gcf, 'Color', 'w', 'Position', [100 100 1200 600]);

% Top view planform
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


%  PART 3 — MASS BREAKDOWN


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   MASS BREAKDOWN (Figure 2)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

figure(2); clf;
set(gcf, 'Color', 'w', 'Position', [100 100 900 700]);

% Extract mass data
allNames = cellfun(@(x) x, {BoxMass.Name}, 'UniformOutput', false);
allMass  = [BoxMass.m] / 1e3;  % convert to tonnes

% Color code: structure (blue), systems (green), fuel (orange), payload (red)
colors = repmat([0.3 0.5 0.8], length(allNames), 1);  % default blue
for i = 1:length(allNames)
    name = allNames{i};
    if contains(name, 'Fuel', 'IgnoreCase', true)
        colors(i,:) = [0.9 0.6 0.1];  % orange
    elseif strcmp(name, 'Payload')
        colors(i,:) = [0.9 0.3 0.3];  % red
    elseif contains(name, {'Systems','Avionics','Hydraulics','Electrical','APU',...
                           'Cargo','Ice','Fire','Tank','Operator','Wiring'})
        colors(i,:) = [0.3 0.7 0.4];  % green
    end
end

% Horizontal bar chart
bh = barh(allMass, 0.7);
set(bh, 'FaceColor', 'flat');
bh.CData = colors;
set(gca, 'YTick', 1:length(allNames), 'YTickLabel', allNames, 'FontSize', 9);
xlabel('Mass (tonnes)', 'FontSize', 12);
title(sprintf('Boxwing — Component Mass Breakdown  |  OEM=%.0ft  Fuel=%.0ft  Payload=%.0ft', ...
      ADP.OEM/1e3, sizing_out.BlockFuel/1e3, ADP.TLAR.Payload/1e3), 'FontSize', 12);
grid on;
xlim([0 max(allMass)*1.15]);

% Add legend
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


%  PART 5 — TRADE STUDY: SPAN vs MTOM & FUEL


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   TRADE STUDY: Wing Span Sweep\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Define span range to test
Spans = 40:2:60;   % [m]

% Pre-allocate result arrays
mtoms = zeros(size(Spans));
fuels = zeros(size(Spans));
oems  = zeros(size(Spans));
areas = zeros(size(Spans));
ARs   = zeros(size(Spans));

% Store baseline ADP to reset after each iteration
ADP0 = ADP;

fprintf('Testing %d span configurations from %.0f m to %.0f m...\n', ...
        length(Spans), min(Spans), max(Spans));
a = 0;
% Loop over spans
for i = 1:length(Spans)
    fprintf('  [%2d/%2d] Span = %.0f m ... ', i, length(Spans), Spans(i));
    
    % Reset ADP and set new span
    % ADPi = ADP0; % reset to baseline
    ADPi = BoxWing.B777.ADP(); % Tis line was changed
    ADPi.TLAR           = BoxWing.cast.TLAR.Boxwing();
    ADPi.Engine         = BoxWing.cast.eng.TurboFan.GE90(1.0, ADPi.TLAR.Alt_cruise, ADPi.TLAR.M_c);
    ADPi.CockpitLength  = ADP.CockpitLength;
    ADPi.CabinRadius    = ADP.CabinRadius;
    ADPi.CabinLength    = ADP.CabinLength;
    ADPi.V_HT           = 0;
    ADPi.V_VT           = 0.05;
    ADPi.FrontWingSpan = Spans(i);
    ADPi.RearWingSpan  = Spans(i);
    ADPi.ConnectorHeight = ADP.ConnectorHeight;
    ADPi.updateDerivedProps();


    % Fresh MTOM seed — always start from a clean estimate
    ADPi.MTOM    = 3.0 * ADPi.TLAR.Payload;
    ADPi.Mf_Fuel = 0.28;
    ADPi.Mf_res  = 0.04;
    ADPi.Mf_Ldg  = 0.75;
    ADPi.Mf_TOC  = 0.98;

    try
          % Re-size aircraft
          ADPi = BoxWing.B777.Size(ADPi);

          % Store results
          mtoms(i) = ADPi.MTOM;
          fuels(i) = ADPi.Mf_Fuel * ADPi.MTOM;
          oems(i)  = ADPi.OEM;
          areas(i) = ADPi.WingArea;
          ARs(i)   = ADPi.AR();
    
          fprintf('MTOM=%.0f t, Fuel=%.0f t, AR=%.2f\n', ...
            mtoms(i)/1e3, fuels(i)/1e3, ARs(i));
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

% Tile 1: MTOM vs Span
nexttile(1);
plot(Spans, mtoms/1e3, '-s', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.4 0.6 1.0]);
grid on;
xlabel('Span [m]', 'FontSize', 11);
ylabel('MTOM [t]', 'FontSize', 11);
title('MTOM vs Span', 'FontSize', 12, 'FontWeight', 'bold');

% Tile 2: Block Fuel vs Span
nexttile(2);
plot(Spans, fuels/1e3, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.9 0.5 0.1], 'MarkerFaceColor', [1.0 0.7 0.3]);
grid on;
xlabel('Span [m]', 'FontSize', 11);
ylabel('Block Fuel [t]', 'FontSize', 11);
title('Block Fuel vs Span', 'FontSize', 12, 'FontWeight', 'bold');

% Tile 3: OEM vs Span
nexttile(3);
plot(Spans, oems/1e3, '-d', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.3 0.7 0.4], 'MarkerFaceColor', [0.5 0.9 0.6]);
grid on;
xlabel('Span [m]', 'FontSize', 11);
ylabel('OEM [t]', 'FontSize', 11);
title('OEM vs Span', 'FontSize', 12, 'FontWeight', 'bold');

% Tile 4: Wing Area vs Span
nexttile(4);
plot(Spans, areas, '-^', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.7 0.3 0.7], 'MarkerFaceColor', [0.9 0.5 0.9]);
grid on;
xlabel('Span [m]', 'FontSize', 11);
ylabel('Wing Area [m²]', 'FontSize', 11);
title('Wing Area vs Span', 'FontSize', 12, 'FontWeight', 'bold');

% Tile 5: Aspect Ratio vs Span
nexttile(5);
plot(Spans, ARs, '-v', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [1.0 0.4 0.4]);
grid on;
xlabel('Span [m]', 'FontSize', 11);
ylabel('Aspect Ratio [-]', 'FontSize', 11);
title('Aspect Ratio vs Span', 'FontSize', 12, 'FontWeight', 'bold');

% Tile 6: Fuel Fraction vs Span
nexttile(6);
plot(Spans, (fuels./mtoms)*100, '-p', 'LineWidth', 2, 'MarkerSize', 8, ...
     'Color', [0.5 0.5 0.5], 'MarkerFaceColor', [0.7 0.7 0.7]);
grid on;
xlabel('Span [m]', 'FontSize', 11);
ylabel('Fuel Fraction [% MTOM]', 'FontSize', 11);
title('Fuel Fraction vs Span', 'FontSize', 12, 'FontWeight', 'bold');

% Overall title
title(tt, 'Boxwing Freighter — Wing Span Trade Study', ...
      'FontSize', 14, 'FontWeight', 'bold');

%  PART 6 — OPTIMUM SPAN IDENTIFICATION


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   OPTIMUM SPAN ANALYSIS\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Find span that minimizes MTOM
[mtom_min, idx_mtom] = min(mtoms);
span_opt_mtom = Spans(idx_mtom);

% Find span that minimizes fuel
[fuel_min, idx_fuel] = min(fuels);
span_opt_fuel = Spans(idx_fuel);

fprintf('Minimum MTOM:       %.1f t  at  span = %.0f m\n', mtom_min/1e3, span_opt_mtom);
fprintf('Minimum Block Fuel: %.1f t  at  span = %.0f m\n', fuel_min/1e3, span_opt_fuel);
fprintf('\n');

% Add markers to trade study plot
figure(3);
nexttile(1); hold on;
plot(span_opt_mtom, mtom_min/1e3, 'r*', 'MarkerSize', 15, 'LineWidth', 2);
text(span_opt_mtom, mtom_min/1e3, sprintf(' ← Min MTOM\n   (%.0f m)', span_opt_mtom), ...
     'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');

nexttile(2); hold on;
plot(span_opt_fuel, fuel_min/1e3, 'r*', 'MarkerSize', 15, 'LineWidth', 2);
text(span_opt_fuel, fuel_min/1e3, sprintf(' ← Min Fuel\n   (%.0f m)', span_opt_fuel), ...
     'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');


%  PART 7 — SUMMARY TABLE


fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   SUMMARY TABLE\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('%-25s | %-12s | %-12s | %-12s\n', 'Parameter', 'Baseline', 'Min MTOM', 'Min Fuel');
fprintf('%s\n', repmat('-', 1, 70));
fprintf('%-25s | %10.1f m | %10.1f m | %10.1f m\n', 'Span', ADP.EffectiveSpan, span_opt_mtom, span_opt_fuel);
fprintf('%-25s | %10.1f t | %10.1f t | %10.1f t\n', 'MTOM', ADP.MTOM/1e3, mtom_min/1e3, mtoms(idx_fuel)/1e3);
fprintf('%-25s | %10.1f t | %10.1f t | %10.1f t\n', 'Block Fuel', sizing_out.BlockFuel/1e3, fuels(idx_mtom)/1e3, fuel_min/1e3);
fprintf('%-25s | %10.1f t | %10.1f t | %10.1f t\n', 'OEM', ADP.OEM/1e3, oems(idx_mtom)/1e3, oems(idx_fuel)/1e3);
fprintf('%-25s | %10.1f m2| %10.1f m2| %10.1f m2\n', 'Wing Area', ADP.WingArea, areas(idx_mtom), areas(idx_fuel));
fprintf('%-25s | %10.2f   | %10.2f   | %10.2f\n', 'Aspect Ratio', ADP.AR(), ARs(idx_mtom), ARs(idx_fuel));
fprintf('%s\n\n', repmat('-', 1, 70));


%  PART 8 — EXPORT RESULTS

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('   EXPORTING RESULTS\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Save figures
saveas(figure(1), 'Boxwing_Geometry.png');
saveas(figure(2), 'Boxwing_MassBreakdown.png');
saveas(figure(3), 'Boxwing_TradeStudy.png');

fprintf('Figures saved:\n');
fprintf('  • Boxwing_Geometry.png\n');
fprintf('  • Boxwing_MassBreakdown.png\n');
fprintf('  • Boxwing_TradeStudy.png\n\n');

% Save trade study data to CSV
T = table(Spans', mtoms'/1e3, fuels'/1e3, oems'/1e3, areas', ARs', ...
          'VariableNames', {'Span_m', 'MTOM_t', 'BlockFuel_t', 'OEM_t', 'WingArea_m2', 'AspectRatio'});
writetable(T, 'Boxwing_TradeStudy.csv');
fprintf('Trade study data saved: Boxwing_TradeStudy.csv\n\n');


%  DONE


fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                  ANALYSIS COMPLETE                         ║\n');
fprintf('╠════════════════════════════════════════════════════════════╣\n');
fprintf('║  All results displayed in Figures 1–3 and saved to disk.   ║\n');
fprintf('║  Trade study data exported to Boxwing_TradeStudy.csv       ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');
