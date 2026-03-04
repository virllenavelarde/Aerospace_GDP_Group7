function Log = logPolarToStruct(ADP, configName)
%LOGPOLARTOSTRUCT  Collect key aero metrics into a struct you can save to .mat

Log = struct();
Log.Config   = configName;
Log.MTOM_kg  = ADP.MTOM;
Log.MTOM_t   = ADP.MTOM/1e3;
Log.WS_Nm2   = ADP.WingLoading;
Log.WS_lbft2 = ADP.WingLoading * SI.lbft;
Log.S_m2     = ADP.WingArea;
Log.b_m      = ADP.Span;
Log.AR       = ADP.Span^2 / ADP.WingArea;
Log.TW       = ADP.ThrustToWeightRatio;

% Cruise condition point (if present)
if isprop(ADP,'CL_cruise') && ~isempty(ADP.CL_cruise) && isfinite(ADP.CL_cruise)
    Log.CL_cruise = ADP.CL_cruise;
else
    Log.CL_cruise = NaN;
end

% CLmax (clean) if you set it
if isprop(ADP,'CL_max') && ~isempty(ADP.CL_max) && isfinite(ADP.CL_max)
    Log.CL_max_clean = ADP.CL_max;
else
    Log.CL_max_clean = NaN;
end

% Aero polar-derived metrics
if ~isempty(ADP.AeroPolar)
    polar = ADP.AeroPolar;

    % Evaluate over a reasonable CL grid (extend a bit past cruise but not crazy)
    CL = linspace(0, 1.4, 400);
    CD = polar.CD(CL);

    % Basic sanity (avoid division by 0 / negatives if model misbehaves)
    CD(CD <= 0) = NaN;
    LD = CL ./ CD;

    % CD0 estimate
    CD0 = polar.CD(0);

    % Estimate induced drag factor k by fitting CD = CD0 + k CL^2 over small CL range
    fitMask = CL >= 0.05 & CL <= 0.8 & isfinite(CD);
    if nnz(fitMask) >= 10
        p = polyfit(CL(fitMask).^2, (CD(fitMask) - CD0), 1);
        k_est = p(1);
    else
        k_est = NaN;
    end

    % Important points
    [LDmax, iMax] = max(LD);
    CL_LDmax = CL(iMax);
    CD_LDmax = CD(iMax);

    % Cruise point values
    CLc = Log.CL_cruise;
    if isfinite(CLc)
        CDc = polar.CD(CLc);
        LDc = CLc / CDc;

        % induced drag proxy: CDi = CD - CD0 (good if your polar is CD0 + kCL^2-ish)
        CDi_c = CDc - CD0;
    else
        CDc = NaN; LDc = NaN; CDi_c = NaN;
    end

    % Pack results
    Log.Polar.CL = CL;
    Log.Polar.CD = CD;
    Log.Polar.LD = LD;

    Log.CD0      = CD0;
    Log.k_ind    = k_est;

    Log.Cruise.CL  = CLc;
    Log.Cruise.CD  = CDc;
    Log.Cruise.LD  = LDc;
    Log.Cruise.CDi = CDi_c;

    Log.MaxLD.CL  = CL_LDmax;
    Log.MaxLD.CD  = CD_LDmax;
    Log.MaxLD.LD  = LDmax;
    Log.MaxLD.CDi = CD_LDmax - CD0;

else
    Log.Note = "AeroPolar empty -> no polar-derived logging";
end
end
