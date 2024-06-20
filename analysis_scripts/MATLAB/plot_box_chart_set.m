% File name: plot_box_chart_set.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function [b, stdL, meanL, error] = plot_box_chart_set(paths, labels, plotOutliers, jitterOutliers)
%PLOT_BOX_CHART_SET Plots a set of tests within the same plot
% Args: - Paths -> paths in which lookup for CSV files
% labels: Labels for each folder
% plotOutliers: if true outliers will be plotted
% jitterOutliers: if true outliers will be displaced in x-axis.

directories = [];
path = [];

for k = 1 : length(paths)
    directories = [directories; dir(paths(k))];
end

% Exclude current and top directories
directories = directories(~startsWith({directories.name}, '.'));
[~, index] = sort_nat({directories.name});
directories = directories(index, :);

f = figure;

hold on
infoK = 0;
meanL = [];
stdL = [];
error = [];

for k = 1 : length(directories)
    if ~directories(k).isdir
        continue;
    end
   infoK = infoK + 1;
   c_processing = directories(k).folder + "\" + directories(k).name;
   disp(sprintf('Currently processing: %s', c_processing));
    latency_unit = get_run_latency(c_processing, "ms");
    copia = repmat(labels(infoK), length(latency_unit), 1);
    b = boxchart(categorical(copia),latency_unit);
    % Jitter outliers
    b.JitterOutliers = jitterOutliers;
    if plotOutliers 
        b.MarkerStyle = '.';
    else 
        b.MarkerStyle = "none";
    end
    % Plots run mean
    hold on
    path = c_processing;
    [meanc, stdc, errorc] = stats_per_run_simple(path)
    plot(categorical(labels(infoK)), meanc, '*');
    meanL = [meanL; meanc];
    stdL = [stdL; stdc];
    error = [error; errorc];
end
set(gca, 'YScale', 'log')
hold off
title('All nodes combined')
ylabel(sprintf('Latency %s', "ms"));
fontsize(gcf,18, "points")


% boxchart(run.latency_unit, run.info);

function run_latency = get_run_latency(fpath, unit)
% returns combined run latency at the given fpath measured at unit.
% Loopback communications are not accounted

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

files = get_csv_files_from_path(fpath);
data = [];
for i = 1 : length(files)
    data = [data; readtable(files(i), MissingRule="omitrow")];
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
end
localhost_indexes = contains(string(data.IP), "127.0.0.1");
% Trim loopback data
data(localhost_indexes, :) = [];
% Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
% RTT)
more_than_second_indexes = data.d_s >= 1;
% Convert ns to the desired unit
run_latency = data.d_ns ./ conversionFactor;
% Add seconds to that unit.
run_latency(more_than_second_indexes) = run_latency(more_than_second_indexes) + ...
    (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));

end

end

