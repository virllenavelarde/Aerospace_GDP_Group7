%based on corke ch3
%input --> OBJ + WS grid
%output --> T/W req for ROC

function [TW_ROC] = ROC(obj,WS)    %rate of climb --> subsonic climb --> source of drag = CD0 + lift induced (no wave drag)
    WS = WS(:).';   %force row vector for consistency
    %assumptions
    ROC_req_ftmin = obj.TLAR.ROC_min_at_cruise;      % [ft/min] requirement
    ROC_req = (ROC_req_ftmin / SI.ft) / 60;          % [m/s]
    alt_climb = obj.TLAR.Alt_cruise;  %sea level climb

    %atmos
    [rho,a,~,~,~,~,~] = cast.atmos(alt_climb);
    V = obj.TLAR.M_c*a;   % CAS ≈ TAS for class-I
    q = 0.5*rho.*(V.^2); %dynamic

    %model: (3.13): D/W = q*CD0/WS + W/S * 1(q*pi*AR*e) : e = oswald efficiency factor, AR = aspect ratio
    %no CD0/e/AR defined clear, need place holders
    if isprop(obj,'AeroPolar') && ~isempty(obj.AeroPolar)
        CL = WS./q;
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