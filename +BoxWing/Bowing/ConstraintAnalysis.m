function [TW_SLS, WS] = ConstraintAnalysis(obj)
%Constraint analysis Wing loading and SLS thrust-to-weight for boxwing.
%
%  W/S is computed from the landing stall-speed constraint:
%    V_stall_land = V_app / 1.3     (FAR 25 approach = 1.3 * Vs)
%    WS_land = 0.5*rho_sl*Vs^2*CL_max_land   (at MLW)
%    WS_MTOW = WS_land / Mf_Ldg              (scale to MTOW)
%    Clamp to 6000-8500 N/m^2  (real freighter range) this are assumption
%    and internet values 
%
%  T/W is from cruise drag, corrected to sea-level-static via lapse model.

%% Wing loading
rho_sl  = 1.225;
V_app   = obj.TLAR.V_app;           % approach speed [m/s]
V_stall = V_app / 1.30;             
CL_land = 2.8;                      % CL_max with landing flaps

WS_land = 0.5 * rho_sl * V_stall^2 * CL_land;   % [N/m^2] at MLW
WS      = WS_land / obj.Mf_Ldg;                  % [N/m^2] at MTOW

% Clamp to realistic range for wide-body freighters:
%   A350F ~ 7000 N/m^2,  B777F ~ 6700 N/m^2
WS = max(6000, min(WS, 8500)); % assumption

%% Thrust-to-weight (cruise, then converted to SLS)
[rho_c, a_c] = cast.atmos(obj.TLAR.Alt_cruise);
q_c    = 0.5 * rho_c * (obj.TLAR.M_c * a_c)^2;
CL_c   = WS / q_c;
CD_c   = obj.CD0 + CL_c^2 / (pi * obj.e * obj.AR());
TW_cr  = (q_c * CD_c / WS) * 1.10;   % cruise T/W + 10% margin

% Turbofan thrust lapse: T/T_SLS ~ (rho/rho_sl)^0.75
lapse_ratio = (rho_c / rho_sl)^0.75;
TW_SLS = TW_cr / lapse_ratio;

end
