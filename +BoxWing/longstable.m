%% BOXWING LONGITUDINAL STABILITY ANALYSIS
%  For forward-swept rear wing configuration
%  

fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════╗\n');
fprintf('║     BOXWING STABILITY ANALYSIS - Simple Report           ║\n');
fprintf('╚═══════════════════════════════════════════════════════════╝\n\n');

%% 
%  STEP 1: LOAD AIRCRAFT

fprintf('STEP 1: Loading aircraft...\n');

projectRoot = pwd;
addpath(projectRoot);
clear classes;

ADP = Boxwing.ADP();
ADP.TLAR = cast.TLAR.Boxwing();

ADP.CockpitLength = 6.5;
ADP.CabinRadius = 2.93;
ADP.CabinLength = 70.0 - ADP.CockpitLength - ADP.CabinRadius*2*1.48;

L_f = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
ADP.FrontWingPos = 0.40 * L_f;
ADP.RearWingPos = 0.75* L_f;
ADP.FrontWingSpan = 60;
ADP.RearWingSpan = 45;
ADP.ConnectorHeight = 8;
ADP.updateDerivedProps();

ADP.MTOM = 3.0 * ADP.TLAR.Payload;
ADP.Mf_Fuel = 0.28;
Boxwing.UpdateAero(ADP);
[ADP, ~] = Boxwing.Size(ADP);
[BoxGeom, BoxMass] = Boxwing.BuildGeometry(ADP);

fprintf('  MTOM: %.1f tonnes\n', ADP.MTOM/1e3);
fprintf('  OEM:  %.1f tonnes\n\n', ADP.OEM/1e3);


%  STEP 2: AERODYNAMIC CENTER & NEUTRAL POINT


fprintf('STEP 2: Finding AC and NP...\n');

% Front Wing
S_front = ADP.FrontWingArea;
b_front = ADP.FrontWingSpan;
taper_front = 0.35;
sweep_front = 25;
c_r_front = 2*S_front / (b_front*(1+taper_front));
MAC_front = (2/3) * c_r_front * (1 + taper_front + taper_front^2) / (1 + taper_front);
ac_frac_front = 0.25 + 0.02 * sweep_front/25;
x_ac_wing = ADP.FrontWingPos + ac_frac_front * MAC_front;

% Rear Wing
S_rear = ADP.RearWingArea;
b_rear = ADP.RearWingSpan;
taper_rear = 0.38;
sweep_rear = -20;
c_r_rear = 2*S_rear / (b_rear*(1+taper_rear));
MAC_rear = (2/3) * c_r_rear * (1 + taper_rear + taper_rear^2) / (1 + taper_rear);
ac_frac_rear = 0.25 + 0.02 * abs(sweep_rear)/25;
x_ac_tail = ADP.RearWingPos + ac_frac_rear * MAC_rear;

% Tail Volume
l_tail = x_ac_tail - x_ac_wing;
V_H = (S_rear * l_tail) / (S_front * MAC_front);

% Neutral Point
downwash = 0.45;
efficiency = 0.90;
x_np = x_ac_wing + efficiency * V_H * (1 - downwash) * MAC_front;

fprintf('  Wing AC:  %.1f m\n', x_ac_wing);
fprintf('  Tail AC:  %.1f m\n', x_ac_tail);
fprintf('  NP:       %.1f m\n\n', x_np);


%  STEP 3: CG POSITIONS


fprintf('STEP 3: Calculating CG positions...\n');

cases = {
    'Empty', ...
    'Empty+Crew', ...
    'Cargo Fwd', ...
    'Cargo Aft', ...
    'Half Fuel', ...
    'Full Fuel', ...
    'T/O Fwd', ...
    'T/O Aft', ...
    'Cruise', ...
    'Landing'
};

n = length(cases);
cg_position = zeros(n, 1);
aircraft_weight = zeros(n, 1);

comp_mass = [BoxMass.m];
comp_name = {BoxMass.Name};
comp_x = cellfun(@(x) x(1), {BoxMass.X});

% Filter structure (remove fuel and payload)
structure_only = true(size(comp_name));
for i = 1:length(comp_name)
    name_lower = lower(comp_name{i});
    if ~isempty(strfind(name_lower, 'fuel')) || ~isempty(strfind(name_lower, 'payload'))
        structure_only(i) = false;
    end
end

m_struct = comp_mass(structure_only);
x_struct = comp_x(structure_only);

