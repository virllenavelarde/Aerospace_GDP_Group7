%% ECONOMIC EVALUATION
% function DOC(MTOM, no_landings, ICAO_taxi_configuration, no_days_landing, fuel_kerosene_percentage, fuel_SAF_percentage, fuel_consumption_per_flight, total_flight_hours)
% Inputs from other disciplines
MTOM = 330;                     % tonnes
% no_landings = 30;               % number of landings per year per aircraft
ICAO_taxi_configuration = 'E';  % ICAO taxi configuration
% total_flight_hours = 4214;      % total flight hours per year per aircraft
fleet_size = 6;                 % number of aircraft in the fleet
% no_flights = 50; % number of flights per year per aircraft
M_e = 100000;                   % kg, empty mass of the aircraft
V_max = 400;                    % km/h, maximum velocity 
N_ownership = fleet_size;       % number of aircraft in 5 years production
T_max = 115;                    % kN; maximum thrust
M_max = 0.85;                   % -, maximum Mach number
T_3 = 1000;                     % K, turbine inlet temperature
N_ft = 2;                       % assumption, number of flight test aircraft
N_leasing = 50;                 % assumption, number of aircraft leased per year

% Extra variables for maintenance costs
leg_distances_km = [16847, 8018, 1457, 8052, 1272, 11621, 2264, ...
                     6129,  957, 4462, 6940, 15821, 1204,  7433, ...
                     9782, 13053,  321, 5454];
nav_unit_rate       = 90;       % [$/unit] Eurocontrol 2024, EUR→USD converted
nav_weight_factor   = sqrt(MTOM / 50);  % [-] MTOM weight coefficient
nav_charge_per_leg  = nav_unit_rate * (leg_distances_km/100) * nav_weight_factor;
total_nav_charges   = sum(nav_charge_per_leg) * fleet_size;  % [$/season]


% MISSION ANALYSIS
leg_distances_km = [16847, 8018, 1457, 8052, 1272, 11621, 2264, ...
                     6129,  957, 4462, 6940, 15821, 1204,  7433, ...
                     9782, 13053,  321, 5454];
 
cruise_speed_kmh     = 868;   % [km/h] Mach 0.82 @ FL350, ISA
block_overhead       = 1.12;  % [-] 12% block overhead factor
total_distance_km    = sum(leg_distances_km);
total_flight_hours   = (total_distance_km / cruise_speed_kmh) * block_overhead;
refuel_stops         = 5;       % number of refuel stops per season per aircraft: target range = 8500 km
no_landings          = length(leg_distances_km) + refuel_stops;   % 18 per season per aircraft
% n_air_freight_races  = 19;
% avg_days_race_stop   = 6;
% no_days_parking      = n_air_freight_races * avg_days_race_stop;   % 114 days 
no_days_parking = 193;          % number of days an aircraft is parked at the airport per year


% CASH OPERATIONG COSTS
% Crew cost
crew_cost_per_year = 150000; % $
crew_members = 4; % number of crew members
crew_cost_per_aircraft = crew_cost_per_year * crew_members; % $ per year
total_crew_cost = crew_cost_per_aircraft * fleet_size; % $ per year

% Landing fees
landing_fee_per_tonne = 25; % $ per tonne
landing_fee_per_aircraft = landing_fee_per_tonne * MTOM; % $ per landing
total_landing_fees = landing_fee_per_aircraft * no_landings * fleet_size; % $ per year

% Parking fees - fees based on the taxi configuration
if ICAO_taxi_configuration == 'C'
    parking_fee_per_day = 1000; % $ per day for configuration C
elseif ICAO_taxi_configuration == 'D'
    parking_fee_per_day = 2000; % $ per day for configuration D
elseif ICAO_taxi_configuration == 'E'
    parking_fee_per_day = 4000; % $ per day for configuration D
elseif ICAO_taxi_configuration == 'F'
    parking_fee_per_day = 6000; % $ per day for configuration D
end
total_parking_fees = parking_fee_per_day * no_days_parking * fleet_size; % $ per year

% Fuel costs
fuel_kerosene_percentage = 0;   % percentage of fuel that is kerosene
fuel_SAF_percentage = 1;        % percentage of fuel that is SAF
fuel_consumption_per_hour = 8002.77 * 0.8; % liters per flight
fuel_price_kerosene = 1.00; % $ per liter
fuel_price_SAF = 2.00; % $ per liter
total_fuel_price_per_litre = fuel_price_kerosene * fuel_kerosene_percentage + fuel_price_SAF * fuel_SAF_percentage; % $ per liter
total_fuel_cost = total_fuel_price_per_litre * fuel_consumption_per_hour * fleet_size * total_flight_hours; % $ per year

