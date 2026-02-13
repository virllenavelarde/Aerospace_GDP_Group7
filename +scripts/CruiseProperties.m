cruiseMach = 0.85;   %defined
cruiseAlt_m = 11500;   %defined (m)
[rho,a,T,P,nu,z,sigma] = cast.atmos(cruiseAlt_m); %temperature at cruise altitude
v_cruise = cruiseMach * a; %m/s

chord = ;
Reynolds = v_cruise * chord / nu; % Reynolds number at cruise

disp(cruiseMach);
disp(cruiseAlt_m);
disp(Reynolds);