m_pilots = 400;
x_pilots = 3.0;
m_cargo = ADP.TLAR.Payload;
m_fuel_all = ADP.MTOM * ADP.Mf_Fuel;
m_fuel_front = m_fuel_all * 0.70;
m_fuel_rear = m_fuel_all * 0.30;
x_fuel_front = ADP.FrontWingPos + MAC_front * 0.35;
x_fuel_rear = ADP.RearWingPos + MAC_rear * 0.35;
x_cargo_front = ADP.CockpitLength + 3.0;                     % Front
x_cargo_middle = ADP.CockpitLength + ADP.CabinLength * 0.30; % Middle
x_cargo_back = ADP.CockpitLength + ADP.CabinLength * 0.45;   % 45% MAX ✓
getCG = @(m, x) sum(m .* x) / sum(m);

% 1. Empty
cg_position(1) = getCG(m_struct, x_struct);
aircraft_weight(1) = sum(m_struct);

% 2. Empty + Pilots
cg_position(2) = getCG([m_struct, m_pilots], [x_struct, x_pilots]);
aircraft_weight(2) = sum([m_struct, m_pilots]);

% 3. Cargo front
cg_position(3) = getCG([m_struct, m_pilots, m_cargo], [x_struct, x_pilots, x_cargo_front]);
aircraft_weight(3) = sum([m_struct, m_pilots, m_cargo]);

% 4. Cargo back
cg_position(4) = getCG([m_struct, m_pilots, m_cargo], [x_struct, x_pilots, x_cargo_back]);
aircraft_weight(4) = sum([m_struct, m_pilots, m_cargo]);

% 5. Half fuel
cg_position(5) = getCG([m_struct, m_pilots, m_fuel_front*0.5, m_fuel_rear*0.5], ...
                       [x_struct, x_pilots, x_fuel_front, x_fuel_rear]);
aircraft_weight(5) = sum([m_struct, m_pilots, m_fuel_front*0.5, m_fuel_rear*0.5]);

% 6. Full fuel
cg_position(6) = getCG([m_struct, m_pilots, m_fuel_front, m_fuel_rear], ...
                       [x_struct, x_pilots, x_fuel_front, x_fuel_rear]);
aircraft_weight(6) = sum([m_struct, m_pilots, m_fuel_front, m_fuel_rear]);

% 7. T/O front
cg_position(7) = getCG([m_struct, m_pilots, m_cargo, m_fuel_front, m_fuel_rear], ...
                       [x_struct, x_pilots, x_cargo_front, x_fuel_front, x_fuel_rear]);
aircraft_weight(7) = sum([m_struct, m_pilots, m_cargo, m_fuel_front, m_fuel_rear]);

% 8. T/O back
cg_position(8) = getCG([m_struct, m_pilots, m_cargo, m_fuel_front, m_fuel_rear], ...
                       [x_struct, x_pilots, x_cargo_back, x_fuel_front, x_fuel_rear]);
aircraft_weight(8) = sum([m_struct, m_pilots, m_cargo, m_fuel_front, m_fuel_rear]);

% 9. Cruise
cg_position(9) = getCG([m_struct, m_pilots, m_cargo, m_fuel_front, m_fuel_rear], ...
                       [x_struct, x_pilots, x_cargo_middle, x_fuel_front, x_fuel_rear]);
aircraft_weight(9) = sum([m_struct, m_pilots, m_cargo, m_fuel_front, m_fuel_rear]);

% 10. Landing
cg_position(10) = getCG([m_struct, m_pilots, m_cargo, m_fuel_front*0.05, m_fuel_rear*0.05], ...
                        [x_struct, x_pilots, x_cargo_middle, x_fuel_front, x_fuel_rear]);
aircraft_weight(10) = sum([m_struct, m_pilots, m_cargo, m_fuel_front*0.05, m_fuel_rear*0.05]);

cg_front = min(cg_position);
cg_back = max(cg_position);

fprintf('  CG Range: %.1f to %.1f m\n\n', cg_front, cg_back);


%  STEP 4: STATIC MARGIN

fprintf('STEP 4: Static Margin...\n');

static_margin = (x_np - cg_position) / MAC_front * 100;
sm_worst = min(static_margin);
sm_best = max(static_margin);

fprintf('  SM Range: %.1f%% to %.1f%% MAC\n', sm_worst, sm_best);

if sm_worst > 5
    status = 'STABLE';
    fprintf('  Status: STABLE\n\n');
elseif sm_worst > 0
    status = 'MARGINAL';
    fprintf('  Status: MARGINAL\n\n');
else
    status = 'UNSTABLE';
    fprintf('  Status: UNSTABLE\n\n');
end


%  STEP 5: STABILITY DERIVATIVE


fprintf('STEP 5: Cm_alpha...\n');

M = 0.82;
CL_alpha = 2*pi / sqrt(1 - M^2);
cg_cruise = cg_position(9);
h = (cg_cruise - x_ac_wing) / MAC_front;
Cm_wing = -CL_alpha * h;
Cm_tail = -efficiency * V_H * CL_alpha * (1 - downwash);
Cm_total = Cm_wing + Cm_tail;