total_COC = total_crew_cost + total_landing_fees + total_parking_fees + total_fuel_cost; % $ per year
disp(['Total Cash Operating Cost (COC) per year: $', num2str(total_COC), ' = $', num2str(total_COC/1000000), ' millions']);

% FINANCIAL COSTS
% Initial cost estimate
R_E = 115; % $/hour, engineering costs
R_T = 118; % $/hour, tooling costs
R_Q = 108; % $/hour, quality control costs
R_M = 98; % $/hour, manufacturing costs

eta_M = 1.2;% aluminium: 1.0
            % grapite-epoxy: 1.1 - 1.8
            % fibreglass: 1.1 - 1.2
            % steel: 1.5 - 2.0
            % titanium: 1.1 - 1.8

% Extra costs
C_D = 67.4*M_e^0.63*V_max^1.3; % $, development costs
C_F = 1947*M_e^0.325*V_max^0.822+N_ft^1.21; % $, flight test costs
C_E = 3112 * (9.66*T_max + 243.25*M_max+1.74*T_3-2228); % $, engine costs

eta_cpi_2012 = 1.43;  % Scale for inflation: 143% since 2012
% eta_cpi_1970 = 8.10;  % Scale for inflation: 810% since 1970

function [total_cost, cost_per_ac] = run_DAPCA(M_e, V_max, N, eta_M, ...
                                                R_E, R_T, R_M, R_Q, ...
                                                C_D, C_F, C_E, eta_cpi)
    H_E = 5.18 * M_e^0.777 * V_max^0.894 * N^0.163; % hours, engineering
    H_T = 7.22 * M_e^0.777 * V_max^0.696 * N^0.263; % hours, tooling
    H_M = 10.5 * M_e^0.82 * V_max^0.484 * N^0.641; % hours, manufacturing
    H_Q = 0.076 * H_M; % hours, quality
    C_m = 31.2*M_e^0.921*V_max^0.621*N^0.799; % $, material costs
    labour  = (H_E*R_E + H_T*R_T + H_M*R_M + H_Q*R_Q) * eta_M;
    total_cost   = (C_E + C_m + C_F + C_D + labour) * eta_cpi;
    cost_per_ac  = total_cost / N;
end

% Run DAPCA for both scenarios and both CPI values
[cost_own_2012, cpa_own_2012] = run_DAPCA(M_e,V_max,N_ownership,eta_M,R_E,R_T,R_M,R_Q,C_D,C_F,C_E,eta_cpi_2012);
% [cost_own_1970, cpa_own_1970] = run_DAPCA(M_e,V_max,N_ownership,eta_M,R_E,R_T,R_M,R_Q,C_D,C_F,C_E,eta_cpi_1970);
[cost_les_2012, cpa_les_2012] = run_DAPCA(M_e,V_max,N_leasing,eta_M,R_E,R_T,R_M,R_Q,C_D,C_F,C_E,eta_cpi_2012);
% [cost_les_1970, cpa_les_1970] = run_DAPCA(M_e,V_max,N_leasing,eta_M,R_E,R_T,R_M,R_Q,C_D,C_F,C_E,eta_cpi_1970);

Ce_2012     = C_E * eta_cpi_2012;        % [$] per engine, 2012$
Ca_2012     = cpa_own_2012 - Ce_2012*N_ft; % [$] airframe cost less engines, 2012$

% HULL VALUE: 2 methods: A) specifications, B) derived from DAPCA for boxwing novelty
V_hull_A = 44800 * MTOM^0.65;    % $ Method A: specifcations-based hull value (Raymer 2018)
profit_margin = 0.15;             % 15% OEM profit margin (Raymer 2018)
 
% Method B uses ownership DAPCA cost per aircraft as a proxy for the hull value.
V_hull_B_own = cpa_own_2012 * (1 + profit_margin);
% V_hull_B_own_1970 = cpa_own_1970 * (1 + profit_margin);
V_hull_B_les = cpa_les_2012 * (1 + profit_margin);
% V_hull_B_les_1970 = cpa_les_1970 * (1 + profit_margin);

% Maintenance costs
% V_hull = 44800 * MTOM ^ 0.65; % $ hull value
eta_MRO = 1.3;  % maintenance complexity multiplier (novelty premium)
 
