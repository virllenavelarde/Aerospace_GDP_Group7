function visualize_boxwing_3D()
%VISUALIZE_BOXWING_3D  Generate a 3D render of the boxwing freighter.
%
%  Creates a professional 3D visualization showing:
%    - Front and rear swept wings with dihedral
%    - Vertical wingtip connectors (winglets)
%    - Fuselage with cargo door
%    - 2 × UltraFan engines mounted UNDER the rear wing
%    - Landing gear (nose + 2 main)
%    - Realistic lighting and materials
%
%  HOW TO RUN:
%    1. Copy this file to your MATLAB working directory
%    2. Run:  visualize_boxwing_3D
%    3. Use mouse to rotate view (click + drag)

close all;
figure('Color','w','Position',[100 100 1200 800]);
hold on; axis equal; grid on;
xlabel('X — Longitudinal (m)');
ylabel('Y — Lateral (m)');
zlabel('Z — Vertical (m)');
title('Boxwing Freighter — 319 t MTOW with Rear-Mounted UltraFan Engines');
view([-140 20]);

%% ══════════════════════════════════════════════════════════════
%  GEOMETRY PARAMETERS (calibrated to your BoxwingProject)
%  ══════════════════════════════════════════════════════════════
L_fus     = 66.0;      % fuselage length [m]
R_fus     = 2.93;      % fuselage radius [m]
L_nose    = 6.5;       % nose length
L_tail    = 8.0;       % tail cone length

% Front wing
b_front   = 50.0;      % span [m]
c_r_front = 8.0;       % root chord [m]
c_t_front = 2.8;       % tip chord [m]
sweep_front = 25;      % quarter-chord sweep [deg]
x_front   = 23.0;      % position along fuselage [m]
z_front   = -1.5;      % vertical position [m]
dihedral_front = 3;    % dihedral angle [deg]

% Rear wing
b_rear    = 50.0;      % span [m]
c_r_rear  = 8.0;       % root chord [m]
c_t_rear  = 3.0;       % tip chord [m]
sweep_rear = 22;       % quarter-chord sweep [deg]
x_rear    = 43.0;      % position along fuselage [m]
z_rear    = 6.5;       % vertical position [m] — 8m above front wing
dihedral_rear = 3;     % dihedral angle [deg]

% Vertical connectors (wingtip fins)
h_connector = 8.0;     % height [m]
c_connector = 3.5;     % chord [m]

% Engines (UltraFan)
D_eng     = 4.5;       % engine diameter [m]
L_eng     = 6.5;       % engine length [m]
x_eng     = x_rear - 2.0;  % mounted 2m forward of rear wing LE
z_eng     = z_rear - 2.5;  % hung below rear wing
y_eng     = R_fus + 6.0;   % lateral position (outboard)

% Landing gear
x_nose_gear = L_nose + 2;
x_main_gear = x_front + 4.0;
y_main_gear = R_fus + 3.0;

%% ══════════════════════════════════════════════════════════════
%  1. FUSELAGE
%  ══════════════════════════════════════════════════════════════
N_circ = 50;  N_len = 80;
theta = linspace(0, 2*pi, N_circ);

% Nose section (elliptical)
x_nose = linspace(0, L_nose, 30);
for i = 1:length(x_nose)
    r = R_fus * sqrt(x_nose(i)/L_nose);  % elliptical profile
    X_nose(:,i) = x_nose(i);
    Y_nose(:,i) = r * cos(theta)';
    Z_nose(:,i) = r * sin(theta)';
end

% Main barrel (constant diameter)
x_barrel = linspace(L_nose, L_fus - L_tail, N_len);
for i = 1:length(x_barrel)
    X_barrel(:,i) = x_barrel(i);
    Y_barrel(:,i) = R_fus * cos(theta)';
    Z_barrel(:,i) = R_fus * sin(theta)';
end

% Tail cone (tapering to zero)
x_tail = linspace(L_fus - L_tail, L_fus, 30);
for i = 1:length(x_tail)
    frac = 1 - (x_tail(i) - (L_fus-L_tail))/L_tail;
    r = R_fus * frac;
    X_tail(:,i) = x_tail(i);
    Y_tail(:,i) = r * cos(theta)';
    Z_tail(:,i) = r * sin(theta)';
end

% Draw fuselage
surf(X_nose, Y_nose, Z_nose, 'FaceColor',[0.85 0.85 0.85],'EdgeColor','none','FaceAlpha',1);
surf(X_barrel, Y_barrel, Z_barrel, 'FaceColor',[0.85 0.85 0.85],'EdgeColor','none','FaceAlpha',1);
surf(X_tail, Y_tail, Z_tail, 'FaceColor',[0.85 0.85 0.85],'EdgeColor','none','FaceAlpha',1);

% Cargo door outline (side of fuselage)
x_door = [25 40 40 25 25];
z_door = [-2.5 -2.5 2.0 2.0 -2.5];
y_door = R_fus * ones(size(x_door));
plot3(x_door, y_door, z_door, 'k-', 'LineWidth', 2);

