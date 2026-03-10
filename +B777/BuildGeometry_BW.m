function [gList,mList] = BuildGeometry_BW(ADP)
    % Box-wing ONLY geometry builder
    
    FuncNames = {'fuselage_bw', 'boxwingmass', 'empenage_bw', 'engine', 'landingGear'};
    
    gList = cast.GeomObj.empty;
    mList = cast.MassObj.empty;
    
    for i = 1:length(FuncNames)
        [gTmp,mTmp] = B777.geom.(FuncNames{i})(ADP);
        
        % Handle single or multiple objects
        if isscalar(gTmp)
            gList(end+1) = gTmp;
        else
            gList = [gList, gTmp];
        end
        
        if isscalar(mTmp)
            mList(end+1) = mTmp;
        else
            mList = [mList, mTmp];
        end
    end
end