function maint_total = calc_maintenance(Ca, Ce, Ne, eta_MRO, total_FH, no_cycles, fleet)
    % Raymer (2018) Eq.18.12 — maintenance material cost per flight hour [2012$/FH]
    maint_per_FH    = 3.3*(Ca/1e6) + 14.2 + (58*(Ce/1e6) - 26.1)*Ne; %   Combines airframe + engine material cost rates
    maint_per_cycle = 4.0*(Ca/1e6) + 9.3  + (7.5*(Ce/1e6) + 5.6)*Ne; % Raymer (2018) Eq.18.13 — maintenance material cost per cycle (landing) [2012$/cycle]
    maint_total = eta_MRO * (maint_per_FH*total_FH + maint_per_cycle*no_cycles) * fleet; % Annual fleet total with novelty complexity multiplier eta_MRO
end

%% SCENARIO 1: OWNERSHIP
aircraft_life_option1 = 20;   % yr, aircraft design life
aircraft_life_option2 = 14*fleet_size*total_flight_hours;
if aircraft_life_option1 < aircraft_life_option2
    aircraft_life_yr = aircraft_life_option1;
else
    aircraft_life_yr = aircraft_life_option2;
end

function [DOC, breakdown, FC] = ownership_DOC(total_init_cost, V_hull, fleet, aircraft_life_yr, eta_MRO, total_FH, no_cycles, Ca, Ce, Ne, COC_fixed)    
    dep   = total_init_cost / aircraft_life_yr;          % [$/yr] annual depreciation
    intr  = 0.05 * total_init_cost;                      % [$/yr] 5% interest
    ins   = 0.006 * V_hull * fleet;                      % [$/yr] 0.6% hull value
    maint = calc_maintenance(Ca, Ce, Ne, eta_MRO, total_FH, no_cycles, fleet);    
    FC    = dep + intr + ins;
    DOC   = COC_fixed + maint + FC;
    breakdown = struct('depreciation',dep,'interest',intr,'insurance',ins, ...
                       'maintenance',maint,'FC',FC);
end
 
% COC_fixed = total_crew_cost + total_fuel_cost + total_parking_fees + total_landing_fees;
COC_fixed = total_crew_cost + total_fuel_cost + total_parking_fees + total_landing_fees + total_nav_charges; % Ownership: Method A hull

[DOC_own_A, BD_own_A, FC_own_A] = ownership_DOC(cost_own_2012, V_hull_A,fleet_size, aircraft_life_yr, eta_MRO, total_flight_hours, no_landings, Ca_2012, Ce_2012, N_ft, COC_fixed); 
% Ownership: Method B hull
[DOC_own_B, BD_own_B, FC_own_B] = ownership_DOC(cost_own_2012, V_hull_B_own, fleet_size, aircraft_life_yr, eta_MRO, total_flight_hours, no_landings, Ca_2012, Ce_2012, N_ft, COC_fixed);
% [DOC_own_B_1970, BD_own_B_1970] = ownership_DOC(cost_own_1970, V_hull_B_own_1970, fleet_size, aircraft_life_yr, eta_MRO, total_flight_hours, no_landings, ...
%     Ca_1970, Ce_1970, Ne, COC_fixed);
 
%% SCENARIO 2: LEASING
LRF = 0.0090;   % [-] 0.90%/month of per-aircraft acquisition cost
 
function DOC_lease = leasing_DOC(cpa_lessor, LRF, fleet, V_hull, COC_fixed)
    lease_annual  = LRF * 12 * cpa_lessor * fleet;   % [$/yr] total lease payments
    ins_liability = 0.003 * V_hull * fleet;           % [$/yr] liability-only insurance
    DOC_lease     = COC_fixed + lease_annual + ins_liability;
end
 
% Leasing 
DOC_les_2012 = leasing_DOC(cpa_les_2012, LRF, fleet_size, V_hull_B_les, COC_fixed);
% DOC_les_1970 = leasing_DOC(cpa_les_1970, LRF, fleet_size, V_hull_B_les_1970, COC_fixed);
 
%% Display results

% Reference case: Ownership, Method B hull
maint_ref   = calc_maintenance(Ca_2012, Ce_2012, N_ft, eta_MRO, total_flight_hours, no_landings, fleet_size);
dep_ref     = cost_own_2012 / aircraft_life_yr;
int_ref     = 0.05 * cost_own_2012;
ins_ref     = 0.006 * V_hull_B_own * fleet_size;

% SAF price cases used across all sensitivity figures
SAF_prices = [1.00, 2.00, 3.00, 4.00, 5.00];   % [$/L]
SAF_labels = {'SAF $1/L','SAF $2/L (base)','SAF $3/L','SAF $4/L','SAF $5/L'};
n_saf      = length(SAF_prices);

