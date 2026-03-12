function [BlockFuel,TripFuel,ResFuel,Mf_TOC,MissionTime,cruise_FL] = ...
         MissionAnalysis(obj, tripRange, M_TO)
%MISSIONANALYSIS  Fuel burn for the boxwing freighter mission.

arguments
    obj
    tripRange
    M_TO = obj.MTOM;
end

EWF = 1;
fs  = double.empty;
ts  = double.empty;

%% Cruise – pick best altitude
alts = linspace(15e3/SI.ft, 44e3/SI.ft, 61);
[rho,a,~,~] = cast.atmos(alts);
M_c = obj.TLAR.M_c;

CL_c = EWF*M_TO*9.81 ./ (0.5*rho.*(a*M_c).^2 .* obj.WingArea);
CD_c = obj.AeroPolar.CD(CL_c);
LD_c = CL_c ./ CD_c;
[~,idx] = max(LD_c);

alt   = alts(idx);
[~,a_cr,~,~] = cast.atmos(alt);
cruise_FL = round(alt*SI.ft/100, 0);

fs(1) = exp(-tripRange*9.81*obj.Engine.TSFC(M_c,alt) / (M_c*a_cr*LD_c(idx)));
ts(1) = tripRange / (M_c * a_cr);
EWF   = EWF * fs(1);

%% Alternate
[rho,a,~,~] = cast.atmos(obj.TLAR.Alt_alternate);
altRange = obj.TLAR.Range_alternate;
CL_a = EWF*M_TO*9.81 / (0.5*rho*(a*M_c)^2*obj.WingArea);
LD_a = CL_a / obj.AeroPolar.CD(CL_a);

fs(2) = exp(-altRange*9.81*obj.Engine.TSFC(M_c,altRange) / (M_c*a*LD_a));
ts(2) = altRange / (M_c * a);
EWF   = EWF * fs(2);

%% Loiter
[rho,a,~,~] = cast.atmos(0);
Mach = 150/a;
CL_l = EWF*M_TO*9.81 / (0.5*rho*(a*Mach)^2*obj.WingArea);
LD_l = CL_l / obj.AeroPolar.CD(CL_l);

fs(3) = exp(-obj.TLAR.Loiter*9.81*obj.Engine.TSFC(Mach,0)/LD_l);
ts(3) = obj.TLAR.Loiter;
EWF   = EWF * fs(3);

%% Contingency 3%
df    = (1-EWF)*0.03;
fs(4) = 1 - df/EWF;
ts(4) = 5*60;
EWF   = EWF * fs(4);

%% Outputs
BlockFuel   = (1 - EWF) * M_TO;
TripFuel    = (1 - fs(1)) * M_TO;
ResFuel     = (1 - prod(fs(2:end))) * M_TO;
Mf_TOC      = 1;
MissionTime = ts(1);
end
