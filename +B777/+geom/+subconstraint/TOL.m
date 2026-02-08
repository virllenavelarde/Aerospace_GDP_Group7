function [TW_req, WS_SI] = TOL(WS_SI, sTO_m, hAirport_m, CLmax_TO)
%TOL  Take-off field length constraint using TOP correlation.
%
% Inputs
%   WS_SI       : Wing loading vector [N/m^2] at take-off (use MTOM -> W_TO/S)
%   sTO_m       : Required balanced field take-off distance [m] (brake release to 35 ft)
%   hAirport_m  : Airport elevation [m]
%   CLmax_TO    : Maximum lift coefficient in take-off config (3D aircraft CLmax)
%
% Outputs
%   TW_req      : Required thrust-to-weight ratio T/W [-] for each WS point
%   WS_SI       : (returned) Wing loading [N/m^2]
%
% Notes
% - Correlation constants (20.9, 87) are in "imperial Raymer-style" form:
%     sTO in ft, W/S in lb/ft^2, TOP in ft/(lb/ft^2)
% - Atmosphere: ISA+15C density ratio at airport altitude (pressure ISA, T shifted +15C)

    % ---- 1) Atmosphere: sigma = rho_TO/rho_SL at ISA+15C ----
    rho_SL = 1.225;          % kg/m^3 (sea-level ISA density)
    dT = 15;                 % ISA +15C
    rho_TO = rhoISA_plusDeltaT(hAirport_m, dT);  % kg/m^3
    sigma  = rho_TO / rho_SL;

    % ---- 2) Unit conversions to match the empirical correlation ----
    sTO_ft = sTO_m / 0.3048;               % m -> ft
    WS_lbft2 = WS_SI / 47.880258;          % (N/m^2) -> (lb/ft^2)
    % (since 1 lb/ft^2 = 47.880258 N/m^2)

    % ---- 3) Solve implicit equation for TW at each W/S ----
    TW_req = nan(size(WS_lbft2));

    opts = optimset('Display','off');

    for i = 1:numel(WS_lbft2)
        WS_i = WS_lbft2(i);

        % Solve for TW in a realistic range; use fzero with bracket
        f = @(TW) takeoffDistResidual(TW, WS_i, CLmax_TO, sigma, sTO_ft);

        % Bracket: cargo jets often 0.2–0.5-ish, but bracket wide for robustness
        TW_low = 0.05;
        TW_high = 1.50;

        % Ensure sign change; if not, expand bracket a bit
        fL = f(TW_low); fH = f(TW_high);
        if sign(fL) == sign(fH)
            TW_low  = 0.01;
            TW_high = 3.00;
            fL = f(TW_low); fH = f(TW_high);
        end

        if sign(fL) == sign(fH)
            % If still no root, give NaN and continue (means correlation not feasible there)
            TW_req(i) = NaN;
        else
            TW_req(i) = fzero(f, [TW_low, TW_high], opts);
        end
    end
end

% ---------- Residual for takeoff distance equation ----------
function r = takeoffDistResidual(TW, WS_lbft2, CLmax_TO, sigma, sTO_ft)
    % TOP = (W/S)*(1/CLmax)*(W/T)*(1/sigma) = (W/S)/(CLmax*sigma*(T/W))
    TOP = WS_lbft2 / (CLmax_TO * sigma * TW);

    % Raymer-style correlation (as in your screenshot)
    s_est = 20.9 * TOP + 87 * sqrt(TOP * TW);

    % residual
    r = s_est - sTO_ft;
end

% ---------- ISA density with +DeltaT (pressure ISA, temperature shifted) ----------
function rho = rhoISA_plusDeltaT(h_m, deltaT_C)
    % Constants
    T0 = 288.15;        % K
    p0 = 101325;        % Pa
    g  = 9.80665;       % m/s^2
    R  = 287.05287;     % J/(kg*K)
    L  = 0.0065;        % K/m (troposphere lapse rate)

    % ISA temperature at altitude (troposphere approx, ok for airports)
    T_ISA = T0 - L*h_m;

    % ISA pressure at altitude (troposphere)
    p_ISA = p0 * (T_ISA/T0)^(g/(R*L));

    % ISA + deltaT temperature (in Kelvin)
    T = T_ISA + deltaT_C;

    % Density using ISA pressure with shifted temperature
    rho = p_ISA / (R*T);
end