fuel_costs_saf = SAF_prices * fuel_consumption_per_hour * fleet_size * total_flight_hours;

% COC components for pie chart
coc_labels  = {'Crew','Fuel','Landing','Parking','Interest','Maintenance'};
coc_values  = [total_crew_cost, total_fuel_cost, total_landing_fees, total_parking_fees, total_nav_charges, maint_ref];

% DOC components for pie chart (COC + Financial)
doc_labels  = [coc_labels, {'Depreciation','Interest','Insurance'}];
doc_values  = [coc_values,  dep_ref, int_ref, ins_ref];

% Terminal breakdown table 
fprintf('==========================================================\n');
fprintf('  GROUP 7 BOXWING F1 FREIGHTER — DOC ANALYSIS\n');
fprintf('  Reference: Ownership - Method B Hull \n');
fprintf('==========================================================\n\n');
fprintf('%-28s  %12s  %8s\n','Cost Item','$/season','% DOC');
DOC_ref = sum(doc_values);
for i = 1:length(doc_labels)
    fprintf('  %-26s  %10.0f  %7.1f%%\n', doc_labels{i}, doc_values(i), ...
            100*doc_values(i)/DOC_ref);
end
fprintf('  %-26s  %10.0f  %7.1f%%\n','TOTAL DOC',DOC_ref,100);
fprintf('\n');
fprintf('--- OWNERSHIP DOC MATRIX ---\n');
fprintf('  %-28s  %10s  %10s\n','Hull/CPI','CPI=1.43x');
fprintf('  %-28s  %9.2fM  %9.2fM\n','Method A', DOC_own_A/1e6);
fprintf('  %-28s  %9.2fM  %9.2fM\n','Method B (DAPCA N=6)', DOC_own_B/1e6);
fprintf('\n--- LEASING DOC ---\n');
fprintf('  %-28s  %9.2fM  %9.2fM\n','Lessor N=50 (DAPCA B)', DOC_les_2012/1e6);
fprintf('\n');

% ---- FIGURE 1: COC Pie Chart ----
figure('Name','COC Breakdown - Owning Scenario','Position',[100 100 650 500]);
for k = 1:n_saf
    subplot(1, n_saf, k);
    fc_k    = fuel_costs_saf(k);
    vals_k  = [total_crew_cost, fc_k, total_landing_fees, ...
               total_parking_fees, total_nav_charges, maint_ref];
    % Distinct colours per slice (no two alike)
    cmap_coc = [0.20 0.55 0.85;  ... % crew        — steel blue
                0.95 0.45 0.10;  ... % fuel         — burnt orange
                0.35 0.75 0.35;  ... % landing      — mid green
                0.15 0.50 0.20;  ... % parking      — dark green
                0.75 0.85 0.30;  ... % nav           — yellow-green
                0.55 0.25 0.65];     % maintenance  — purple
    pie_h = pie(vals_k);
    colormap(gca, cmap_coc);
    % Move small labels outward to avoid overlap
    for p = 2:2:length(pie_h)   % text objects are even-indexed
        pie_h(p).FontSize = 8;
    end
    title(SAF_labels{k},'FontSize',10,'FontWeight','bold');
    if k == 3
        xlabel('Cash Operating Cost (COC) Breakdown — Fleet of 6, per season', ...
               'FontSize',11,'FontWeight','bold');
    end
end
legend(coc_labels,'Location','southoutside','Orientation','horizontal', ...
       'FontSize',9);
sgtitle('COC Breakdown: Owning Scenario','FontSize',14,'FontWeight','bold');


% ---- FIGURE 2: DOC Pie Chart ----

cmap_doc = [0.85 0.20 0.20;  ... % crew        — vivid red
            0.95 0.50 0.15;  ... % fuel         — orange-red
            0.80 0.35 0.55;  ... % landing      — rose-red
            0.65 0.15 0.15;  ... % parking      — dark red
            0.95 0.75 0.20;  ... % nav           — amber (warm, distinct)
            0.20 0.70 0.25;  ... % maintenance  — mid green
            0.15 0.35 0.80;  ... % depreciation — deep blue
            0.40 0.60 0.90;  ... % interest     — medium blue
            0.65 0.80 0.95];     % insurance    — light blue

doc_slice_labels = {'Crew','Fuel','Landing','Parking','Interest', 'Maintenance','Depreciation','Interest','Insurance'};

