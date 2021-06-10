function [simElec, simStochastic, simInnovations] = simulateElecPrices(elecModel, dates, Ntrials, simTemp, simTempStochastic, simNG, holidays)
% SIMULATEELECPRICES simulates the electricity price model derived in script
% "ModelElecPrices.m". 
%
% SYNTAX:
% [simElec, simStochastic, simInnovations] = simulateElecPrices(elecModel, dates, Ntrials, simTemp, simTempStochastic, simNG, holidays)
%
% INPUTS:
% * elecModel: Structure containing Electricity model parameters
% * dates    : Vector of dates at which to simulate the model
% * Ntrials  : Number of trials/paths
% * simTemp  : Ndates-by-Ntrials matrix of simulated temperatures
% * simTempStochastic: Ndates-by-Ntrials matrix of stochastic component of
%                      temperature (deviations above seasonal average)
% * simNG    : Ndates-by-Ntrials matrix of simulated Natural Gas Prices
% * holidays : Vector of holidays that span date range
%
% OUTPUTS
% * simElec        : Ndates-by-Ntrials matrix of simulated electricity prices
% * simStochastic  : Ndates-by-Ntrials matrix of stochastic component 
% * simInnovations : Ndates-by-Ntrials matrix of independent draws from probability distribution

% 1. Generate all Innovations (from distribution)
simInnovations = random(elecModel.dist, length(dates), Ntrials);

% 2. Compute stochastic component with linear regression
offset = elecModel.reglags(end);
simStochastic = zeros(length(dates)+elecModel.reglags(end),Ntrials);
simStochastic(1:offset,:) = repmat(elecModel.presample,1,Ntrials);
for i = offset+1:size(simStochastic,1)
    simStochastic(i,:) = elecModel.regbeta' * simStochastic(i-elecModel.reglags,:) + simInnovations(i-offset,:);
end
simStochastic(1:offset,:) = [];

% 3. Compute deterministic component (regression tree)
hour = round((dates - floor(dates))*24)+1;
% Compute static columns of predictor matrix (hour, weekday, holidays)
X = genPredictorsElec(dates, hour, holidays, simNG(:,1), simTemp(:,1), simTempStochastic(:,1));
% Initialize output matrix
simElec = zeros(length(dates),Ntrials);
for i = 1:Ntrials % For each column/trial
    % Compute dynamic components of predictor matrix (NG prices and temp predictors)
    X(:,[1 2 6 7 8]) = [simTemp(:,i) simTempStochastic(:,i) ...
        simNG(:,i) [simNG(ones(24,1),i);simNG(1:end-24,i)], [simNG(ones(168,1),i);simNG(1:end-168,i)] ];
    % Evaluate Tree model
    simElec(:,i) = elecModel.treemodel(X);
end

% 4. Add stocahstic and deterministic components and exponentiate
simElec = exp(simElec + simStochastic);
