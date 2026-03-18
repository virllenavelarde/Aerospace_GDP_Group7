function UpdateAero(obj, x_cg)
    if nargin < 2
        obj.AeroPolar = BoxWing.B777.AeroPolar(obj);
    else
        obj.AeroPolar = BoxWing.B777.AeroPolar(obj, x_cg);
    end
end