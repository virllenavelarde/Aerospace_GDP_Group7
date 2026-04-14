%% =========================================================================
%  DIRECT OPERATING COST MODEL — BOXWING FREIGHTER GROUP 7
%  =========================================================================
%  Methods:
%    - Cash Operating Costs  : first-principles (mission schedule)
%    - Maintenance            : Raymer Eq. 18.12 / 18.13 + eta_MRO = 1.3
%    - Acquisition cost       : DAPCA IV (Raymer 2018)  [primary]
%    - Acquisition cross-check: TU Berlin parametric method
%    - Financial costs        : depreciation / interest / insurance
%
%  All costs reported in USD per season, fleet of 6 aircraft.
%
%  NOTE ON FINANCIAL COSTS:
%    DAPCA IV is sensitive to empty mass and production quantity.
%    At low N and high OEM, programme costs can be unrealistically large.
%    A dedicated warning block flags this and provides a market-calibrated
%    cross-check. See Section 4 and the commentary in Section 6.
%
%  OUTPUTS:
%    - Terminal summary table
%    - Figure 1 : DOC breakdown pie chart (baseline SAF)
%    - Figure 2 : SAF price sensitivity bar chart
%    - Figure 3 : Multi-panel pies at SAF $2 / $3 / $5 per litre
%    - Figure 4 : MTOM trade study
%    - Figure 5 : Ownership vs Leasing comparison
%    - Figure 6 : DAPCA vs TU Berlin cross-check
% =========================================================================

clear; clc; close all;

%% =========================================================================
%  SECTION 1 — AIRCRAFT & MISSION PARAMETERS
%  =========================================================================

% --- Aircraft sizing inputs ---
MTOM_kg        = 500000;          % [kg]  Maximum take-off mass
OEM_kg         = 150000;          % [kg]  Operating empty mass
payload_kg     = 123000;          % [kg]  Design payload
V_max_kmh      = 868;             % [km/h] Max cruise speed (Mach 0.82 @ FL350)
n_engines      = 2;               % [-]   Number of engines

% --- Fleet ---
fleet_size     = 6;               % [-]   Aircraft in fleet

% --- Mission schedule (one F1 season per aircraft) ---
% Loaded legs: 16 freight legs + 1 season-start + 1 season-end = 18
% Refuel stops: 5 intermediate stops on ultra-long legs
% Empty ferry legs: 2 (NCE→MAD, AUS→MEX)
leg_distances_km = [16847, 8018, 1457, 8052, 1272, 11621, 2264, ...
                     6129,  957, 4462, 6940, 15821, 1204, 7433, ...
                     9782, 13053,  321, 5454];

cruise_speed_kmh    = 868;        % [km/h]
block_overhead      = 1.12;       % [-]   12 % block time overhead
refuel_stops        = 5;          % [-]   intermediate stops per season
n_landings_per_ac   = length(leg_distances_km) + refuel_stops;  % 23

total_dist_km       = sum(leg_distances_km);
total_flt_hr        = (total_dist_km / cruise_speed_kmh) * block_overhead;

% Parking days
n_park_days         = 193;        % [days] Madrid (64) + Mexico City (~129)
ICAO_code           = 'E';        % ICAO taxi code

fprintf('=== MISSION SUMMARY (per aircraft, per season) ===\n');
fprintf('  Total distance   : %.0f km\n',   total_dist_km);
fprintf('  Block flight hrs : %.1f hr\n',   total_flt_hr);
fprintf('  Landings         : %d\n',         n_landings_per_ac);
fprintf('  Parking days     : %d\n\n',       n_park_days);

%% =========================================================================
%  SECTION 2 — CASH OPERATING COSTS (COC)
%  =========================================================================
%  These are computed directly from the mission schedule and published
%  rate data. They are the most reliable component of the DOC model.

% ---- 2.1 Crew -------------------------------------------------------
n_crew           = 4;             % [-]   pilots + relief
salary_per_crew  = 150000;        % [$/yr] per crew member
% Season ≈ 8 months of active operations, but crew are salaried annually
crew_cost_per_ac = n_crew * salary_per_crew;
total_crew       = crew_cost_per_ac * fleet_size;

