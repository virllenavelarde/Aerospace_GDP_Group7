function [L_cargo, D_fuse] = fuselage_sizing(fleet_size)

    % Assumptions: double deck, double aisle. Reference these vales!!!
    no_decks = 2; % number of decks (double deck)
    no_pallets_per_row = 2; % number of pallets per row + clearances
    side_clearance = 0.10; % m, clearance on each side of the pallets
    deck_vertical_clearance = 0.15; % m, clearance between the top of the pallets and the deck above
    floor_thickness = 0.20; % m, thickness of the floor between the lower and upper deck
    t_wall    = 0.20; % m, thickness of the fuselage wall (skin + frames)

    % Number and dimensions of pallets
    N_P6P_total  = 242; % number of P6P pallets
    N_P6Pp_total = 4; % number of P6P+ pallets
    total_N_pallets = N_P6P_total + N_P6Pp_total; % total number of pallets

    L_P6P  = 3.175;   % m, Length of a P6P pallet
    L_P6Pp = 4.978;   % m, Length of a P6P+ pallet
    L_avg = (N_P6P_total*L_P6P + N_P6Pp_total*L_P6Pp) / total_N_pallets; % m, Average pallet length
    W_pallet = 2.435; % m, Width of a pallet (both P6P and P6P+)
    H_pallet = 1.626; % m, Height of a pallet (both P6P and P6P+)

    % Fuselage diameter calculation
    W_int = no_pallets_per_row*W_pallet + (no_pallets_per_row+1)*side_clearance; % m, internal width of the cargo area based on the number of pallets abreast and clearances
    H_int =  no_decks * (H_pallet + deck_vertical_clearance) + floor_thickness; % m, internal height of the cargo area based on the number of decks, pallet height, vertical clearances and floor thickness
    D_fuse = max(W_int, H_int) + 2*t_wall; % m, fuselage diameter 
   
    % Fuselage length calculation
    N_total_pallets_aircraft = total_N_pallets / fleet_size; % Number of pallets per aircraft
    N_stations = ceil(N_total_pallets_aircraft / (no_pallets_per_row*no_decks)); % stations needed to accommodate the pallets, rounded up to the nearest whole number
    L_cargo = N_stations * L_avg; % m, cargo length    

end
