%Assumptions: 
%-box wing doesn't have kink position for front/rear wing, therefore, no
%kink
%-atm undefined fuselage blending geometry
%-unknown detailed chord distribution

%wing was assumed to be a trapezoid shape (to calculated Cr)


function [m_boxwing] = raymerWingMass(obj)


    % ----- baseline planform parameters (same as wing.m) -----
    b = obj.Span;                                 % full span
    S = (obj.MTOM * 9.81) / obj.WingLoading;      % wing ref area

    % ----- box-wing hyperparameters (you will sweep these) -----
    eta    = obj.etaLift;     % lift split front wing (0.4-0.6 typical)
    alpha  = obj.alphaArea;   % area split front wing (often = eta initially)
    k_join = obj.kJoin;       % join penalty (e.g. 0.05-0.20)

    % ----- split areas (still using total S) -----
    Sf = alpha * S;  %area front
    Sr = (1 - alpha) * S;  %area rear

    % For early Class I, assume both wings have same span as baseline constraint
    bf = b;
    br = b;

    SweepQtrChord = real(acosd(0.75.*obj.Mstar./obj.TLAR.M_c));
    sweepHalf = SweepQtrChord;    

    b_f_ft  = bf * SI.ft;           % [ft]
    b_r_ft  = br * SI.ft;           % [ft]

    S_f_ft  = Sf* (SI.ft)^2;        % [ft^2]
    S_r_ft  = Sr* (SI.ft)^2;        % [ft^2]

    n_z    = 2.5 * 1.5;             % ultimate load factor

    % ----- effective design weights for Raymer calls -----
    % Used same "design gross weight" convention as in wing.m.
    % Example pattern (you'll match the exact variable names in your code):
    Wdg_total_lb = obj.MTOM * obj.Mf_TOC * SI.lb;   % <-- only if this is how wing.m defines it

    Wdg_f_lb = eta * Wdg_total_lb;
    Wdg_r_lb = (1 - eta) * Wdg_total_lb;

    % ----- geometry assumptions needed by Raymer -----
    % Use the SAME sweep / tc  assumptions as wing.m for consistency
    cosLambda = cosd(sweepHalf);     % only if it exists; otherwise compute like wing.m does
    
    
    %trapezoid wing shape assumed:
    tr = 0.3; % 2 options: set it as a hyperparm 0.2-0.4 or check how wing.m calcs it

    c_rf = 2*Sf/(bf*(1+tr));     % Root chord for front wing[m]
    c_rr = 2*Sr/(br*(1+tr));     % Root chord for rear wing[m]
    
    t_wf = 0.15*c_rf*SI.ft;      % Thickness of root (front wing), with 15% of root chord [ft] 
    t_wr = 0.15*c_rr*SI.ft;      % [ft]

    % ----- compute each wing panel mass using Raymer helper -----
    w_front_lb = 0.00125*Wdg_f_lb * (b_f_ft/cosLambda)^0.75*...
        (1 + sqrt(6.3*cosLambda/b_f_ft))*n_z^0.55*...
        (b_f_ft*S_f_ft/(t_wf*Wdg_f_lb*cosLambda))^0.3;

    w_rear_lb = 0.00125*Wdg_r_lb * (b_r_ft/cosLambda)^0.75*...
        (1 + sqrt(6.3*cosLambda/b_r_ft))*n_z^0.55*...
        (b_r_ft*S_r_ft/(t_wr*Wdg_r_lb*cosLambda))^0.3;
    

    m_wing_front = (w_front_lb/SI.lb);
    m_wing_rear =  (w_rear_lb/SI.lb);


    % ----- add join penalty -----
    m_boxwing = (m_wing_front + m_wing_rear) * (1 + obj.kJoin);

    
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
