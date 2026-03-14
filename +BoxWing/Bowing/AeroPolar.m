classdef AeroPolar
    %AEROPOLAR  Drag polar for the boxwing freighter.

    properties
        CD0     % zero-lift drag coefficient
        e       % Oswald efficiency factor
        Beta    % induced drag factor  = 1/(pi*AR*e)
    end

    methods
        function obj = AeroPolar(ADP)
            % CD0 – boxwing has lower wetted area than conventional
            obj.CD0 = ADP.CD0;   % taken directly from ADP (set to 0.016)

            % Effective AR of the boxwing lifting system
            AR = ADP.AR();

            % Oswald efficiency (Kroo 2005 boxwing correction: e > 1 possible)
            Q = 1.02;  P = 0.006;
            obj.e    = min(1.0/(Q + P*pi*AR), ADP.e);  % cap at ADP.e
            obj.Beta = 1 / (pi * AR * obj.e);
        end

        function CD = CD(obj, CL)
            %CD  Return drag coefficient for a given lift coefficient.
            CD = obj.CD0 + obj.Beta .* CL.^2;
        end
    end
end
