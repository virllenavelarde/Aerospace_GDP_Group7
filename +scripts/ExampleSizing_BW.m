%% size an BoxWing at a Mach number of 0.85
clear; clc;
% Instantiate an instance of the BoxWing class add define some initial
% parameters
ADP = B777.ADP_BW();
ADP.TLAR = cast.TLAR.TubeWing(); % sets top level aircraft requirements
ADP.TLAR.M_c = 0.85;       % set cruise Mach number (override default in TLAR if needed)
% --------------------- set TubeWing specific parameters ---------------------
ADP.KinkPos = 10;       % spanwise position of TE kink in wing planform

% NOTE: These are already defaults in ADP_BW, only override if you want a different fuselage
%ADP.CabinRadius = 2.8;
%ADP.CabinLength = 70.8 - 7.3 - 2.8*2*1.48;

ADP.WingPos = 0.43*70.8;    % normalised wing position (% of fuselage length)

% NOTE: V_HT and V_VT already set in ADP_BW defaults; only override if you want a different tail sizing
%ADP.V_HT = 0.55;    % horizontal tail volume coefficent
%ADP.V_VT = 0.05;    % vertical tail volume coefficent

ADP.HtpPos = 0.88*70.8;% normalised HTP position (% of fuselage length)
ADP.VtpPos = 0.82*70.8;% normalised VTP position (% of fuselage length)

% ------------------------- set Hyper-parameters -------------------------
ADP.Span = 64.8;

% ------------------------- span-cap + AR guardrails -------------------------
% NOTE: already defined in ADP_BW defaults; only override here if you want to run a different cap/AR range
%ADP.Span_max  = 65;        % [m] hard cap for ICAO gate / your requirement
%ADP.AR_target = 10;        % target AR used by sizing when span is capped
%ADP.WS_min    = 4.0e3;     % [N/m^2] sanity lower bound
%ADP.WS_max    = 1.30e4;    % [N/m^2] sanity upper bound

% ADP.Fleetsize = 6;

% -------------------------- class-I estimates ---------------------------
% initial mission analysis to estimate MTOM
ADP.MTOM = 3.3*ADP.TLAR.Payload; % VERY basic guess of MTOM from payload (need further adjusments)

% initial estimate of fuel mass ( % of MTOM)
ADP.Mf_Fuel = 0.19; % maximum fuel mass
ADP.Mf_res = 0.03;  % reserve fuel mass

% initial estimate of mass fractions at important flight phases
ADP.Mf_Ldg = 0.68;  % maximum landing mass
ADP.Mf_TOC = 0.97;  % mass at teh Top of Climb (TOC)

% -------------------------------- Sizing --------------------------------
% Note - see the "size" function at the bottum of this script
ADP = B777.size(ADP);                     % Regular size still works


% ------------------------ DEBUG / UNIT CHECK (BW) ------------------------
fprintf("\n--- UNIT CHECK (BW) ---\n");
fprintf("MTOM (kg)          = %.6e\n", ADP.MTOM);
fprintf("Weight W (N)       = %.6e\n", ADP.MTOM*9.81);

fprintf("WingLoading stored = %.6e\n", ADP.WingLoading);
fprintf("WingLoading [lb/ft^2] = %.3f\n", ADP.WingLoading*SI.lbft);

fprintf("WingArea stored (m^2) = %.6e\n", ADP.WingArea);
fprintf("Computed S=W/WS (m^2) = %.6e\n", (ADP.MTOM*9.81)/ADP.WingLoading);

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
if isprop(ADP,'Cl_max') && ~isempty(ADP.Cl_max) && isfinite(ADP.Cl_max)
    ADP.CL_max = 0.90 * ADP.Cl_max; %in case it escapes the loop or the value needs rewritten
end

% --- Report outputs ---
fprintf("=== BoxWing polard ===\n");
fprintf("MTOM: %.0f t\n", ADP.MTOM/1e3);
fprintf("WingLoading: %.2f lb/ft^2\n", ADP.WingLoading * SI.lbft);
fprintf("WingArea: %.1f m^2\n", ADP.WingArea);
fprintf("Span: %.1f m\n", ADP.Span);
fprintf("T/W: %.3f\n", ADP.ThrustToWeightRatio);

% AeroPolar may exist only if UpdateAero builds it
if ~isempty(ADP.AeroPolar)
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

