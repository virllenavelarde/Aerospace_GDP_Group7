%helper function to calculate CD0 for two wing planforms, doesnt need surface roughness if we're using michel's criterion
    function CD0_wing = CD0(obj,B7Geom)
        if nargin < 2
            B7Geom = [];    %estimate
        end

        %atmos / cruise
        [rho, a, ~, ~, mu] = cast.atmos(obj.TLAR.Alt_cruise); 
        V = obj.TLAR.M_c * a;   %Velocity at cruise
        M = obj.TLAR.M_c;    %Mach

        %geom
        S_ref = obj.WingArea; %reference area
        b = obj.Span;        %span

        %check for MAC availability
        if isprop(obj, 'MAC') && ~isempty(obj.MAC) && isfinite(obj.MAC)
            c_ref = obj.MAC; %use provided MAC
        else
            c_ref = S_ref / b; %mean aerodynamic chord, S/b first-cut
        end
        
        %thickness ratio
        tc = obj.tc_ref;
        x_tc = 0.37; % supercritical airfoil http://airfoiltools.com/airfoil/details?airfoil=sc20714-il max at 37% chord

        %sweep
        if isprop(obj,'SweepLE') && ~isempty(obj.SweepLE) && isfinite(obj.SweepLE) %%%%Need to check the values here to change in accordance with hyperparameter
            % Convert LE sweep to approx max-thickness sweep
            % Lambda_maxt ~ Lambda_LE - arctan(2*tc / AR)  (rough)
            AR = b^2 / S_ref;
            Lambda_deg = obj.SweepLE - rad2deg(atan(2*tc / AR));
        elseif isprop(obj,'Sweep25') && ~isempty(obj.Sweep25) && isfinite(obj.Sweep25)
            Lambda_deg = obj.Sweep25 - 2.0;   % max-t line ~ 2 deg aft of c/4
        else
            Lambda_deg = 30.0;
            warning('CD0_wing_michel: sweep not found, using fallback Lambda = %.1f deg', Lambda_deg);
        end
        Lambda_rad = deg2rad(Lambda_deg);

        
        %%wetted --> check if case if box-wing or tube wing + %interference factor (wing-fuse) (not yet finished (the isa loop))
        if isa(obj, 'B777.ADP_BW')
            if ~isempty(B7Geom)
                % -------------------------------------------------
                % REAL wetted areas from geometry
                % run this to find your exact component names:
                for i=1:numel(B7Geom)
                    fprintf('[%d] %s\n', i, B7Geom(i).Name);
                end
                % -------------------------------------------------
                %not yet finished, need to recheck the geometry and sum wetted areas by component name
                % S_wet_main  = sumWetted(B7Geom, 'LowerWing');
                % S_wet_upper = sumWetted(B7Geom, 'UpperWing');
                % S_wet_fins  = sumWetted(B7Geom, 'Join');
                % S_wet = S_wet_main + S_wet_upper + S_wet_fins;

                % fprintf('  [BW wetted areas from geometry]\n');
                % fprintf('  S_wet lower wing  = %.2f m^2\n', S_wet_main);
                % fprintf('  S_wet upper wing  = %.2f m^2\n', S_wet_upper);
                % fprintf('  S_wet tip fins    = %.2f m^2\n', S_wet_fins);
            else
                % -------------------------------------------------
                % FALLBACK first-cut estimates (B7Geom not provided), assumptions, need reference and fixing
                % -------------------------------------------------
                S_wet_main = 2.0 * S_ref * (1 + 0.2*tc);

                if isprop(obj,'alphaArea') && ~isempty(obj.alphaArea) && isfinite(obj.alphaArea)
                    alpha_area = obj.alphaArea;
                else
                    alpha_area = 0.5;
                end
                S_wet_upper = 2.0 * (alpha_area * S_ref) * (1 + 0.2*tc);

                h_fin      = 0.10 * (b/2);
                c_tip      = c_ref * 0.35;
                S_wet_fins = 2 * (2 * h_fin * c_tip);

                S_wet = S_wet_main + S_wet_upper + S_wet_fins;
                warning('B777.CD0: B7Geom not provided, using first-cut BW wetted area estimates');

                fprintf('  [BW wetted areas -- first-cut estimates]\n');
                fprintf('  S_wet lower wing  = %.2f m^2\n', S_wet_main);
                fprintf('  S_wet upper wing  = %.2f m^2\n', S_wet_upper);
                fprintf('  S_wet tip fins    = %.2f m^2\n', S_wet_fins);
            end
            Q = 1.05; % interference factor for box wing, slightly higher than clean tube wing, max bound 1.10
            
        else %tube wing
            Q = 1.0; %clean mid/low = 1.0, 1.05-1.10 for high wing
            S_wet = 2.0 * S_ref * (1 + 0.2*tc); %usually wetted ~2x ref area, but can use first-cut
        end
        Swet_Sref = S_wet / S_ref;

        %Reynolds number
        Re_L = (rho * V * c_ref) / mu;

        %Find transition using Michel's criterion (1951): https://www.researchgate.net/publication/260310401_An_Investigation_of_the_Numerical_Prediction_of_Static_and_Dynamic_Stall/citations
        %Retheta = 1.174(1+22400,Rex)Rex^(0.46), Retheta = 0.664sqrt(Rex) (LHS)
        michel_residual = @(Re_x) 0.664 .* Re_x.^0.5 - 1.174 .* (1 + (22400 ./ Re_x)) .* Re_x.^0.46; %F(Re_x)
        
        %sign changes in brackets indicate root crossings, which is where the transition occurs
        f_low = michel_residual(1e4);
        f_high = michel_residual(Re_L);
        if sign(f_low) ~= sign(f_high)
            Re_x_tr = fzero(michel_residual, [1e4, Re_L]);
        else
            % Fallback: flat-plate Michel solution ~1e7 (from our earlier analysis)
            Re_x_tr = fzero(michel_residual, 1e7);
            warning('CD0_wing_michel: Michel bracket sign check failed, using unbounded fzero');
        end

        Re_x_tr = max(min(Re_x_tr, Re_L), 1e4); %initial guess, clamp to physical domain
        Re_theta_tr = 0.664 * sqrt(Re_x_tr); %calculate Reynolds number at transition
        xc_tr = Re_x_tr / Re_L; %chord fraction at transition
        
        %%schlichting full-turb 
        Cf_turb = 0.455 ./ (log10(Re_L)).^2.58;

        %A factor
        Re_tr_table = [3e5,  5e5,  3e6,   1e7  ];
        A_table     = [1050, 1700, 8700,  27000 ];
        A = interp1(Re_tr_table, A_table, Re_x_tr, 'linear', 'extrap');
        A = max(A, 0);   % physical floor

         % Mixed Cf (incompressible)
        Cf_mixed_incomp = Cf_turb - A / Re_L;
        Cf_mixed_incomp = max(Cf_mixed_incomp, 0);   % sanity floor

        % Diagnostic laminar Cf at transition (not used in CD0 directly)
        Cf_lam_tr = 1.328 / sqrt(Re_x_tr);

        %% Compressibility correction (Eckert reference temperature method)
        comp_corr = (1 + 0.144 * M^2)^0.65;
        Cf_mixed  = Cf_mixed_incomp / comp_corr;

        %%Form Factor
        FF_thickness = 1 + (0.6/x_tc)*tc + 100*tc^4;
        FF_mach_sweep = 1.34 * M^0.18 * cos(Lambda_rad)^0.28;
        FF = FF_thickness * FF_mach_sweep;

        %%CD0 calculation
        CD0_wing = Cf_mixed * FF * Q * Swet_Sref;

        %  PRINT SUMMARY
        fprintf('\n==============================================\n');
        fprintf('  CD0_WING_MICHEL - RESULTS\n');
        fprintf('==============================================\n');
        fprintf('  c_ref (MAC)           = %.3f m\n',   c_ref);
        fprintf('  Re_L                  = %.4e\n',      Re_L);
        fprintf('  Re_x,tr  (Michel)     = %.4e\n',      Re_x_tr);
        fprintf('  Re_theta,tr           = %.2f\n',      Re_theta_tr);
        fprintf('  x_tr/c                = %.4f  (%.1f%% chord)\n', xc_tr, xc_tr*100);
        fprintf('----------------------------------------------\n');
        fprintf('  Cf turb (Schlichting) = %.4e\n',      Cf_turb);
        fprintf('  A-factor              = %.0f\n',       A);
        fprintf('  Cf mixed (incomp.)    = %.4e\n',      Cf_mixed_incomp);
        fprintf('  Compressibility corr  = %.4f\n',      comp_corr);
        fprintf('  Cf mixed (final)      = %.4e\n',      Cf_mixed);
        fprintf('----------------------------------------------\n');
        fprintf('  t/c                   = %.3f\n',      tc);
        fprintf('  x/c max-thickness     = %.2f\n',      x_tc);
        fprintf('  Sweep Lambda          = %.1f deg\n',  Lambda_deg);
        fprintf('  FF (thickness)        = %.4f\n',      FF_thickness);
        fprintf('  FF (Mach+sweep)       = %.4f\n',      FF_mach_sweep);
        fprintf('  FF (total)            = %.4f\n',      FF);
        fprintf('  Swet/Sref             = %.4f\n',      Swet_Sref);
        fprintf('----------------------------------------------\n');
        fprintf('  CD0_wing              = %.5f  <-- output\n', CD0_wing);
        fprintf('==============================================\n\n');

        %note, the different material affectts the transition locatioon (accounted by turbulence intensity by Michel's criterion)
    end