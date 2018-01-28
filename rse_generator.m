function [rse_file] = rse_generator(time,thrust,mass,cg,diameter,...
    case_weight,throat_diameter,exit_diameter,isp,impulse,classification,...
    motor_length,mass_frac)
%rse_generator Generates a Rocksim XML format engine file
%   Generates a rocksim format engine file that can be used to simulate
%   motors generated
%   This DOES NOT do input sanitization. Odd stuff may happen without
%   proper units. 
%   The first data point must have zero thrust and time but the correct
%   mass and cg points
%   The code assumes that the motor is a reloadable pligged motor. It gives
%   it the manufacturer designation of "UA Wildcat Rocketry". 
%   This output will generate the output ans = [data: null]. Your data is
%   there and the warning can be safely ignored.
%   Inputs:
%   time: An array of time points (s)
%   thrust: Thrust force (N)
%   mass: Mass of the system (propellant + weight) (g)
%   cg: Center of gravity location from nozzle end (mm)
%   diameter: Motor diameter (mm)
%   motor_length: Motor length (mm)
%   case_weight: Weight of the em[ty case (g)
%   throat_diameter: Throat diameter (mm)
%   exit_diameter: Exit diameter (mm)
%   classification: Amature motor classification (string format)
%   mass_frac: Fraction of propellant in the motor
%   Output:
%   rse_file: The name of the file generated 

%While this may look like XML formatting Rocksim wont read true XML. So we
%do this the hard way!

%File naming
rse_file_name = sprintf('%s.rse',classification);
rse_file_name = strrep(rse_file_name,' ','_');
fid = fopen(rse_file_name,'wt');

%Header stuff
fprintf(fid,'<engine-database>\n');
fprintf(fid,'  <engine-list>\n');

%Engine data
fprintf(fid,'    <engine  mfg="UAWR" ');
fprintf(fid,'code="%s" ',classification);
fprintf(fid,'Type="reloadable" ');
fprintf(fid,'dia="%.0f." ',diameter);
fprintf(fid,'len="%.0f."\n',motor_length);
fprintf(fid,'initWt="%.1f" ',mass(1));
fprintf(fid,'propWt="%.2f" ',mass(1) - case_weight);
fprintf(fid,'delays="1000" auto-calc-mass="1"\n');
fprintf(fid,'auto-calc-cg="1" ');
fprintf(fid,'avgThrust="%.2f" ',mean(thrust));
fprintf(fid,'peakThrust="%.2f" ',max(thrust));
fprintf(fid,'throatDia="%.1f"\n',throat_diameter);
fprintf(fid,'exitDia="%.1f" ',exit_diameter);
fprintf(fid,'Itot="%.0f." ',impulse);
fprintf(fid,'burn-time="%.2f" ',time(length(time)));
fprintf(fid,'massFrac="%.2f" ',mass_frac);
fprintf(fid,'Isp="%.2f" \n',isp);
fprintf(fid,'tDiv="20" tStep="-1." tFix="1" FDiv="20" FStep="-1." FFix="1" mDiv="10"\n');
fprintf(fid,'mStep="-1." mFix="1" cgDiv="10" cgStep="-1." cgFix="1">\n');
fprintf(fid,'    <data>\n');

%Need to remove the case mass to get the propellant mass
mass = mass-case_weight;

%Time dependant data
for i = 1:length(time)
    fprintf(fid,'      <eng-data  ');
    fprintf(fid,'t="%.3f" ',time(i));
    fprintf(fid,'f="%.2f" ',thrust(i));
    fprintf(fid,'m="%.2f" ',mass(i));
    fprintf(fid,'cg="%.0f"/>\n',cg(i));
end

%File close and cleanup
fprintf(fid','    </data>\n  </engine>\n</engine-list>\n</engine-database>\n');
rse_file = rse_file_name;
fclose(fid);


% %Header fluff
% docNode = com.mathworks.xml.XMLUtils.createDocument('engine-database');
% engine_list_ode = docNode.createElement('engine-list');
% docNode.getDocumentElement.appendChild(engine_list_ode);
% 
% %This describes the engine
% engine_node = docNode.createElement('engine');
% engine_node.setAttribute('mfg','UA Wildcat Rocktery'); %Manufacturer
% engine_node.setAttribute('code',classification);%Classification
% engine_node.setAttribute('Type','reloadable');%This shouldnt change
% engine_node.setAttribute('dia',sprintf('%.2f',diameter));%Motor diameter
% engine_node.setAttribute('len',sprintf('%.0f',motor_length));%Motor length
% engine_node.setAttribute('initWt',sprintf('%.2f',mass(1)));%Initial weight
% engine_node.setAttribute('propWt',sprintf('%.2f',...
%                             mass(1)-case_weight));%Propellant weight
% engine_node.setAttribute('delays','1000');%Default for plugged motor
% engine_node.setAttribute('auto-calc-mass','1');%We provide mass vs time
% engine_node.setAttribute('auto-calc-cg','1');%We provide cg vs time
% engine_node.setAttribute('avgThrust',sprintf('%.2f',mean(thrust)));
% engine_node.setAttribute('peakThrust',sprintf('%.2f',max(thrust)));
% engine_node.setAttribute('throatDia',sprintf('%.4f',throat_diameter));
% engine_node.setAttribute('exitDia',sprintf('%.4f',exit_diameter));
% engine_node.setAttribute('Itot',sprintf('%.4f',impulse));
% engine_node.setAttribute('burn-time',sprintf('%.4f',time(length(time))));
% engine_node.setAttribute('massFrac',sprintf('%.2f',mass_frac));
% engine_node.setAttribute('Isp',sprintf('%.2f',isp));
% %The rest of these seem to relate to the eng-data reading. The steps are
% %set to -1. My best guess is that the -1 forces the reading program to
% %ignore the rest of the parameters when reading the engine data however the
% %data is required in the header. So here it is.
% engine_node.setAttribute('tDiv','20');
% engine_node.setAttribute('tStep','-1');
% engine_node.setAttribute('tFix','1');
% engine_node.setAttribute('fDiv','20');
% engine_node.setAttribute('fStep','-1');
% engine_node.setAttribute('fFix','1');
% engine_node.setAttribute('mDiv','20');
% engine_node.setAttribute('mStep','-1');
% engine_node.setAttribute('mFix','1');
% engine_node.setAttribute('cgDiv','20');
% engine_node.setAttribute('cgStep','-1');
% engine_node.setAttribute('cgFix','1');
% 
% %Data node start
% data_node = docNode.createElement('data');
% 
% %Need to offset the mass for output
% mass = mass-mass(length(mass));
% 
% %Main data dump loop
% for i = 1:length(time)
%     engine_data_node = docNode.createElement('eng-data');
%     data = sprintf('Hook t="%.3f" f="%.2f" m="%.2f" cg="%.2f"',time(i)...
%                                                 ,thrust(i),mass(i),cg(i));
%     engine_data_node.setTextContent(data);
%     data_node.appendChild(engine_data_node);
% end
% 
% %Link all the nodes back
% engine_list_ode.appendChild(engine_node);
% engine_list_ode.appendChild(data_node);
% 
% %Cleanup fluff Rocksim XML isnt true XML so the output of the Java DOM
% %needs to be modified.
% tmp = xmlwrite(docNode);
% tmp = strrep(tmp,'<?xml version="1.0" encoding="utf-8"?>','');
% tmp = strrep(tmp,'>Hook','');
% tmp = strrep(tmp,'</eng-data>','/>');
% rse_file = strtrim(tmp);
end