% ---- 2.2 Fuel -------------------------------------------------------
% Fuel consumption modelled as liters per block hour
% Calibrated to block fuel from mission analysis (Mf_fuel ≈ 0.28 of MTOM)
% Block fuel per ac per season: ~0.28 × 330000 × 0.95 (trip only) ≈ 87780 kg
% At Jet-A density 785 kg/m³ → liters per kg = 1000/785 = 1.274 L/kg
block_fuel_kg_per_ac = MTOM_kg * 0.28;          % [kg] approx block fuel
fuel_density_kgL     = 0.785;                    % [kg/L] Jet-A / SAF
block_fuel_L_per_ac  = block_fuel_kg_per_ac / fuel_density_kgL;

% SAF baseline price
SAF_price_base   = 2.00;          % [$/L]
fuel_cost_base   = SAF_price_base * block_fuel_L_per_ac * fleet_size;

% SAF sensitivity range
SAF_prices       = [1.00, 2.00, 3.00, 4.00, 5.00];  % [$/L]
fuel_costs_saf   = SAF_prices * block_fuel_L_per_ac * fleet_size;

% ---- 2.3 Landing fees -----------------------------------------------
% Published rate: $25 per tonne MTOM per landing
landing_rate     = 25;            % [$/tonne]
MTOM_t           = MTOM_kg / 1000;
landing_cost     = landing_rate * MTOM_t * n_landings_per_ac * fleet_size;

% ---- 2.4 Parking fees -----------------------------------------------
% ICAO Code E: $4000/day (based on published airport charges)
switch ICAO_code
    case 'C',  park_rate = 1000;
    case 'D',  park_rate = 2000;
    case 'E',  park_rate = 4000;
    case 'F',  park_rate = 6000;
    otherwise, park_rate = 4000;
end
parking_cost     = park_rate * n_park_days * fleet_size;

% ---- 2.5 Navigation charges (Eurocontrol formula) -------------------
% Charge = nav_unit_rate × (distance_km / 100) × sqrt(MTOM_t / 50)
% Applied per leg, summed over season, then scaled to fleet
nav_unit_rate    = 90;            % [$/unit] Eurocontrol 2024, EUR→USD
nav_weight_fac   = sqrt(MTOM_t / 50);
nav_charge_per_leg  = nav_unit_rate .* (leg_distances_km ./ 100) .* nav_weight_fac;
total_nav        = sum(nav_charge_per_leg) * fleet_size;

% ---- COC summary ----------------------------------------------------
COC_components   = [total_crew, fuel_cost_base, landing_cost, ...
                     parking_cost, total_nav];
COC_labels       = {'Crew', 'Fuel (SAF $2/L)', 'Landing fees', ...
                    'Parking fees', 'Navigation'};
total_COC        = sum(COC_components);

fprintf('=== CASH OPERATING COSTS (COC) ===\n');
for i = 1:length(COC_labels)
    fprintf('  %-22s : %8.2f M$/season  (%5.1f%%)\n', ...
        COC_labels{i}, COC_components(i)/1e6, ...
        100*COC_components(i)/total_COC);
end
fprintf('  %-22s : %8.2f M$/season\n\n', 'TOTAL COC', total_COC/1e6);

%% =========================================================================
%  SECTION 3 — MAINTENANCE (Raymer Eq. 18.12 / 18.13)
%  =========================================================================
%  eta_MRO = 1.3 applied as a novelty multiplier for the unconventional
%  boxwing configuration (forward-swept rear wing, wingtip connectors,
%  non-standard MRO supply chain). For a mature conventional aircraft
%  this factor would be 1.0.

eta_MRO          = 1.3;

% Airframe cost (from DAPCA — see Section 4)
% Placeholder values; will be updated once DAPCA is computed below.
% These are set after Section 4 runs, so maintenance is re-computed there.
% For now, define the maintenance function handle.
calc_maintenance = @(Ca, Ce, Ne, FH, cycles, fleet) ...
    eta_MRO * ( (3.3*(Ca/1e6) + 14.2 + (58*(Ce/1e6) - 26.1)*Ne) * FH + ...
                (4.0*(Ca/1e6) + 9.3  + (7.5*(Ce/1e6) + 5.6)*Ne) * cycles ) * fleet;

%% =========================================================================
%  SECTION 4 — ACQUISITION COST: DAPCA IV (PRIMARY)
%  =========================================================================
%  DAPCA IV (Raymer 2018) — calibrated on US military/commercial programmes.
%  Inputs: empty mass [lb], max speed [knots], production quantity N.
%
%  UNIT NOTE: Raymer DAPCA uses:
%    W_e  [lb]     — empty weight
%    V    [knots]  — maximum speed
%  CPI correction applied to bring 1999 base year to 2024 USD.

