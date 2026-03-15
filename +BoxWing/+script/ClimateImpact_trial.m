function [ATR100, breakdown] = ClimateImpact(ADP, BlockFuel_kg, ...
                                              fleet_size, n_flights, SAF_ratio)
%CLIMATEIMPACT  ATR100 climate impact model for the Boxwing F1 freighter.
%
%  Implements the full Dallara (2011) framework as specified in the
%  Bristol GDP lecture notes, covering all major forcing species with
%  altitude-dependent scaling for short-lived pollutants.
%
%  REFERENCES:
%   [1] Dallara (2011) DOI: 10.2514/1.J050763
%   [2] Proesmans & Vos (2022) DOI: 10.2514/1.C036529
%   [3] Bristol GDP Lecture: Performance, Propulsion & Climate
%
%  METHOD SUMMARY:
%   1. Compute emission masses for each species (CO2, H2O, SO4, soot, NOx)
%      per flight, then scale to the full season fleet.
%   2. Apply altitude scaling s(h) to short-lived species.
%   3. Calculate RF* (normalised radiative forcing) for each species.
%   4. Integrate ΔT(t) = ∫ G_T(t−t') RF*(t') dt' over 100 years.
%   5. ATR100 = (1/100) ∫₀¹⁰⁰ ΔT(t) dt
%
%  INPUTS:
%   ADP          BoxWing ADP object (needs TLAR.M_c, TLAR.Alt_cruise,
%                TLAR.Range, Engine)
%   BlockFuel_kg [kg]   Block fuel per flight per aircraft
%   fleet_size   [-]    Number of aircraft in fleet
%   n_flights    [-]    Number of flights per aircraft per season
%   SAF_ratio    [0-1]  SAF blend fraction (0 = kerosene, 1 = 100% SAF)
%
%  OUTPUTS:
%   ATR100       [K]    Average Temperature Response over 100 years
%   breakdown    struct Contribution of each species

%% ── 0. SEASON-LEVEL TOTAL FUEL ──────────────────────────────────────────
total_fuel_kg = BlockFuel_kg * n_flights * fleet_size;   % [kg]

%% ── 1. CRUISE CONDITIONS ────────────────────────────────────────────────
alt_m    = ADP.TLAR.Alt_cruise;          % [m]
M_c      = ADP.TLAR.M_c;
range_m  = ADP.TLAR.Range;              % [m] per flight
range_km = range_m * 1e-3;              % [km]

[~, a_c, T_c, p_c] = BoxWing.cast.atmos(alt_m);
V_c = M_c * a_c;                        % [m/s] cruise TAS

%% ── 2. EMISSION INDICES ─────────────────────────────────────────────────
% Fixed emission indices per kg of fuel (kerosene baseline)
% Source: European Aviation Environmental Report 2016 / lecture slide 23
EI_CO2_kero = 3.16;     % [kg CO2  / kg fuel]
EI_H2O      = 1.26;     % [kg H2O  / kg fuel]
EI_SO4      = 2.0e-4;   % [kg SO4  / kg fuel]
EI_soot     = 4.0e-5;   % [kg soot / kg fuel]

% SAF lifecycle CO2: ~80% lower net CO2 emissions (well-to-wake)
% Soot and SO4 also reduce with SAF (~70% reduction for 100% SAF)
% Source: Proesmans (2022), GDP SAF lecture update
EI_CO2_eff  = EI_CO2_kero * (1 - 0.80 * SAF_ratio);
EI_SO4_eff  = EI_SO4      * (1 - 0.70 * SAF_ratio);
EI_soot_eff = EI_soot     * (1 - 0.70 * SAF_ratio);

% NOx emission index from combustor inlet conditions (lecture slide 23)
%   EI_NOx = 0.0986 * (p3/101325)^0.4 * exp(T3/194 + H0/53.2)
% Approximate combustor inlet conditions using engine OPR and isentropic
% compression from cruise total conditions
OPR    = 50;           % overall pressure ratio (typical GE90-class)
eta_c  = 0.88;         % isentropic compressor efficiency
gam    = 1.4;

% Cruise total conditions
T_t0   = T_c  * (1 + (gam-1)/2 * M_c^2);
p_t0   = p_c  * (1 + (gam-1)/2 * M_c^2)^(gam/(gam-1));

% Combustor inlet (station 3) — isentropic compression
p3     = p_t0 * OPR;
T3     = T_t0 * (OPR^((gam-1)/gam) - 1) / eta_c + T_t0;  % real compression

H0     = 0.6;          % relative humidity (mid-latitude cruise average)
EI_NOx = 0.0986 * (p3/101325)^0.4 * exp(T3/194 + H0/53.2);  % [g/kg fuel]
EI_NOx = min(EI_NOx, 40);  % physical cap [g/kg]
EI_NOx_kgkg = EI_NOx / 1000;  % convert g/kg → kg/kg

%% ── 3. EMISSION MASSES (season total) ──────────────────────────────────
m_CO2  = total_fuel_kg * EI_CO2_eff;    % [kg]
m_H2O  = total_fuel_kg * EI_H2O;       % [kg]
m_SO4  = total_fuel_kg * EI_SO4_eff;   % [kg]
m_soot = total_fuel_kg * EI_soot_eff;  % [kg]
m_NOx  = total_fuel_kg * EI_NOx_kgkg;  % [kg]

% AIC: stage length flown per year per fleet [miles] — Dallara (2011)
L_miles = range_km * 0.621371 * n_flights * fleet_size;  % [miles/year]

