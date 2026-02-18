classdef ADP < handle
    %ADP Aircraft Design Parameters for a B777F


    % Top level Design Parameters

    % Masses
    properties
        TLAR
        Engine
        AeroPolar
    end

    properties
        MTOM    % Maximum take-off mass
        OEM     % Operational Empty Mass
        Mf_Ldg  % maximum landing mass fraction (e.g. MLDG = MTOM*Mf_Ldg)
        Mf_Fuel % fuel mass fraction 
        Mf_TOC  % "top of climb" mass fraction
        Mf_res  % "Resevre Fuel" mass fraction
    end
    % constraint Paramters
    properties
        ThrustToWeightRatio  % 
        WingLoading          % 
    end
    % --------------------- Aerodynamic ----------------------
    properties
        % --- Airfoil definition ---
        AirfoilName = "NASA SC(2)-0714";
        tc_ref = 0.14;                 % thickness ratio (midspan reference)

        % --- Section lift characteristics (interpolated from XFOIL @ Re = 1e6, SC(2)-0714) ---
        Re_section_ref = 1e6;
        Cl_alpha_perdeg = 0.1233;      % lift-curve slope [1/deg]
        Cl_alpha = 7.06;               % lift-curve slope [1/rad]
        alphaL0_deg = -4.69;           % zero-lift angle [deg]
        Cl_max = 1.77;                 % 2D clean section Clmax (from XFOIL)

        % --- Wing-level lift assumptions (conceptual placeholders) ---
        CL_max = 1.59                  %0.90*Cl_max;    % uses ADP.Cl_max=1.77  % max CL clean*** (no high-lift devices)
        Delta_Cl_ld = 1.0;             % extra CL during landing        --> ****REFINEMENT (2)
        Delta_Cl_to = 0.8;             % extra CL at take-off           --> ****REFINEMENT (3)

        % --- Ground run assumptions ---
        CD_TO = 0.05;            %--> ****REFINEMENT (4)
        CL_TO = 0.8;             %--> ****REFINEMENT (5)
        CD_LDG = 0.08;           %--> ****REFINEMENT (6)
        CL_LDG = 0.5;            %--> ****REFINEMENT (7)

        % --- Cruise condition ---
        CL_cruise  %= NaN;  %to be calculated in sizing, estimated from section Clmax + 3D             % wing CL during cruise, typical widebody-level assumptions ---> *****REFINEMENT (8)

        % --- Aircraft drag polar parameters (cruise) ---
        CD0 = 0.021;                   % zero-lift drag coefficient (widebody baseline) --> %--> ****REFINEMENT (9) --> Need to do plate analysis on Wednesday
        e = 0.85;                      % Oswald efficiency factor (range usually around 0.80-0.90)
        CDwave = 0.001;                % wave drag increment at M ~ 0.85    %--> ****REFINEMENT (10)

        V_HT = 0.9;
        V_VT = 0.07;

        CL_ceiling = 1.0;   % hyperparameter for ceiling sizing
    end

    %loop limit
    properties
        %loop lmit
        AR_target = 10;                %AR target (match tube wing) (8-12)
        Span_max = 65; %m
        WS_min = 4.0e3;
        WS_max = 1.30e4;
    end

    % Sizing Flags (whether to Adjust certain values during sizing process)
    properties
        isSizeEng = true; % whether to change engine maximum Thrust Value
        isSizeWing = true; % whether to size the wing
    end

    % Concrete properties
    properties
        Thrust; %--> may need to impose bypass ratio + Installed thrust/engine N fuselage outer

        % planfrom specific
        Span;
        WingArea;
        KinkPos;    % y position of wing kink 
        WingPos;    % Wing position along fuselage
        HtpPos;     % HTP pos along fuselage
        VtpPos;     % VTP pos along fuselage

        Mstar = 0.935; % wing technology factor

        % Empenage Specific
        HtpArea;
        VtpArea
    end

    % useful properties
    properties
        c_ac % mean geometric chord of main wing
        x_ac % x location of mean geometeric chord
        c_ach % mean geometric chord of HTP
        c_acv % mean geometric chord of VTP
    end

    % fuselage properties
    properties
        CockpitLength = 7.3;
        CabinRadius = 2.8;
        CabinLength = 70.8 - 7.3 - 2.8*2*1.48;  % cabin length= Lf_A350- CockpitLength-(1.4*2*CabinRadius)
    end

    % Box wing properties
    properties
        etaLift = 0.5; 
        alphaArea = 0.5;
        kJoin = 0.1;
    end

    
    methods
        function out = AR(obj)
            out = obj.Span.^2./obj.WingArea;
        end
    end
end
