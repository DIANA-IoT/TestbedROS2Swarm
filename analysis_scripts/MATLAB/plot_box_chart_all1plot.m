% File name: plot_box_chart_all1plot.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%% plot_box_char_all1plot: Plots in a single box chart a set of latency tests, 
% each one in a different folder. The parent folder must be set on 'path'
% variable. Modify 'info' variable for the labels.


directories = dir(path);
% Exclude current and top directories
directories = directories(~startsWith({directories.name}, '.'));
[~, index] = sort_nat({directories.name});
directories = directories(index, :);

f = figure;

% Plot one 'whisker' for each directory. To identify them, use info
% variable.
info = [];

run = {};
hold on
infoK = 0;
% Firstly plot intra nodes without losses. TX DS ~= DS{0}
old_path = path;
for k = 1 : length(directories)
    if ~directories(k).isdir
        continue;
    end
   infoK = infoK + 1;
   c_processing = directories(k).folder + "\" + directories(k).name;
   disp(sprintf('Currently processing: %s', c_processing));
    latency_unit = get_run_latency(c_processing, "ms");
    % latency_unit = get_run_latency_trimmed(directories(k).folder + "\" + directories(k).name, ...
    %     "ms", ...
    %     "low", ...
    %     4000);
    copia = repmat(info(infoK), length(latency_unit), 1);
    b = boxchart(categorical(copia),latency_unit);
    % Jitter outliers
    b.JitterOutliers = 'on';
    b.MarkerStyle = '.';
    % ylim([0 80])
    % Plots run mean
    hold on
    % meanL = groupsummary(latency_unit, copia, 'mean');
    % plot(categorical(info(k)), meanL, '*')
    meanL = mean(latency_unit);
    plot(categorical(info(infoK)), meanL, '*');
    path = c_processing;
    stats_per_run
    get_total_losses
end
path = old_path;
hold off
title('All nodes combined')
ylabel(sprintf('Latency %s', "ms"));


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

function run_latency = get_run_latency_trimmed(fpath, unit, what, limit)
% returns combined run latency at the given fpath measured at unit.
% Loopback communications are not accounted
% what: 'low', trims the lower end, 'limit' should be the last value to be
% trimmed
% 'up', trims the upper end, 'limit' should be the first value to be
% trimmed
% 'limit' is type of SN.

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
    
if what == "low"
   % trim lower end
   trim_indexes = data.SN < limit;
elseif what == "up"
   % trim upper end
   trim_indexes = data.SN > limit;
else
    disp("Unknown option at 'what'");
    return
end
data(trim_indexes, :) = [];
% Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
% RTT)
more_than_second_indexes = data.d_s >= 1;
% Convert ns to the desired unit
run_latency = data.d_ns ./ conversionFactor;
% Add seconds to that unit.
run_latency(more_than_second_indexes) = run_latency(more_than_second_indexes) + ...
    (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));

end

function run_latency = get_run_latency_nodes_nolosses(fpath, unit, what, limit)

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
        % robot6 is the robot that usually suffers from disconnections
        if contains(files(i), 'robot6')
            continue;
        end
        data = [data; readtable(files(i), MissingRule="omitrow")];
        warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    end
    localhost_indexes = contains(string(data.IP), "127.0.0.1");
    % Trim loopback data
    data(localhost_indexes, :) = [];
        
    if what == "low"
       % trim lower end
       trim_indexes = data.SN < limit;
    elseif what == "up"
       % trim upper end
       trim_indexes = data.SN > limit;
    else
        disp("Unknown option at 'what'");
        return
    end
    data(trim_indexes, :) = [];
    % Filter table indexes that belong to the unstable node
    trim_indexes = contains(string(data.IP), "192.168.2.8");
    data(trim_indexes, :) = [];
    % Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
    % RTT)
    more_than_second_indexes = data.d_s >= 1;
    % Convert ns to the desired unit
    run_latency = data.d_ns ./ conversionFactor;
    % Add seconds to that unit.
    run_latency(more_than_second_indexes) = run_latency(more_than_second_indexes) + ...
        (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));

end

function run_latency = get_run_latency_nodes_rxlosses(fpath, unit, what, limit)
    % Returns latency to destinations = node that suffers the losses
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
        % robot6 is the robot that usually suffers from disconnections
        if contains(files(i), 'robot6')
            continue;
        end
        data = [data; readtable(files(i), MissingRule="omitrow")];
        warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    end
    localhost_indexes = contains(string(data.IP), "127.0.0.1");
    % Trim loopback data
    data(localhost_indexes, :) = [];
        
    if what == "low"
       % trim lower end
       trim_indexes = data.SN < limit;
    elseif what == "up"
       % trim upper end
       trim_indexes = data.SN > limit;
    else
        disp("Unknown option at 'what'");
        return
    end
    data(trim_indexes, :) = [];
    % Filter table indexes that belong to the unstable node
    trim_indexes = contains(string(data.IP), "192.168.2.8");
    data(~trim_indexes, :) = [];
    % Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
    % RTT)
    more_than_second_indexes = data.d_s >= 1;
    % Convert ns to the desired unit
    run_latency = data.d_ns ./ conversionFactor;
    % Add seconds to that unit.
    run_latency(more_than_second_indexes) = run_latency(more_than_second_indexes) + ...
        (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));

end

function run_latency = get_run_latency_nodes_txlosses(fpath, unit, what, limit)
    % Returns latency to destinations = node that suffers the losses
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
        % robot6 is the robot that usually suffers from disconnections
        if ~contains(files(i), 'robot6')
            continue;
        end
        data = [data; readtable(files(i), MissingRule="omitrow")];
        warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    end
    localhost_indexes = contains(string(data.IP), "127.0.0.1");
    % Trim loopback data
    data(localhost_indexes, :) = [];
        
    if what == "low"
       % trim lower end
       trim_indexes = data.SN < limit;
    elseif what == "up"
       % trim upper end
       trim_indexes = data.SN > limit;
    else
        disp("Unknown option at 'what'");
        return
    end
    data(trim_indexes, :) = [];
    % Filter table indexes that belong to the unstable node
    %trim_indexes = contains(string(data.IP), "192.168.2.8");
    %data(~trim_indexes, :) = [];
  
    % Mark those cells with d_s >= 1.  (Those that took more than a 1 in its
    % RTT)
    more_than_second_indexes = data.d_s >= 1;
    % Convert ns to the desired unit
    run_latency = data.d_ns ./ conversionFactor;
    % Add seconds to that unit.
    run_latency(more_than_second_indexes) = run_latency(more_than_second_indexes) + ...
        (data.d_s(more_than_second_indexes) .* (1e9/conversionFactor));

end