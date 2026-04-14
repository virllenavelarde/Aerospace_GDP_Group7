function results = DOC_methodComparsion(MTOM_t, OEM_kg, BlockFuel_kg, fleet_size, SAF_ratio, M_c, T_max_kN)
%  REFERENCES
%   [ATA]   ATA, Standard Method of Estimating Comparative DOC of
%           Turbine-Powered Transport Airplanes, Washington D.C., 1967.
%   [AEA]   AEA, Long Range Aircraft: AEA Requirements, Brussels, 1989.
%   [JEN]   Jenkinson, Simpkin & Rhodes, Civil Jet Aircraft Design,
%           Arnold/AIAA, 1999, Ch.14.
%   [TUB]   Thorbeck J. & Scholz D., DOC-Assessment Method, 3rd Symp. on
%           Collaboration in Aircraft Design, Linköping, 2013.
%   [NASA]  Liebeck R.H., Advanced Subsonic Airplane Design and Economic
%           Studies, NASA CR-195443, April 1995.
%   [RAY]   Raymer D.P., Aircraft Design: A Conceptual Approach, 7th Ed.,
%           AIAA, 2024, Ch.18.
%   [RAND]  Hess & Romanoff, RAND R-3255-AF, 1987 (DAPCA IV).
%   [SCH]   Scholz D., Aircraft Design Lecture Notes, HAW Hamburg, 2015.
%% Instantiate Boxwing 
ADP = BoxWing.B777.ADP();
ADP.TLAR = BoxWing.cast.TLAR.Boxwing();
ADP.Engine = BoxWing.cast.eng.TurboFan.GE90(1.0, ADP.TLAR.Alt_cruise, ADP.TLAR.M_c);
ADP.CockpitLength = 6.5;
ADP.CabinRadius   = 2.93;
ADP.CabinLength   = 70.0 - ADP.CockpitLength - ADP.CabinRadius*2*1.48;
L_f = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
ADP.FrontWingPos = 0.40 * L_f;
ADP.RearWingPos  = 0.90 * L_f;
ADP.V_HT = 0;
ADP.V_VT = 0.05;
ADP.FrontWingSpan   = 64.9;              % [m]  ICAO Cat E limit
ADP.RearWingSpan    = ADP.FrontWingSpan - 10;  % [m]  = 54.9 m
ADP.ConnectorHeight = 8;                 % [m]
ADP.AR_target       = 10.0;             % fixed AR throughout
ADP.updateDerivedProps();
ADP.MTOM    = 3.0 * ADP.TLAR.Payload;
ADP.Mf_Fuel = 0.28;
ADP.Mf_res  = 0.04;
ADP.Mf_Ldg  = 0.75;
ADP.Mf_TOC  = 0.98;
BoxWing.B777.UpdateAero(ADP);
[ADP, sizing_out] = BoxWing.B777.Size(ADP);
ac = BoxWing.B777.liftingSurfaceAC(ADP);
[BoxGeom, BoxMass] = BoxWing.B777.BuildGeometry(ADP);

MTOM_t = ADP.MTOM / 1e3;
OEM_kg   = ADP.OEM;
BlockFuel_kg = sizing_out.BlockFuel;
M_c       = ADP.TLAR.M_c;
fleet_size = 6;
SAF_ratio  = 1.0;
T_max_kN   = ADP.Engine.T_Static / 1000;




% narginchk(7,7);

%% Run all five DOC methods 
[DOC_cur,  BD_cur]  = DOC_Current (MTOM_t,OEM_kg,BlockFuel_kg,fleet_size,SAF_ratio,M_c,T_max_kN);
[DOC_ata,  BD_ata]  = DOC_ATA1967 (MTOM_t,OEM_kg,BlockFuel_kg,fleet_size,SAF_ratio,M_c,T_max_kN);
[DOC_aea,  BD_aea]  = DOC_AEA1989 (MTOM_t,OEM_kg,BlockFuel_kg,fleet_size,SAF_ratio,M_c,T_max_kN);
[DOC_tub,  BD_tub]  = DOC_TUBerlin(MTOM_t,OEM_kg,BlockFuel_kg,fleet_size,SAF_ratio,M_c,T_max_kN);
[DOC_nasa, BD_nasa] = DOC_NASADOCI(MTOM_t,OEM_kg,BlockFuel_kg,fleet_size,SAF_ratio,M_c,T_max_kN);

methods  = {'Current (DAPCA-AEA)', 'ATA 1967', 'AEA 1989', ...
            'TU Berlin 2013',      'NASA DOC+I'};
DOC_vals = [DOC_cur, DOC_ata, DOC_aea, DOC_tub, DOC_nasa];
BDs      = {BD_cur,  BD_ata,  BD_aea,  BD_tub,  BD_nasa};

%% Console output 
print_comparison(methods, DOC_vals, BDs, MTOM_t, OEM_kg, BlockFuel_kg, ...
                 fleet_size, SAF_ratio, M_c);

%% Plots 
plot_DOC_comparison(methods, DOC_vals, BDs);

%% Package results 
results.methods   = methods;
results.DOC_vals  = DOC_vals;            % [$/season]
results.DOC_M     = DOC_vals / 1e6;     % [M$/season]
results.breakdown = BDs;
results.delta_pct = (DOC_vals - DOC_vals(1)) ./ DOC_vals(1) * 100;
end


