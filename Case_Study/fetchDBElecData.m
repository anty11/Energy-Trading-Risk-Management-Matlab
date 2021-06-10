function data = fetchDBElecData(startDate, endDate)
% FETCHDBDATA is a modified auto-generated function to import electricity
% price data from a database
% 
% SYNTAX:
% data = fetchDBElecData(startDate, endDate)

% Set preferences with setdbprefs.
s.DataReturnFormat = 'structure';
s.ErrorHandling = 'store';
s.NullNumberRead = 'NaN';
s.NullNumberWrite = 'NaN';
s.NullStringRead = 'null';
s.NullStringWrite = 'null';
s.JDBCDataSourceFile = '';
s.UseRegistryForSources = 'yes';
s.TempDirForRegistryOutput = 'C:\Temp';
s.DefaultRowPreFetch = '10000';
setdbprefs(s)

% Make connection to database.  Note that the password has been omitted.
% Using ODBC driver.
conn = database('EnergyData','','password');

% Read data from database.
if nargin > 0
    if isnumeric(startDate)
        startDate = datestr(startDate,'yyyy-mm-dd');
        endDate = datestr(endDate,'yyyy-mm-dd');
    end
    e = exec(conn,['SELECT ALL Date,Hour,DryBulb,DewPnt,NGPrice,ElecPrice FROM NEData WHERE Date BETWEEN #' startDate '# AND #' endDate '#  ']);
else
    e = exec(conn,'SELECT ALL Date,Hour,DryBulb,DewPnt,NGPrice,ElecPrice FROM NEData');
end

e = fetch(e);
close(e)

% Assign data to output variable.
data = e.Data;
data.NumDate = datenum(data.Date, 'yyyy-mm-dd') + (data.Hour-1)/24;

% Close database connection.
close(conn)
