%based on corke ch3
%input --> OBJ + WS grid
%output --> T/W req for ROC

function [TW_ROC] = ROC(obj,WS)    %rate of climb --> subsonic climb --> source of drag = CD0 + lift induced (no wave drag)
    %assumptions
    ROC_req = 1500/60 * SI.ft; 
    alt_climb = 0;  %sea level climb

    %atmos
    rho = cast.atmos(alt_climb);
    V = obj.TLAR.V_climb;   % CAS ≈ TAS for class-I
    q = 0.5*rho.*(V.^2); %dynamic

    %model: (3.13): D/W = q*CD0/WS + W/S * 1(q*pi*AR*e) : e = oswald efficiency factor, AR = aspect ratio
    %no CD0/e/AR defined clear, need place holders
    if isprop(obj,'AeroPolar') && ~isempty(obj.AeroPolar)
        CL = WS./q
        CD = obj.AeroPolar.CD(CL);
        DtoW = CD ./ CL;
    else
        CD0 = 0.02; %placeholder
        AR = 9;     %placeholder
        e = 0.8;    %placeholder
        DtoW = q.* CD0./WS + WS./(q*pi*AR*e);
    end

    TW_ROC = DtoW + ROC_req ./ V;      %3.11, G = climb gradient = (T-D)/W = sin(climb angle)
end