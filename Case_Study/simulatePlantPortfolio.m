function [assetResults, portResults] = simulatePlantPortfolio(assets, startDate, endDate, Ntrials)
% SIMULATEPLANTPORTFOLIO jointly simulates natural gas prices, temperatures
% and electricity prices using the hybrid electricity model and applies the
% optimal dispatch algorithm for each path to generate total profit and
% operation statistics for all simulated natural gas and electricity
% price paths. The distribution of the resulting profits or total cash-flows 
% is analyzed to compute expected cash-flow and cash-flow-at-risk.
% 
% SYNTAX:
% [assetResults, portResults] = simulatePlantPortfolio(assets, startDate, endDate, Ntrials)
%
% "assets" is an Nplant-by-4 matrix of plant capacity, heat rate, VOM costs 
%    and minimum run time with each row corresponding to a plant. 
% "assetResults" is a Nplant-by-6 matrix of 90% and 95% cash-flow-at-risk, 
%    expected earnings/profit, average number of operating days, average percentage 
%    of time running and (expected) average number of hours per operating day 
%    for each plant
% "portResults" is a vector of expected profit, 90% and 95%
%    Cash-flow-at-risk for the overall portfolio

% Load Models & Holidays -------------------------------------------------
wb = waitbar(0, 'Loading models'); c = onCleanup(@()delete(wb));
tempModel = load('SavedModels\TemperatureModel.mat');
NGModel   = load('SavedModels\NGPriceModel.mat');
elecModel = load('SavedModels\ElectricityModel.mat');
holidays  = load('SavedModels\NEholidays.mat');

% Convert dates if necessary ---------------------------------------------
if isnumeric(startDate) && startDate<700000
    startDate = x2mdate(startDate);
    endDate = x2mdate(endDate);
elseif ischar(startDate)
    startDate = datenum(startDate);
    endDate   = datenum(endDate);
end
dates = (datenum(startDate):1/24:datenum(endDate)+23/24)';

% Perform Simulation -----------------------------------------------------
% Initialize variables
blockSize = 100;
earnings  = zeros(size(assets,1),Ntrials);
numOpDays = zeros(size(earnings));
aveHrs = zeros(size(earnings));
pctRun = zeros(size(earnings));

% Simulation is done in blocks of 100 trials to accommodate computers with 
% limited RAM
for i = 0:blockSize:Ntrials-1
    waitbar(.05+.75*i/Ntrials, wb, 'Running Simulation & Dispatch'); % Populate progress bar
    ind = i+1:i+blockSize;
    [earnings(:,ind), numOpDays(:,ind), aveHrs(:,ind), pctRun(:,ind)] = ...
        doSimulation(dates, blockSize, NGModel, tempModel, elecModel, holidays.dates, assets);
end

% Aggregate Results ------------------------------------------------------
waitbar(.9, wb, 'Creating plots');

assetAveEarn = mean(earnings,2);
assetCFaR = [assetAveEarn assetAveEarn] - prctile(earnings',[10 5])';
numOpDays = mean(numOpDays,2);
aveHrs = mean(aveHrs,2);
pctRun = mean(pctRun,2);
assetResults = [assetCFaR assetAveEarn numOpDays pctRun aveHrs];

portEarnings = sum(earnings,1);
portAveEarn = mean(portEarnings);
portCFaR = portAveEarn - prctile(portEarnings, [10 5])';
portResults = [portAveEarn; portCFaR];

% Create Histogram Visualization------------------------------------------
nhist = max(Ntrials/30,10);
fig = figure('Visible','off','Position',[314   370   600   322]);
hist(portEarnings/1e6, nhist);
line(portAveEarn*[1 1]/1e6, ylim, 'Color', 'g');
line((portAveEarn - portCFaR(1))*[1 1]/1e6, ylim, 'Color', 'r', 'LineWidth', 2);
line((portAveEarn - portCFaR(2))*[1 1]/1e6, ylim, 'Color', 'm', 'LineWidth', 2);
legend('Cash-flow Distribution', 'Expected Profit', '90% CFaR', '95% CFaR')
xlabel('Portfolio Cash-flows (Millions of $)');
ylabel('Count');
title('Portfolio Cash-flow Distribution');
print(fig,'-dmeta');
close(fig);

% ----------- Function to perform simulation ------------------------------
function [earnings, numOpDays, aveHrs, pctRun] = ...
        doSimulation(dates, Ntrials, NGModel, tempModel, elecModel, holidays, assets)

% Simulating Temperature
[simTemp, simTempStochastic] = simulateTemperature(tempModel, dates, Ntrials);

% Simulate Natural Gas
simNG = simulateNGPrices(NGModel, dates, Ntrials);

% Simulate Electricity
simElec = simulateElecPrices(elecModel, dates, Ntrials, simTemp, simTempStochastic, simNG, holidays);

% Compute Optimal Dispatch -----------------------------------------------
earnings  = zeros(size(assets,1),Ntrials);
numOpDays = zeros(size(earnings));
aveHrs = zeros(size(earnings));
pctRun = zeros(size(earnings));

for i = 1:size(assets,1)
    for j = 1:Ntrials
        [earnings(i,j), numOpDays(i,j), aveHrs(i,j), pctRun(i,j)] =...
            dispatch(assets(i,1), assets(i,2), assets(i,3), assets(i,4), simElec(:,j), simNG(:,j));
    end
end













% Ensure these functions get pulled in to the compiled archive
%#function classregtree
%#function paretotails
%#function hwv
%#function ProbDistUnivParam
%#function fitDist
%#function cfit
%#function tick2ret