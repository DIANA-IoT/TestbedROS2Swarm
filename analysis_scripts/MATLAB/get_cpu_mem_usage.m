% File name: get_cpu_mem_usage.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function get_cpu_mem_usage(path, do_plot)
% GET_CPU_MEM_USAGE retrieves the evolution of the CPU and RAM usage
% throught time from path. Args: Path, do_plot.

[cpu_files, mem_files] = get_cpu_mem_files_from_path(path);

if length(cpu_files) ~= length(mem_files)
    disp(['Files error, different number of CPU and memory files ' ...
        'at this path']);
    return;
end
    % Plotting is enabled: plot in a unique figure every machine statistics
if do_plot
    % Store figure handler in case it is needed later
    f = figure;
    tiledlayout('flow');
    
    for k = 1 : length(cpu_files)
        nexttile
        warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
        % Imports CPU data, assume every file is created equally.
        dt = readtimetable(cpu_files(k), MissingRule = "omitrow", ...
            numheaderlines=2, ReadVariableNames=true);
        dt.Properties.DimensionNames = {'timestamp', 'Variables'};
        % Extract meaningful data, potentially to compare with other files
        current_timestamp = dt.timestamp;
        % My usage will be defined to 100 - %idle_time throughout all cores.
        current_cpu_usage = 100 - dt.x_idle;
        clear dt;
        [mem_timestamp, tm, fm, stotal, sfree] = read_memory_file(mem_files(k));
        phy_usage = 100 .* (tm - fm) ./ tm;
        swap_usage = 100 .* (stotal - sfree) ./ stotal;
        hold on
        plot(current_timestamp, current_cpu_usage)
        plot(mem_timestamp, phy_usage)
        plot(mem_timestamp, swap_usage)
        ylim([0 100])
        legend('CPU usage', 'Phy RAM usage', 'Swap usage');
        title(sprintf('Resource utilization on machine %d', k));
        hold off
    end
    
    % plotting disabled: print in text format 
else 
    cpu_mean = zeros(length(cpu_files),1);
    cpu_std = zeros(length(cpu_files),1);
    phy_mean = zeros(length(cpu_files),1);
    phy_std = zeros(length(cpu_files),1);
    swap_mean = zeros(length(cpu_files),1);
    swap_std = zeros(length(cpu_files),1);
    for k = 1 : length(cpu_files)
        warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
        % Imports CPU data, assume every file is created equally.
        dt = readtimetable(cpu_files(k), MissingRule = "omitrow", ...
            numheaderlines=2, ReadVariableNames=true);
        dt.Properties.DimensionNames = {'timestamp', 'Variables'};
        % My usage will be defined to 100 - %idle_time throughout all cores.
        current_cpu_usage = 100 - dt.x_idle;
        clear dt;
        [mem_timestamp, tm, fm, stotal, sfree] = read_memory_file(mem_files(k));
        phy_usage = 100 .* (tm - fm) ./ tm;
        swap_usage = 100 .* (stotal - sfree) ./ stotal;
        % Compute means and stds
        cpu_mean(k) = mean(current_cpu_usage);
        cpu_std(k) = std(current_cpu_usage);
        phy_mean(k) = mean(phy_usage);
        phy_std(k) = std(phy_usage);
        swap_mean(k) = mean(swap_usage);
        swap_std(k) = std(swap_usage);
    end
    index = 1 : length(cpu_files);
    T = table(index', cpu_mean, cpu_std, phy_mean, phy_std, swap_mean, ...
        swap_std);
    T.Properties.DimensionNames{1} = 'RobotIndex';
    T.Properties.DimensionNames{2} = 'CPU mean (%)';
    T

end

end

function [ts, total, free, stotal, sfree] = read_memory_file(file_path)
% Reads a text file, located at file_path, with the following format: 
% '%s MemTotal: %d kB MemAvailable: %d kB SwapTotal: %d kB SwapFree: %d kB\n'
% Returns: ts -> vector timestamp
% total, free, stotal, sfree -> kB vectors of total and free pyhsical and
% swap
    fileid = fopen(file_path);
    c = textscan(fileid, '%s MemTotal: %f kB MemAvailable: %f kB SwapTotal: %f kB SwapFree: %f kB\n');
    ts = duration(string(c{1}));
    total = c{2};
    free = c{3};
    stotal = c{4};
    sfree = c{5};
    fclose(fileid);
end

