% File name: dump_stats_to_file.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function dump_stats_to_file(filename,infos,meanL,stdL,err)
%DUMP_STATS_TO_FILE Dumps the given stats to a file
%  Args: filename, info for test, meanL, stdL, err
fd = fopen(filename, 'w+');
fprintf(fd, "Test|MeanL|stdL|MeanE\n");
err = err .* 1e2;
for k = 1 : length(infos)
    fprintf(fd, "%s|%4.3f|%4.3f|%4.3f\n", infos(k), meanL(k), stdL(k), err(k));
end
fclose(fd);
end