%% ══════════════════════════════════════════════════════════════
%  2. FRONT WING (swept, tapered, with dihedral)
%  ══════════════════════════════════════════════════════════════
draw_wing(x_front, z_front, 0, b_front, c_r_front, c_t_front, ...
          sweep_front, dihedral_front, [0.3 0.3 0.35]);

%% ══════════════════════════════════════════════════════════════
%  3. REAR WING (swept, tapered, with dihedral)
%  ══════════════════════════════════════════════════════════════
draw_wing(x_rear, z_rear, 0, b_rear, c_r_rear, c_t_rear, ...
          sweep_rear, dihedral_rear, [0.3 0.3 0.35]);

%% ══════════════════════════════════════════════════════════════
%  4. VERTICAL CONNECTORS (wingtip fins closing the box)
%  ══════════════════════════════════════════════════════════════
% Left connector
y_conn_L = -b_front/2;
draw_connector(x_front, y_conn_L, z_front, x_rear, y_conn_L, z_rear, ...
               c_connector, h_connector, [0.25 0.25 0.30]);

% Right connector
y_conn_R = b_front/2;
draw_connector(x_front, y_conn_R, z_front, x_rear, y_conn_R, z_rear, ...
               c_connector, h_connector, [0.25 0.25 0.30]);

%% ══════════════════════════════════════════════════════════════
%  5. ENGINES — UltraFan mounted UNDER rear wing
%  ══════════════════════════════════════════════════════════════
% Left engine
draw_engine(x_eng, -y_eng, z_eng, L_eng, D_eng, [0.15 0.15 0.18]);

% Right engine
draw_engine(x_eng, y_eng, z_eng, L_eng, D_eng, [0.15 0.15 0.18]);

% Engine pylons (struts connecting engine to rear wing)
draw_pylon(x_eng + L_eng*0.3, -y_eng, z_eng + D_eng/2, z_rear);
draw_pylon(x_eng + L_eng*0.3, y_eng, z_eng + D_eng/2, z_rear);

%% ══════════════════════════════════════════════════════════════
%  6. LANDING GEAR
%  ══════════════════════════════════════════════════════════════
% Nose gear
draw_gear(x_nose_gear, 0, -R_fus, 2.5);

% Main gear (left and right)
draw_gear(x_main_gear, -y_main_gear, -R_fus, 3.5);
draw_gear(x_main_gear, y_main_gear, -R_fus, 3.5);

%% ══════════════════════════════════════════════════════════════
%  7. LIGHTING & FINAL TOUCHES
%  ══════════════════════════════════════════════════════════════
light('Position',[100 -100 150],'Style','infinite');
light('Position',[-50 100 80],'Style','infinite');
lighting gouraud;
material([0.5 0.6 0.4 5]);

% Add registration text on fuselage side
text(35, R_fus+0.2, 1, 'G-BXWG', 'FontSize', 14, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'center');

% Set better axis limits
xlim([-5 L_fus+5]);
ylim([-b_front/2-5 b_front/2+5]);
zlim([-R_fus-5 z_rear+3]);

fprintf('3D Boxwing visualization complete.\n');
fprintf('• Use mouse to rotate view (click + drag)\n');
fprintf('• Engines are mounted under the REAR wing at x=%.1f m\n', x_eng);
fprintf('• To save: saveas(gcf, ''boxwing_3D.png'')\n');

end

%% ══════════════════════════════════════════════════════════════
%  HELPER FUNCTIONS
%  ══════════════════════════════════════════════════════════════