%% SHARED HELPER 1 – F1 2026 MISSION PARAMETERS

function M = mission_params(M_c)
%MISSION_PARAMS  Fixed F1 2026 air-freight schedule parameters.

M.leg_distances_km = [16847, 8018, 1457, 8052, 1272, 11621, 2264, ...
                       6129,  957, 4462, 6940, 15821, 1204,  7433, ...
                       9782, 13053,  321, 5454];

M.cruise_speed_kmh  = M_c * 1116;          % TAS at FL350 ISA [km/h]
M.block_overhead    = 1.12;                 % 12% taxi/approach overhead
M.total_dist_km     = sum(M.leg_distances_km);
M.total_FH          = (M.total_dist_km / M.cruise_speed_kmh) * M.block_overhead;
M.refuel_stops      = 5;
M.no_landings       = length(M.leg_distances_km) + M.refuel_stops;  % = 23
M.no_days_parking   = 193;                 % aircraft-days parked per season
M.aircraft_life_yr  = 20;                  % assumed design life [yr]
M.Ne                = 2;                   % number of engines
M.N_crew            = 4;                   % flight crew complement
M.fuel_density      = 0.800;              % [kg/L] Jet-A & SAF (similar density)
end


%% SHARED HELPER 2 – DAPCA-IV ACQUISITION COST
function [C_total, C_airframe, C_eng_each, Ca, Ce] = ...
         dapca_cost(OEM_kg, M_c, T_max_kN, N_prod)
%DAPCA_COST  RAND DAPCA-IV development + production cost estimate.
%  Ref: Hess & Romanoff, RAND R-3255-AF, 1987; Raymer (2024) Eq.18.1-18.8.
%
%  N_prod : production run size (use fleet_size for ownership scenario)
%  Returns per-PROGRAMME total and per-aircraft breakdowns.

M_e     = OEM_kg;
V_max   = M_c * 1116;    % [km/h] – cruise speed proxy for DAPCA
T_3     = 1000;           % [K] turbine inlet temperature (fixed assumption)
eta_M   = 1.2;            % CFRP composite manufacturing complexity factor
                           % [Raymer §18.4: composite multiplier 1.1–1.8]
eta_cpi = 1.43;           % CPI inflation factor (base year 2012 USD)
N_ft    = 2;              % flight-test aircraft count
Ne      = 2;              % number of engines per aircraft

% DAPCA labour hours [Raymer Eq.18.1-18.4]
H_E = 5.18  * M_e^0.777 * V_max^0.894 * N_prod^0.163;  % Engineering [hr]
H_T = 7.22  * M_e^0.777 * V_max^0.696 * N_prod^0.263;  % Tooling     [hr]
H_M = 10.5  * M_e^0.82  * V_max^0.484 * N_prod^0.641;  % Manufacturing [hr]
H_Q = 0.076 * H_M;                                       % Quality ctrl  [hr]

% Labour rates [$/hr, 2012 USD — Raymer Table 18.1]
R_E = 115; R_T = 118; R_M = 98; R_Q = 108;

% Cost elements [$, pre-CPI]
C_m = 31.2  * M_e^0.921 * V_max^0.621 * N_prod^0.799;   % Materials
C_D = 67.4  * M_e^0.63  * V_max^1.3;                     % Development support
C_F = 1947  * M_e^0.325 * V_max^0.822 + N_ft^1.21;       % Flight test
C_E = 3112  * (9.66*T_max_kN + 243.25*M_c + 1.74*T_3 - 2228); % Total engines

labour    = (H_E*R_E + H_T*R_T + H_M*R_M + H_Q*R_Q) * eta_M;
C_total   = (C_E + C_m + C_F + C_D + labour) * eta_cpi;  % Total programme [$]

% Per-aircraft breakdowns
C_airframe  = (C_m + C_D + C_F + labour) * eta_cpi;       % Airframe programme
C_eng_each  = (C_E * eta_cpi) / (Ne * N_prod);            % Cost per single engine
Ca          = C_airframe / N_prod;                          % Airframe cost per a/c
Ce          = C_eng_each;                                   % Engine cost (per engine)
end


%% METHOD 1 – CURRENT MODEL (DAPCA-IV / AEA hybrid)
function [DOC, BD] = DOC_Current(MTOM_t, OEM_kg, BlockFuel_kg, ...
                                  fleet_size, SAF_ratio, M_c, T_max_kN)
%DOC_CURRENT  Group 7 existing DOC model.
%  Aircraft acquisition: DAPCA-IV [Raymer, RAND R-3255-AF].
%  Operating costs: AEA-style (crew, fuel, fees, maintenance).
%  Maintenance: Raymer Eq.18.12/18.13.
%  Ownership: depreciation + interest + hull insurance.

M       = mission_params(M_c);
Ne      = M.Ne;
eta_MRO = 1.3;   % Novelty maintenance multiplier (boxwing, non-conventional)
profit  = 0.15;  % OEM profit margin on hull value

% DAPCA acquisition cost
[C_total, ~, ~, Ca, Ce] = dapca_cost(OEM_kg, M_c, T_max_kN, fleet_size);
cost_per_ac = C_total / fleet_size;
V_hull      = cost_per_ac * (1 + profit);

% ── Cash Operating Costs ──────────────────────────────────────────────
p_fuel      = 1.00*(1-SAF_ratio) + 2.00*SAF_ratio;   % [$/L]
fuel_L      = (BlockFuel_kg / M.fuel_density) * M.no_landings;
fuel_cost   = p_fuel * fuel_L * fleet_size;

