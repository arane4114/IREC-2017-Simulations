%IREC 2017 Internal Balistics Stricp
%This script models the internal balistics for a motor till the depletion
%of fuel
%Author: Abhishek Rane

clc
clear
close all

fprintf('Internal Balistics code for IREC\n')

%Matlab Enviornment
%Release: R2016b

%File Dependencies
%   cylindrical_grain_burn_area.m
%   cylindrical_grain_geomtetry_update.m
%   cylindrical_grain_volume.m

%Grain geometry
grain_count = 5;
grain_Do = [3.387,3.387,3.35,3.35,3.35];%Outer Diameter (in) 
grain_length = [12,6,6,6,6];%Length (in)
grain_Di = [1.5,1.59,1.6,1.685,1.7];%Inner Diammmmeter(in)  
grain_burning_ends = [2,2,2,2,2];%Burning faces
propellant_density = 0.061456;%lbs/in^3
grain_volume = zeros(1,grain_count);%in^3
grain_centerpoint = zeros(1,grain_count);%in measured from the base (noz)
grain_initial_length = sum(grain_length);
for i = 1:grain_count
    grain_volume(i) = cylindrical_grain_volume(grain_Do(i),grain_Di(i),...
                                               grain_length(i));
    grain_centerpoint(i) = (grain_length(i)*i) - (grain_length(i)/2);
end
grain_weight = grain_volume.*propellant_density;
grain_centerpoint = grain_centerpoint + 1.9685;%Offset by about 50 mm for nozzle
%Comment this out to measure from the head
%grain_centerpoint = fliplr(grain_centerpoint);


%Case data
case_mass = 11.41;%lbm
case_centerpoint = (39.3701)/2; %1 meter case
case_cg_data = case_mass*case_centerpoint;%lbm*in, used for CG 

%Propellant Model
%Data is generated in the static fire analysis script
Pc_via_kn = @(kn) 2.725060*kn - 236.099212;
Br_via_kn = @(kn) 0.000366*kn + 0.083967;
ISP = 200;%Estimate

%Simulation Settings
sim_timestep = 0.001;%Simulation time step

%Nozzle geometry
nozzle_throat_diameter = 0.95;%In
nozzle_throat_area = pi*(nozzle_throat_diameter/2)^2;
nozzle_converging_entrance_diameter = 2.5;
nozzle_converging_entrance_area =  pi*...
                                (nozzle_converging_entrance_diameter/2)^2;
nozzle_cf = 1.5;%Estimate, due to high cf
nozzle_entrance_id = grain_count + 1;%Used for mdot data storage
nozzle_throat_id = grain_count + 2;
nozzle_exit_diameter = 2.35;%In

%Output options [1 = enable, 0 = disable]
output_rse = 1;%Generates rocksim file
output_pressure = 1;%Generates pressure vs time curve
output_thrust = 1;%Generates thrust vs time curve
output_mass_flow = 1;%Generates mdot/area vs time curve
output_mass_generated = 1;%Generates mass generated per grain vs time curve
output_port_to_throat = 1;%Generates port to throat vs time per grain curve
output_l_Star = 1;%Generates l* vs time curve
output_system_mass = 1;%Generates system mass vs time curve
output_cg = 1;%Generates cg vs time curve

%Start of sim loop
run_loop_flag = 1;
sim_grain_current_id = grain_Di;
sim_grain_current_length = grain_length;
sim_current_area = zeros(1,grain_count);
sim_current_volume_change = zeros(1,grain_count);
sim_current_mass_generated = zeros(1,grain_count);
sim_current_mass_flowing = zeros(1,grain_count);
sim_current_free_volume = zeros(1,grain_count+1);
sim_current_grain_mass = zeros(1,grain_count);
sim_current_grain_cg = zeros(1,grain_count);
sim_current_time = 0.0;
sim_diff_checker = 0.0;