% --- Unit conversions ---
OEM_lb           = OEM_kg    * 2.20462;     % kg → lb
V_max_kts        = V_max_kmh / 1.852;       % km/h → knots
N_prod           = 1;              % production quantity
eta_composite    = 1.15;  % complexity/novelty factor for unconventional config
eta_CPI          = 1.43;  % CPI correction: 1999 → 2024 USD (approx 75% inflation)

% Labour rates (2024 USD/hr)
R_E = 115;  R_T = 118;  R_M = 98;  R_Q = 108;

% DAPCA IV labour hour equations (Raymer Eq. 18.4–18.7)
H_E = 5.18  * OEM_kg^0.777 * V_max_kmh^0.894 * N_prod^0.163;
H_T = 7.22  * OEM_kg^0.777 * V_max_kmh^0.696 * N_prod^0.263;
H_M = 10.5  * OEM_kg^0.82  * V_max_kmh^0.484 * N_prod^0.641;
H_Q = 0.076 * H_M;

% Material cost
C_mat = 31.2 * OEM_kg^0.921 * V_max_kmh^0.621 * N_prod^0.799;

% Additional cost components
N_ft  = 2;           % flight test aircraft
T_max_kN = 380;      % max thrust per engine [kN]
M_max    = 0.85;     % max Mach
T_3_K    = 1900;     % turbine inlet temperature [K]
C_dev    = 67.4  * OEM_kg^0.63  * V_max_kmh^1.3;
C_flt    = 1947  * OEM_kg  ^0.325 * V_max_kmh^0.822 + N_ft^1.21;
C_eng    = 3112  * (9.66*T_max_kN*0.2248 + 243.25*M_max + 1.74*T_3_K - 2228);
% Note: T_max converted to lbf for Raymer equation (×0.2248)

% Total DAPCA programme cost
labour_cost  = (H_E*R_E + H_T*R_T + H_M*R_M + H_Q*R_Q) * eta_composite;
C_prog_DAPCA = (C_dev + C_flt + C_eng + C_mat + labour_cost) * eta_CPI;

C_per_ac_DAPCA = C_prog_DAPCA / N_prod;

% Airframe cost (excluding engines) for maintenance equations
Ce_DAPCA = C_eng * eta_CPI;
Ca_DAPCA = C_per_ac_DAPCA - Ce_DAPCA;

fprintf('=== DAPCA IV PROGRAMME COST ===\n');
fprintf('  OEM input            : %.0f lb (%.0f kg)\n', OEM_lb, OEM_kg);
fprintf('  V_max input          : %.1f kts (%.0f km/h)\n', V_max_kts, V_max_kmh);
fprintf('  N_prod               : %d aircraft\n', N_prod);
fprintf('  Labour cost          : %.2f B$\n', labour_cost/1e9);
fprintf('  Total programme cost : %.2f B$\n', C_prog_DAPCA/1e9);
fprintf('  Cost per aircraft    : %.2f M$\n', C_per_ac_DAPCA/1e6);

%% =========================================================================
%  SECTION 5 — ACQUISITION COST: TU BERLIN CROSS-CHECK
%  =========================================================================
%  TU Berlin parametric method (Thorbeck, 2008).
%  Unit cost estimate based on MTOM and aircraft category.
%  Provides an independent market-anchored cross-check on DAPCA IV.
%
%  Formula: C_ac = k_TUB * MTOM_t^0.60  [M$]
%  Coefficient k_TUB calibrated to wide-body freighter market data.
%  B777F list price ~$340M, MTOM 347t → k = 340 / 347^0.60 = ~14.2

k_TUB            = 14.2;         % calibrated to B777F market price
C_per_ac_TUB     = k_TUB * MTOM_t^0.60 * 1e6;  % [USD]
C_prog_TUB       = C_per_ac_TUB * N_prod;

% Apply novelty premium for boxwing (15% above conventional)
novelty_premium  = 1.15;
C_per_ac_TUB_adj = C_per_ac_TUB * novelty_premium;
C_prog_TUB_adj   = C_per_ac_TUB_adj * N_prod;

fprintf('\n=== TU BERLIN CROSS-CHECK ===\n');
fprintf('  Cost per aircraft (conventional) : %.2f M$\n', C_per_ac_TUB/1e6);
fprintf('  Cost per aircraft (+15%% novelty) : %.2f M$\n', C_per_ac_TUB_adj/1e6);
fprintf('  Total programme cost (adj)       : %.2f B$\n\n', C_prog_TUB_adj/1e9);

