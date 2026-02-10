%input = obj, ws 
%output = TW required
%take off climb gradient (OEI)

function [TW_TOCG] = TOCG(obj,WS)   %take off climb gradient
    %requirement
    % NOTE: 0.024 is NOT the usual "OEI second segment" value for twins
    G_min = 0.024; %FAR, 3% at V_CL, but we need to calculate the actual value based on the TOCG conditions (gear up/down, V2/VTO, etc)

    %conditions
    alt_tocg = 0; %airport alt
    rho = cast.atmos(alt_tocg);

    CLmax_TO = 2.2;   % placeholder, assume single-slotted flap equivalent
    Vs_TO = sqrt( 2*WS ./ (rho * CLmax_TO) );
    V = 1.25 * Vs_TO;    % V2
    q = 0.5 * rho .* (V.^2);
    
    %model
    if isprop(obj,'AeroPolar') && ~isempty(obj.AeroPolar)
        CL = WS ./ q;
        CD = obj.AeroPolar.CD(CL);
        DoverW = CD ./ CL;
    else
        CD0 = 0.03;      % higher than cruise due to high-lift / gear (placeholder)
        AR  = 10;
        e   = 0.80;
        DoverW = q .* CD0 ./ WS + WS ./ (q*pi*AR*e);
    end

    %OEI factor (Twin-engine)
    nEng = 2;
    OEI_factor = (nEng-1)/nEng; %simple assumption, need to confirm with actual engine out performance requirements

    TW_TOCG = (DoverW + G_min) ./OEI_factor;