results_lbms_to_ns = 4.44822162;%Lbm*s tp N*s
results_lbm_to_g = 453.592;%Lbm to gram
results_in_to_mm = 25.4;%inches to mm
results_time = zeros(1,1);
results_mass_genrated_overall = zeros(1,1);
results_mass_generated_per_grain= zeros(1,1);%(Simstep, grainid)
results_port_to_throat = zeros(1,1);%(simstep,grainid)
results_mass_flow_per_area_grain = zeros(1,1);%(Simstep,grainid)
results_loop_iterator = 1;
results_burn_area = zeros(1,1);
results_burn_rate = zeros(1,1);
results_chamber_pressure = zeros(1,1);
results_kn = zeros(1,1);
results_l_star = zeros(1,1);
results_system_mass = zeros(1,1);
results_system_cg = zeros(1,1);
results_burnout = zeros(1,grain_count);

%Initialize a few datapoints
results_system_mass(1) = sum(grain_weight) + case_mass;
sim_current_grain_cg(grain_count + 1) = case_cg_data;
for i = 1:grain_count
    sim_current_grain_cg(i) = grain_weight(i) *...
        grain_centerpoint(i);
end
results_system_cg(results_loop_iterator) = sum(sim_current_grain_cg)/...
    results_system_mass(results_loop_iterator);

while run_loop_flag == 1
    
    results_loop_iterator = results_loop_iterator + 1;
    
    %Part 1
    %Generate and save current geometry based data
    sim_current_time = sim_current_time + sim_timestep;
    for i = 1:grain_count
        sim_current_area(i) = cylindrical_grain_burn_area(grain_Do(i),...
            sim_grain_current_id(i),...
            sim_grain_current_length(i),...
            grain_burning_ends(i));
        sim_current_area(i) = max(sim_current_area(i),0);
    end
    sim_motor_available_area = sum(sim_current_area);
    sim_current_kn = sim_motor_available_area/nozzle_throat_area;
    sim_current_pressure = Pc_via_kn(sim_current_kn);
    sim_current_br = Br_via_kn(sim_current_kn);
    results_time(results_loop_iterator) = sim_current_time;
    results_burn_area(results_loop_iterator) = sim_motor_available_area;
    results_chamber_pressure(results_loop_iterator) = sim_current_pressure;
    results_burn_rate(results_loop_iterator) = sim_current_br;
    
    %Part 2
    %Regress grains and calculate the mass flow. Save said data and update
    %the sim state
    for i = 1:grain_count
        [new_di,new_l,vol_change,new_voluume] = ...
            cylindrical_grain_geomtetry_update...
            (grain_Do(i),...
            sim_grain_current_id(i),...
            sim_grain_current_length(i),...
            sim_current_br,...
            sim_timestep,...
            grain_burning_ends(i));
        sim_current_volume_change(i) = vol_change;
        sim_current_mass_generated(i) = sim_current_volume_change(i)*...
            propellant_density;
        results_mass_generated_per_grain(results_loop_iterator,i) = ...
            sim_current_mass_generated(i);
        sim_grain_current_id(i) = new_di;
        sim_grain_current_length(i) = new_l;
        sim_current_grain_mass(i) = new_voluume*propellant_density;
    end
    
    %Part 3
    %Get the mass flowing per each grain
    sim_current_mass_flowing(1) = sim_current_mass_generated(1);
    for i = 2:grain_count
        sim_current_mass_flowing(i) = sim_current_mass_flowing(i-1) + ...
                              sim_current_mass_generated(i);
    end
    
    sim_current_mass_flowing = sim_current_mass_flowing./sim_timestep;
    
    %Part 4
    %Calculate the port to throat ratio
    for i = 1:grain_count
        if i == grain_count
            ratio = (pi*(sim_grain_current_id(i)/2)^2)/nozzle_throat_area;
            results_port_to_throat(results_loop_iterator,i) = ratio;
        else
           ratio = (pi*(sim_grain_current_id(i)/2)^2)/...
                   (pi*(sim_grain_current_id(i+1)/2)^2);
           results_port_to_throat(results_loop_iterator,i) = ratio;         
        end
    end
    
    %Part 5
    %Calculate the mass flow over area at various locations in the motor
    for i = 1:grain_count
        results_mass_flow_per_area_grain(results_loop_iterator,i) = ...
                sim_current_mass_flowing(i)/...
                (pi*(sim_grain_current_id(i)/2)^2);
    end
    results_mass_flow_per_area_grain(results_loop_iterator,...
        nozzle_entrance_id) = ...
        sim_current_mass_flowing(i)/...
        nozzle_converging_entrance_area;
    results_mass_flow_per_area_grain(results_loop_iterator,...
        nozzle_throat_id) = ...
        sim_current_mass_flowing(i)/...
        nozzle_throat_area;
    
    %Part 6
    %Calculate the l star at the current point in the sim
    for i = 1:grain_count
        sim_current_free_volume = sim_grain_current_length(i) * ...
            pi * (sim_grain_current_id(i)/2)^2;
    end
    sim_free_length = grain_initial_length - ...%TODO
        sum(sim_grain_current_length);
    sim_current_free_volume(grain_count+1) = sim_free_length*pi*...
            (grain_Do(i)/2)^2;
    results_l_star(results_loop_iterator) = sum(sim_current_free_volume)...
        /nozzle_throat_area;
    
    %Part 7
    %Calculate the current mass and center of gravity for rocksim
    for i = 1:grain_count
        sim_current_grain_cg(i) = sim_current_grain_mass(i) *...
            grain_centerpoint(i);
    end
    results_system_mass(results_loop_iterator) = ...
        sum(sim_current_grain_mass) + case_mass;
    results_system_cg(results_loop_iterator) = sum(sim_current_grain_cg)/...
                              results_system_mass(results_loop_iterator);
    
    %Part 8
    %Calculate burnout locations
    for i = 1:grain_count
        if((sim_current_grain_mass(i) + results_burnout(i)) == 0)
            results_burnout(i) = results_time(results_loop_iterator);
        end
    end
                          
    %Check end conditions. Once the inner diameter equals the outer
    %diameter we can end the burn.
    sim_diff_checker = sum(grain_Do - sim_grain_current_id);
    if sim_diff_checker == 0
        run_loop_flag = 0;
    end
