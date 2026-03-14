%use appraoch constraint for VSL, then VSL for Sfl

function [WS_Max_LFL] = LFL(obj)
    %requirements
    sL_m = obj.TLAR.GroundRunLanding; %m
    sL_ft = sL_m * SI.ft; %m -> ft

    %assumptions
    CL_max_clean = obj.CL_max; %adp val
    CL_max_landing = CL_max_clean + obj.Delta_Cl_ld; %adp val

    %airport atmos (assume SL, ISA)
    hAirport = 0;     % m       %maximum allowable limits for airports*
    [~,~,~,~,~,~,sigma] = cast.atmos(hAirport);    %want density ratio from height and isa offset, [rho,a,T,P,nu,z,sigma] = atmos(h,tOffset)

    %model
    LP = (sL_ft - 400) ./ 118; %landing parameter from corke, ft
    WS_Max_LFL = (sigma .* CL_max_landing) .* (LP); %lb/ft^2
end