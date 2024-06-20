% File name: stats_per_run.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
% Prints on console the mean and standard deviation of
% latency present inside "path's" files
% 'Path' variable needs to be set. CSV files need to be inside
% this variable.

% Retrieve files from path
files = get_csv_files_from_path(path);

data = [];
for k = 1 : length(files)
    data = readtable(files(k), MissingRule="omitrow");
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
end

conversionFactor = 1e6;
localhost_indexes = contains(string(data.IP), "127.0.0.1");
% Trim loopback data
data(localhost_indexes, :) = [];
% Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
% RTT)
more_than_second_indexes = data.d_s >= 1;
% Convert ns to the desired unit
time_unit = data.d_ns ./ conversionFactor;
% Add seconds to that unit.
time_unit(more_than_second_indexes) = time_unit(more_than_second_indexes) + ...
    (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));
% Compute stats
avg = mean(time_unit);
typ = std(time_unit);
fprintf('Avg latency: %f, std latency: %f\n', avg, typ);