crew_cost   = 150000 * M.N_crew * fleet_size;

land_cost   = 25 * MTOM_t * M.no_landings * fleet_size;
park_cost   = 4000 * M.no_days_parking * fleet_size;   % ICAO Code E
nav_cost    = sum(90 * (M.leg_distances_km/100) .* sqrt(MTOM_t/50)) * fleet_size;
fees        = land_cost + park_cost + nav_cost;

COC = fuel_cost + crew_cost + fees;

% ── Maintenance (Raymer Eq.18.12/18.13) ──────────────────────────────
maint_FH    = 3.3*(Ca/1e6) + 14.2 + (58*(Ce/1e6) - 26.1)*Ne;   % $/FH
maint_cycle = 4.0*(Ca/1e6) +  9.3 + ( 7.5*(Ce/1e6) + 5.6)*Ne; % $/cycle
maint_cost  = eta_MRO * ...
    (maint_FH*M.total_FH + maint_cycle*M.no_landings) * fleet_size;

% ── Ownership (Financial Costs) ───────────────────────────────────────
dep_cost = C_total / M.aircraft_life_yr;
int_cost = 0.05 * C_total;
ins_cost = 0.006 * V_hull * fleet_size;
FC       = dep_cost + int_cost + ins_cost;

DOC = COC + maint_cost + FC;

BD = make_breakdown(fuel_cost, crew_cost, fees, maint_cost, ...
                    dep_cost, int_cost, ins_cost, DOC, ...
    ['DAPCA-IV acquisition + Raymer Eq.18.12/13 maintenance. ' ...
     'AEA-style fees (landing, navigation, parking). ' ...
     'eta_MRO=1.3 novelty multiplier applied.']);
end


%% ======================================================================
%%  METHOD 2 – ATA 1967
%% ======================================================================
function [DOC, BD] = DOC_ATA1967(MTOM_t, OEM_kg, BlockFuel_kg, ...
                                   fleet_size, SAF_ratio, M_c, T_max_kN)
%DOC_ATA1967  Air Transport Association, Standard Method, 1967. [ATA]
%  Maintenance equations: [JEN] Ch.14 App.C; Roskam Pt.VIII (1990).
%
%  STRUCTURAL LIMITATIONS (explicit):
%   - Landing fees, navigation charges, ground handling: NOT INCLUDED.
%     ATA treated these as airport/ground costs outside DOC scope.
%     For a multi-stop European mission this causes systematic under-prediction.
%   - Interest on investment: NOT INCLUDED.
%   - Maintenance man-hours calibrated to 1960s aircraft technology.
%     Known to over-predict by ~2-4x vs modern methods [SCH, 2013].
%   - Oil cost included (ATA includes this as a separate 1.5% of fuel item).

M         = mission_params(M_c);
Ne        = M.Ne;
R_lab     = 75;     % [$/hr] maintenance labour rate (2012 USD adjusted)
TBO       = 20000;  % [hr] engine time between overhaul (modern turbofan)

% Unit conversions required by ATA equations
MTOW_klb  = MTOM_t * 2.2046;           % MTOM in units of 1000 lb
T_SLS_klb = T_max_kN * 0.2248;         % SLS thrust in units of 1000 lbf

% Aircraft acquisition cost – DAPCA IV substituted for novel aircraft
% (ATA originally used manufacturer list price; Raymer recommends DAPCA
% for aircraft without historical price data [RAY §18.5])
[C_total, ~, ~, Ca, Ce] = dapca_cost(OEM_kg, M_c, T_max_kN, fleet_size);
cost_per_ac = C_total / fleet_size;

% ── Crew [ATA: annual salary-based] ──────────────────────────────────
% ATA crew cost = salaries + per-diem allowances per crew member
crew_cost = 150000 * M.N_crew * fleet_size;

% ── Fuel & Oil [ATA includes oil at ~1.5% of fuel cost] ──────────────
p_fuel    = 1.00*(1-SAF_ratio) + 2.00*SAF_ratio;   % [$/L]
fuel_L    = (BlockFuel_kg / M.fuel_density) * M.no_landings;
fuel_cost = p_fuel * fuel_L * fleet_size;
oil_cost  = 0.015 * fuel_cost;                       % ATA empirical approximation

% ── Insurance [ATA: 0.5% of aircraft delivery price per year] ─────────
ins_cost  = 0.005 * cost_per_ac * fleet_size;

% ── Airframe Maintenance [JEN p.323, App.C] ───────────────────────────
% Labour
MH_AF_FH = 3.0 + 0.067 * MTOW_klb;   % man-hours/FH  [Jenkinson Eq.C.1]
MH_AF_FC = 1.3;                         % man-hours/FC  [Jenkinson Eq.C.2]
AF_lab   = (MH_AF_FH*M.total_FH + MH_AF_FC*M.no_landings) * R_lab * fleet_size;
% Materials (as fraction of airframe acquisition cost)
AF_mat   = (6.24e-5*Ca*M.total_FH + 1.03e-4*Ca*M.no_landings) * fleet_size;

