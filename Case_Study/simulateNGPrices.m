function [simNGHourly, simNGDaily] = simulateNGPrices(NGModel, dates, Ntrials, startPrice)
% SIMULATENGPRICES simulates the natural gas price model derived in script
% "ModelNGPrices.m". 
%
% SYNTAX:
% [simNGHourly, simNGDaily] = simulateNGPrices(NGModel, dates, Ntrials, startPrice)
%
% INPUTS:
% * NGModel    : Structure containing Natural Gas model parameters
% * dates      : Vector of hourly dates at which to simulate the model
% * Ntrials    : Number of trials/paths
% * startPrice : Initial price of natural gas price (optional) If not
%                specified, the initial price is set to be the initial
%                value of the HWV model
% OUTPUTS
% * simNGHourly : Ndates-by-Ntrials matrix of simulated natural gas prices.
%                 These are computed by interpolating the daily prices with
%                 a zero-order hold (intraday prices are constant)
% * simNGDaily  : Ndates/24-by-Ntrials matrix of simulated natural gas
%                 prices

% Change start price if specified
if nargin > 3
    NGModel.OUmodel.StartState = log(startPrice);
end

% Simulate model (on daily scale)
NSteps = length(dates)/24;
Xsim = simByEuler(NGModel.OUmodel, NSteps, 'NTrials', Ntrials, 'DeltaTime', NGModel.dt);
simNGDaily = exp(squeeze(Xsim(2:end,:)));

% Convert to hourly scale by repeating each daily observation 24 times
simNGHourly = repmat(simNGDaily(:), 1, 24)';
simNGHourly = reshape(simNGHourly, 24*NSteps, Ntrials);