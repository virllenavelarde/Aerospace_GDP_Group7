classdef TLAR
    %TLAR Top-Level Aircraft (Design) Requirements
    
    %To be added more

    properties
        Crew
        Range       % Harmonic Range
        Payload     % Max. Payload
        V_ld        % Landing Speed
        V_app       % approach speed
        V_climb     % climb speed (CAS)
        GroundRun
        GroundRunLanding
        M_c         % cruise Mach number
        Alt_max     % max altitude in m
        Alt_cruise  % Cruise Altitude
        CrewMass    % Mass of the Crew
    end

    properties       %take off constraint properties
        H_to_screen
        TOCG_AEO_gearUp
        TOCG_OEI_gearDown
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
    end

    % alternate airport diversion properties
    properties
        Alt_alternate = 22e3./SI.ft;
        Range_alternate = 200./SI.Nmile;
        Loiter = 30./SI.min; % 30 minutes in seconds
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
            obj.V_app = 200./SI.knt;
            obj.V_ld = 150./SI.knt;
            obj.V_climb = 250./SI.knt;

            %take off
            obj.H_to_screen = 35./SI.ft;
            obj.TOCG_AEO_gearUp   = 0.03;   % 3% at V_CL
            obj.TOCG_OEI_gearDown = 0.005;  % 0.5% at V_CL
            obj.V_tocg_ref = obj.V_climb;   % placeholder: you may replace with V2/VTO
            obj.ISA_deltaT_TO = 15;         % K (ISA+15)

            %roc
            obj.TTC_alt1 = 1500./SI.ft;
            obj.TTC_alt2 = max(obj.Alt_cruise, 20e3./SI.ft);
            obj.TTC_time = 30./SI.min;
            obj.ROC_min_at_cruise = 300 .* SI.ft / SI.min;

            obj.Alt_speed_restriction = 10e3./SI.ft;
            obj.Vmax_below_10k = 250./SI.knt;
            obj.ISA_deltaT_climb = 0;       % K (ISA)
        end
    end
end