% ── Engine Maintenance [JEN p.323, per engine] ────────────────────────
% Labour
MH_ENG_FH = 0.645 + 0.05 * T_SLS_klb;  % man-hours/FH/engine [Jenkinson Eq.C.3]
MH_ENG_FC = 0.5;                          % man-hours/FC/engine
ENG_lab   = (MH_ENG_FH*M.total_FH + MH_ENG_FC*M.no_landings) * R_lab * Ne * fleet_size;
% Materials
ENG_mat   = (2.77e-5*Ce*M.total_FH + 0.259*Ce/TBO*M.no_landings) * Ne * fleet_size;

maint_cost = AF_lab + AF_mat + ENG_lab + ENG_mat;

% ── Depreciation [ATA: straight-line, 10% residual, 16 yr] ───────────
dep_cost  = (cost_per_ac * 0.90) / 16 * fleet_size;

% ── Explicitly excluded items ─────────────────────────────────────────
fees      = 0;   % ATA 1967 does NOT include landing or nav fees
int_cost  = 0;   % ATA 1967 does NOT include interest

DOC = crew_cost + fuel_cost + oil_cost + ins_cost + maint_cost + dep_cost;

BD = make_breakdown(fuel_cost+oil_cost, crew_cost, fees, maint_cost, ...
                    dep_cost, int_cost, ins_cost, DOC, ...
    ['ATA 1967: fees=0 (by design), interest=0 (by design). ' ...
     'Oil included at 1.5%% fuel cost. ' ...
     'Maintenance man-hours based on 1960s technology – likely over-predicted. ' ...
     'DAPCA IV substituted for aircraft price (no list price available).']);
end


%% ======================================================================
%%  METHOD 3 – AEA 1989 (Long-Range)
%% ======================================================================
function [DOC, BD] = DOC_AEA1989(MTOM_t, OEM_kg, BlockFuel_kg, ...
                                   fleet_size, SAF_ratio, M_c, T_max_kN)
%DOC_AEA1989  Association of European Airlines, long-range variant. [AEA]
%  Structural equations: [JEN] Ch.14 pp.316-325; [SCH] Ch.10.
%
%  Key differences from ATA 1967:
%   + Landing fees and navigation charges INCLUDED (European context)
%   + Interest on investment INCLUDED (AEA §4.1: 5.3% avg over life)
%   + Maintenance regression re-calibrated (lower MH than ATA 1967)
%   + 16-year amortisation period with 10% residual value
%
%  Aircraft price: AEA parametric formula reported for information,
%  but DAPCA IV used as primary input (appropriate for novel aircraft).

M       = mission_params(M_c);
Ne      = M.Ne;
R_lab   = 75;   % [$/hr] maintenance labour rate (2012 USD)

% ── Aircraft price ────────────────────────────────────────────────────
% AEA parametric (Jenkinson p.317): P_af = 700 $/kg OEW, P_eng = 25 $/N thrust
P_af_AEA   = 700 * OEM_kg;
P_eng_AEA  = 25 * (T_max_kN*1e3) * Ne;
P_ac_AEA   = (P_af_AEA * 1.10) + (P_eng_AEA * 1.30);  % with spares

% DAPCA IV (used as primary – more physically grounded for novel aircraft)
[C_total, ~, ~, Ca, Ce] = dapca_cost(OEM_kg, M_c, T_max_kN, fleet_size);
P_ac = C_total / fleet_size;   % per-aircraft programme cost (DAPCA primary)

% ── Ownership [AEA long-range: 16 yr, 10% residual, 5.3% interest] ───
dep_cost = (P_ac * 0.90) / 16 * fleet_size;    % Jenkinson p.317
int_cost =  P_ac * 0.053       * fleet_size;    % AEA §4.1 average interest
ins_cost =  P_ac * 0.005       * fleet_size;    % 0.5% hull insurance

% ── Fuel ──────────────────────────────────────────────────────────────
p_fuel   = 1.00*(1-SAF_ratio) + 2.00*SAF_ratio;
fuel_L   = (BlockFuel_kg / M.fuel_density) * M.no_landings;
fuel_cost = p_fuel * fuel_L * fleet_size;

% ── Crew ──────────────────────────────────────────────────────────────
crew_cost = 150000 * M.N_crew * fleet_size;

% ── Navigation charges [Eurocontrol; AEA long-range variant] ──────────
% Jenkinson p.322: AEA uses distance-based nav charge per leg
% Eurocontrol unit rate × distance factor × weight factor
nav_cost  = sum(90 .* (M.leg_distances_km/100) .* sqrt(MTOM_t/50)) * fleet_size;

% ── Landing fees [AEA: ~$10/tonne MTOM, Jenkinson p.322] ─────────────
land_cost = 10 * MTOM_t * M.no_landings * fleet_size;

fees = nav_cost + land_cost;

% ── Airframe Maintenance [JEN p.320, Eq.14.3a-b] ─────────────────────
% Labour (man-hours per FH and per FC; MTOM in tonnes)
MH_AF_FH = 0.09 * MTOM_t + 0.15;    % [man-hrs/FH]  Jenkinson Eq.14.3a
MH_AF_FC = 0.057 * MTOM_t + 0.28;   % [man-hrs/FC]  Jenkinson Eq.14.3b
AF_lab   = (MH_AF_FH*M.total_FH + MH_AF_FC*M.no_landings) * R_lab * fleet_size;
% Materials (fraction of airframe price)
AF_mat   = (6.24e-5*Ca*M.total_FH + 1.03e-4*Ca*M.no_landings) * fleet_size;

