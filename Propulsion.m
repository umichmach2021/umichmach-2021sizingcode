function [MTOW, thrust] = Propulsion (MTOW, weightWings, weightFuselage, RegConst, AR, thrustToWeight)
   % Estimated weight of the electronic systems 
   % Todo: calculate endurance based on electronic systems and battery
   % capacity
    for k = 0:100
        weight_empty = weight_fuselage + weight_wings + weight_propulsion; %empty weight (N)
        MTOW = weight_empty + sensor .* ((sensorWeight + sensorContainer) .* g); %Max Takeoff weight (N) (pass weigh 3 oz 0.085 kg)
        % thrust = 70;
        thrust = thrust_to_weight*MTOW; %thrust (N) 
        reqPropWeight = (thrust*0.224809 - RegConst(1))/RegConst(2)*4.44822; 
        err = sum(sum(abs(reqPropWeight - weightPropulsion))); %sum of absolute error
        fprintf('err %f\n',err);

        if err < 1e-8
            fprintf('thrust converged after %d\n',k);
            break
        end
        
       weightPropulsion = weightPropulsion + 0.1*((thrust*0.224809 -RegConst(1))/RegConst(2)*4.44822 - weightPropulsion) ;
    end
    
    weight_empty = weight_fuselage + weight_wings + weight_propulsion;
    MTOW = weight_empty + sensor .* ((sensorWeight + sensorContainer) .* g); %Max Takeoff weight (N) (pass weigh 3 oz 0.085 kg)
        % thrust = 70;
end