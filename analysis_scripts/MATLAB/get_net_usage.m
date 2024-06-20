% File name: get_net_usage.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function get_net_usage(path)
% Plots the kernel network usage for each node in a different plot
% Args: path with the network report files ("net*.txt")

out = dir(append(path, "/net*.txt"));
for k = 1 : length(out)
    net_files(k) = append(out(k).folder, "/", out(k).name);
end

% Store figure handler in case it is needed later
f = figure;
tiledlayout('flow');


for k = 1 : length(net_files)
    nexttile
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    % Imports Net data, assume every file is created equally.
    data = readtimetable(net_files(k), MissingRule = "omitrow", ...
        ReadVariableNames=true);
    timestamp = data.Time;
    d_timestamp = timestamp(2:end) - timestamp(1);
    d_seconds = seconds(diff(timestamp));
    % Evolution of each parameter: accounting for 1 sample per second
    erxb = diff(data.RX_bytes) ./ (1e3 .* d_seconds);
    erxp = diff(data.RX_packets) ./ d_seconds;
    etxb = diff(data.TX_bytes) ./ (1e3 .* d_seconds);
    etxp = diff(data.Tx_packets) ./d_seconds;
    emcast = diff(data.Multicast) ./d_seconds;
    % ylim([0 2e6])
    hold on
    plot(d_timestamp(1:end), erxb);
    plot(d_timestamp(1:end), erxp);
    plot(d_timestamp(1:end), etxb);
    plot(d_timestamp(1:end), etxp);
    plot(d_timestamp(1:end), emcast);
    legend('RX kBytes/s', 'RX packets/s', 'TX kBytes/s', 'TX packets/s', ...
        ' Multicast packets /s');
    title(sprintf('Network utilization on machine %d', k));
    hold off
end

end