% ── Engine Maintenance [JEN p.321, AEA variant] ───────────────────────
% Labour (per engine)
MH_ENG_FH = 0.21 + 0.00067 * T_max_kN;  % [man-hrs/FH/engine]
MH_ENG_FC = 0.30;                          % [man-hrs/FC/engine]
ENG_lab   = (MH_ENG_FH*M.total_FH + MH_ENG_FC*M.no_landings) * R_lab * Ne * fleet_size;
% Materials
ENG_mat   = 2.77e-5 * Ce * M.total_FH * Ne * fleet_size;

maint_cost = AF_lab + AF_mat + ENG_lab + ENG_mat;

% ── Total ─────────────────────────────────────────────────────────────
COC = fuel_cost + crew_cost + fees;
FC  = dep_cost + int_cost + ins_cost;
DOC = COC + maint_cost + FC;

BD = make_breakdown(fuel_cost, crew_cost, fees, maint_cost, ...
                    dep_cost, int_cost, ins_cost, DOC, ...
    ['AEA 1989 long-range: fees+interest included. ' ...
     'DAPCA IV used as aircraft price (AEA parametric: $' ...
     sprintf('%.1fM', P_ac_AEA/1e6) '). ' ...
     '16yr depreciation, 5.3%% avg interest rate.']);
BD.AEA_parametric_price_M = P_ac_AEA / 1e6;
BD.DAPCA_price_M          = P_ac / 1e6;
end


%% ======================================================================
%%  METHOD 4 – TU BERLIN 2013 (Thorbeck-Scholz)
%% ======================================================================
function [DOC, BD] = DOC_TUBerlin(MTOM_t, OEM_kg, BlockFuel_kg, ...
                                    fleet_size, SAF_ratio, M_c, T_max_kN)
