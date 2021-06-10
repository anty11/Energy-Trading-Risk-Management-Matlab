function data = fetchNGData()
% FETCHDBDATA is a modified auto-generated function to import natural gas
% price data from a database
% 
% SYNTAX:
% data = fetchNGData()

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
e = exec(conn,'SELECT ALL Date,NaturalGas,CrudeOil,FuelOil FROM Fuels');
e = fetch(e);
close(e)

% Assign data to output variable.
data = e.Data;
data.Date = datenum(data.Date, 'yyyy-mm-dd HH:MM:SS');

% Close database connection.
close(conn)