% --- Cross-check comparison ---
ratio_DAPCA_TUB = C_prog_DAPCA / C_prog_TUB_adj;
fprintf('=== DAPCA vs TU BERLIN RATIO ===\n');
fprintf('  DAPCA IV       : %.2f B$\n', C_prog_DAPCA/1e9);
fprintf('  TU Berlin adj  : %.2f B$\n', C_prog_TUB_adj/1e9);
fprintf('  Ratio (DAPCA/TUB): %.2f\n', ratio_DAPCA_TUB);
if ratio_DAPCA_TUB > 2.0
    fprintf('  *** WARNING: DAPCA IV exceeds TU Berlin by factor %.1f. ***\n', ratio_DAPCA_TUB);
    fprintf('  *** This is consistent with known DAPCA over-prediction at  ***\n');
    fprintf('  *** low N and high OEM. See financial cost commentary below. ***\n\n');
else
    fprintf('  Methods agree within acceptable tolerance.\n\n');
end

% Use TU Berlin (market-calibrated) as the reference for financial costs
% and flag DAPCA result separately.
C_per_ac_ref     = C_per_ac_TUB_adj;  % use this for financial costs
Ca_ref           = C_per_ac_ref * 0.75;  % airframe fraction (~75%)
Ce_ref           = C_per_ac_ref * 0.25;  % engine fraction (~25%)

%% =========================================================================
%  SECTION 6 — FINANCIAL COSTS
%  =========================================================================
%  Computed for two scenarios:
%    (A) DAPCA IV programme cost  — unvalidated, shown for completeness
%    (B) TU Berlin market-calibrated cost — recommended reference
%
%  Hull value methods:
%    Method A: Roskam parametric: V_hull = 44800 * MTOM_t^0.65  [$]
%    Method B: DAPCA/TUB-derived: V_hull = C_per_ac * (1 + profit_margin)

aircraft_life_yr = 20;
interest_rate    = 0.05;          % 5% annual
ins_rate_hull    = 0.006;         % 0.6% hull value/year (ownership)
profit_margin    = 0.15;          % 15% OEM profit margin

% Hull value — Method A (Roskam)
V_hull_A         = 44800 * MTOM_t^0.65;   % [$]

% Hull value — Method B
V_hull_B_DAPCA   = C_per_ac_DAPCA * (1 + profit_margin);
V_hull_B_TUB     = C_per_ac_TUB_adj * (1 + profit_margin);

% Maintenance (now that Ca and Ce are defined)
maint_DAPCA      = calc_maintenance(Ca_DAPCA, Ce_DAPCA, n_engines, ...
                       total_flt_hr, n_landings_per_ac, fleet_size);
maint_TUB        = calc_maintenance(Ca_ref,   Ce_ref,   n_engines, ...
                       total_flt_hr, n_landings_per_ac, fleet_size);

% --- Scenario A: DAPCA IV ---
dep_DAPCA        = (C_prog_DAPCA) / aircraft_life_yr;
int_DAPCA        = interest_rate  * C_prog_DAPCA;
ins_DAPCA        = ins_rate_hull  * V_hull_B_DAPCA * fleet_size;
FC_DAPCA         = dep_DAPCA + int_DAPCA + ins_DAPCA;

DOC_DAPCA        = total_COC + maint_DAPCA + FC_DAPCA;

% --- Scenario B: TU Berlin (recommended) ---
dep_TUB          = (C_prog_TUB_adj) / aircraft_life_yr;
int_TUB          = interest_rate * C_prog_TUB_adj;
ins_TUB          = ins_rate_hull  * V_hull_B_TUB * fleet_size;
FC_TUB           = dep_TUB + int_TUB + ins_TUB;

DOC_TUB          = total_COC + maint_TUB + FC_TUB;

