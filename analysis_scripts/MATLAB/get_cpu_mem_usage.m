% File name: get_cpu_mem_usage.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function [cpu, mem, time] = get_cpu_mem_usage(path)
% GET_CPU_MEM_USAGE retrieves the evolution of the CPU and RAM usage
% throught time from path. Args: Path. Returns [cpu, mem, time] in a common time_frame.

[cpu_files, mem_files] = get_cpu_mem_files_from_path(path);

if length(cpu_files) ~= length(mem_files)
    disp(['Files error, different number of CPU and memory files ' ...
        'at this path']);
    return;
end

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
    phy_usage = 100 .* (tm - fm) / tm;
    swap_usage = 100 .* (stotal - sfree) / stotal;
    hold on
    plot(current_timestamp, current_cpu_usage)
    plot(mem_timestamp, phy_usage)
    plot(mem_timestamp, swap_usage)
    ylim([0 100])
    legend('CPU usage', 'Phy RAM usage', 'Swap usage');
    title(sprintf('Resource utilization on machine %d', k));
    hold off
end

end

function [ts, total, free, stotal, sfree] = read_memory_file(file_path)
% Reads a text file, located at file_path, with the following format: 
% '%s MemTotal: %d kB MemFree: %d kB SwapTotal: %d kB SwapFree: %d kB\n'
% Returns: ts -> vector timestamp
% total, free, stotal, sfree -> kB vectors of total and free pyhsical and
% swap
    fileid = fopen(file_path);
    c = textscan(fileid, '%s MemTotal: %f kB MemFree: %f kB SwapTotal: %f kB SwapFree: %f kB\n');
    ts = duration(string(c{1}));
    total = c{2};
    free = c{3};
    stotal = c{4};
    sfree = c{5};
    fclose(fileid);
end

