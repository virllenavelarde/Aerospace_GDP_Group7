cruiseMach = 0.85;   %defined
cruiseAlt_m = 11500;   %defined (m)
[rho,a,T,P,nu,z,sigma] = cast.atmos(cruiseAlt_m); %temperature at cruise altitude
v_cruise = cruiseMach * a; %m/s

chord = 9.11;  %m (MAC) = 9.109 m, 12.78 root, 0.3 taper, mainly use MAC chord***
Reynolds = v_cruise * chord / nu; % Reynolds number at cruise

disp(cruiseMach);
disp(cruiseAlt_m);
disp(Reynolds);