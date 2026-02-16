%% ECONOMIC EVALUATION
% function DOC(MTOM, no_landings, ICAO_taxi_configuration, no_days_landing, fuel_kerosene_percentage, fuel_SAF_percentage, fuel_consumption_per_flight, total_flight_hours)
% Inputs from other disciplines
MTOM = 270; % tonnes
no_landings = 50; % number of landings per year per aircraft
ICAO_taxi_configuration = 'D'; % ICAO taxi configuration
no_days_landing = 50; % number of days an aircraft is parked at the airport per year
fuel_kerosene_percentage = 0.95; % percentage of fuel that is kerosene
fuel_SAF_percentage = 0.05; % percentage of fuel that is SAF
fuel_consumption_per_flight = 5000; % liters per flight
total_flight_hours = 2000; % total flight hours per year
fleet_size = 10; % number of aircraft in the fleet
no_flights = 50; % number of flights per year per aircraft
% Crew cost
crew_cost_per_year = 150000; % $
crew_members = 4; % number of crew members
crew_cost_per_aircraft = crew_cost_per_year * crew_members; % $ per year
total_crew_cost = crew_cost_per_aircraft * fleet_size; % $ per year

% Landing fees
landing_fee_per_tonne = 25; % $ per tonne
landing_fee_per_aircraft = landing_fee_per_tonne * MTOM; % $ per landing
total_landing_fees = landing_fee_per_aircraft * no_landings * fleet_size; % $ per year

% Parking fees - fees based on the taxi configuration
if ICAO_taxi_configuration == 'C'
    parking_fee_per_day = 1000; % $ per day for configuration C
elseif ICAO_taxi_configuration == 'D'
    parking_fee_per_day = 2000; % $ per day for configuration D
elseif ICAO_taxi_configuration == 'E'
    parking_fee_per_day = 4000; % $ per day for configuration D
elseif ICAO_taxi_configuration == 'F'
    parking_fee_per_day = 6000; % $ per day for configuration D
end
total_parking_fees = parking_fee_per_day * no_days_landing * fleet_size; % $ per year

% Fuel costs
fuel_price_kerosene = 1.00; % $ per liter
fuel_price_SAF = 2.00; % $ per liter
total_fuel_price_per_litre = fuel_price_kerosene * fuel_kerosene_percentage + fuel_price_SAF * fuel_SAF_percentage; % $ per liter
total_fuel_cost = total_fuel_price_per_litre * fuel_consumption_per_flight * fleet_size * no_flights; % $ per year

% Maintenance costs
V_hull = 44800 * MTOM ^ 0.65; % $ hull value
maintenance_fixed_cost = 0.03 * V_hull; % $ fixed maintenance cost per year
maintenance_variable_cost = 5e-06 * V_hull; % $/FH variable maintenance cost per
total_maintenance_cost = maintenance_fixed_cost + maintenance_variable_cost*total_flight_hours; % $ per year

% Insurance costs
total_insurance_cost = 0.005 * V_hull; % $ insurance cost per year

total_DOC = total_crew_cost + total_landing_fees + total_parking_fees + total_fuel_cost + total_maintenance_cost + total_insurance_cost; % $ per year
disp(['Total Direct Operating Cost (DOC) per year: $', num2str(total_DOC)]);

% end