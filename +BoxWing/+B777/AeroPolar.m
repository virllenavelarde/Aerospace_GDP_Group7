classdef AeroPolar
    %AEROPOLAR  Drag polar for the boxwing freighter — including trim drag.

    properties
        CD0      % zero-lift drag coefficient    [-]
        e        % Oswald efficiency factor       [-]
        Beta     % induced drag factor 1/(pi*AR*e)[-]
        CD_trim  % trim drag increment            [-]
    end

    methods
        function obj = AeroPolar(ADP, x_cg)

            %% Zero-lift drag
            obj.CD0 = ADP.CD0;

            %% Induced drag
            AR = ADP.AR();
            Q = 1.02;  P = 0.006;
            obj.e    = min(1.0/(Q + P*pi*AR), ADP.e);
            obj.Beta = 1 / (pi * AR * obj.e);

            %% Trim drag — use real CG if provided, else fall back to 48% fuselage
            if nargin < 2 || isempty(x_cg)
                L_f  = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius * 1.48;
                x_cg = 0.48 * L_f;
            end

            try
                [obj.CD_trim, ~] = BoxWing.B777.trimDrag(ADP, x_cg);
            catch ME
                warning('AeroPolar: trimDrag failed (%s). CD_trim = 0.', ME.message);
                obj.CD_trim = 0;
            end
        end

        function CD = CD(obj, CL)
            CD = obj.CD0 + obj.Beta .* CL.^2 + obj.CD_trim;
        end

        function CD = CD_no_trim(obj, CL)
            CD = obj.CD0 + obj.Beta .* CL.^2;
        end
    end
end