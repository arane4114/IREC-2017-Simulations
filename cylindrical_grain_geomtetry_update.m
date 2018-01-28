function [new_di,new_l,vol_change,new_volume] = cylindrical_grain_geomtetry_update(Do,Di,l,br,dt,n)
%cylindrical_grain_burn_update Updates bates grains for internal balistics
%   This script accepts the current geometry of a cylindrical grain and
%   computes the change in geometry of the grain 
%Input Arguments
%   Do - Outer grain diameter
%   Di - Inner grain diameter
%   l  - Grain segment length
%   br - Propellant burn rate
%   dt - time change
%   n  - number of burning faces
%Output
%   new_di - new inner grain diameter post burn
%   new__l - new grain length post burn
%   vol_change - volume change during burn

initial_volume = cylindrical_grain_volume(Do,Di,l);
new_l = l - (n*br*dt);
new_di = Di + (2*br*dt);
new_l = max(new_l,0);
new_di = min(new_di,Do);
new_volume = cylindrical_grain_volume(Do,new_di,new_l);
if(new_volume > initial_volume)
    error('Negative volume change occured!')
end
vol_change = initial_volume - new_volume;
end

