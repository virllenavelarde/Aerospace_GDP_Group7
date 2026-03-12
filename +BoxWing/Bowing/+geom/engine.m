function [GeomObj, massObj] = engine(obj)
%ENGINE  UltraFan engines mounted under the rear wing.

obj.Engine = cast.eng.TurboFan.UltraFan(1, obj.TLAR.Alt_cruise, obj.TLAR.M_c);
obj.Engine = obj.Engine.Rubberise(obj.Thrust / 2);

%% Geometry
Xs  = [-0.5,0.5; 0.5,0.5; 0.5,-0.5; -0.5,-0.5] ...
      .* [obj.Engine.Length, obj.Engine.Diameter];
off = [obj.RearWingPos - obj.Engine.Length*0.3, ...
       obj.CabinRadius  + 1.60*obj.Engine.Diameter];

GeomObj    = cast.GeomObj(Name="Engine Right", Xs=Xs+off);
GeomObj(2) = cast.GeomObj(Name="Engine Left",  Xs=Xs+off.*[1 -1]);

%% Mass  (Raymer 15.52 installation + 15% composite saving)
m_pyl = 1.0*(2.575*(obj.Engine.Mass*SI.lb)^0.922)/SI.lb - obj.Engine.Mass;
m_pyl = m_pyl * 0.85; % this is with tha K_mat 
offP  = off + [obj.Engine.Length/2, 0];

massObj        = cast.MassObj(Name="Engine Right",       m=obj.Engine.Mass, X=off);
massObj(end+1) = cast.MassObj(Name="Engine Pylon Right", m=m_pyl,           X=offP);
massObj(end+1) = cast.MassObj(Name="Engine Left",        m=obj.Engine.Mass, X=off.*[1 -1]);
massObj(end+1) = cast.MassObj(Name="Engine Pylon Left",  m=m_pyl,           X=offP.*[1 -1]);
end
