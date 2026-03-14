function [BlockFuel,TripFuel,ResFuel,Mf_TOC,MissionTime,cruise_FL] = MissionAnalysis(ADP,tripRange,M_TO)
%MISSIONANALYSIS conduct mission analysis to estimate fuel burn
arguments
    ADP
    tripRange
    M_TO = ADP.MTOM;
end

EWF = 1.0;                 % "empty weight fraction" style accumulator (really mass fraction remaining)
fs  = zeros(1,4);
ts  = zeros(1,4);

%% ------------------- CRUISE (fixed altitude) -------------------
alt = ADP.TLAR.Alt_cruise;
[rho,a,~,~] = BoxWing.cast.atmos(alt);
M_cruise = ADP.TLAR.M_c;

% Lift coefficient and L/D at cruise
CL_c = (EWF*M_TO*9.81) / (0.5*rho*(a*M_cruise)^2 * ADP.WingArea);
CD_c = ADP.AeroPolar.CD(CL_c);
LD_c = CL_c / CD_c;


%fprintf('DEBUG MA: WingArea=%.1f  Span=%.1f  CD0=%.4f  Beta=%.4f\n', ...
%        ADP.WingArea, ADP.Span, ADP.AeroPolar.CD0, ADP.AeroPolar.Beta);
%fprintf('DEBUG MA: CL=%.4f  CD=%.4f  LD=%.4f\n', CL_c, CD_c, LD_c);
% fprintf("CRUISE: S=%.1f  b=%.1f  AR=%.2f  CL=%.3f  CD=%.4f  LD=%.2f  TSFC=%.3e\n", ...
%     ADP.WingArea, ADP.Span, AR, CL_c, CD_c, LD_c, TSFC_c);  %remove

% Basic sanity (prevents nonsense)
if ~isfinite(LD_c) || LD_c <= 1
    error("MissionAnalysis: nonphysical L/D at cruise (LD=%.3g). Check AeroPolar/CD.", LD_c);
end

cruise_FL = round(alt*SI.ft/1e2,0);
TSFC_c = ADP.Engine.TSFC(M_cruise, alt);
V      = M_cruise*a;

AR = ADP.Span^2 / ADP.WingArea;

% Breguet (jet): exp(-R * g * TSFC / (V * L/D))
%TSFC_c = ADP.Engine.TSFC(M_cruise, alt);    % MUST be in [1/s] for this formula as written
%V      = M_cruise*a;

if ~isfinite(TSFC_c) || TSFC_c <= 0
    error("MissionAnalysis: nonphysical TSFC (%.3g). Check engine TSFC units.", TSFC_c);
end

fs(1) = exp(-(tripRange*9.81*TSFC_c)/(V*LD_c));
ts(1) = tripRange / V;
EWF   = EWF * fs(1);

%% ------------------- ALTERNATE CRUISE -------------------
%altA = ADP.TLAR.Alt_alternate;
%[rhoA,aA,~,~] = BoxWing.cast.atmos(altA);

%CL_a = (EWF*M_TO*9.81) / (0.5*rhoA*(aA*M_cruise)^2 * ADP.WingArea);
%CD_a = ADP.AeroPolar.CD(CL_a);
%LD_a = CL_a / CD_a;



%TSFC_a = ADP.Engine.TSFC(M_cruise, altA);
%VA     = M_cruise*aA;

%fs(2) = exp(-(ADP.TLAR.Range_alternate*9.81*TSFC_a)/(VA*LD_a));
%ts(2) = ADP.TLAR.Range_alternate / VA;
%EWF   = EWF * fs(2);


altA = ADP.TLAR.Alt_alternate;          % 1500 ft
[rhoA, aA, ~, ~] = BoxWing.cast.atmos(altA);

M_alt = 0.4;    % low-speed alternate, NOT cruise Mach
VA    = M_alt * aA;

CL_a = (EWF*M_TO*9.81) / (0.5*rhoA*VA^2 * ADP.WingArea);
CD_a = ADP.AeroPolar.CD(CL_a);
LD_a = CL_a / CD_a;

if ~isfinite(LD_a) || LD_a <= 1
    error("MissionAnalysis: nonphysical L/D on alternate (LD=%.3g).", LD_a);
end

TSFC_a = ADP.Engine.TSFC(M_alt, altA);
VA     = M_cruise*aA;
fs(2) = exp(-(ADP.TLAR.Range_alternate*9.81*TSFC_a)/(VA*LD_a));
ts(2) = ADP.TLAR.Range_alternate / VA;
EWF   = EWF * fs(2);

%% ------------------- LOITER -------------------
[rho0,a0,~,~] = BoxWing.cast.atmos(0);
V_loit = 150;                 % [m/s] placeholder
Mach   = V_loit/a0;

CL_l = (EWF*M_TO*9.81) / (0.5*rho0*V_loit^2 * ADP.WingArea);
CD_l = ADP.AeroPolar.CD(CL_l);
LD_l = CL_l / CD_l;

TSFC_l = ADP.Engine.TSFC(Mach, 0);

fs(3) = exp(-(ADP.TLAR.Loiter*9.81*TSFC_l)/LD_l);
ts(3) = ADP.TLAR.Loiter;
EWF   = EWF * fs(3);

%% ------------------- CONTINGENCY -------------------
df    = (1-EWF)*0.03;
fs(4) = 1 - df/EWF;
ts(4) = 5*60;
EWF   = EWF * fs(4);

%% ------------------- OUTPUTS -------------------
BlockFuel   = (1-EWF) * M_TO;
TripFuel    = (1-fs(1)) * M_TO;
W_after_cruise = fs(1) * M_TO;
ResFuel = (1 - prod(fs(2:end))) * W_after_cruise;

% Until you explicitly model climb, don't let TOC fraction be "1".
% Use a stable placeholder (typical 0.97–0.99). This is mainly used by your wing mass model.
Mf_TOC      = 0.98;

MissionTime = ts(1);
end
