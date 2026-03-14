function [ADP,out] = size(ADP)

delta = inf;
it = 0;

% ---- tuning knobs (minimal + safe) ----
relax      = 0.05;
maxIt      = 2000;
tol_rel    = 1e-4;     % 0.01% relative tolerance
S_max      = 2e4;      % sanity cap

% ---- Aerodynamic design choice: keep AR fixed ----
if ~isprop(ADP,'AR_target') || isempty(ADP.AR_target)
    ADP.AR_target = 12;   % 8–12 typical for transonic widebody , reduce AR for lower W/S
end

% ---- ICAO span cap ----
if ~isprop(ADP,'Span_max') || isempty(ADP.Span_max)
    ADP.Span_max = 65;     % [m]
end

% ---- W/S guardrails when span-cap forces S ----
if ~isprop(ADP,'WS_min') || isempty(ADP.WS_min)
    ADP.WS_min = 4.0e3;    % [N/m^2] avoid absurdly low W/S
end
if ~isprop(ADP,'WS_max') || isempty(ADP.WS_max)
    ADP.WS_max = 1.30e4;   % [N/m^2] bump if your constraints allow
end

while true
    it = it + 1;

    % always recompute constraints
    doPlot = false; % don't plot during iterations
    [ADP.ThrustToWeightRatio, ADP.WingLoading] = B777.ConstraintAnalysis(ADP, doPlot);

    % build geometry (BoxWing / TubeWing)
    % (do aero sizing first, then build geometry, then UpdateAero)

    % ---------------- update Aero / planform from constraints ----------------
    % update wing area from W/S
    W = ADP.MTOM * 9.81;
    ADP.WingArea = W / ADP.WingLoading;
    ADP.Thrust   = ADP.ThrustToWeightRatio * W;

    % ------------------------- SPAN CAP + FIX AR ----------------------------
    % Start from desired AR, then enforce b <= Span_max by overriding S (=> raises W/S)
    ADP.Span = sqrt(ADP.AR_target * ADP.WingArea);

    if ADP.Span > ADP.Span_max
        % enforce b = b_max and keep AR_target => S = b^2 / AR
        ADP.WingArea    = (ADP.Span_max^2) / ADP.AR_target;
        ADP.WingLoading = W / ADP.WingArea;  % increases W/S automatically

        % optional guardrails
        ADP.WingLoading = min(max(ADP.WingLoading, ADP.WS_min), ADP.WS_max);
        ADP.WingArea    = W / ADP.WingLoading; % keep consistent after clamp

        % update span + effective AR (AR may shift if W/S clamped)
        ADP.Span      = ADP.Span_max;
        ADP.AR_target = (ADP.Span^2) / ADP.WingArea; % effective AR after clamping
    end

    if ~isfinite(ADP.WingArea) || ADP.WingArea > S_max
        error("WingArea runaway at it=%d: S=%.3e m^2, MTOM=%.3e kg, WS=%.3e Pa", ...
              it, ADP.WingArea, ADP.MTOM, ADP.WingLoading);
    end

    % -------------------------- build geometry ------------------------------
    if isa(ADP, 'B777.ADP_BW')
        [~, B7Mass] = B777.BuildGeometry_BW(ADP); %span definition of AR may vary (recheck)
    else
        [~, B7Mass] = B777.BuildGeometry(ADP);
    end

    % enforce span again in case geometry overwrites it
    if ADP.Span > ADP.Span_max
        ADP.Span = ADP.Span_max;
    end

    B777.UpdateAero(ADP);

    % mission
    [BlockFuel,TripFuel,ResFuel,Mf_TOC,MissionTime] = ...
        B777.MissionAnalysis(ADP, ADP.TLAR.Range, ADP.MTOM);

    if any(~isfinite([BlockFuel,TripFuel,ResFuel,Mf_TOC,MissionTime]))
        error("MissionAnalysis returned NaN/Inf at it=%d", it);
    end

    % ---- fuel sanity guard ----
    fuelFrac = BlockFuel / ADP.MTOM;
    if fuelFrac > 0.7
        error("Nonphysical fuel fraction at it=%d: BlockFuel/MTOM=%.3f", ...
              it, fuelFrac);
    end

    % OEM excludes Fuel & Payload
    idx = contains([B7Mass.Name],"Fuel","IgnoreCase",true) | ...
          contains([B7Mass.Name],"Payload","IgnoreCase",true);

    ADP.OEM = sum([B7Mass(~idx).m]);

    % MTOM update
    mtom_new = ADP.OEM + ADP.TLAR.Payload + BlockFuel;
    mtom     = (1-relax)*ADP.MTOM + relax*mtom_new;

    % convergence check
    delta = abs(mtom - ADP.MTOM);
    if (delta / max(ADP.MTOM,1)) < tol_rel
        ADP.MTOM = mtom;
        % Plot final consistent constraint diagram once
        [ADP.ThrustToWeightRatio, ADP.WingLoading] = B777.ConstraintAnalysis(ADP, true);
        % ---- RE-SYNC S and b to the final WS/TW ----
        W = ADP.MTOM * 9.81;
        ADP.WingArea = W / ADP.WingLoading;
        ADP.Span     = min(sqrt(ADP.AR_target * ADP.WingArea), ADP.Span_max);
        % if want span to be hard-capped, need to re-enforce S again:
        if ADP.Span == ADP.Span_max
            ADP.WingArea    = (ADP.Span_max^2) / ADP.AR_target;
            ADP.WingLoading = W / ADP.WingArea;
        end
        break;
    end

    ADP.MTOM = mtom;

    % update mass fractions
    ADP.Mf_Fuel = BlockFuel / ADP.MTOM;
    ADP.Mf_TOC  = (1-relax)*ADP.Mf_TOC + relax*Mf_TOC;
    ADP.Mf_Ldg  = (ADP.MTOM-TripFuel)/ADP.MTOM;
    ADP.Mf_res  = ResFuel/ADP.MTOM;

    % % debug print
    % if mod(it,10)==0
    %     AR = ADP.Span^2 / ADP.WingArea;
    %     fprintf("it=%4d  MTOM=%.3e  S=%.1f  b=%.1f  AR=%.2f  W/S=%.1f  fuelFrac=%.3f\n", ...
    %         it, ADP.MTOM, ADP.WingArea, ADP.Span, AR, ADP.WingLoading, fuelFrac);
    % end

    if it > maxIt
        error("Sizing did not converge after %d iterations.", maxIt);
    end
end

out = struct();
out.BlockFuel = BlockFuel;
out.DOC = BlockFuel;
out.ATR = BlockFuel;
end
