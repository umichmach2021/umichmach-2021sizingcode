% ===========================================================
%                                         .:,:`           
%                                      `:,:               
%     ...       ...     `;;;          :,,     ;;;     ,;; 
%     ,,,:     ,,,,     ####        `,,:      ###     ;## 
%     ,,,,,   .,,,,     #####      `,,:       ###     ;## 
%     ,,,,,. `,,,,,    +##+##      ,,,        ###     ;## 
%     ,,,,,, ,,,,,,    ### ###    ,,,.        ###     ;## 
%     ,,, ,,,,, ,,,   .##` ###   ,,,,  #+     ########### 
%     ,,,  ,,,  ,,,   ###  `##;  *######+.,,,,########### 
%     ,,,  `,.  ,,,   ###   ###   ::,       .,,:.     :## 
%     ,,,   `   ,,,  ##########.  :,,         '`,,,,, ;## 
%     ,,,       ,,,  ###########   ,,,        ##@.,,,,, # 
%     ,,,       ,,, .##;     ###    ,,        ###  ,,,,,` 
%     ,,,       ,,: ###       ###    :,       ###  :,,,,, 
%                                   `:                 
% ===========================================================
%
% SUMMARY: Scoring analysis for the 2020-2021 DBF competition

%% Initialization
% close all
clear all
close all
clc

%% =========================== Unit Conversions ============================= %%

in2m = 0.0254; %inches to meters
ft2m = in2m * 12; %feet to meters
kg2N = 9.81; % Convert kg to newtons
oz2kg = 0.0283495; % Convert ounces to kg

%% =========================== Variables and Constants ===================================== %%
n = 60; % Number of test cases to run
g = 9.81; % Accleration due to gravity in m/s^2

% Wing Properties
span_wing = linspace(54, 54, n)*in2m; % Wingspan vector converted from inches to meters. 2021 competition states max 5ft wingspan. 54 inches accounts for 6 inch fuselage thickness
num_wings = 1; % Number of wings
wing_ref_area = 0.4; % inital guess for wing area (m^2)
dens_lin_wing = (0.2875 * 0.0283495 * g / in2m);  % density N/m

% Fuselage Properties
weight_fuselage_initial = 23; % Empty fuselage weight guess in Newtons (Does not include wings, payloads, or propulsion system)
weight_fuselage = weight_fuselage_initial; % Sets up place holder for fuselage weight iterations
weight_propulsion = 18; % inital guess for Propulsion System weight in Newtons

% Proplusion Properties
weight_propulsion = 18; % inital guess for Propulsion System weight in Newtons
RegConst = [-0.823411250229396;4.34939493516460]; % Regression constants from proplusion trade study

% Desired and Approximated Aerodynamic Properties
thrust_to_weight = 0.6; % Desired thrust to weight ratio
Takeoff_velocity = 15; % Desired takeoff velocity in m/s
CD_0 = 0.06; % Zero-lift drag coefficient guess (CFD model approximation would be better)
taperR = 1.0; % Taper ratio used to calculate Oswald efficiency factor
mu = 0.02;  % Dynamic viscosity
airfoil_Cl_max = 1.46; % Maximum lift coefficient for chosen BOE103
delta_Cl = 0.6*cosd(-10); % delta cl due to flaps: Raymer 279, 0.6 = Ratio of flapped area and total area
Cf = 0.006; % Coefficient of skin friction (Need a serious evaluation over how feasible this is)

% Course Properties
lap_length = 4000 * ft2m; % Approximate course length in feet converted to meters
air_density = 1.12; % Air density in Tucson, AZ



%% ================ Payload ======================= %%
% To meet competition criteria, minimum Length/Diameter ratio for the
% sensor is 4 where the minimum diameter is 1 inch
n_sensors = 6; % Maximum number of sensors that our aircraft could feasible carry
max_sensor_length = 24; % Maximum sensor length value to evaluate in inches
min_sensor_length = 8; % Minimum sensor length value to evaluate in inches
min_sensor_length = min_sensor_length * in2m;
max_sensor_length = max_sensor_length * in2m;
% min_sensor_mass = 8; % Minimum sensor mass in ounces (Would be better to get a linear density plot instead of a guess)
% max_sensor_mass = 18; % Maximum sensor mass in ounces (Would be better to get a linear density plot instead)
min_container_mass = min_sensor_length * 0.0016129 * 2000; % Minimum sensor container mass in kg based on linear density model 2000 kg/m3 carbon fiber
max_container_mass = max_sensor_length * 0.0016129 * 2000; % Maximum sensor container mass in kg based on linear density model 2000 kg/m3 carbon fiber 

min_sensor_mass = .220 + (min_sensor_length * pi * (0.03175.^2 - 0.028575.^2) * 1530);
max_sensor_mass = .220 + (max_sensor_length * pi * (0.03175.^2 - 0.028575.^2) * 1530);% 1530 references density of ABS in kg/m3
min_sensor_mass = min_sensor_mass * kg2N; % Not actually mass, it's N
max_sensor_mass = max_sensor_mass * kg2N; % Not actually mass, it's N
min_container_mass = min_container_mass * kg2N; % Not actually mass, it's N
max_container_mass = max_container_mass * kg2N; % Not actually mass, it's N
sensor_length = linspace(6,12,n);
sensor_weight = linspace(min_sensor_mass, max_sensor_mass, n);
sensor_container_weight = linspace(min_container_mass, max_container_mass, n);

% [sensor_length,sensor_weight,sensor_container_weight] = Payload(n, max_sensor_length, min_sensor_length,max_sensor_mass,min_sensor_mass,min_container_mass,max_container_mass);

%% ========== MTOW ========== %%

sensor = linspace(1, n_sensors, n); % Generates vector for number of sensors carried by aircraft versus test cases
[span_wing, sensor] = meshgrid(span_wing, sensor); % Creates matrix relating cases for each wingspan/sensor configuration
[wing_ref_area, AR, thrust, MTOW, Cl_takeoff, weight_propulsion] = SizeAircraftNew(span_wing, wing_ref_area, num_wings, dens_lin_wing, weight_fuselage, weight_propulsion, sensor_weight, sensor_container_weight, thrust_to_weight, RegConst, airfoil_Cl_max, delta_Cl, air_density, Takeoff_velocity, sensor);

%% ========== Takeoff ========== %%

[wing_ref_area,takeoff_dist,e] = Takeoff(mu,taperR,AR,MTOW,thrust,air_density,wing_ref_area,Cl_takeoff,CD_0,g,Takeoff_velocity)

%% ========= Cruise Velocity ========== %%

[v_cruise] = CruiseVelocity(thrust_to_weight, MTOW, air_density, wing_ref_area, CD_0, AR, span_wing, sensor, e, Cf);

%% ========== Lap Times ========== %%

[laps_10min,t_3laps] = lapTime(v_cruise,lap_length);

%% ========== Realism =========== %%
for i = 1:n
    for j = 1:n
        if AR(i,j) < 4
            AR(i,j) = NaN;
            MTOW(i,j) = NaN;
            wing_ref_area(i,j) = NaN;
            thrust(i,j) = NaN;
        end
    end
end
%% ========== Score ========== %%

[score, M1, M2, M3] = Scoring(sensor, t_3laps, laps_10min, sensor_length, sensor_weight);

%% ========= Plotting ========== %%
fprintf('The code has run successfully!')


% Score as a function of AR and sensor count
figure(1)
shading interp;
[ANALY2 , ANALY2] = contourf(sensor, AR, score);
set(ANALY2,'edgecolor','none');
title('Aspect Ratio and Sensor Analysis','FontSize',20);
ylabel('AR','FontSize',32,'FontWeight','bold');
xlabel('# Sensors','FontSize',32,'FontWeight','bold');
hold on 
set(gca,'fontsize',20)
c = colorbar;
c.Label.String = 'Normalized Score';
c.Label.FontSize = 16

% Score as a function of sensor weight and length
figure(2)
contourf(sensor_weight,sensor_length, score);
ylabel('Sensor Length (m)','FontSize',20);
xlabel('Sensor Weight (N)','FontSize',20);
title('Sensor Design Analysis','FontSize',20);
hold on
c = colorbar;
c.Label.String = 'Normalized Score';
c.Label.FontSize = 16

% Score as a function of sensor length and sensor number
sensor_length_matrix = zeros(size(sensor));
for p = 1:n
    sensor_length_matrix(p,:) = sensor_length;
end
figure(3)
contourf(sensor, sensor_length_matrix, score);
ylabel('Sensor Length (m)','FontSize',20);
xlabel('# Sensors','FontSize',20);
title('Sensor Quantity Analysis','FontSize',20);
hold on
c = colorbar;
c.Label.String = 'Normalized Score';
c.Label.FontSize = 16