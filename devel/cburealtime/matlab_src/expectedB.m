% expected value of B given x,s,t

function [B]=expectedB(x,s,t)
% determines slope of function
k0=0.4;
B=s./(1+exp(-(x-t)/k0));
end