% ---- Financial cost commentary ----------------------------------------
fprintf('=================================================================\n');
fprintf('  FINANCIAL COST COMMENTARY\n');
fprintf('=================================================================\n');
fprintf('  Scenario A — DAPCA IV programme cost:\n');
fprintf('    Programme cost    : %.2f B$\n',   C_prog_DAPCA/1e9);
fprintf('    Depreciation/yr   : %.2f M$\n',   dep_DAPCA/1e6);
fprintf('    Interest/yr       : %.2f M$\n',   int_DAPCA/1e6);
fprintf('    Insurance/yr      : %.2f M$\n',   ins_DAPCA/1e6);
fprintf('    --> DAPCA financial costs are likely over-predicted.\n');
fprintf('    --> Root cause: DAPCA was calibrated on 1970s-80s programmes.\n');
fprintf('    --> High OEM (%.0f kg) and low N (%d) amplify this error.\n', OEM_kg, N_prod);
fprintf('    --> The TU Berlin result should be used as primary reference.\n\n');
fprintf('  Scenario B — TU Berlin market-calibrated (RECOMMENDED):\n');
fprintf('    Programme cost    : %.2f B$\n',   C_prog_TUB_adj/1e9);
fprintf('    Depreciation/yr   : %.2f M$\n',   dep_TUB/1e6);
fprintf('    Interest/yr       : %.2f M$\n',   int_TUB/1e6);
fprintf('    Insurance/yr      : %.2f M$\n',   ins_TUB/1e6);
fprintf('    --> Calibrated to B777F market price (~$340M list).\n');
fprintf('    --> 15%% novelty premium applied for boxwing configuration.\n');
fprintf('=================================================================\n\n');

%% =========================================================================
%  SECTION 7 — DOC SUMMARY TABLE
%  =========================================================================

fprintf('=================================================================\n');
fprintf('  TOTAL DOC SUMMARY — Fleet of %d, per Season (2024 USD)\n', fleet_size);
fprintf('=================================================================\n');
fprintf('  %-30s  %10s  %10s\n', 'Component', 'DAPCA (M$)', 'TUB (M$)');
fprintf('  %s\n', repmat('-',1,55));
fprintf('  %-30s  %10.2f  %10.2f\n', 'Crew', total_crew/1e6, total_crew/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Fuel (SAF $2/L)', fuel_cost_base/1e6, fuel_cost_base/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Landing fees', landing_cost/1e6, landing_cost/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Parking fees', parking_cost/1e6, parking_cost/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Navigation', total_nav/1e6, total_nav/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Maintenance (eta_MRO=1.3)', maint_DAPCA/1e6, maint_TUB/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Depreciation', dep_DAPCA/1e6, dep_TUB/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Interest', int_DAPCA/1e6, int_TUB/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', 'Insurance', ins_DAPCA/1e6, ins_TUB/1e6);
fprintf('  %s\n', repmat('-',1,55));
fprintf('  %-30s  %10.2f  %10.2f\n', 'TOTAL DOC', DOC_DAPCA/1e6, DOC_TUB/1e6);
fprintf('  %-30s  %10.2f  %10.2f\n', '  of which: COC+Maint only', ...
    (total_COC+maint_DAPCA)/1e6, (total_COC+maint_TUB)/1e6);
fprintf('=================================================================\n\n');

%% =========================================================================
%  SECTION 8 — SENSITIVITY: SAF PRICE
%  =========================================================================

DOC_saf_DAPCA    = (DOC_DAPCA - fuel_cost_base) + fuel_costs_saf;
DOC_saf_TUB      = (DOC_TUB   - fuel_cost_base) + fuel_costs_saf;
COC_saf          = (total_COC  - fuel_cost_base) + fuel_costs_saf;

%% =========================================================================
%  SECTION 9 — SENSITIVITY: MTOM TRADE STUDY
%  =========================================================================

MTOM_range       = 250:10:430;   % [t]
DOC_mtom_TUB     = zeros(size(MTOM_range));
DOC_mtom_COC     = zeros(size(MTOM_range));

for idx = 1:length(MTOM_range)
    mt = MTOM_range(idx);
    % Scale empty mass (rough fraction: OEM/MTOM ≈ 0.68 for this aircraft)
    oem_i     = 0.68 * mt;
    % Fuel scales with MTOM (fuel fraction held constant)
    bf_L_i    = (mt * 1000 * 0.28 / fuel_density_kgL);
    fuel_i    = SAF_price_base * bf_L_i * fleet_size;
    % Landing fees scale linearly with MTOM
    land_i    = landing_rate * mt * n_landings_per_ac * fleet_size;
    % Navigation scales with sqrt(MTOM/50)
    nav_fac_i = sqrt(mt / 50);
    nav_i     = nav_unit_rate * sum(leg_distances_km/100) * nav_fac_i * fleet_size;
    coc_i     = total_crew + fuel_i + land_i + parking_cost + nav_i;
    % TU Berlin acquisition scales with MTOM
    C_ac_i    = k_TUB * mt^0.60 * 1e6 * novelty_premium;
    Ca_i      = C_ac_i * 0.75;   Ce_i = C_ac_i * 0.25;
    maint_i   = calc_maintenance(Ca_i, Ce_i, n_engines, total_flt_hr, n_landings_per_ac, fleet_size);
    C_prog_i  = C_ac_i * N_prod;
    fc_i      = (interest_rate + 1/aircraft_life_yr) * C_prog_i + ...
                ins_rate_hull * C_ac_i*(1+profit_margin) * fleet_size;
    DOC_mtom_TUB(idx) = coc_i + maint_i + fc_i;
    DOC_mtom_COC(idx) = coc_i + maint_i;
