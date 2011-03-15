% likelihood of B0 given x0,s,t

% issue - what is good estimator for sigma?

function [L]=likelihood(B0,x0,s,t,sigma)
L=normpdf(B0,expectedB(x0,s,t),sigma);
end