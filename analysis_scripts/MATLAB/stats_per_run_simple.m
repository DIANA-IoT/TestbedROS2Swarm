% File name: stats_per_run_simple.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function [meanL,stdL, error] = stats_per_run_simple(path)
%STATS_PER_RUN_SIMPLE Gets mean latency, std latency and error


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
meanL = mean(time_unit);
stdL = std(time_unit);

clear data;


tx_packets = [];
loss = [];
ips_r = [];

for k = 1 : length(files)
    data = readtable(files(k), MissingRule="omitrow");
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    ips = unique(string(data.IP));
    [l_tx_packets, l_loss, l_ips_r] = get_losses_per_node(data, ips);
    tx_packets = [tx_packets; l_tx_packets];
    loss = [loss; l_loss];
    ips_r = [ips_r; l_ips_r];
end

localhost_indexes = contains(string(ips_r), "127.0.0.1");
error = mean(loss(~localhost_indexes));

end