fprintf('  Cm_alpha: %.3f /rad\n', Cm_total);
if Cm_total < 0
    fprintf('  → STABLE (negative)\n\n');
else
    fprintf('  → UNSTABLE (positive)\n\n');
end


%  SIMPLE BLACK & WHITE GRAPHS


fprintf('Creating simple B&W graphs...\n\n');

%% FIGURE 1: TOP VIEW (BLACK & WHITE, LINES ONLY)

figure(1); clf;
set(gcf, 'Position', [100 100 1200 500], 'Color', 'w');

% Fuselage outline
plot([0 L_f L_f 0 0], [-3 -3 3 3 -3], 'k-', 'LineWidth', 2);
hold on; grid on; box on;

% Front wing (simple lines)
plot([ADP.FrontWingPos ADP.FrontWingPos+8], [b_front/2 b_front/2], 'k-', 'LineWidth', 2);
plot([ADP.FrontWingPos ADP.FrontWingPos+8], [-b_front/2 -b_front/2], 'k-', 'LineWidth', 2);
plot([ADP.FrontWingPos ADP.FrontWingPos], [0 b_front/2], 'k-', 'LineWidth', 2);
plot([ADP.FrontWingPos ADP.FrontWingPos], [0 -b_front/2], 'k-', 'LineWidth', 2);
text(ADP.FrontWingPos+4, b_front/2+3, 'Front Wing', 'FontSize', 11, 'HorizontalAlignment', 'center');

% Rear wing (forward sweep - lines)
plot([ADP.RearWingPos-3 ADP.RearWingPos+5], [b_rear/2 b_rear/2], 'k-', 'LineWidth', 2);
plot([ADP.RearWingPos-3 ADP.RearWingPos+5], [-b_rear/2 -b_rear/2], 'k-', 'LineWidth', 2);
plot([ADP.RearWingPos ADP.RearWingPos], [0 b_rear/2], 'k-', 'LineWidth', 2);
plot([ADP.RearWingPos ADP.RearWingPos], [0 -b_rear/2], 'k-', 'LineWidth', 2);
text(ADP.RearWingPos+1, b_rear/2+3, 'Rear Wing (Fwd Sweep)', 'FontSize', 11, 'HorizontalAlignment', 'center');

% Connectors
plot([ADP.FrontWingPos+4, ADP.RearWingPos+1], [b_front/2, b_rear/2], 'k--', 'LineWidth', 1.5);
plot([ADP.FrontWingPos+4, ADP.RearWingPos+1], -[b_front/2, b_rear/2], 'k--', 'LineWidth', 1.5);

