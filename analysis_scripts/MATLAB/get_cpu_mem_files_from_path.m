% File name: get_cpu_mem_files_from_path.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function [cpu_files,mem_files] = get_cpu_mem_files_from_path(path)
%GET_CPU_MEM_FILES_FROM_PATH retrieves full path for [cpu, mem] files at
% argument path

out = dir(append(path, "/cpu_*.txt"));
for k = 1 : length(out)
    cpu_files(k) = append(out(k).folder, "/", out(k).name);
end

out = dir(append(path, "/mem_*.txt"));
for k = 1 : length(out)
    mem_files(k) = append(out(k).folder, "/", out(k).name);
end

end