function draw_wing(x_root, z_root, y_root, span, c_root, c_tip, sweep_qc, dihedral, color)
%DRAW_WING  Draw a swept, tapered wing with dihedral.
    
    % Wing geometry
    half_span = span/2;
    sweep_le = atand(tand(sweep_qc) + (c_root - c_tip)/(4*half_span));
    
    % Spanwise stations
    eta = linspace(0, 1, 30);  % 0 = root, 1 = tip
    
    for i = 1:length(eta)
        y(i) = eta(i) * half_span;
        c(i) = c_root + eta(i)*(c_tip - c_root);
        x_le(i) = x_root + y(i)*tand(sweep_le);
        z_offset(i) = y(i)*tand(dihedral);
        
        % Chordwise: from LE to TE
        x_chord = linspace(x_le(i), x_le(i) + c(i), 20);
        
        % Airfoil thickness (symmetric, NACA 0012 style)
        t_c = 0.12;  % thickness-to-chord ratio
        for j = 1:length(x_chord)
            x_local = (x_chord(j) - x_le(i))/c(i);
            thick = t_c * c(i) * (0.2969*sqrt(x_local) - 0.1260*x_local ...
                    - 0.3516*x_local^2 + 0.2843*x_local^3 - 0.1015*x_local^4);
            
            % Upper surface
            X_upper(i,j) = x_chord(j);
            Y_upper(i,j) = y_root + y(i);
            Z_upper(i,j) = z_root + z_offset(i) + thick;
            
            % Lower surface
            X_lower(i,j) = x_chord(j);
            Y_lower(i,j) = y_root + y(i);
            Z_lower(i,j) = z_root + z_offset(i) - thick;
        end
    end
    
    % Draw upper and lower surfaces (right half)
    surf(X_upper, Y_upper, Z_upper, 'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 1);
    surf(X_lower, Y_lower, Z_lower, 'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 1);
    
    % Mirror for left half
    surf(X_upper, -Y_upper, Z_upper, 'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 1);
    surf(X_lower, -Y_lower, Z_lower, 'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 1);
end

function draw_connector(x_f, y, z_f, x_r, ~, z_r, chord, height, color)
%DRAW_CONNECTOR  Vertical wingtip fin connecting front and rear wings.
    
    % Define connector as a vertical quad
    x_c = [x_f, x_r, x_r + chord, x_f + chord, x_f];
    y_c = [y, y, y, y, y];
    z_c = [z_f, z_r, z_r, z_f, z_f];
    
    % Draw as patch
    patch(x_c, y_c, z_c, color, 'EdgeColor', 'k', 'LineWidth', 0.5, 'FaceAlpha', 0.9);
end

function draw_engine(x, y, z, length, diameter, color)
%DRAW_ENGINE  Draw a turbofan engine (cylindrical nacelle).
    
    N = 30;
    theta = linspace(0, 2*pi, N);
    
    % Engine centerline runs along X
    x_stations = linspace(x, x + length, 40);
    
    for i = 1:length(x_stations)
        % Slight radius variation (larger at fan, smaller at nozzle)
        frac = (x_stations(i) - x)/length;
        if frac < 0.3  % fan section
            r = diameter/2 * (1 + 0.1*(1 - frac/0.3));
        else
            r = diameter/2 * (1 - 0.2*(frac - 0.3)/0.7);
        end
        
        X_eng(:,i) = x_stations(i);
        Y_eng(:,i) = y + r*cos(theta)';
        Z_eng(:,i) = z + r*sin(theta)';
    end
    
    surf(X_eng, Y_eng, Z_eng, 'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 1);
    
    % Fan face (front)
    X_fan = x * ones(size(theta));
    Y_fan = y + (diameter/2)*cos(theta);
    Z_fan = z + (diameter/2)*sin(theta);
    patch(X_fan, Y_fan, Z_fan, [0.1 0.1 0.1], 'EdgeColor', 'none');
    
    % Nozzle (aft)
    X_noz = (x + length) * ones(size(theta));
    Y_noz = y + (diameter/2)*0.8*cos(theta);
    Z_noz = z + (diameter/2)*0.8*sin(theta);
    patch(X_noz, Y_noz, Z_noz, [0.2 0.2 0.25], 'EdgeColor', 'none');
end

function draw_pylon(x, y, z_bottom, z_top)
%DRAW_PYLON  Strut connecting engine to wing.
    
    % Simple vertical strut
    width = 0.4;
    depth = 1.2;
    
    x_p = [x - depth/2, x + depth/2, x + depth/2, x - depth/2, x - depth/2];
    y_p = [y - width/2, y - width/2, y + width/2, y + width/2, y - width/2];
    
    % Bottom face
    patch(x_p, y_p, z_bottom*ones(size(x_p)), [0.3 0.3 0.35], 'EdgeColor', 'k', 'LineWidth', 0.5);
    
    % Top face
    patch(x_p, y_p, z_top*ones(size(x_p)), [0.3 0.3 0.35], 'EdgeColor', 'k', 'LineWidth', 0.5);
    
    % Side faces
    for i = 1:4
        x_side = [x_p(i), x_p(i+1), x_p(i+1), x_p(i)];
        y_side = [y_p(i), y_p(i+1), y_p(i+1), y_p(i)];
        z_side = [z_bottom, z_bottom, z_top, z_top];
        patch(x_side, y_side, z_side, [0.3 0.3 0.35], 'EdgeColor', 'none');
    end
end

function draw_gear(x, y, z_attach, height)
%DRAW_GEAR  Simple landing gear (strut + wheels).
    
    % Strut (vertical line)
    plot3([x x], [y y], [z_attach z_attach - height], 'k-', 'LineWidth', 4);
    
    % Wheels (two cylinders)
    N = 20;
    theta = linspace(0, 2*pi, N);
    wheel_r = 0.6;
    wheel_w = 0.3;
    
    for offset = [-0.5 0.5]
        z_wheel = z_attach - height;
        y_wheel = y + offset;
        
        % Wheel as disk
        Y_wheel = y_wheel + wheel_w*[-1 1 1 -1 -1]';
        Z_wheel = z_wheel + wheel_r*[0 0 1 1 0; 0 0 -1 -1 0]';
        X_wheel = x * ones(size(Z_wheel));
        patch(X_wheel, Y_wheel, Z_wheel, [0.1 0.1 0.1], 'EdgeColor', 'k');
    end
end