%DOC_TUBBERLIN  TU Berlin DOC-assessment method, 2013. [TUB]
%  Ref: Thorbeck J. & Scholz D., "DOC-Assessment Method", 3rd Symp. on
%       Collaboration in Aircraft Design, Linköping, Sweden, 2013.
%       Scholz D., Aircraft Design Lecture Notes, HAW Hamburg, 2015, Ch.10.
%
%  European context; most recently calibrated (2010 airline data).
%  Structurally similar to AEA 1989 but with:
%   - Updated maintenance regression coefficients (lower than AEA)
%   - 20-year depreciation period (updated from AEA's 16 yr)
%   - 4% interest rate (updated from AEA's 5.3%)
%   - Cabin/interior maintenance omitted (freighter: not applicable)
%
%  Aircraft price: DAPCA IV (same as other methods for consistency).

M       = mission_params(M_c);
Ne      = M.Ne;
R_lab   = 75;   % [$/hr]

% ── Aircraft price (DAPCA IV) ─────────────────────────────────────────
[C_total, ~, ~, Ca, Ce] = dapca_cost(OEM_kg, M_c, T_max_kN, fleet_size);
P_ac = C_total / fleet_size;

% ── Ownership [TUB: 20 yr, 10% residual, 4% interest] ────────────────
% Thorbeck-Scholz (2013): extended to 20 yr reflecting modern aircraft life
dep_cost = (P_ac * 0.90) / 20 * fleet_size;
int_cost =  P_ac * 0.04       * fleet_size;   % 4% (lower than AEA's 5.3%)
ins_cost =  P_ac * 0.005      * fleet_size;   % 0.5% (same as AEA)

% ── Fuel ──────────────────────────────────────────────────────────────
p_fuel    = 1.00*(1-SAF_ratio) + 2.00*SAF_ratio;
fuel_L    = (BlockFuel_kg / M.fuel_density) * M.no_landings;
fuel_cost = p_fuel * fuel_L * fleet_size;

% ── Crew ──────────────────────────────────────────────────────────────
crew_cost = 150000 * M.N_crew * fleet_size;

% ── Navigation [Eurocontrol – same formula as AEA] ────────────────────
nav_cost  = sum(90 .* (M.leg_distances_km/100) .* sqrt(MTOM_t/50)) * fleet_size;

% ── Landing fees [TUB: ~$12/tonne – slightly updated from AEA $10] ────
land_cost = 12 * MTOM_t * M.no_landings * fleet_size;

fees = nav_cost + land_cost;

% ── Airframe Maintenance [Thorbeck-Scholz 2013, updated regression] ───
% Labour – note slightly smaller coefficients than AEA (2010 data, improved MRO)
MH_AF_FH = 0.076 * MTOM_t + 0.12;   % [man-hrs/FH] vs AEA 0.090+0.15
MH_AF_FC = 0.048 * MTOM_t + 0.21;   % [man-hrs/FC] vs AEA 0.057+0.28
AF_lab   = (MH_AF_FH*M.total_FH + MH_AF_FC*M.no_landings) * R_lab * fleet_size;
% Materials (same fraction as AEA – insufficient differentiation in literature)
AF_mat   = (6.24e-5*Ca*M.total_FH + 1.03e-4*Ca*M.no_landings) * fleet_size;

% ── Engine Maintenance [Thorbeck-Scholz: higher thrust sensitivity] ───
MH_ENG_FH = 0.21 + 0.006 * T_max_kN;   % vs AEA 0.21 + 0.00067 T_kN
MH_ENG_FC = 0.30;
ENG_lab   = (MH_ENG_FH*M.total_FH + MH_ENG_FC*M.no_landings) * R_lab * Ne * fleet_size;
ENG_mat   = 2.77e-5 * Ce * M.total_FH * Ne * fleet_size;

maint_cost = AF_lab + AF_mat + ENG_lab + ENG_mat;

% ── Total ─────────────────────────────────────────────────────────────
COC = fuel_cost + crew_cost + fees;
FC  = dep_cost + int_cost + ins_cost;
DOC = COC + maint_cost + FC;

BD = make_breakdown(fuel_cost, crew_cost, fees, maint_cost, ...
                    dep_cost, int_cost, ins_cost, DOC, ...
    ['TU Berlin 2013: 20yr depreciation, 4%% interest (most recent calibration). ' ...
     'Updated maintenance coefficients (lower than AEA). ' ...
     'DAPCA IV aircraft price. European fees included.']);
end


%% ======================================================================
%%  METHOD 5 – NASA DOC+I (Liebeck 1995)
%% ======================================================================
function [DOC, BD] = DOC_NASADOCI(MTOM_t, OEM_kg, BlockFuel_kg, ...
                                    fleet_size, SAF_ratio, M_c, T_max_kN)
%DOC_NASADOCI  NASA DOC+I method – Liebeck (McDonnell Douglas data). [NASA]
%  Ref: Liebeck R.H., "Advanced Subsonic Airplane Design and Economic
%       Studies", NASA CR-195443, April 1995.
%
%  Based on McDonnell Douglas commercial aircraft experience (1993 data).
%  The "+I" explicitly includes interest (unlike ATA 1967).
%
%  STRUCTURAL LIMITATIONS:
%   - US calibration: NO landing fees, NO navigation charges (excluded by
%     US DOT accounting conventions). Systematic under-prediction for
%     European operations estimated at 10-15% [SCH, 2013].
%   - 15-year depreciation (shorter than AEA/TUB – MD fleet planning era).
%   - 10% interest rate (higher US market rate vs European 4-5%).
%   - No parking fees in standard formulation.

M         = mission_params(M_c);
Ne        = M.Ne;
R_lab     = 75;   % [$/hr]
MTOW_klb  = MTOM_t * 2.2046;   % MTOM in 1000 lb (for NASA equations)

% ── Aircraft price (DAPCA IV) ─────────────────────────────────────────
[C_total, ~, ~, Ca, Ce] = dapca_cost(OEM_kg, M_c, T_max_kN, fleet_size);
P_ac = C_total / fleet_size;

% ── Ownership [NASA DOC+I: 15 yr, 15% residual, 10% interest] ─────────
% Liebeck (1995): shorter life/higher rate reflecting US airline economics
dep_cost = (P_ac * 0.85) / 15 * fleet_size;    % 15yr, 15% residual
int_cost =  P_ac * 0.10       * fleet_size;    % 10% (explicit +I term)
ins_cost =  P_ac * 0.005      * fleet_size;    % 0.5%

% ── Fuel ──────────────────────────────────────────────────────────────
p_fuel    = 1.00*(1-SAF_ratio) + 2.00*SAF_ratio;
fuel_L    = (BlockFuel_kg / M.fuel_density) * M.no_landings;
fuel_cost = p_fuel * fuel_L * fleet_size;

% ── Crew ──────────────────────────────────────────────────────────────
crew_cost = 150000 * M.N_crew * fleet_size;

% ── Fees – EXPLICITLY ZERO (NASA DOC+I, US convention) ───────────────
fees = 0;   % Landing fees and nav charges not included in US DOC+I

% ── Airframe Maintenance [Liebeck 1995, adapted from NASA CR-195443] ──
% Labour – NASA uses MTOW in 1000 lb, resulting in fewer man-hours than ATA
MH_AF_FH = 1.5 + 0.040 * MTOW_klb;   % [man-hrs/FH] Liebeck §3.4
MH_AF_FC = 0.4 + 0.008 * MTOW_klb;   % [man-hrs/FC]
AF_lab   = (MH_AF_FH*M.total_FH + MH_AF_FC*M.no_landings) * R_lab * fleet_size;
% Materials (slightly lower fraction than ATA)
AF_mat   = (5.0e-5*Ca*M.total_FH + 0.8e-4*Ca*M.no_landings) * fleet_size;

% ── Engine Maintenance [Liebeck 1995, per engine] ─────────────────────
T_SLS_klb = T_max_kN * 0.2248;
MH_ENG_FH = 0.4 + 0.030 * T_SLS_klb;   % [man-hrs/FH/engine]
MH_ENG_FC = 0.25;
ENG_lab   = (MH_ENG_FH*M.total_FH + MH_ENG_FC*M.no_landings) * R_lab * Ne * fleet_size;
ENG_mat   = 2.5e-5 * Ce * M.total_FH * Ne * fleet_size;

maint_cost = AF_lab + AF_mat + ENG_lab + ENG_mat;

% ── Total ─────────────────────────────────────────────────────────────
COC = fuel_cost + crew_cost;   % NO fees in NASA DOC+I
FC  = dep_cost + int_cost + ins_cost;
DOC = COC + maint_cost + FC;

BD = make_breakdown(fuel_cost, crew_cost, fees, maint_cost, ...
                    dep_cost, int_cost, ins_cost, DOC, ...
    ['NASA DOC+I 1995: fees=0 (US convention, known under-prediction for Europe). ' ...
     '15yr depreciation, 10%% interest (+I explicit). ' ...
     'McDonnell Douglas 1993 calibration base.']);
end


%% ======================================================================
%%  SHARED HELPER 3 – STANDARDISED BREAKDOWN STRUCT
%% ======================================================================
function BD = make_breakdown(fuel, crew, fees, maint, dep, int_c, ins, DOC, note)
%MAKE_BREAKDOWN  Create standardised breakdown struct for all methods.
BD.fuel         = fuel;
BD.crew         = crew;
BD.fees         = fees;
BD.maintenance  = maint;
BD.depreciation = dep;
BD.interest     = int_c;
BD.insurance    = ins;
BD.COC          = fuel + crew + fees;
BD.FC           = dep + int_c + ins;
BD.DOC          = DOC;
BD.notes        = note;
end


%% ======================================================================
%%  CONSOLE OUTPUT
%% ======================================================================
function print_comparison(methods, DOC_vals, BDs, MTOM_t, OEM_kg, ...
                           BlockFuel_kg, fleet_size, SAF_ratio, M_c)
n = length(methods);
includes_fees = {'Yes','No','Yes','Yes','No'};
includes_int  = {'Yes','No','Yes','Yes','Yes'};

fprintf('\n');
fprintf('══════════════════════════════════════════════════════════════════════\n');
fprintf('  DOC METHOD COMPARISON — Fleet=%d, F1 2026 Season\n', fleet_size);
fprintf('  MTOM=%.0ft  OEM=%.0ft  Fuel/leg=%.0ft  SAF=%.0f%%  M=%.2f\n', ...
        MTOM_t, OEM_kg/1e3, BlockFuel_kg/1e3, SAF_ratio*100, M_c);
fprintf('══════════════════════════════════════════════════════════════════════\n');
fprintf('  %-22s  %9s  %8s  %5s  %5s\n', ...
        'Method','DOC [M$]','vs.Cur[%]','Fees?','Int?');
fprintf('  %-22s  %9s  %8s  %5s  %5s\n', ...
        repmat('-',1,22),repmat('-',1,9),repmat('-',1,8),'-----','-----');
for i = 1:n
    d = (DOC_vals(i)-DOC_vals(1))/DOC_vals(1)*100;
    fprintf('  %-22s  %9.2f  %+7.1f%%  %5s  %5s\n', ...
        methods{i}, DOC_vals(i)/1e6, d, includes_fees{i}, includes_int{i});
end
fprintf('══════════════════════════════════════════════════════════════════════\n\n');

% Cost breakdown table
comp   = {'fuel','crew','fees','maintenance','depreciation','interest','insurance'};
labels = {'Fuel','Crew','Land+Nav Fees','Maintenance','Depreciation','Interest','Insurance'};
fprintf('  COST BREAKDOWN [M$/season]\n');
hdr = sprintf('  %-18s', 'Component');
for i = 1:n; hdr = [hdr sprintf('  %10s', strtrim(methods{i}(1:min(10,end))))]; end %#ok
fprintf('%s\n', hdr);
fprintf('  %s\n', repmat('-', 1, 22 + n*12));
for c = 1:length(comp)
    row_str = sprintf('  %-18s', labels{c});
    for i = 1:n
        if isfield(BDs{i}, comp{c}) && BDs{i}.(comp{c}) >= 0
            row_str = [row_str sprintf('  %10.2f', BDs{i}.(comp{c})/1e6)]; %#ok
        else
            row_str = [row_str sprintf('  %10s', 'N/A')]; %#ok
        end
    end
    fprintf('%s\n', row_str);
end
fprintf('  %s\n', repmat('-', 1, 22 + n*12));
tot_str = sprintf('  %-18s', 'TOTAL DOC');
for i = 1:n; tot_str = [tot_str sprintf('  %10.2f', DOC_vals(i)/1e6)]; end %#ok
fprintf('%s\n\n', tot_str);

% Print method notes
%fprintf('  METHOD NOTES:\n');
%for i = 1:n
%    fprintf('  [%d] %s:\n      %s\n\n', i, methods{i}, BDs{i}.notes);
%end
end


%% ======================================================================
%%  PLOTTING
%% ======================================================================
function plot_DOC_comparison(methods, DOC_vals, BDs)
n   = length(methods);
clr = [0.20 0.45 0.70; 0.85 0.33 0.10; 0.47 0.67 0.19;
       0.49 0.18 0.56; 0.30 0.75 0.93];

comp_fields  = {'fuel','crew','fees','maintenance','depreciation','interest','insurance'};
comp_labels  = {'Fuel','Crew','Land+Nav','Maintenance','Depreciation','Interest','Insurance'};
comp_colors  = [0.95 0.45 0.10; 0.20 0.55 0.85; 0.35 0.75 0.35;
                0.55 0.25 0.65; 0.15 0.35 0.75; 0.40 0.60 0.90;
                0.65 0.80 0.95];

data = zeros(n, length(comp_fields));
for i = 1:n
    for c = 1:length(comp_fields)
        if isfield(BDs{i}, comp_fields{c})
            data(i,c) = max(0, BDs{i}.(comp_fields{c})) / 1e6;
        end
    end
end

short_names = {'Current','ATA 1967','AEA 1989','TUB 2013','NASA DOC+I'};

%% Figure 1 – Total DOC bar
figure('Name','DOC: Total Comparison','Color','w','Position',[50 50 900 500]);
b1 = bar(DOC_vals/1e6, 0.72);
b1.FaceColor = 'flat';
for i = 1:n; b1.CData(i,:) = clr(i,:); end
set(gca,'XTickLabel',short_names,'XTickLabelRotation',12,'FontSize',11);
ylabel('Total Fleet DOC [M$/season]','FontSize',12);
title('DOC Method Comparison — Total Fleet Cost, F1 2026','FontSize',13,'FontWeight','bold');
grid on; box on; yline(DOC_vals(1)/1e6,'--k','LineWidth',1.5);
for i = 1:n
    text(i, DOC_vals(i)/1e6 + 0.008*max(DOC_vals)/1e6, ...
         sprintf('$%.1fM', DOC_vals(i)/1e6), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

%% Figure 2 – Stacked breakdown
figure('Name','DOC: Breakdown','Color','w','Position',[80 80 1100 540]);
bh = bar(data, 'stacked');
for c = 1:length(comp_fields); bh(c).FaceColor = comp_colors(c,:); end
set(gca,'XTickLabel',short_names,'XTickLabelRotation',12,'FontSize',11);
ylabel('DOC [M$/season]','FontSize',12);
title('DOC Cost Breakdown by Method','FontSize',13,'FontWeight','bold');
legend(comp_labels,'Location','northeast','FontSize',9);
grid on; box on;

%% Figure 3 – Delta from current model
figure('Name','DOC: Delta from Current','Color','w','Position',[110 110 860 460]);
delta = (DOC_vals - DOC_vals(1)) ./ DOC_vals(1) * 100;
b3 = bar(delta, 0.72);
b3.FaceColor = 'flat';
for i = 1:n; b3.CData(i,:) = clr(i,:); end
yline(0,'--k','LineWidth',1.8);
set(gca,'XTickLabel',short_names,'XTickLabelRotation',12,'FontSize',11);
ylabel('\DeltaDOC from Current Model [%]','FontSize',12);
title('DOC Divergence Relative to Current (DAPCA-AEA) Model','FontSize',13,'FontWeight','bold');
grid on; box on;
for i = 1:n
    ofs = 0.3 * sign(delta(i)); if ofs==0; ofs=0.3; end
    text(i, delta(i)+ofs, sprintf('%+.1f%%',delta(i)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

%% Figure 4 – Fee inclusion sensitivity (what does ATA/NASA miss?)
figure('Name','DOC: Fee Sensitivity','Color','w','Position',[140 140 900 500]);
DOC_no_fees = zeros(1,n);
for i = 1:n
    if isfield(BDs{i},'fees'); DOC_no_fees(i) = DOC_vals(i) - BDs{i}.fees;
    else;                       DOC_no_fees(i) = DOC_vals(i); end
end
fee_contrib = (DOC_vals - DOC_no_fees) / 1e6;

hold on;
b4a = bar(DOC_no_fees/1e6, 0.72, 'FaceColor',[0.75 0.75 0.75],'EdgeColor','k');
b4b = bar(DOC_vals/1e6, 0.72, 'FaceColor','none','EdgeColor','none');
for i = 1:n
    if fee_contrib(i) > 0
        b_patch = bar(i, fee_contrib(i), 0.72, ...
            'FaceColor',[0.35 0.75 0.35],'EdgeColor','k', ...
            'BaseValue', DOC_no_fees(i)/1e6);
    end
end
set(gca,'XTickLabel',short_names,'XTickLabelRotation',12,'FontSize',11);
ylabel('DOC [M$/season]','FontSize',12);
title('Fee Sensitivity: What ATA 1967 and NASA DOC+I Omit','FontSize',13,'FontWeight','bold');
legend({'DOC excluding fees','Fee contribution (landing + nav)'},'Location','northwest','FontSize',10);
for i = 1:n
    text(i, DOC_vals(i)/1e6 + 0.01*max(DOC_vals)/1e6, ...
         sprintf('$%.1fM', DOC_vals(i)/1e6), ...
         'HorizontalAlignment','center','FontSize',9);
end
grid on; box on;

%% Figure 5 – Maintenance cost comparison (key differentiator between methods)
maint_vals = zeros(1,n);
for i = 1:n
    if isfield(BDs{i},'maintenance'); maint_vals(i) = BDs{i}.maintenance/1e6; end
end
figure('Name','DOC: Maintenance Comparison','Color','w','Position',[170 170 800 450]);
b5 = bar(maint_vals, 0.72);
b5.FaceColor = 'flat';
for i = 1:n; b5.CData(i,:) = clr(i,:); end
set(gca,'XTickLabel',short_names,'XTickLabelRotation',12,'FontSize',11);
ylabel('Maintenance Cost [M$/season]','FontSize',12);
title('Maintenance Cost by Method — Key Sensitivity Parameter','FontSize',13,'FontWeight','bold');
grid on; box on;
annotation('textbox',[0.12 0.78 0.55 0.08],'String', ...
    'ATA 1967 over-predicts maintenance vs modern methods (1960s calibration)', ...
    'EdgeColor','r','BackgroundColor',[1 0.9 0.9],'FontSize',9);
for i = 1:n
    text(i, maint_vals(i)+0.005*max(maint_vals), ...
         sprintf('$%.2fM',maint_vals(i)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

end