end
results_thrust = (nozzle_cf*nozzle_throat_area).*results_chamber_pressure;
results_inpulse = trapz(results_time,results_thrust);
results_subplot_size = grain_count/2;

fprintf('Simulation exited nominally after %.0f iterations!\n',...
    results_loop_iterator);
fprintf('Motor Stats:\n');
fprintf('Weight: %.2f (lbs)\n',sum(grain_weight));
fprintf('Impulse: %.2f (lbf*s)\n',results_inpulse);
fprintf('Max pressure: %.2f (psi)\n',max(results_chamber_pressure));
fprintf('Max thrust: %.2f (lbf)\n',max(results_thrust));
fprintf('Average thrust: %.2f (lbf)\n',mean(results_thrust));
fprintf('Classification: N%.0f-P\n',mean(results_thrust)*...
                                    results_lbms_to_ns);

fprintf('\nGrain Data\n');
fprintf('Id\tWeight (lbm)\tBurnout Time (s)\n')
for i = 1:grain_count
    fprintf('%.0f\t%.2f\t\t%.3f\n',i,grain_weight(i),results_burnout(i));
end

if output_rse == 1
    %Generate Rocksim Eng file here
    fprintf('\nCreating Rocksim XML file\n');
    rse_system_mass = results_system_mass*results_lbm_to_g;%Convert to g
    rse_thrust = results_thrust * results_lbms_to_ns;%Convert to Ns
    rse_system_cg = results_system_cg*results_in_to_mm;%convert to mm
    rse_system_diameter = 98;%98 mm form factor
    rse_case_mass = case_mass*results_lbm_to_g;
    rse_throat_diameter = nozzle_throat_diameter*results_in_to_mm;
    rse_exit_diameter = nozzle_exit_diameter*results_in_to_mm;
    rse_isp = ISP;
    rse_impulse = results_inpulse*results_lbms_to_ns;
    rse_classification = sprintf('N%.0f-P',mean(results_thrust)*...
                                    results_lbms_to_ns);
    for i = 1:grain_count
        rse_classification = strcat(rse_classification,...
            sprintf(' (%.2f-%d)',grain_Di(i),grain_burning_ends(i)));
    end
    rse_motor_length = 1000;
    rse_mass_fraction = 64.67;%I dont think this does anything
    rse_file  = rse_generator(results_time,rse_thrust,rse_system_mass,...
                rse_system_cg,rse_system_diameter,rse_case_mass,...
                rse_throat_diameter,rse_exit_diameter,rse_isp,...
                rse_impulse,rse_classification,rse_motor_length,...
                rse_mass_fraction);
    fprintf('Rocksim file saved to "%s"\n',rse_file);                          
