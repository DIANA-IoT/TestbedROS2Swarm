% File name: plot_individual_latency_vs_sn.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function plot_individual_latency_vs_sn(data, unit, method, type)
%PLOT_INDIVIDUAL_LATENCY_VS_SN Plots the latency of each node and packet
%  versus the sequence number.
% Args: data -> table with IP, timestamps, SN, etc.
% unit: ns/us/ms/s, requires timestamp to have ns precision
% method: individual/piled
% type: plot or scatter
conversionFactor = 0.0;
if unit == "ns"
    conversionFactor = 1.0;
elseif unit == "us"
    conversionFactor = 1e3;
elseif unit == "ms"
    conversionFactor = 1e6;
elseif unit == "s"
    conversionFactor = 1e9;
else
    disp('Wrong unit {ns,us,ms,s}');
    return;
end

% Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
% RTT)
more_than_second_indexes = data.d_s >= 1;
% Convert ns to the desired unit
time_unit = data.d_ns ./ conversionFactor;
% Add seconds to that unit.
time_unit(more_than_second_indexes) = time_unit(more_than_second_indexes) + ...
    (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));

% Gets unique SN
sn = unique(data.SN);
% Get different destinations
destinations = unique(string(data.IP));

% Plot a plot
if type == "plot"
    % Employ one plot for each destination
    if method == "individual"
        tiledlayout('flow');
    elseif method == "piled"
    else
        disp('Wrong method {individual, piled}');
        return;
    end
    for j = 1 : length(destinations)
        nexttile;
        % Figure out the indexes of each specific destination
        destination_indexes = contains(string(data.IP), ...
            destinations(j));
        non_sn_vector = zeros(length(0:1:max(data.SN)), 1);
        non_sn_vector(data.SN(destination_indexes)+1) = NaN;
        v = NaN(max(data.SN)+1, 1);
        v(data.SN(destination_indexes)+1) = time_unit(destination_indexes);
        hold on
        plot(v);
        % plot(data.SN(destination_indexes), ...
        %     time_unit(destination_indexes));
        plot(non_sn_vector, 'xr');
        % plot(data.TX_s(destination_indexes) ...
        %     + data.TX_ns(destination_indexes)./ 1e9, data.SN(destination_indexes),'xr');
        % plot( data.RX_s(destination_indexes) ...
        %     + data.RX_ns(destination_indexes)./1e9, data.SN(destination_indexes), '.b');
        xlim([0 max(data.SN)]);
        hold off
        xlabel('Sequence number');
        ylabel(sprintf("Latency (%s)", unit));
        legend('Latency', 'Lost sample')
        title(sprintf('With respect to %s', destinations(j)));
    end
    % Use only plot for all destinations
% Draw using scatter plot
elseif type == "scatter"
    % Employ one plot for each destination
    if method == "individual"
    % Use only plot for all destinations
    elseif method == "piled"
    else
        disp('Wrong method {individual, piled}');
        return;
    end
    for j = 1 : length(destinations)
        nexttile;
        % Figure out the indexes of each specific destination
        destination_indexes = contains(string(data.IP), ...
            destinations(j));
        scatter(data.SN(destination_indexes), ...
            time_unit(destination_indexes));
        xlabel('Sequence number');
        ylabel(sprintf("Latency (%s)", unit));
        title(sprintf('With respect to %s', destinations(j)));
    end
% Incorrect type
else
    disp('Wrong type {plot, scatter}');
    return;
end

end

