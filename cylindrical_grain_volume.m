function [volume] = cylindrical_grain_volume(Do,Di,l)
%cylindrical_grain_volume Volume of a cylindrical grain
Ri = Di/2;
Ro = Do/2;
volume = pi*l*((Ro^2) - (Ri^2));
end