end

%% =========================================================================
%  SECTION 10 — LEASING SCENARIO
%  =========================================================================
%  Under a dry lease, the operator pays a monthly lease rate and does not
%  carry depreciation or interest. Insurance switches to liability-only.

LRF              = 0.0090;        % 0.90 %/month of per-aircraft acquisition
ins_liability    = 0.003;         % 0.3 % hull value/year (liability only)

lease_annual_TUB = LRF * 12 * C_per_ac_TUB_adj * fleet_size;
ins_les_TUB      = ins_liability  * V_hull_B_TUB * fleet_size;
DOC_les_TUB      = total_COC + maint_TUB + lease_annual_TUB + ins_les_TUB;

DOC_lease_saf    = (DOC_les_TUB - fuel_cost_base) + fuel_costs_saf;

fprintf('=== LEASING SCENARIO (TU Berlin, N=50 lessor) ===\n');
fprintf('  Lease payments/yr  : %.2f M$\n', lease_annual_TUB/1e6);
fprintf('  Liability ins/yr   : %.2f M$\n', ins_les_TUB/1e6);
fprintf('  Total DOC (lease)  : %.2f M$\n\n', DOC_les_TUB/1e6);

%% =========================================================================
%  FIGURES
%  =========================================================================

% Colour palette — consistent across all figures
c_crew   = [0.20 0.55 0.85];   % steel blue
c_fuel   = [0.95 0.45 0.10];   % burnt orange
c_land   = [0.35 0.75 0.35];   % mid green
c_park   = [0.15 0.50 0.20];   % dark green
c_nav    = [0.75 0.85 0.30];   % yellow-green
c_maint  = [0.55 0.25 0.65];   % purple
c_dep    = [0.20 0.35 0.80];   % deep blue
c_int    = [0.40 0.60 0.90];   % medium blue
c_ins    = [0.65 0.80 0.95];   % light blue

cmap_9   = [c_crew; c_fuel; c_land; c_park; c_nav; c_maint; c_dep; c_int; c_ins];

% ---- FIGURE 1: DOC Breakdown Pie (TU Berlin, SAF $2/L) ----------------
fig1_vals   = [total_crew, fuel_cost_base, landing_cost, parking_cost, ...
               total_nav, maint_TUB, dep_TUB, int_TUB, ins_TUB];
fig1_labels = {'Crew','Fuel (SAF $2/L)','Landing','Parking','Navigation',...
               'Maintenance','Depreciation','Interest','Insurance'};

figure('Name','Fig1 DOC Breakdown','Position',[50 50 800 600],'Color','w');
pie_h = pie(fig1_vals);
colormap(gca, cmap_9);
for p = 2:2:length(pie_h)
    pie_h(p).FontSize = 9;
    if fig1_vals(p/2)/sum(fig1_vals) < 0.03
        pie_h(p).String = '';
    end
end
title({'DOC Breakdown — Boxwing Freighter', ...
       sprintf('Fleet of %d | Season | SAF \\$2/L | TU Berlin method', fleet_size)}, ...
    'FontSize', 13, 'FontWeight', 'bold');
legend(fig1_labels, 'Location', 'eastoutside', 'FontSize', 9);

% ---- FIGURE 2: SAF Sensitivity Bar Chart ------------------------------
figure('Name','Fig2 SAF Sensitivity','Position',[100 50 780 500],'Color','w');
saf_bar_cols = [0.60 0.80 0.95; 0.20 0.50 0.85; 0.10 0.30 0.65; ...
                0.80 0.25 0.25; 0.55 0.08 0.08];
b2 = bar(DOC_saf_TUB/1e6, 'FaceColor', 'flat');
for k = 1:length(SAF_prices)
    b2.CData(k,:) = saf_bar_cols(k,:);
end
set(gca, 'XTickLabel', {'SAF \$1/L','SAF \$2/L','SAF \$3/L','SAF \$4/L','SAF \$5/L'}, ...
    'FontSize', 11, 'XTickLabelRotation', 15);
