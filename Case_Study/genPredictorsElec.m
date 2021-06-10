function [X, labels] = genPredictorsElec(dates, hour, holidays, NGPrice, Drybulb, tempDeviation)
% GENPREDICTORSELEC generates a set of predictors for modeling electricity
% prices. This is a helper function for script "modelElectricity.m". The
% predictors generated include
% * Drybulb temperature
% * Temperature deviation (actual temperature minus seasonal average)
% * Hour of day
% * Day of week
% * Logical vector indicating if the day is a working day
% * Natural Gas price
% * Previous day Natural Gas price
% * Previous week Natural Gas Price
% 
% SYNTAX:
% [X, labels] = genPredictorsElec(dates, hour, holidays, NGPrice, Drybulb, tempDeviation)
%
% INPUTS:
% * dates         : List of dates (serial dates or cell array of date strings)
% * hour          : Vector of hour corresponding to each date (numeric 0 through 23)
% * holidays      : List of dates corresponding to holidays (serial date or date strings)
% * NGPrice       : Vector of Natural Gas Prices (hourly)
% * DryBulb       : Vector of dry bulb temperatures
% * tempDeviation : Stochastic component of dry bulb temperature (deviation
%                   above seasonal norm/average). If this isn't specified
%                   it is computed using the temperatureModel
% OUTPUTS:
% X      : Ndates-by-8 predictors with one predictor per column
% labels : A cell array of labels describing each predictor

% Convert Dates into a Numeric Representation if necessary
if ~isnumeric(dates)
    dates = datenum(dates, 'mm/dd/yyyy') + (hour-1)/24;
end
holidays = datenum(holidays);

% Holidays
isWorkingDay = ~ismember(floor(dates),holidays) & weekday(dates)>1 & weekday(dates)<7;

% Average temperature and deviation
if nargin < 6
    tempModel = load('SavedModels\TemperatureModel.mat');
    aveTemp = tempModel.m + tempModel.sinmodel(dates);
    tempDeviation = Drybulb - aveTemp;
end

% Natural gas and lagged natural gas predictors
fuelprice = NGPrice;
prevDayFuelPrice = [fuelprice(ones(24,1)); fuelprice(1:end-24,:)];
prevWeekFuelPrice = [fuelprice(ones(168,1)); fuelprice(1:end-168,:)];

% Collect predictors into a single matrix
X = [Drybulb tempDeviation hour weekday(dates) isWorkingDay fuelprice prevDayFuelPrice prevWeekFuelPrice];
labels = {'Temp', 'TempDeviation', 'Hour', 'Weekday', 'IsWorkingDay', 'NGPrice', 'PrevDayNG', 'PrevWeekNG'};
