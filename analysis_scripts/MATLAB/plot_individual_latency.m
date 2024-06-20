% File name: plot_individual_latency.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function h = plot_individual_latency(data, unit, lower_ns, upper_ns)
%PLOT_INDIVIDUAL_LATENCY Plots single's node individual latency in a
% histogram. Bin limits are bounded by lower_ns and upper_ns
% unit: which unit is used to convert latency, originally metrics are in
% ns.

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

lower_tu = lower_ns ./conversionFactor;
upper_tu = upper_ns ./ conversionFactor;

% Updates figure
h = histogram(time_unit, 100, 'Normalization', 'probability', ...
    'BinLimits', [lower_tu, upper_tu]);
end