%graph aero polarar CD vs CL : Drag polarar plots
if ~isempty(ADP.AeroPolar)
    polar = ADP.AeroPolar;

    CL = linspace(0, 1.2, 200);
    CD = polar.CD(CL);
    LD = CL ./ CD;

    % cruise point
    CLc = ADP.CL_cruise;
    CDc = polar.CD(CLc);
    LDc = CLc / CDc;

    % max L/D (within plotted range)
    [LDmax, iMax] = max(LD);
    CL_LDmax = CL(iMax);
    CD_LDmax = CD(iMax);

    figure(201); clf; grid on; hold on;
    plot(CL, CD, 'LineWidth', 2);
    plot(CLc, CDc, 'ko', 'MarkerFaceColor','k');
    plot(CL_LDmax, CD_LDmax, 'ks', 'MarkerFaceColor','k');
    xlabel('C_L'); ylabel('C_D');
    title('BW Drag Polar: C_D vs C_L');
    legend('Polar', sprintf('Cruise (CL=%.2f, CD=%.3f)', CLc, CDc), ...
           sprintf('Max L/D (CL=%.2f)', CL_LDmax), 'Location','best');

    figure(202); clf; grid on; hold on;
    plot(CL, LD, 'LineWidth', 2);
    plot(CLc, LDc, 'ko', 'MarkerFaceColor','k');
    plot(CL_LDmax, LDmax, 'ks', 'MarkerFaceColor','k');
    xlabel('C_L'); ylabel('L/D');
    title('BW Efficiency: L/D vs C_L');
    legend('L/D', sprintf('Cruise (L/D=%.1f)', LDc), ...
           sprintf('Max L/D=%.1f', LDmax), 'Location','best');

    fprintf("\n--- POLAR SUMMARY (BW) ---\n");
    fprintf("Cruise: CL=%.3f CD=%.4f L/D=%.2f\n", CLc, CDc, LDc);
    fprintf("Max L/D (in plot range): CL=%.3f CD=%.4f L/D=%.2f\n", CL_LDmax, CD_LDmax, LDmax);
end


%% build the "sized" geometry and plot it
[B7Geom,B7Mass] = B777.BuildGeometry_BW(ADP); % get list of components geometries and masses

% plot the geometry (ontop of an image of a B777F for reference)
f = figure(1);
clf;
img = imread('B777F_planform.png');
imshow(img, 'XData', [0 63.7], 'YData', [-64.8 64.8]/2);

cast.draw(B7Geom,B7Mass)
ax = gca;
ax.XAxis.Visible = "on";
ax.YAxis.Visible = "on";
axis equal
ylim([-0.5 0.5]*ADP.Span)


% print some key data points
names  = string({B7Mass.Name});
masses = double([B7Mass.m]);
wingMask = contains(names,"Wing","IgnoreCase",true) | contains(names,"Join","IgnoreCase",true);
mWingTot = sum(masses(wingMask));

fprintf('MTOM: %0.0f t, Fuel Mass: %0.0f t, Wing(+Join) Mass %0.0f t\n', ...
    ADP.MTOM/1e3, ADP.Mf_Fuel*ADP.MTOM/1e3, mWingTot/1e3);

if ~isempty(ADP.AeroPolar)
    fprintf('CD0: %0.3f, CD (CL): %0.3f \n',ADP.AeroPolar.CD(0),ADP.AeroPolar.CD(0.5));
end

%% Example call to mission analysis discipline
[BlockFuel,TripFuel,ResFuel,Mf_TOC,MissionTime] = B777.MissionAnalysis(ADP,ADP.TLAR.Range, ADP.MTOM);

%% Example Trade study, comparing MTOM and Block Fuel as a function of wing span
% predefine spans to test
Spans = 50:5:100;

% per-allocate arrays for results
mtoms = Spans*0;
fuels = mtoms;

% loop over spans and size aircraft for each span
ADP0 = ADP; % store initial ADP to reset after each iteration (avoid baseline corruption)

for i = 1:length(Spans)
    ADPi = ADP0; %make copy
    ADPi.Span = Spans(i);

    ADPi = B777.size(ADPi);

    mtoms(i) = ADPi.MTOM;
    fuels(i) = ADPi.Mf_Fuel*ADPi.MTOM;
end

f = figure(2);
clf;
tt = tiledlayout(2,1);
nexttile(1);
plot(Spans,mtoms/1e3,'-s')
xlabel('Span [m]')
ylabel('MTOM [t]')

nexttile(2);
plot(Spans,fuels/1e3,'-o')
xlabel('Span [m]')
ylabel('Block Fuel [t]')

LogBW = scripts.logPolarToStruct(ADP, "BoxWing");
save("AeroLog_BoxWing.mat","LogBW");

%% Sizing Function
