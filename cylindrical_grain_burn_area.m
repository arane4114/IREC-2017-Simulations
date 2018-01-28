function [Ab] = cylindrical_grain_burn_area(Do,Di,l,n)
%cylindrical_grain_burn_area Provides the current burn surface area for a
%cylindrical grain
%   This function provides the burn surface area for a cylindrical grain
%   when provided its geometry. No propellant charactersitics are used
%   here.
%Input arguments
%   Do - Grain outer diameter
%   Di - Grain inner diameter
%   l  - Grain segment length
%   n  - Number of burning faces

if n < 0 || n > 2
    error('Number of burning faces must be between 0 and 2')
end

Ab_face = n*pi*((Do/2)^2 - (Di/2)^2);           
Ab_inner = 2*pi*(Di/2)*l;                      

Ab = Ab_face + Ab_inner;
end

