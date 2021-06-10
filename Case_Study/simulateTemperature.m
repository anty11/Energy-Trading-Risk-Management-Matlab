function [simTemp, simStochastic, simInnovations] = simulateTemperature(tempModel, dates, Ntrials)
% SIMULATETEMPERATURE simulates the temperature model derived in script
% "ModelTemperature.m". 
%
% SYNTAX:
% [simTemp, simStochastic, simInnovations] = simulateTemperature(tempModel, dates, Ntrials)
%
% INPUTS:
% * tempModel  : Structure containing Temperature model parameters
% * dates      : Vector of hourly dates at which to simulate the model
% * Ntrials    : Number of trials/paths
% 
% OUTPUTS
% * simTemp        : Ndates-by-Ntrials matrix of simulated temperatures
% * simStochastic  : Ndates-by-Ntrials matrix of stochastic component of simulated 
%                    temperature (deviations from deterministic seasonal temperature)
% * simInnovations : Ndates-by-Ntrials matrix of samples from probability
%                    distribution (which drive the stochastic linear regression series)

% 1. Generate Innovations (sample from distribution)
simInnovations = random(tempModel.dist, length(dates), Ntrials);

% 2. Compute stochastic component (regression on Innovations)
offset = tempModel.reglags(end);
simStochastic = zeros(length(dates)+tempModel.reglags(end), Ntrials);
simStochastic(1:offset,:) = repmat(tempModel.presample,1,Ntrials);
for i = offset+1:length(simStochastic)
    simStochastic(i,:) = tempModel.regbeta' * simStochastic(i-tempModel.reglags,:) + simInnovations(i-offset,:);
end
simStochastic(1:offset,:) = [];

% 3. Compute deterministic component and final simluation
% Use BSXFUN to add single column of deterministic component to each column
% of stochastic component.
simTemp = bsxfun(@plus, simStochastic, tempModel.m + tempModel.sinmodel(dates));
