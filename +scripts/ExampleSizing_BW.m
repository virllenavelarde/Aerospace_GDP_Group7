%% Size an BoxWing at a Mach number of 0.84

% Instantiate an instance of the BoxWing class add define some initial
% parameters
ADP = B777.ADP_BW();
ADP.TLAR = cast.TLAR.B777F(); % sets top level aircraft requirements
ADP.TLAR.M_c = 0.82;    % set cruise Mach number to 0.82 from Tlars (fixed 9/2/2026)

% --------------------- set B777 specific parameters ---------------------
ADP.KinkPos = 10;       % spanwise position of TE kink in wing planform
ADP.CabinRadius = 2.8;
ADP.CabinLength = 70.8 - 7.3 - 2.8*2*1.48;
ADP.WingPos = 0.43*70.8;    % normalised wing position (% of fuselage length)
ADP.V_HT = 0.55;    % horizontal tail volume coefficent
ADP.V_VT = 0.05;    % vertical tail volume coefficent
ADP.HtpPos = 0.88*70.8;% normalised HTP position (% of fuselage length)
ADP.VtpPos = 0.82*70.8;% normalised VTP position (% of fuselage length)

% ------------------------- set Hyper-parameters -------------------------
ADP.Span = 64.8;
% ADP.FleetSize = 6;

% -------------------------- class-I estimates ---------------------------
% initial mission analysis to estimate MTOM
ADP.MTOM = 3.35*ADP.TLAR.Payload; % VERY basic guess of MTOM from payload (need further adjusments)

% initial estimate of fuel mass ( % of MTOM)
ADP.Mf_Fuel = 0.19; % maximum fuel mass
ADP.Mf_res = 0.03;  % reserve fuel mass

% initial estimate of mass fractions at important flight phases
ADP.Mf_Ldg = 0.68;  % maximum landing mass
ADP.Mf_TOC = 0.97;  % mass at teh Top of Climb (TOC)

% -------------------------------- Sizing --------------------------------
% Note - see the "size" function at the bottum of this script
ADP = B777.Size(ADP);                     % Regular Size still works

%% build the "Sized" geometry and plot it
[B7Geom,B7Mass] = B777.BuildGeometry(ADP); % get list of components geometries and masses

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
d = B7Mass.GetData;
fprintf('MTOM: %0.0f t, Fuel Mass: %0.0f t, Wing Mass %0.0f t\n',ADP.MTOM/1e3,ADP.Mf_Fuel*ADP.MTOM/1e3,double(d(strcmp(d(:,1),"Wing"),2)));
fprintf('CD0: %0.3f, CD (CL=0.5): %0.3f \n',ADP.AeroPolar.CD(0),ADP.AeroPolar.CD(0.5));

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

    ADPi = B777.Size(ADPi);
    
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



%% Sizing Function