% AC marker (circle)
plot(x_ac_wing, 0, 'ko', 'MarkerSize', 12, 'LineWidth', 2, 'MarkerFaceColor', 'k');
text(x_ac_wing, -5, 'AC', 'FontSize', 11, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% NP marker (square)
plot(x_np, 0, 'ks', 'MarkerSize', 12, 'LineWidth', 2, 'MarkerFaceColor', 'k');
text(x_np, 5, 'NP', 'FontSize', 11, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% CG range (thick line with triangles)
plot([cg_front cg_back], [0 0], 'k-', 'LineWidth', 4);
plot(cg_front, 0, 'k^', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'k');
plot(cg_back, 0, 'k^', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'k');
text((cg_front+cg_back)/2, -9, 'CG Range', 'FontSize', 11, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

xlabel('Distance from nose (m)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Wingspan (m)', 'FontSize', 12, 'FontWeight', 'bold');
title('Boxwing Configuration - Top View', 'FontSize', 14, 'FontWeight', 'bold');
ylim([-30 30]);
xlim([0 L_f+2]);

%% FIGURE 2: STATIC MARGIN (SIMPLE BARS)

figure(2); clf;
set(gcf, 'Position', [150 150 1000 500], 'Color', 'w');

% Simple bar chart (black & white)
bar(1:n, static_margin, 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 1.5);
hold on; grid on; box on;

% Reference line at 5%
plot([0 n+1], [5 5], 'k--', 'LineWidth', 2);
text(1, 6, '5% (Safe Minimum)', 'FontSize', 10);

% Zero line
plot([0 n+1], [0 0], 'k-', 'LineWidth', 1);

% Highlight worst case
[~, idx_worst] = min(static_margin);
bar(idx_worst, static_margin(idx_worst), 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k', 'LineWidth', 2);

ylabel('Static Margin (% MAC)', 'FontSize', 12, 'FontWeight', 'bold');
title('Static Margin for Each Loading Case', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', 1:n, 'XTickLabel', 1:n);
xlabel('Case Number', 'FontSize', 12, 'FontWeight', 'bold');

%% FIGURE 3: CG TRAVEL (DOTS AND LINES)

figure(3); clf;
set(gcf, 'Position', [200 200 900 600], 'Color', 'w');

% Simple line plot with dots
plot(cg_position, aircraft_weight/1e3, 'ko-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'k');
hold on; grid on; box on;

% NP line
plot([x_np x_np], [0 max(aircraft_weight/1e3)*1.1], 'k--', 'LineWidth', 2);
text(x_np-1, max(aircraft_weight/1e3)*0.9, 'NP Limit', 'FontSize', 11, 'FontWeight', 'bold');

% Mark worst case
plot(cg_position(idx_worst), aircraft_weight(idx_worst)/1e3, 'ko', 'MarkerSize', 14, 'LineWidth', 3);
text(cg_position(idx_worst)+1, aircraft_weight(idx_worst)/1e3, sprintf('Case %d\n(Worst)', idx_worst), 'FontSize', 10);

xlabel('CG Position (m)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Aircraft Mass (tonnes)', 'FontSize', 12, 'FontWeight', 'bold');
title('CG Travel vs Aircraft Mass', 'FontSize', 14, 'FontWeight', 'bold');
xlim([cg_front-2, x_np+3]);
ylim([0, max(aircraft_weight/1e3)*1.1]);

%% FIGURE 4: STABILITY CURVE (SIMPLE LINE)

figure(4); clf;
set(gcf, 'Position', [250 250 800 500], 'Color', 'w');

alpha_deg = -5:1:15;
Cm = Cm_total * alpha_deg * pi/180;

plot(alpha_deg, Cm, 'k-', 'LineWidth', 2.5);
hold on; grid on; box on;
plot(alpha_deg, zeros(size(alpha_deg)), 'k--', 'LineWidth', 1);

if Cm_total < 0
    text(8, -0.15, 'STABLE', 'FontSize', 14, 'FontWeight', 'bold');
    text(8, -0.18, '(Negative slope)', 'FontSize', 11);
end

xlabel('Angle of Attack (deg)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Pitching Moment Cm', 'FontSize', 12, 'FontWeight', 'bold');
title('Stability: Cm vs Angle of Attack', 'FontSize', 14, 'FontWeight', 'bold');

%% PRINT SUMMARY TABLE

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('                   STABILITY SUMMARY                         \n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('GEOMETRY:\n');
fprintf('  Fuselage length:    %.1f m\n', L_f);
fprintf('  Front wing:         %.1f m span, +25° sweep\n', b_front);
fprintf('  Rear wing:          %.1f m span, -20° forward sweep\n', b_rear);
fprintf('\n');

fprintf('KEY POSITIONS:\n');
fprintf('  Wing AC:            %.1f m\n', x_ac_wing);
fprintf('  Neutral Point:      %.1f m\n', x_np);
fprintf('  CG forward limit:   %.1f m\n', cg_front);
fprintf('  CG aft limit:       %.1f m\n', cg_back);
fprintf('\n');

fprintf('STABILITY METRICS:\n');
fprintf('  Tail volume (V_H):  %.3f\n', V_H);
fprintf('  SM minimum:         %.1f%% MAC (Case %d: %s)\n', sm_worst, idx_worst, cases{idx_worst});
fprintf('  SM maximum:         %.1f%% MAC\n', sm_best);
fprintf('  Cm_alpha:           %.3f /rad\n', Cm_total);
fprintf('\n');

fprintf('LOADING CASES:\n');
fprintf('  #  | Case          | CG (m) | Mass (t) | SM (%%)\n');
fprintf('  ---|---------------|--------|----------|-------\n');
for i = 1:n
    fprintf('  %2d | %-13s | %6.1f | %8.1f | %+6.1f\n', ...
            i, cases{i}, cg_position(i), aircraft_weight(i)/1e3, static_margin(i));
end
fprintf('\n');

fprintf('CONCLUSION: %s\n', status);
if strcmp(status, 'STABLE')
    fprintf('  → Safe to fly in all loading conditions\n');
elseif strcmp(status, 'MARGINAL')
    fprintf('  → Barely stable - be careful with cargo loading\n');
    fprintf('  → Recommend: Add %.0f kg ballast at nose\n', abs((x_np-cg_back)*ADP.MTOM/(cg_back-3)));
else
    fprintf('  → UNSAFE - must redesign\n');
end

fprintf('\n═══════════════════════════════════════════════════════════\n');
fprintf('                    ANALYSIS COMPLETE                         \n');
fprintf('═══════════════════════════════════════════════════════════\n\n');
fprintf('4 figures created (use print command to save manually)\n\n');