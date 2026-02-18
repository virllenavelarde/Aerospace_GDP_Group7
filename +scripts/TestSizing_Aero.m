% scripts/TestSizing_Aero.m  (SCRIPT)

clear; clc;

ADP = B777.ADP();   %calling class ADP
ADP.TLAR = cast.TLAR.TubeWing();    %change here bc obj. is defined in TLAR (cast)

% --- Seed mass fractions so geometry/mass models don't crash on iter 1 ---
ADP.Mf_TOC  = 0.97;
ADP.Mf_Fuel = 0.20;
ADP.Mf_res  = 0.03;
ADP.Mf_Ldg  = 0.70;

% --- Hyperparameter seed ---
ADP.KinkPos = 10;                       % keep for now (B777 wing builder needs it)
Lf = ADP.CockpitLength + ADP.CabinLength + 1.48*2*ADP.CabinRadius;
ADP.WingPos = 0.44*Lf;
ADP.HtpPos  = 0.85*Lf;
ADP.VtpPos  = 0.82*Lf;


% --- Initial MTOM seed for the iteration ---
ADP.MTOM = 3.3 * ADP.TLAR.Payload;      % kg (seed)



% --- Run iterative sizing (this finds MTOM) ---
ADP = B777.size(ADP);

%debug sesh
fprintf("\n--- UNIT CHECK ---\n");
fprintf("MTOM (kg)          = %.6e\n", ADP.MTOM);
fprintf("Weight W (N)       = %.6e\n", ADP.MTOM*9.81);

fprintf("WingLoading stored = %.6e\n", ADP.WingLoading);
fprintf("WingLoading as lb/ft^2 (if SI) = %.3f\n", ADP.WingLoading*SI.lbft);

fprintf("WingArea stored (m^2) = %.6e\n", ADP.WingArea);
fprintf("Computed S = W/WS (m^2) = %.6e\n", (ADP.MTOM*9.81)/ADP.WingLoading);
fprintf("AR from stored = %.6f\n", ADP.Span^2/ADP.WingArea);
fprintf("AR from W/WS S = %.6f\n", ADP.Span^2/((ADP.MTOM*9.81)/ADP.WingLoading));
fprintf("\n")

%impose cruise CL
[rho,a] = cast.atmos(ADP.TLAR.Alt_cruise);
V = ADP.TLAR.M_c * a;
q = 0.5*rho*V^2;

W = ADP.MTOM * 9.81 * ADP.Mf_TOC;   % TOC weight proxy
ADP.CL_cruise = W/(q*ADP.WingArea);

%impose CLmaxclean = nu3D*Clmax (nu3d = 3d conversion factor, depends on sweep, taper, tip, but ~.85-.95)
ADP.CL_max = 0.90 * ADP.Cl_max; %in case it escapes the loop or the value needs rewritten

% --- Report outputs ---
fprintf("=== TubeWing Sized ===\n");
fprintf("MTOM: %.0f t\n", ADP.MTOM/1e3);
fprintf("WingLoading (raw): %.2f\n", ADP.WingLoading);
fprintf("WingLoading: %.2f lb/ft^2\n", ADP.WingLoading * SI.lbft);
fprintf("WingArea: %.1f m^2\n", ADP.WingArea);
fprintf("Span: %.1f m\n", ADP.Span);

% AeroPolar may exist only if UpdateAero builds it
if ~isempty(ADP.AeroPolar)
    % Use computed cruise CL (fallback to 0.5 if not available)
    if isprop(ADP,'CL_cruise') && ~isempty(ADP.CL_cruise) && isfinite(ADP.CL_cruise)
        CL_use = ADP.CL_cruise;
        tag = "cruise";
    else
        CL_use = 0.5;
        tag = "default";
    end
    CD_use = ADP.AeroPolar.CD(CL_use);
    fprintf("CD(CL_%s=%.3f): %.4f\n", tag, CL_use, CD_use);
    fprintf("L/D(CL_%s=%.3f): %.1f\n", tag, CL_use, CL_use/CD_use);
else
    fprintf("AeroPolar not built yet (check B777.UpdateAero).\n");
end