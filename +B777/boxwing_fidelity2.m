clc; clear; close all;

%%  INPUTS

ADP.Span_max = 64.8;      % [m]
ADP.MTOM     = 300000;    % [kg]

% Material / stiffness assumptions: Using CFRP
% Replace these with your own values later
E_front = 70e9;           % [Pa]
E_rear  = 70e9;           % [Pa]

I_front = 0.08;           % [m^4] placeholder
I_rear  = 0.08;           % [m^4] placeholder

% Lift split between front and rear wings
% Must sum to 1.0 for the half-aircraft lift
lift_split_front = 0.5;
lift_split_rear  = 0.5;

% 3 Load factors for 3 different load cases
n = 1; %for straight and level flight
% n = 2; %for
% n = 2.5; %for 


%%  CREATE FRONT AND REAR BEAM OBJECTS


front = B777.geom.beamproperties(ADP, 'Front Wing', lift_split_front, E_front, I_front);

rear  = B777.geom.beamproperties(ADP, 'Rear Wing',  lift_split_rear,  E_rear,  I_rear);

front = front.calcTriangularLoad(n);
rear  = rear.calcTriangularLoad(n);


%%  SOLVE TIP COMPATIBILITY FOR Rt


% First: triangular-load-only tip deflections
delta_front_0 = front.tipDeflectionTriangular();
delta_rear_0  = rear.tipDeflectionTriangular();

% Flexibility coefficients due to unit tip force
cf = front.beamlength^3 / (3 * front.E * front.I);
cr = rear.beamlength^3  / (3 * rear.E  * rear.I);

% Assume:
% - front wing gets a downward tip force  => Rt_sign = -1
% - rear wing gets an upward tip force    => Rt_sign = +1
%
% Then:
% delta_front = delta_front_0 - Rt*cf
% delta_rear  = delta_rear_0  + Rt*cr
%
% Compatibility:
% delta_front = delta_rear

Rt = (delta_front_0 - delta_rear_0) / (cf + cr);   % [N]

front = front.setTipForce(Rt, -1);
rear  = rear.setTipForce(Rt, +1);

front = front.reactionLoads();
rear  = rear.reactionLoads();


%%  PRINT RESULTS

fprintf('\n============================================================\n');
fprintf('TIP COMPATIBILITY SOLUTION\n');
fprintf('============================================================\n');
fprintf('Rt magnitude = %.3f MN\n', Rt / 1e6);
fprintf('Front wing triangular-only tip deflection = %.4f m\n', delta_front_0);
fprintf('Rear  wing triangular-only tip deflection = %.4f m\n', delta_rear_0);
fprintf('Front wing final tip deflection           = %.4f m\n', front.tipDeflectionTotal());
fprintf('Rear  wing final tip deflection           = %.4f m\n', rear.tipDeflectionTotal());

front.printSummary();
rear.printSummary();


%%  PLOT SHEAR AND MOMENT DIAGRAMS

npts = 300;
[xf, Sf, Mf] = front.diagrams(npts);
[xr, Sr, Mr] = rear.diagrams(npts);

figure('Name','Front Wing Shear / Moment');
subplot(2,1,1)
plot(xf, Sf/1e6, 'LineWidth', 1.8)
grid on
xlabel('x [m]')
ylabel('Shear [MN]')
title('Front Wing Shear Force')

subplot(2,1,2)
plot(xf, Mf/1e6, 'LineWidth', 1.8)
grid on
xlabel('x [m]')
ylabel('Moment [MN m]')
title('Front Wing Bending Moment')

figure('Name','Rear Wing Shear / Moment');
subplot(2,1,1)
plot(xr, Sr/1e6, 'LineWidth', 1.8)
grid on
xlabel('x [m]')
ylabel('Shear [MN]')
title('Rear Wing Shear Force')

subplot(2,1,2)
plot(xr, Mr/1e6, 'LineWidth', 1.8)
grid on
xlabel('x [m]')
ylabel('Moment [MN m]')
title('Rear Wing Bending Moment')
