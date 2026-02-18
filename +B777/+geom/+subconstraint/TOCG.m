%input = obj, ws 
%output = TW required
%take off climb gradient (OEI)

function [TW_TOCG] = TOCG(obj,WS)   %take off climb gradient
    %requirement
    % NOTE: 0.024 is NOT the usual "OEI second segment" value for twins
    G_min = obj.TLAR.TOCG_AEO_gearUp;  % or OEI requirement depending on segment

    %conditions
    alt_tocg = 0; %airport alt  
    [rho,~] = cast.atmos(alt_tocg,0);


    CLmax_TO = obj.CL_max + obj.Delta_Cl_to;   % use your own takeoff CLmax
    Vs_TO = sqrt( 2*WS ./ (rho * CLmax_TO) );
    V = 1.25 * Vs_TO;    % V2
    q = 0.5 * rho .* (V.^2);
    
    %model
    if isprop(obj,'AeroPolar') && ~isempty(obj.AeroPolar)
        CL = WS ./ q;
        CD = obj.AeroPolar.CD(CL);
        DoverW = CD ./ CL;
    else
        CD0 = obj.CD_TO;   % use takeoff config drag
        e   = obj.e;
        AR = obj.AR();
        if isempty(AR) || ~isfinite(AR) || AR <= 0
            AR = obj.AR_target;
        end
        DoverW = q .* CD0 ./ WS + WS ./ (q*pi*AR*e);
    end

    %OEI factor (Twin-engine)
    nEng = 2;
    OEI_factor = (nEng-1)/nEng; %simple assumption, need to confirm with actual engine out performance requirements

    TW_TOCG = (DoverW + G_min) ./OEI_factor;