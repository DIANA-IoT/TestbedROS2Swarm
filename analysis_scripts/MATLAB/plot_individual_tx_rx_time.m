% File name: plot_individual_tx_rx_time.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function plot_individual_tx_rx_time(data)
%% Plots the timestamp at which each packet was sent and received.
% Creates one plot for every identified IP.
% Args: data -> a table with IP and timestamps

destinations = unique(string(data.IP));

for j = 1 : length(destinations)
        nexttile;
        % Figure out the indexes of each specific destination
        destination_indexes = contains(string(data.IP), ...
            destinations(j));
        hold on
        time_zero = data.TX_s(1) ...
            + data.TX_ns(1)./ 1e9;
        scatter(data.TX_s(destination_indexes) ...
            + data.TX_ns(destination_indexes)./ 1e9 - time_zero, data.SN(destination_indexes),'xr');
        scatter( data.RX_s(destination_indexes) ...
            + data.RX_ns(destination_indexes)./1e9 - time_zero, data.SN(destination_indexes), '.b');
        hold off
        xlabel('Time (s)');
        ylabel('Sequence number');
        legend('TX', 'RX')
        title(sprintf('With respect to %s', destinations(j)));
    end

end