figure('Name','DOC Breakdown - SAF Sensitivity','Position',[50 80 1500 600]);
SAF_prices_2 = [2.00, 3.00, 5.00];   % [$/L]
SAF_labels_2 = {'SAF $2/L (base)','SAF $3/L','SAF $5/L'};
n_saf_2      = length(SAF_prices_2);
fuel_costs_saf_2 = SAF_prices_2 * fuel_consumption_per_hour * fleet_size * total_flight_hours;

for k = 1:n_saf_2
    subplot(1, n_saf_2, k);
    fc_k     = fuel_costs_saf_2(k);
    vals_doc = [total_crew_cost, fc_k, total_landing_fees, total_parking_fees, total_nav_charges, maint_ref, dep_ref, int_ref, ins_ref];
    % Explode very small slices outward to reduce label overlap
    total_k  = sum(vals_doc);
    explode  = double(vals_doc/total_k < 0.04);   % explode slices < 4%
    pie_h    = pie(vals_doc, explode);
    colormap(gca, cmap_doc);
    for p = 2:2:length(pie_h)
        pie_h(p).FontSize = 7.5;
        % If slice is tiny, suppress label to avoid overlap
        if vals_doc((p/2)) / total_k < 0.03
            pie_h(p).String = '';
        end
    end
    title(SAF_labels_2{k},'FontSize',10,'FontWeight','bold');
    if k == 3
        xlabel('Direct Operating Cost (DOC) Breakdown: Fleet of 6, per season','FontSize',11,'FontWeight','bold');
    end
end
legend(doc_slice_labels,'Location','southoutside','Orientation','horizontal', 'FontSize',9);
sgtitle({'DOC Breakdown - Sensitivity to SAF Price', 'Red = Flying Costs  |  Green = Maintenance  |  Blue = Financial Costs'},'FontSize',13,'FontWeight','bold');


% ---- FIGURE 3: SAF Price Sensitivity Bar Chart ----
figure('Name','SAF Sensitivity — Total DOC','Position',[150 100 700 480]);
DOC_SAF_vec = DOC_ref - total_fuel_cost + fuel_costs_saf;
b3 = bar(DOC_SAF_vec/1e6,'FaceColor','flat');
saf_bar_colours = [0.60 0.80 0.95; 0.20 0.50 0.85; 0.10 0.30 0.65; ...
                   0.70 0.20 0.20; 0.50 0.08 0.08];
