%input as adp object (based from ADP.m --> can further change)
%output is T/W = f(W/S) for TOL constraint
%to be plotted in constraint analysis
% refer to cork 54/406 for constraint analysis and equations    
% Full Corke takeoff correlation (includes linear term) solved implicitly.
% Uses cubic in x = sqrt(T/W).
% Units: Corke constants assume sTO in ft and W/S in lb/ft^2.

function [TW_TO] = TOL(adp,WS_TO) 

    %required field length in imperial
    sTO_req_m = adp.TLAR.GroundRun; %m
    sTO_req_ft = sTO_req_m * SI.ft; %ft

    % airport atmos (assume SL, ISA+15C)
    hAirport = 0;     % m
    delta_T = 15;     %temp offset from ISA in K or C
    [~,~,~,~,~,~,sigma] = cast.atmos(hAirport, delta_T);    %want density ratio from height and isa offset, [rho,a,T,P,nu,z,sigma] = atmos(h,tOffset)

    %get CL_max_TO from max lift clean + high lift TO
    CL_max_TO = adp.CL_max + adp.Delta_Cl_to;               %may need to check the CL vs Cl + other lift coefficients parameters
    
    %since corke is used for eq, and its in imperial
    WS_lbft2 = WS_TO * SI.lbft; 

    % helper func for take off para
    A = WS_lbft2 ./ (sigma .* CL_max_TO);

    %initialize nan grid for implicit solve
    TW_TO = NaN(size(WS_TO));

    for i = 1:numel(WS_TO)  %loop through all WS elements
        Ai = A(i);          %initial helper func, aka topstar
        if ~(isfinite(Ai) && Ai > 0)    % skip non-physical case
            continue
        end

        % 87*sqrt(A)*x^3 - sTO*x^2 + 0*x + 20.9*A = 0, cubic form of take off correlation
        coeffs = [87*sqrt(Ai), -sTO_req_ft, 0, 20.9*Ai];
        r = roots(coeffs);

        % keep positive real roots only
        r = r(imag(r)==0 & real(r)>0);
        if isempty(r)
            continue
        end

        x = min(real(r));      % choose smallest positive root (physical)
        TW_TO(i) = x^2;        % T/W
    end
end