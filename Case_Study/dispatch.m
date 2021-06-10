function [profit, numOpDays, aveHrs, pctRun, cflows] = dispatch(capacity, heatRate, VOM, minRun, Elec, NG)
% DISPATCH computes optimal daily dispatch decisions for a gas-fired plant
% given its heatRate, VOM costs, minimum runtime and a vector of
% electricity and natural gas prices. Cash-flows arising from these
% operating decision are computed along with operating statistics described
% below.
%
% SYNTAX:
% [profit, numOpDays, aveHrs, pctRun, cflows] = dispatch(capacity, heatRate, VOM, minRun, Elec, NG)
%
% INPUTS:
% capacity : Capacity of power plant in MW
% heatRate : Heat rate of plant in Btu/KWh
% VOM      : Variable operation and maintenance costs in $/MWh
% minRun   : Minimum number of hours the unit must run consecutively
% Elec     : Vector of hourly electricity prices
% NG       : Vector of hourly natural gas prices
% 
% OUTPUTS:
% profit    : Total profit (sum of cash-flows) from operating plant
% numOpDays : Number of profitable operating days
% aveHrs    : Average number of hours run on profitable operating days
% pctRun    : Total percentage of hours run
% cflows    : Vector of cash-flows for every day ($/MW)

% Compute vector of hourly spark spread
spark = Elec - heatRate/1000*NG - VOM;

% Convert into a matrix of 24-by-numDays spark spread
sparkMat = reshape(spark, 24, length(spark)/24);

% For every day (column of spark spread matrix) compute most profitable operating
% decision and return vector of daily cashflows/earnings and daily number of hours run
[cflows, numHrs] = computeOptimalDispatch(sparkMat, minRun);

% Calculate total profit (sum of daily cashflows)
% NOTE: Although not performed here, a true valuation would need to discount each 
% cash-flow by an appropriate factor computed from a risk-free interest rate
profitableDays = cflows > 0; 
profit = sum(cflows(profitableDays))*capacity;

% Calculate operational statistics
numOpDays = sum(profitableDays);
aveHrs = mean(numHrs(profitableDays));
pctRun = sum(numHrs(profitableDays))/length(Elec);
cflows(~profitableDays) = 0;

% Helper Function to compute the best dispatch
function [earnings, numHrs, startTime] = computeOptimalDispatch(sparkMat, minRun)
% For every day (24 hour period) of the spark spread,
% computeOptimalDispatch finds the optimal block of hours greater than
% minRun that produces the most profit. 

P = 25-minRun; % Number of different blocks of hours of length minRun
Y = zeros(P*(P+1)/2, size(sparkMat,2)); % Matrix of all combinations of block for every day
loc = zeros(size(Y,1),2); % Matrix to remember location of each block in Y

% Compute earnings for all P minRun blocks (the minimum block size) this is
% just a sum of hourly spark spreads for each of the P blocks of size
% minRun
temp = filter(ones(minRun,1),1,sparkMat);
Y(1:P,:) = temp(end-P+1:end,:);
loc(1:P,1) = minRun;
loc(1:P,2) = 1:P;

% Now fill in matrix Y for block sizes greater than minRun. Keep track of
% the size and start time of each block in loc
k = P;
for j = 1:P-1 % Loop through block sizes (from minRun+1 to 24)
    Y(k+1:k+P-j,:) = Y(k-P+j:k-1,:) + sparkMat(minRun+j:24,:);
    loc(k+1:k+P-j,1) = minRun+j;
    loc(k+1:k+P-j,2) = 1:P-j;
    k = k+P-j;
end
[earnings, ind] = max(Y); % Find max profit for each day
numHrs = loc(ind,1); % Find block corresponding to max profit for each day
startTime = loc(ind,2);
earnings = earnings';