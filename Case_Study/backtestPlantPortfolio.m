function [results, earnings] = backtestPlantPortfolio(assets, startDate, endDate)
% BACKTESTPLANTPORTFOLIO applies the simple dispatch algorithm on
% historical natural gas and electricity prices (imported from Database)
% and computes operational statistics and cash-flows. This function is
% called from the PlantRiskTool Excel spreadsheet.
%
% SYNTAX:
% [results, earnings] = backtestPlantPortfolio(assets, startDate, endDate)
%
% "assets" is an Nplant-by-4 matrix of plant capacity, heat rate, VOM costs 
%    and minimum run time with each row corresponding to a plant. 
% "results" is a Nplant-by-4 matrix of total profit, number of operating
%    days, percentage of time running and average number of hours per
%    operating day for each plant
% "earnings" is an Nplants-by-Ndates matrix of profits/cash-flows for each p
%    plant for each day

% Convert date formats if required
if isnumeric(startDate) && startDate<700000
    startDate = x2mdate(startDate);
    endDate = x2mdate(endDate);
end

% Fetch data from Access database for specified date range
try
    data = fetchDBElecData(startDate, endDate);
    Elec = data.ElecPrice;
    NG = data.NGPrice;
catch ME
    if isdeployed
        errordlg(sprintf('Error fetching data. Check date ranges: %s', ME.message));
    else
        error('Error fetching data. Check date ranges: %s', ME.message);
    end
    rethrow(ME);
end

% Run dispatch for each plant
results = zeros(size(assets,1), 4);
earnings = zeros(length(Elec)/24, size(assets,1));
for i = 1:size(assets,1)
    [results(i,1) results(i,2) results(i,4) results(i,3), earnings(:,i)] = dispatch(assets(i,1), assets(i,2), assets(i,3), assets(i,4), Elec, NG);
end

% Create daily cash-flow image
fig = figure('Visible','off','Position',[514   570   610   322]);
h = stem(datenum(startDate):datenum(endDate), sum(earnings,2)/1e6, 'fill');
set(h,'MarkerSize',3,'Marker','.');
datetick
xlabel('Date');
ylabel('Cash-flows (Millions of $)');
title('Portfolio cash-flows per day');
print(fig,'-dmeta'); % Copy figure to clipboard
close(fig);