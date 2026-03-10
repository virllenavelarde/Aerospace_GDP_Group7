%Assumptions: 
%-box wing doesn't have kink position for front/rear wing, therefore, no
%kink
%-atm undefined fuselage blending geometry
%-unknown detailed chord distribution

%wing was assumed to be a trapezoid shape (to calculated Cr)


function [GeomObj,massObj,m_boxwing] = boxwingmass(obj)


    % ----- baseline planform parameters (same as wing.m) -----
    b = obj.Span;                                 % full span
    S = (obj.MTOM * 9.81) / obj.WingLoading;      % wing ref area

    % ----- box-wing hyperparameters (you will sweep these) -----
    eta    = obj.etaLift;     % lift split front wing (0.4-0.6 typical)
    alpha  = obj.alphaArea;   % area split front wing (often = eta initially)
    k_relief = obj.k_relief;       % relief factor 

    % ----- split areas (still using total S) -----
    Sf = alpha * S;  %area front         %area of front wing
    Sr = (1 - alpha) * S;  %area rear    %area of rear wing

    % For early Class I, assume both wings have same span as baseline constraint
    bf = b;                         % span of front wing [m]
    br = b;                         % span of rear wing [m]

    SweepQtrChord = real(acosd(0.75.*obj.Mstar./obj.TLAR.M_c));
    sweepHalf = SweepQtrChord;    

    b_f_ft  = bf * SI.ft;           % span of front wing[ft]
    b_r_ft  = br * SI.ft;           % span of rear wing[ft]

    S_f_ft  = Sf* (SI.ft)^2;        % area of front wing[ft^2]
    S_r_ft  = Sr* (SI.ft)^2;        % area of rear wing[ft^2]

    n_z    = 2.5 * 1.5;             % ultimate load factor

    % ----- effective design weights for Raymer calls -----
    % Used same "design gross weight" convention as in wing.m.
    % Example pattern (you'll match the exact variable names in your code):
    Wdg_total_lb = obj.MTOM * obj.Mf_TOC * SI.lb;   % <-- only if this is how wing.m defines it

    Wdg_f_lb = eta * Wdg_total_lb;        %atm eta=0.6, so front wing generates 60% of lift
    Wdg_r_lb = (1 - eta) * Wdg_total_lb;  %atm 1-eta = 0.4, so rear wing generates 40% of lift

    % ----- geometry assumptions needed by Raymer -----
    % Use the SAME sweep / tc  assumptions as wing.m for consistency
    cosLambda = cosd(sweepHalf);     % only if it exists; otherwise compute like wing.m does
    
    
    %trapezoid wing shape assumed:
    tr = 0.3; % 2 options: set it as a hyperparm 0.2-0.4 or check how wing.m calcs it

    c_rf = 2*Sf/(bf*(1+tr));     % Root chord for front wing[m]
    c_rr = 2*Sr/(br*(1+tr));     % Root chord for rear wing[m]
    
    t_wf = 0.15*c_rf*SI.ft;      % Thickness of root (front wing), with 15% of root chord [ft] 
    t_wr = 0.15*c_rr*SI.ft;      % [ft]

    %% calculate geometry  - follows the same process as Fintan's code for wing.m file
    
    c_tf = tr*c_rf;              %Tip chord for front wing [m]
    c_tr = tr*c_rr;              %Tip chord for rear wing [m]

    ys_f = [-bf/2; 0; bf/2];     %Each front wing section: left tip,centroid, right tip i assign a ys position
    ys_r = [-br/2; 0; br/2];     %Each rear wing section: left tip,centroid, right tip i assign a ys position
    
    cs_f = [c_tf; c_rf; c_tf];   %this represents the chord distribution over the front wing so it goes from lefttip>rootchord>righttip
    cs_r = [c_tr; c_rr; c_tr ];   %this represents the chord distribution over the rear wing so it goes from lefttip>rootchord>righttip
    
    x_le_f = [tand(SweepQtrChord)*(bf/2); 0; tand(SweepQtrChord)*(bf/2)]; %front wing leading edge x locations
    x_le_r = [-tand(SweepQtrChord)*(br/2); 0; -tand(SweepQtrChord)*(br/2)]; %rear wing leading edge x locations

    x_le_f = x_le_f - 0.25*c_rf; %move the above x locations to quater chord
    x_le_r = x_le_r - 0.25*c_rr; %move the above x locations to quater chord


    x_qtr_f = x_le_f + 0.25*cs_f; %x position of the quater chord line for the front wing
    x_te_f  = x_le_f + cs_f;      %x position of the trailing edge for the front wing
    
    x_qtr_r = x_le_r + 0.25*cs_r; %x position of the quater chord line for the rear wing
    x_te_r  = x_le_r + cs_r;      %x position of the trailing edge for the rear wing
    

    %Combine x and y coordinates to create closed planform outlines for the front and rear wings
    Xs_f = [x_le_f, ys_f; flipud(x_te_f), flipud(ys_f)];
    Xs_r = [x_le_r, ys_r; flipud(x_te_r), flipud(ys_r)];

    %NEED TO CALCULATE AERODYNAMIC CHORD HERE 
    % taper ratios
    lambda_f = c_tf / c_rf;
    lambda_r = c_tr / c_rr;
    

    % mean aerodynamic chord lengths
    c_mac_f = (2/3) * c_rf * ((1 + lambda_f + lambda_f^2) / (1 + lambda_f));
    c_mac_r = (2/3) * c_rr * ((1 + lambda_r + lambda_r^2) / (1 + lambda_r));

    % spanwise MAC locations from aircraft centreline
    y_mac_f = (bf/6) * ((1 + 2*lambda_f) / (1 + lambda_f));
    y_mac_r = (br/6) * ((1 + 2*lambda_r) / (1 + lambda_r));

    % local aerodynamic-centre x-position before aircraft placement
    x_ac_f_local = interp1(ys_f(2:3), x_qtr_f(2:3), y_mac_f);
    x_ac_r_local = interp1(ys_r(2:3), x_qtr_r(2:3), y_mac_r);

    % place aerodynamic centre at desired aircraft x-position
    Xs_f(:,1) = Xs_f(:,1) + (obj.FrontWingPos - x_ac_f_local);
    Xs_r(:,1) = Xs_r(:,1) + (obj.RearWingPos  - x_ac_r_local);
    
    x_ac_f = obj.FrontWingPos;
    x_ac_r = obj.RearWingPos;


    % equivalent overall reference values (basically just an average wing positions for empenage_bw.m)
    obj.c_ac = alpha*c_mac_f + (1-alpha)*c_mac_r;
    obj.x_ac = alpha*x_ac_f + (1-alpha)*x_ac_r;
    obj.WingPos = obj.x_ac;
    obj.WingArea = Sf + Sr;

    GeomObj(1) = cast.GeomObj(Name="Front Wing", Xs=Xs_f);
    GeomObj(2) = cast.GeomObj(Name="Rear Wing",  Xs=Xs_r);

    
    %% calculate mass
    % ----- compute each wing panel mass using Raymer helper -----
    w_front_lb = 0.00125*Wdg_f_lb * (b_f_ft/cosLambda)^0.75*...
        (1 + sqrt(6.3*cosLambda/b_f_ft))*n_z^0.55*...
        (b_f_ft*S_f_ft/(t_wf*Wdg_f_lb*cosLambda))^0.3;

    w_rear_lb = 0.00125*Wdg_r_lb * (b_r_ft/cosLambda)^0.75*...
        (1 + sqrt(6.3*cosLambda/b_r_ft))*n_z^0.55*...
        (b_r_ft*S_r_ft/(t_wr*Wdg_r_lb*cosLambda))^0.3;
    

    m_wing_front = (w_front_lb/SI.lb);
    m_wing_rear =  (w_rear_lb/SI.lb);

    m_per_span_f = m_wing_front/bf;                 %mass per meter of span for front wing
    m_per_span_r = m_wing_rear/br;                  %mass per meter of span for rear wing   
    m_per_span_av = (m_per_span_f + m_per_span_r)/2; %average mass per meter of span

    %introduce joint mass:
    m_joint_height = obj.CabinRadius;
    m_joint_mass = m_joint_height * m_per_span_av;
    m_joint_mass_total = m_joint_mass *2;

    massObj(1) = cast.MassObj(Name="Front Wing", ...
    m=k_relief*m_wing_front, ...
    X=[x_ac_f; 0]);

    massObj(2) = cast.MassObj(Name="Rear Wing", ...
    m=k_relief*m_wing_rear, ...
    X=[obj.RearWingPos; 0]);

    massObj(3) = cast.MassObj(Name="Wing Joints", ...
    m=k_relief*m_joint_mass_total, ...
    X=[(obj.FrontWingPos + obj.RearWingPos)/2; 0]);
    
    % ----- add relief factor -----
    m_boxwing = k_relief*(m_wing_front + m_wing_rear+m_joint_mass_total) ;
    
    

    
end
    
% function [S,c_t,c_r,A1,A2,A3] = get_areas(c,L2,L3,R_f,tr,SweepQtrChord)
%     c_t = tr*c;
% 
%     sweepLE = atand((tand(SweepQtrChord)*L3+c/4-c_t/4)/L3);
%     c_r = c + tand(sweepLE)*L2;
%     % c_r = (c-c_t)/L3*L2+c;  % if you want no kink
% 
%     % calc area of each area
%     A1 = c_r*R_f;
%     A2 = (c_r+c)/2*L2;
%     A3 = (c+c_t)/2*L3;
%     %calc total area
%     S = 2*(A1+A2+A3);
% end