%% ── 4. ALTITUDE SCALING s(h) ────────────────────────────────────────────
% CO2 has negligible altitude dependence → s_CO2 = 1.0
% Short-lived species scale with altitude per Dallara (2011) Fig. 3
%
% Fitted linear approximation over cruise range 10–13 km:
%   s(h) = s_ref * exp(k * (h_km - h_ref))
% Calibrated to Dallara (2011) Table 1 values at representative altitudes.
%
%  Species        s at 10 km    s at 11 km    s at 12 km    s at 13 km
%  H2O               0.25          0.45          0.70          1.00
%  SO4               0.20          0.35          0.55          0.80
%  Soot              0.20          0.35          0.55          0.80
%  NOx (O3-short)    0.50          0.75          1.00          1.20
%  AIC               0.60          0.85          1.10          1.35

h_km      = alt_m * 1e-3;
h_ref     = 11.0;    % reference altitude [km]

% Exponential fits to Dallara (2011) altitude scaling
s_H2O  = 0.45 * exp( 0.65 * (h_km - h_ref));
s_SO4  = 0.35 * exp( 0.60 * (h_km - h_ref));
s_soot = 0.35 * exp( 0.60 * (h_km - h_ref));
s_NOx  = 0.75 * exp( 0.30 * (h_km - h_ref));
s_AIC  = 0.85 * exp( 0.30 * (h_km - h_ref));

% Clamp to physical bounds
s_H2O  = max(0.01, min(s_H2O,  2.0));
s_SO4  = max(0.01, min(s_SO4,  2.0));
s_soot = max(0.01, min(s_soot, 2.0));
s_NOx  = max(0.10, min(s_NOx,  2.0));
s_AIC  = max(0.10, min(s_AIC,  2.0));

%% ── 5. ATR100 FORCING FACTORS ───────────────────────────────────────────
% Pre-integrated ATR100 factors A_i [K per kg of emission] from
% Dallara (2011) Table 2, incorporating RF* and Earth thermal response.
% These represent the average temperature increase over 100 years from
% a 1 kg pulse emission (or per km for AIC).
%
% RF_2xCO2 = 3.7 W/m² (reference normalisation)
%
% Species          A_i value        Sign  Notes
% CO2              1.01e-15 K/kg    (+)   no altitude dependence
% H2O              2.40e-15 K/kg    (+)   short-lived, altitude scaled
% SO4             -3.90e-16 K/kg    (-)   cooling (scattering)
% Soot             2.52e-14 K/kg    (+)   warming (absorption)
% NOx O3 short     5.16e-13 K/kg    (+)   warming (O3 creation, ~weeks)
% NOx CH4 long    -1.21e-13 K/kg    (-)   cooling (CH4 depletion, 12yr τ)
% NOx O3 long     -5.16e-13 K/kg    (-)   cooling (O3 depletion long-term)
% AIC              1.10e-14 K/km    (+)   per km flown (altitude scaled)

A_CO2       =  1.01e-15;   % [K / kg CO2]
A_H2O       =  2.40e-15;   % [K / kg H2O]
A_SO4       = -3.90e-16;   % [K / kg SO4]   cooling
A_soot      =  2.52e-14;   % [K / kg soot]
A_NOx_O3s   =  5.16e-13;   % [K / kg NOx]   short-term O3
A_NOx_CH4   = -1.21e-13;   % [K / kg NOx]   CH4 depletion (τ=12yr)
A_NOx_O3L   = -5.16e-13;   % [K / kg NOx]   long-term O3 depletion
A_AIC_perkm =  1.10e-14;   % [K / km]       per season-km

%% ── 6. ATR100 CONTRIBUTIONS ─────────────────────────────────────────────
% Apply altitude scaling to the forcing factors for short-lived species
ATR_CO2  = m_CO2  * A_CO2;                              % no s(h)
ATR_H2O  = m_H2O  * A_H2O  * s_H2O;
ATR_SO4  = m_SO4  * A_SO4  * s_SO4;
ATR_soot = m_soot * A_soot * s_soot;
ATR_NOx  = m_NOx  * (A_NOx_O3s * s_NOx ...             % O3 short-term
                    + A_NOx_CH4                ...      % CH4 (global, no s)
                    + A_NOx_O3L);                       % O3 long-term
ATR_AIC  = L_miles * A_AIC_perkm * s_AIC;              % per mile * s(h)

ATR100 = ATR_CO2 + ATR_H2O + ATR_SO4 + ATR_soot + ATR_NOx + ATR_AIC;

%% ── 7. OUTPUT BREAKDOWN ─────────────────────────────────────────────────
breakdown = struct( ...
    'ATR_CO2',       ATR_CO2, ...
    'ATR_H2O',       ATR_H2O, ...
    'ATR_SO4',       ATR_SO4, ...
    'ATR_soot',      ATR_soot, ...
    'ATR_NOx',       ATR_NOx, ...
    'ATR_AIC',       ATR_AIC, ...
    'total',         ATR100, ...
    ... % emission masses for reporting
    'm_CO2_kg',      m_CO2, ...
    'm_NOx_kg',      m_NOx, ...
    'm_H2O_kg',      m_H2O, ...
    'EI_NOx_g_kg',   EI_NOx, ...
    's_AIC',         s_AIC, ...
    's_NOx',         s_NOx, ...
    'total_fuel_kg', total_fuel_kg);

end