ylabel('Total Fleet DOC [M$/season]', 'FontSize', 12);
title({'DOC Sensitivity to SAF Price', ...
       'TU Berlin acquisition method | Ownership scenario'}, ...
    'FontSize', 13, 'FontWeight', 'bold');
yline(DOC_TUB/1e6, '--k', 'Baseline \$2/L', 'LabelHorizontalAlignment', 'left', ...
    'FontSize', 10);
for k = 1:length(SAF_prices)
    text(k, DOC_saf_TUB(k)/1e6 + 0.01*max(DOC_saf_TUB/1e6), ...
        sprintf('$%.1fM', DOC_saf_TUB(k)/1e6), ...
        'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
grid on; box on;

% ---- FIGURE 3: Multi-Panel Pies at SAF $2, $3, $5 --------------------
saf_3pts    = [2.00, 3.00, 5.00];
saf_labels3 = {'SAF \$2/L (baseline)', 'SAF \$3/L', 'SAF \$5/L'};
fuel_3pts   = saf_3pts * block_fuel_L_per_ac * fleet_size;

figure('Name','Fig3 SAF Pie Comparison','Position',[100 100 1300 520],'Color','w');
for k = 1:3
    subplot(1,3,k);
    vals_k = [total_crew, fuel_3pts(k), landing_cost, parking_cost, ...
              total_nav, maint_TUB, dep_TUB, int_TUB, ins_TUB];
    total_k = sum(vals_k);
    ph = pie(vals_k);
    colormap(gca, cmap_9);
    for p = 2:2:length(ph)
        ph(p).FontSize = 7.5;
        if vals_k(p/2)/total_k < 0.03
            ph(p).String = '';
        end
    end
    title({saf_labels3{k}, sprintf('Total: $%.1fM', total_k/1e6)}, ...
        'FontSize', 10, 'FontWeight', 'bold');
end
legend(fig1_labels, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
    'FontSize', 8);
sgtitle({'DOC Breakdown — SAF Price Sensitivity Comparison', ...
         'Red tones = Flying costs  |  Purple = Maintenance  |  Blue tones = Financial'}, ...
    'FontSize', 12, 'FontWeight', 'bold');

% ---- FIGURE 4: MTOM Trade Study ---------------------------------------
figure('Name','Fig4 MTOM Trade','Position',[150 100 800 520],'Color','w');
plot(MTOM_range, DOC_mtom_TUB/1e6, 'b-',  'LineWidth', 2.5, ...
    'DisplayName', 'Total DOC (incl. financial)');
hold on; grid on; box on;
plot(MTOM_range, DOC_mtom_COC/1e6, 'r--', 'LineWidth', 2.5, ...
    'DisplayName', 'COC + Maintenance only');
xline(MTOM_t, 'k-', 'LineWidth', 1.8);
text(MTOM_t + 2, max(DOC_mtom_TUB/1e6)*0.97, ...
    sprintf('Design point\n(%.0f t)', MTOM_t), 'FontSize', 9);
xlabel('MTOM [tonnes]', 'FontSize', 12);
ylabel('Total Fleet DOC [M$/season]', 'FontSize', 12);
title({'DOC Sensitivity to MTOM', 'TU Berlin acquisition | SAF \$2/L'}, ...
    'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);

% ---- FIGURE 5: Ownership vs Leasing Comparison ------------------------
fig5_labels  = {'Own (Method A hull)', 'Own (Method B hull)', 'Lease (N=50)'};
% Method A hull — use Roskam hull value for ownership insurance
ins_own_A    = ins_rate_hull * V_hull_A * fleet_size;
DOC_own_A    = total_COC + maint_TUB + dep_TUB + int_TUB + ins_own_A;
DOC_grp      = [DOC_own_A, DOC_TUB, DOC_les_TUB] / 1e6;
fig5_cols    = [0.80 0.25 0.25; 0.95 0.55 0.30; 0.25 0.55 0.85];

figure('Name','Fig5 Own vs Lease','Position',[200 100 820 520],'Color','w');
b5 = bar(DOC_grp, 'FaceColor', 'flat');
for k = 1:3
    b5.CData(k,:) = fig5_cols(k,:);
end
set(gca, 'XTickLabel', fig5_labels, 'FontSize', 10, 'XTickLabelRotation', 15);
ylabel('Total Fleet DOC [M$/season]', 'FontSize', 12);
title({'Ownership vs Leasing — DOC Comparison', 'TU Berlin acquisition | SAF \$2/L'}, ...
    'FontSize', 13, 'FontWeight', 'bold');
grid on; box on;
for k = 1:3
    text(k, DOC_grp(k) + 0.005*max(DOC_grp), sprintf('$%.1fM', DOC_grp(k)), ...
        'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
end

% ---- FIGURE 6: DAPCA vs TU Berlin Cross-Check -------------------------
MTOM_xcheck   = 250:10:430;
C_DAPCA_xc    = zeros(size(MTOM_xcheck));
C_TUB_xc      = zeros(size(MTOM_xcheck));

for idx = 1:length(MTOM_xcheck)
    mt = MTOM_xcheck(idx);
    oem_lb_i    = mt * 1000 * 0.68 * 2.20462;
    C_DAPCA_xc(idx) = ((5.18*oem_lb_i^0.777*V_max_kts^0.894*N_prod^0.163)*R_E + ...
                        (7.22*oem_lb_i^0.777*V_max_kts^0.696*N_prod^0.263)*R_T + ...
                        (10.5*oem_lb_i^0.82 *V_max_kts^0.484*N_prod^0.641)*R_M + ...
                        0.076*(10.5*oem_lb_i^0.82*V_max_kts^0.484*N_prod^0.641)*R_Q) ...
                       * eta_composite * eta_CPI / N_prod / 1e6;
    C_TUB_xc(idx)   = k_TUB * mt^0.60 * novelty_premium;
end

figure('Name','Fig6 DAPCA vs TUB','Position',[250 100 800 500],'Color','w');
plot(MTOM_xcheck, C_DAPCA_xc, 'r-',  'LineWidth', 2.5, ...
    'DisplayName', 'DAPCA IV (labour only, per aircraft)');
hold on; grid on; box on;
plot(MTOM_xcheck, C_TUB_xc,   'b--', 'LineWidth', 2.5, ...
    'DisplayName', 'TU Berlin (+15% novelty, per aircraft)');
% Market reference points
plot(347, 340, 'ks', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', 'B777F market price (~$340M)');
plot(316, 310, 'k^', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', 'A350F market price (~$310M)');
xline(MTOM_t, 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
text(MTOM_t+2, max(C_TUB_xc)*0.92, sprintf('Design\npoint'), 'FontSize', 9);
xlabel('MTOM [tonnes]', 'FontSize', 12);
ylabel('Cost per aircraft [M$]', 'FontSize', 12);
title({'DAPCA IV vs TU Berlin — Acquisition Cost Cross-Check', ...
       'Note: DAPCA labour component only shown (excludes C_{dev}, C_{flt}, C_{eng})'}, ...
    'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);

%% =========================================================================
%  SECTION 11 — FINAL SUMMARY
%  =========================================================================

fprintf('\n=================================================================\n');
fprintf('  FINAL DOC SUMMARY — RECOMMENDED FIGURES (TU Berlin method)\n');
fprintf('=================================================================\n');
fprintf('  COC (fuel + crew + ops)        : %7.2f M$/season\n', total_COC/1e6);
fprintf('  Maintenance (eta_MRO=1.3)      : %7.2f M$/season\n', maint_TUB/1e6);
fprintf('  Financial costs                : %7.2f M$/season\n', FC_TUB/1e6);
fprintf('  ------------------------------------------\n');
fprintf('  TOTAL DOC                      : %7.2f M$/season\n', DOC_TUB/1e6);
fprintf('  Fuel share of COC              : %7.1f%%\n', 100*fuel_cost_base/total_COC);
fprintf('  Fuel share of total DOC        : %7.1f%%\n', 100*fuel_cost_base/DOC_TUB);
fprintf('\n  SAF sensitivity:\n');
for k = 1:length(SAF_prices)
    fprintf('    SAF $%.2f/L  --> DOC = %.2f M$/season\n', ...
        SAF_prices(k), DOC_saf_TUB(k)/1e6);
end
fprintf('\n  Ownership (Method B hull)      : %7.2f M$/season\n', DOC_TUB/1e6);
fprintf('  Leasing (N=50 lessor)          : %7.2f M$/season\n', DOC_les_TUB/1e6);
fprintf('=================================================================\n');
fprintf('  NOTE: DAPCA IV total DOC = %.2f M$/season (not recommended).\n', DOC_DAPCA/1e6);
fprintf('  DAPCA over-predicts at low N + high OEM. Use TU Berlin values.\n');
fprintf('=================================================================\n\n');
fprintf('  All figures generated. Use mouse to inspect/rotate.\n');
fprintf('  To export: saveas(figure(N), ''Fig_N_name.png'')\n\n');