% File name: get_csv_files_from_path.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%% get_csv_files_from_path returns all the retrieved CSV extension files in an absolute path
function files = get_csv_files_from_path(path)
    if ispc
        out = dir(append(path, "/*.csv"));
        for k = 1 : length(out)
            files(k) = append(out(k).folder, "/", out(k).name);
        end
    elseif isunix
        out = ls(append(path, "/*.csv"));
        for k = 1 : length(out)
            files(k) = append(out(k).folder, "/", out(k).name);
        end
    else
        disp('Platform not supported')
    end
end