function [GeomObj, massObj] = landingGear(obj)
%LANDINGGEAR  Landing gear for the boxwing freighter.

M_ldg  = obj.MTOM * obj.Mf_Ldg * SI.lb;
L_ldg  = obj.Engine.Diameter * 1.25;
Xwheel = [-0.5,0.25; 0.5,0.25; 0.5,-0.25; -0.5,-0.25];

%% Nose gear
m_nose = 0.125*(1*1.5*M_ldg)^0.566*(L_ldg*SI.ft)^0.845 / SI.lb;
off_n  = [obj.CockpitLength, 0];
GeomObj  = cast.GeomObj(Name="Nose Gear", Xs=Xwheel+off_n);
massObj  = cast.MassObj(Name="Nose Gear", m=m_nose, X=off_n);

%% Main gear
m_main = 0.095*(1*1.5*M_ldg)^0.768*(L_ldg*SI.ft)^0.409 / SI.lb;
off_m  = [obj.x_ac + obj.c_ac*0.52, ...
          obj.CabinRadius + 0.45*obj.Engine.Diameter];

GeomObj(end+1) = cast.GeomObj(Name="Main Gear R", Xs=Xwheel+off_m);
massObj(end+1) = cast.MassObj(Name="Main Gear R", m=m_main, X=off_m);
GeomObj(end+1) = cast.GeomObj(Name="Main Gear L", Xs=Xwheel+off_m.*[1 -1]);
massObj(end+1) = cast.MassObj(Name="Main Gear L", m=m_main, X=off_m.*[1 -1]);
end
