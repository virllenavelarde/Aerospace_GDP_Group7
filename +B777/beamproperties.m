classdef beamproperties
        properties
        % identification
        name

        % geometry
        beamlength          % half-span [m]

        % aircraft / loading
        MTOM                % [kg]
        load_factor         % scalar, e.g. 1 or 2.5
        lift_split          % fraction of half-aircraft lift carried by this beam

        % material / stiffness
        E                   % Young's modulus [Pa]
        I                   % second moment of area [m^4]

        % triangular load description: w(x) = gradient*x + intercept
        gradient                        % [N/m^2]
        intercept                       % root load intensity w0 [N/m]
        effective_triangular_force      % [N]
        x_effective_force               % [m] from root

        % tip interaction force
        Rt                  % magnitude [N]
        Rt_sign             % +1 = upward on this beam, -1 = downward on this beam
        x_Rt                %

        % root reactions
        S_r                 % root shear [N]
        M_r                 % root moment [N m]
    end


    
    methods
        function obj = beamproperties(ADP, beam_name, lift_split, E, I)
            obj.name = beam_name;
            obj.beamlength = ADP.Span_max / 2;
            obj.MTOM = ADP.MTOM;

            obj.lift_split = lift_split;
            obj.E = E;
            obj.I = I;

            obj.load_factor = 1.0;
            obj.gradient = 0.0;
            obj.intercept = 0.0;
            obj.effective_triangular_force = 0.0;
            obj.x_effective_force = obj.beamlength / 3;

            obj.Rt = 0.0;
            obj.Rt_sign = 0.0;

            obj.S_r = 0.0;
            obj.M_r = 0.0;
        end 

        function obj = calcTriangularLoad(obj, n)
            g = 9.81;
            total_weight = obj.MTOM * g;
            safe_total_weight = total_weight * n;

            % divide by 2 for one wing / half span
            halfspan_load = safe_total_weight / 2;

            % area under triangular load = halfspan load
            height_of_triangle = (2 * halfspan_load) / obj.beamlength;

            %equation of the triangdistrload: 
            obj.gradient = -height_of_triangle/obj.beamlength; %this equation only works if the TDL is over the whole half span (which it is in this case)

            %area of triangle represents the 'effective' force 
            obj.effective_triangular_force = 0.5*height_of_triangle*obj.beamlength;
        end

        function obj = reaction_shear(obj, Rt, x_Rt)
            obj.Rt = Rt; 
            obj.x_Rt = x_Rt;
            obj.S_r =  Rt - obj.effective_triangular_force;
        end 



    end
end
