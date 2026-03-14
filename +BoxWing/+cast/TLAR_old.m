classdef TLAR_old
    %TLAR Top-Level Aircraft (Design) Requirements
    
    %To be added more && fix accordingly to the excel sheet

    properties
        Crew
        Range       % Harmonic Range
        Payload     % Max. Payload
        V_ld        % Landing Speed
        V_app       % approach speed
        V_climb     % climb speed (CAS)
        GroundRun
        GroundRunLanding    %total ground length
        M_c         % cruise Mach number
        Alt_max     % max altitude in m
        Alt_cruise  % Cruise Altitude
        CrewMass    % Mass of the Crew
    end

    properties       %take off constraint properties
        H_to_screen
        TOCG_OEI_gearDown
        TOCG_AEO_gearUp
        TOCG_OEI_gearUp
        TOCG_OEI_enroute
        TOCG_OEI_approach 
        V_tocg_ref
        ISA_deltaT_TO
    end

    properties       %rate of climb constraint properties
        TTC_alt1
        TTC_alt2
        TTC_time
        ROC_min_at_cruise

        Alt_speed_restriction
        Vmax_below_10k
        ISA_deltaT_climb
    end

    properties
        M_alt % Mach number at each alititude to be limited by either M_c or V_climb
        M_TO
        M_app
    end

    % alternate airport diversion properties
    properties
        Alt_alternate = 1500./SI.ft; %***** fixed
        Range_alternate = 350./SI.km; % m (from km) ***** fixed
        Loiter = 30./SI.min; % 30 minutes in seconds *** fixed
    end

    properties  %structural
        Vc % structural cruise speed
        Vd % dive speed
        Mc_margin
        Md_margin
        BuffetMargin_min
    end

    methods(Static)
        function obj = B777F
            obj = cast.TLAR();
            obj.Range = 4800./SI.Nmile;% m (from nautical miles)
            obj.GroundRun = 2830; %m
            obj.GroundRunLanding = 1500; %m
            obj.M_c = 0.82;
            obj.Alt_max = 39e3./SI.ft; %m (39,000ft)
            obj.Alt_cruise = 31e3./SI.ft;
            obj.Crew = 4;
            obj.Payload = 103700;
            obj.CrewMass = (80+10)*obj.Crew;
            obj.V_app = 145./SI.knt;    %fixed 11/2 to match TLAR
            obj.V_ld = 150./SI.knt;
            obj.V_climb = 250./SI.knt;

            %take off
            obj.H_to_screen = 35./SI.ft;
            obj.TOCG_AEO_gearUp   = 0.03;   % 3% at V_CL
            obj.TOCG_OEI_gearUp = 0.024;
            obj.TOCG_OEI_gearDown = 0.005;  % 0.5% at V_CL
            obj.V_tocg_ref = obj.V_climb;   % placeholder: you may replace with V2/VTO
            obj.ISA_deltaT_TO = 15;         % K (ISA+15)

            %roc
            obj.TTC_alt1 = 1500./SI.ft;
            obj.TTC_alt2 = max(obj.Alt_cruise, 20e3./SI.ft);
            obj.TTC_time = 30./SI.min;
            obj.ROC_min_at_cruise = 300; %ft/min

            obj.Alt_speed_restriction = 10e3./SI.ft;
            obj.Vmax_below_10k = 250./SI.knt;
            obj.ISA_deltaT_climb = 0;       % K (ISA)
        end
    end

    methods(Static)
        function obj = TubeWing    %table 1 Concept down selection
            obj = cast.TLAR();
            obj.Range = 8000./SI.km; % m (from km) ****** fixed
            obj.GroundRun = 3000; %m *****fixed
            obj.GroundRunLanding = 1500; %m
            obj.M_c = 0.85;         %makes most sense as a first guess ****** fixed, nominal
            obj.Alt_max = 12.5./SI.km; %m (12.5km) ****** fixed
            obj.Alt_cruise = 11.5./SI.km; %m (11.5km) ****** fixed
            obj.Crew = 4; %****** fixed
            obj.Payload = 123./SI.Tonne; % kg (from tonnes) ***** fixed, per aircraft (6 aircraft total payload = 738 tonnes)
            obj.CrewMass = (80+10)*obj.Crew;
            obj.V_app = 145./SI.knt;    %******fixed 11/2 to match TLAR
            obj.V_ld = 140./SI.knt;   %******fixed doesnt reach approach
            obj.V_climb = 250./SI.knt;

            %for phasepolar
            obj.M_TO  = 0.25;   % ***REFINEMENT*** take-off Mach
            obj.M_app = 0.20;   % ***REFINEMENT*** approach Mach

            %take off **** NOT FIXED YET (NEED TO DO) ***************************************************************
            obj.H_to_screen = 35./SI.ft;
            obj.ISA_deltaT_TO = 15;         % K (ISA+15)

            obj.TOCG_AEO_gearUp   = 0.03;   % AEO climb target (OK)
            obj.TOCG_OEI_gearUp   = 0.024;  % OEI 2nd segment (critical for twins)
            obj.TOCG_OEI_enroute  = 0.011;
            obj.TOCG_OEI_approach = 0.021;


            obj.V_tocg_ref = obj.V_climb;   % placeholder: you may replace with V2/VTO

            %roc **** NOT FIXED YET (NEED TO DO) --> NEED TO CHECK TTC **************************************************************
            obj.TTC_alt1 = 1500./SI.ft;
            obj.TTC_alt2 = max(obj.Alt_cruise, 20e3./SI.ft);
            obj.TTC_time = 30./SI.min;
            obj.ROC_min_at_cruise = (300./SI.ft).*SI.min; %m/s (from ft/min)

            obj.Alt_speed_restriction = 10e3./SI.ft;
            obj.Vmax_below_10k = 250./SI.knt;
            obj.ISA_deltaT_climb = 0;       % K (ISA)

            obj.Vc = 350./SI.knt; % structural cruise speed
            obj.Vd = (350+35)./SI.knt; % dive speed
            obj.Mc_margin = 0.04; % margin to max cruise Mach number
            obj.Md_margin = 0.07; % margin to max dive Mach number

            obj.Range_alternate = 350./SI.km;   % R4.2.2
            obj.Alt_alternate   = 1500./SI.ft;  % R4.6.2 loiter altitude
            obj.Loiter          = 30./SI.min;   % R4.6.2 loiter time

            obj.BuffetMargin_min = 0.3;
        end
    end
end