end

if output_pressure == 1
    plot(results_time,results_chamber_pressure,'linewidth',2);
    xlabel('Time (s)')
    ylabel('Pressure (psi)')
    title('Pressure vs Time (Overall)')
end

if output_thrust == 1
    figure
    hold on
    plot(results_time,results_thrust,'linewidth',2);
    xlabel('Time (s)')
    ylabel('Thrust (lbf)')
    title('Thrust vs Time (Overall)')
    grid on
    grid minor
    hold off
end

if output_mass_flow == 1
    figure
    hold on
    for i = 1:grain_count
        plot(results_time,results_mass_flow_per_area_grain(:,i),...
            'DisplayName',sprintf('Grain %.0f',i),'linewidth',2);
    end
    plot(results_time,results_mass_flow_per_area_grain(:,nozzle_entrance_id),...
        'DisplayName','Nozzle entrance','linewidth',2);
    plot(results_time,results_mass_flow_per_area_grain(:,nozzle_throat_id),...
        'DisplayName','Nozzle throat','linewidth',2);
    plot(get(gca,'xlim'), [1.25 1.25],'DisplayName','1.25 lbm/s/in^2',...
        'linewidth',2);
    plot(get(gca,'xlim'), [1.5 1.5],'DisplayName','1.5 lbm/s/in^2',...
        'linewidth',2);
    title('Mass flow over port vs time')
    ylabel('Mass flow over port (lbm/s/in^2)')
    xlabel('Time (s)')
    legend('show')
    hold off
end

if output_mass_generated == 1
    figure
    hold on
    for i = 1:grain_count
        plot(results_time,results_mass_generated_per_grain(:,i),...
            'DisplayName',sprintf('Grain %.0f',grain_Di(i),'linewidth',2));
    end
    title('Mass generated per grain vs time')
    ylabel('Mass generated (lbm)')
    xlabel('Time (s)')
    legend('show')
    hold off
end

if output_port_to_throat == 1
    figure
    hold on
    for i = 1:grain_count
        plot(results_time,results_port_to_throat(:,i),...
            'DisplayName',sprintf('Grain %.0f',i),'linewidth',2);
    end
    title('Port to throat ratio vs time')
    ylabel('Port to throat ratio')
    xlabel('Time (s)')
    legend('show')
    hold off
end

if output_l_Star == 1
    figure
    hold on
    plot(results_time,results_l_star,'DisplayName','Overall L*'...
        ,'linewidth',2);
    plot(get(gca,'xlim'), [100 100],'DisplayName','Mimimum Al L*'...
        ,'linewidth',2);
    title('L* vs time')
    ylabel('L* (in)')
    xlabel('Time (s)')
    legend('show')
    hold off
end

if output_system_mass == 1
    figure
    hold on
    plot(results_time,results_system_mass,'linewidth',2);
    title('System mass vs time')
    ylabel('Mass (lbm)')
    xlabel('Time (s)')
    hold off
end

if output_cg == 1
    figure
    hold on
    plot(results_time,results_system_cg,'linewidth',2);
    title('CG vs time')
    ylabel('CG (in)')
    xlabel('Time (s)')
    hold off
end