for k = 1:n_saf; b3.CData(k,:) = saf_bar_colours(k,:); end
set(gca,'XTickLabel',SAF_labels,'FontSize',11,'XTickLabelRotation',15);
ylabel('Total Fleet DOC [M$/season]','FontSize',12);
title('DOC Sensitivity to SAF Price  (Ownership - Method B)','FontSize',13);
yline(DOC_ref/1e6,'--k','Mission spec $2/L','LabelHorizontalAlignment','left','FontSize',10);
grid on; box on;
for k = 1:n_saf
    text(k, DOC_SAF_vec(k)/1e6 + 0.01*max(DOC_SAF_vec/1e6), ...
         sprintf('$%.2fM', DOC_SAF_vec(k)/1e6), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

% ---- FIGURE 4: Ownership vs Leasing Comparison ----
figure('Name','Ownership vs Leasing','Position',[200 100 820 520]);
grp_labels  = {'Own (Method A)','Own (Method B)', 'Lease'};
DOC_grp     = [DOC_own_A, DOC_own_B, DOC_les_2012] / 1e6;
grp_colours = [0.80 0.25 0.25;  % own A 2012  — red
               0.95 0.55 0.30;  % own B 2012  — orange
               0.25 0.55 0.85;  % lease 2012  — blue
               ]
b4 = bar(DOC_grp,'FaceColor','flat');
for k = 1:3; b4.CData(k,:) = grp_colours(k,:); end
set(gca,'XTickLabel',grp_labels,'FontSize',10,'XTickLabelRotation',15);
ylabel('Total Fleet DOC [M$/season]','FontSize',12);
title('DOC All Scenarios: Ownership vs Leasing × Hull Method','FontSize',12);
grid on; box on;
for k = 1:3
    text(k, DOC_grp(k) + 0.005*max(DOC_grp), sprintf('$%.1fM',DOC_grp(k)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
% Manual legend
hold on;
b_leg = [bar(nan,'FaceColor',[0.80 0.25 0.25]); bar(nan,'FaceColor',[0.95 0.55 0.30]); bar(nan,'FaceColor',[0.25 0.55 0.85])];
legend(b_leg,{'Ownership (Method A)','Ownership (Method B)','Leasing'},'Location','northwest','FontSize',11);


% ---- FIGURE 5: DOC Sensitivity to MTOM (trade study) ----
figure('Name','MTOM Trade Study','Position',[250 100 750 500]);
MTOM_range = 200:10:500;
DOC_own_A_mtom = zeros(size(MTOM_range));
DOC_own_B_mtom = zeros(size(MTOM_range));
DOC_les_mtom   = zeros(size(MTOM_range));

for idx = 1:length(MTOM_range)
    mt = MTOM_range(idx);
    land_i   = 25 * mt * no_landings * fleet_size;
    nav_i    = nav_unit_rate * sum(leg_distances_km/100) * sqrt(mt/50) * fleet_size;
    coc_i    = total_crew_cost + total_fuel_cost + total_parking_fees + nav_i + land_i;
    % Scale Ca linearly with MTOM as first-order proxy
    Ca_i     = Ca_2012 * (mt / MTOM);
    maint_i  = calc_maintenance(Ca_i, Ce_2012, N_ft, eta_MRO, total_flight_hours, no_landings, fleet_size);
    % Method A hull (Roskam)
    V_h_A_i  = 44800 * mt^0.65;
    dep_i    = cost_own_2012 / aircraft_life_yr;
    int_i    = 0.05 * cost_own_2012;
    ins_Ai   = 0.006 * V_h_A_i * fleet_size;
    DOC_own_A_mtom(idx) = coc_i + maint_i + dep_i + int_i + ins_Ai;
    % Method B hull (DAPCA-derived, scaled with mt)
    V_h_B_i  = (cpa_own_2012 * (mt/MTOM)) * (1 + profit_margin);
    ins_Bi   = 0.006 * V_h_B_i * fleet_size;
    DOC_own_B_mtom(idx) = coc_i + maint_i + dep_i + int_i + ins_Bi;
    % Leasing
    lease_i  = LRF * 12 * cpa_les_2012 * fleet_size;
    ins_li   = 0.003 * V_h_A_i * fleet_size;
    DOC_les_mtom(idx) = coc_i + lease_i + ins_li;
end
plot(MTOM_range, DOC_own_A_mtom/1e6, 'r-',  'LineWidth',2); hold on;
plot(MTOM_range, DOC_own_B_mtom/1e6, 'm--', 'LineWidth',2);
plot(MTOM_range, DOC_les_mtom/1e6,   'b:',  'LineWidth',2.5);
xline(MTOM,'k-','LineWidth',1.5);
text(MTOM+3, max([DOC_own_A_mtom DOC_own_B_mtom DOC_les_mtom])/1e6*0.97, ...
     sprintf('Design point\n(%d t)',MTOM),'FontSize',9);
xlabel('MTOM [tonnes]','FontSize',12);
ylabel('Total Fleet DOC [M$/season]','FontSize',12);
title('DOC Sensitivity to MTOM: Ownership (A & B) vs Leasing','FontSize',13);
legend('Ownership (Method A)', 'Ownership (Method B)', 'Leasing (N=50)','Location','northwest','FontSize',10);
grid on; box on;


%% ---- FIGURE 7: DOC PIES — Own-A vs Own-B vs Lease (CPI 2012, SAF $2/L) ----
% Financial components per scenario (all CPI 2012, SAF $2/L)
dep_own   = cost_own_2012 / aircraft_life_yr;
int_own   = 0.05 * cost_own_2012;
ins_own_A = 0.006 * V_hull_A * fleet_size;
ins_own_B = 0.006 * V_hull_B_own * fleet_size;
lease_pay = LRF * 12 * cpa_les_2012 * fleet_size;
ins_les   = 0.003 * V_hull_B_les * fleet_size;

% DOC slice vectors
vals_own_A = [total_crew_cost, total_fuel_cost, total_landing_fees, total_parking_fees, total_nav_charges, maint_ref, dep_own, int_own, ins_own_A];
vals_own_B = [total_crew_cost, total_fuel_cost, total_landing_fees, total_parking_fees, total_nav_charges, maint_ref, dep_own, int_own, ins_own_B];
vals_les   = [total_crew_cost, total_fuel_cost, total_landing_fees, total_parking_fees, total_nav_charges, lease_pay, ins_les, 0, 0];   % no dep/int for operator under lease
% Remove zero entries for leasing pie
vals_les_clean   = vals_les(vals_les > 0);
labels_les_clean = doc_slice_labels(vals_les > 0);

fig7_titles  = {'Ownership - Method A', 'Ownership - Method B ','Leasing - N=50'};
fig7_vals    = {vals_own_A, vals_own_B, vals_les_clean};
fig7_labels  = {doc_slice_labels, doc_slice_labels, labels_les_clean};

figure('Name','DOC Comparison: Own-A vs Own-B vs Lease', 'Position',[100 80 1300 560], 'Color','black');
% set(gcf, 'Color', 'black');
% set(gca, 'Color', 'black', 'XColor', 'black', 'YColor', 'black');
for k = 1:3
    subplot(1,3,k);
    total_k  = sum(fig7_vals{k});
    explode  = double(fig7_vals{k}/total_k < 0.04);
    pie_h    = pie(fig7_vals{k}, explode);
    colormap(gca, cmap_doc);
    for p = 2:2:length(pie_h)
        pie_h(p).FontSize = 8;
        if fig7_vals{k}(p/2) / total_k < 0.03
            pie_h(p).String = '';
        end
    end
    title({fig7_titles{k}, sprintf('Total: $%.2fM', total_k/1e6)},'FontSize',10,'FontWeight','bold');
end
legend(doc_slice_labels,'Location','southoutside','Orientation','horizontal', 'FontSize',9);
sgtitle({'DOC Breakdown - Financing & Hull Method Comparison',  'Red=Flying  Green=Maint.  Blue=Financial'},  'FontSize',13,'FontWeight','bold');

%%% ---- FIGURE 9: COC PIES (5 SAF PRICES) — LEASING 
coc_les_labels = {'Crew','Fuel','Landing','Parking','Interest', 'Lease Payments','Liability Ins.'};
% Lease and insurance are SAF-price-independent — only fuel changes
coc_les_fixed  = [total_crew_cost, total_landing_fees, total_parking_fees, total_nav_charges, lease_pay, ins_les];

% COC colour map for leasing (7 slices — no maintenance slice)
cmap_coc_les = [0.20 0.55 0.85;  ... % crew         — steel blue
                0.95 0.45 0.10;  ... % fuel          — burnt orange
                0.35 0.75 0.35;  ... % landing       — mid green
                0.15 0.50 0.20;  ... % parking       — dark green
                0.75 0.85 0.30;  ... % nav           — yellow-green
                0.30 0.55 0.85;  ... % lease payment — medium blue
                0.65 0.80 0.95];     % liability ins — light blue

figure('Name','COC Breakdown - Leasing N=50 | SAF Sensitivity','Position',[50 80 1500 560], 'Color','black');
for k = 1:n_saf
    subplot(1, n_saf, k);
    fc_k   = fuel_costs_saf(k);
    % Insert fuel as second element
    vals_k = [total_crew_cost, fc_k, total_landing_fees, total_parking_fees, total_nav_charges, lease_pay, ins_les];
    pie_h  = pie(vals_k);
    colormap(gca, cmap_coc_les);
    for p = 2:2:length(pie_h)
        pie_h(p).FontSize = 8;
        if vals_k(p/2) / sum(vals_k) < 0.03
            pie_h(p).String = '';
        end
    end
    title(SAF_labels{k},'FontSize',10,'FontWeight','bold');
end
legend(coc_les_labels,'Location','southoutside','Orientation','horizontal',  'FontSize',9);
sgtitle({'COC Breakdown - Leasing Scenario (N=50)', 'Note: Maintenance excluded from operator COC under dry lease (embedded in lease rate)'}, 'FontSize',13,'FontWeight','bold');

%% ---- FIGURE 6: SUMMARY TABLE — exported as CSV ----
csv_rows = {
    'Section',                              'Parameter',                                'Value',                                    'Unit / Notes';
    'UTILISATION',                          'Total season distance',                    sprintf('%.0f',total_distance_km),          'km per aircraft per season';
    'UTILISATION',                          'Block flight hours per season',            sprintf('%.1f',total_flight_hours),         'h per aircraft';
    'UTILISATION',                          'Landings per season',                      sprintf('%d',no_landings),                  'per aircraft';
    'UTILISATION',                          'Race airport parking days',                sprintf('%d',no_days_parking),              'days per aircraft';
    'ACQUISITION COST',                     'Programme cost (N=6 CPI 2012)',            sprintf('%.2f',cost_own_2012/1e6),          'M$ DAPCA-IV';
    'ACQUISITION COST',                     'Cost per aircraft (N=6 CPI 2012)',         sprintf('%.2f',cpa_own_2012/1e6),           'M$ Ownership scenario';
    'ACQUISITION COST',                     'Cost per aircraft (N=50 CPI 2012)',        sprintf('%.2f',cpa_les_2012/1e6),           'M$ Leasing scenario';
    'ACQUISITION COST',                     'Hull value Method A Roskam',               sprintf('%.2f',V_hull_A/1e6),               'M$ MTOM^0.65 parametric';
    'ACQUISITION COST',                     'Hull value Method B DAPCA N=6 CPI 2012',  sprintf('%.2f',V_hull_B_own/1e6),      'M$ DAPCA + 15% OEM margin';
    'ACQUISITION COST',                     'Hull value Method B DAPCA N=50 CPI 2012', sprintf('%.2f',V_hull_B_les/1e6),      'M$ DAPCA + 15% OEM margin';
    'CASH OPERATING COSTS (SAF $2/L)',      'Crew cost',                                sprintf('%.4f',total_crew_cost/1e6),        'M$ 4 crew x 6 aircraft';
    'CASH OPERATING COSTS (SAF $2/L)',      'Fuel cost',                                sprintf('%.4f',total_fuel_cost/1e6),        'M$ 100% SAF at $2/L';
    'CASH OPERATING COSTS (SAF $2/L)',      'Landing fees',                             sprintf('%.4f',total_landing_fees/1e6),     'M$ $25/t MTOM x 18 legs';
    'CASH OPERATING COSTS (SAF $2/L)',      'Parking fees',                             sprintf('%.4f',total_parking_fees/1e6),     'M$ ICAO Code E 114 days';
    'CASH OPERATING COSTS (SAF $2/L)',      'Navigation charges',                       sprintf('%.4f',total_nav_charges/1e6),      'M$ Eurocontrol formula per leg';
    'CASH OPERATING COSTS (SAF $2/L)',      'Maintenance (x1.3 novelty multiplier)',    sprintf('%.4f',maint_ref/1e6),              'M$ Raymer Eq.18.12 and 18.13';
    'FINANCIAL COSTS (Own MethodB CPI2012)','Depreciation',                             sprintf('%.4f',dep_ref/1e6),                'M$ 20-yr airframe life';
    'FINANCIAL COSTS (Own MethodB CPI2012)','Interest',                                 sprintf('%.4f',int_ref/1e6),                'M$ 5% x total investment';
    'FINANCIAL COSTS (Own MethodB CPI2012)','Insurance',                                sprintf('%.4f',ins_ref/1e6),                'M$ 0.6% hull value per yr';
    'TOTAL DOC (fleet of 6 per season)',    'Ownership  Method A  CPI 2012',            sprintf('%.4f',DOC_own_A/1e6),         'M$';
    'TOTAL DOC (fleet of 6 per season)',    'Ownership  Method B  CPI 2012  PRIMARY',   sprintf('%.4f',DOC_own_B/1e6),         'M$ PRIMARY CASE';
    'TOTAL DOC (fleet of 6 per season)',    'Leasing    N=50      CPI 2012',            sprintf('%.4f',DOC_les_2012/1e6),           'M$';
    'SAF SENSITIVITY (Own MethodB CPI2012)','DOC at SAF $1.00/L',                      sprintf('%.4f',(DOC_ref-total_fuel_cost+fuel_costs_saf(1))/1e6), 'M$';
    'SAF SENSITIVITY (Own MethodB CPI2012)','DOC at SAF $2.00/L (baseline)',           sprintf('%.4f',DOC_ref/1e6),                'M$';
    'SAF SENSITIVITY (Own MethodB CPI2012)','DOC at SAF $3.00/L',                      sprintf('%.4f',(DOC_ref-total_fuel_cost+fuel_costs_saf(3))/1e6), 'M$';
    'SAF SENSITIVITY (Own MethodB CPI2012)','DOC at SAF $4.00/L',                      sprintf('%.4f',(DOC_ref-total_fuel_cost+fuel_costs_saf(4))/1e6), 'M$';
    'SAF SENSITIVITY (Own MethodB CPI2012)','DOC at SAF $5.00/L',                      sprintf('%.4f',(DOC_ref-total_fuel_cost+fuel_costs_saf(5))/1e6), 'M$';
};

csv_filename = 'DOC_Summary_Group7.csv';
fid = fopen(csv_filename, 'w');
for r = 1:size(csv_rows,1)
    fprintf(fid, '"%s","%s","%s","%s"\n', ...
            csv_rows{r,1}, csv_rows{r,2}, csv_rows{r,3}, csv_rows{r,4});
end
fclose(fid);
fprintf('Summary table exported to: %s\n', csv_filename);

% end