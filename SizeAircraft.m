function [wing_ref_area, AR, thrust, MTOW, Cl_takeoff] = SizeAircraft(weight_fuselage, sensor, span_wing, wing_ref_area, num_wings, dens_lin_wing, RegConst, airfoil_Cl_max, delta_Cl, air_density, Takeoff_velocity, thrust_to_weight, sensorWeight, sensorContainerWeight, weight_propulsion)
% Iterative method to solve for wing_ref_area, weight_propulsion, MTOW, weight_empty
% Note: this method is not very sophisticated and prone to error 

for i = 0:1000

    % calculate the wingspan from the aspect ratio and wing reference area
    %span_wing = sqrt(AR .* wing_ref_area); %wingspan (m)
    AR = span_wing.^2./wing_ref_area; %wingspan (m)
    % wing weight in Newtons 
    weight_wings = num_wings*(span_wing*dens_lin_wing);

    [MTOW, thrust, weight_propulsion] = Propulsion (weight_wings, weight_fuselage, RegConst, thrust_to_weight, sensorWeight, sensorContainerWeight, sensor, weight_propulsion);
    
    Cl_stall = airfoil_Cl_max * AR ./ (AR + 2); % finite wing correction 
    Cl_takeoff = Cl_stall/(1.1^2)+delta_Cl; % equation from 481
    wing_area_req = 2*MTOW./(Cl_takeoff .* air_density * (Takeoff_velocity^2)); %required wing area


    err_wing_ref_area = sum(sum(abs(wing_ref_area - wing_area_req)));
    fprintf('err  %d  %f\n ', i, err_wing_ref_area);

    if err_wing_ref_area < 1e-8
        fprintf('wing_ref_area converged after %d\n',i);
        break

    end

    wing_ref_area = wing_ref_area + 0.1*(wing_area_req - wing_ref_area);  %m^2
end


