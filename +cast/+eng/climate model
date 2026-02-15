fuel_burn_kg = 17735; 

% CO2 
EI_CO2 = 3.16; 
% NOx 
EI_NOx = 15; 

CO2_kg = fuel_burn_kg * EI_CO2;
NOx_kg = (fuel_burn_kg / 1000) * EI_NOx;

% climate influence
A_CO2 = 1.01e-15; 
A_NOx = 5.16e-13;
ATR100_CO2 = CO2_kg * A_CO2;
ATR100_NOx = NOx_kg * A_NOx;
ATR100_Total = ATR100_CO2 + ATR100_NOx;

fprintf('fuel_burn: %.2f kg\n', fuel_burn_kg);
fprintf('CO2: %.2f kg\n', CO2_kg);
fprintf('NOx: %.2f kg\n', NOx_kg);
fprintf('ATR100:\n');
fprintf('  CO2: %.4e K\n', ATR100_CO2);
fprintf('  NOx: %.4e K\n', ATR100_NOx);
fprintf('  ATR100: %.4e K\n', ATR100_Total);
