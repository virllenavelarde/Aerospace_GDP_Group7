function weight_metrics_calc()
    % fuel burn
    cruise_fuel_burn = 66496.17; 
    
    % profile
    ac.OEW = 129000;            
    ac.payload = 92000;          
    
   
    % W_end / W_start
    ff_taxi_takeoff = 0.990;     
    ff_climb = 0.980;           
    ff_descent = 0.990;         
    ff_landing = 0.995;          
    
    % equation
    reserves = cruise_fuel_burn * 0.10; 
    ZFW = ac.OEW + ac.payload;
    LW = ZFW + reserves;
    W4 = LW / (ff_descent * ff_landing);
    W3 = W4 + cruise_fuel_burn;
    TOW = W3 / ff_climb;
    RAMP_W = TOW / ff_taxi_takeoff;
    block_fuel = RAMP_W - LW;
    fraction_cruise = W4 / W3;
    total_fuel_fraction = LW / RAMP_W;
    
    % result
    fprintf('fuel burn:%.2f kg\n', cruise_fuel_burn);
    fprintf('Reserves:%.2f kg\n', reserves);
    fprintf('landing weight:%.2f kg\n', LW);
    fprintf('take-off weight:%.2f kg\n', TOW);
    fprintf('block fuel:%.2f kg\n', block_fuel);
    fprintf('fuel fractions:\n');
    fprintf('take_off/climb:%.4f\n', ff_taxi_takeoff * ff_climb);
    fprintf('cruise:%.4f\n', fraction_cruise);
    fprintf('total:%.4f\n', total_fuel_fraction);
end
