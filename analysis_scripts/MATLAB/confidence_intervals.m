% File name: confidence_intervals.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%% Get CI retrieves stats from a given file and dumps 95% and 99% to a new
% file
% Args: input_file, output_file
function confidence_intervals(ifile, ofile)
    fdi = fopen(ifile, 'r');
    if fdi == -1 
        disp('Could not open input file. Exiting');
        return
    end
    fdo = fopen(ofile, 'w+');
    if fdo == -1
        disp('Could not open output file. Exiting');
        fclose(fdi);
        return
    end
    % Get header
    % nheader = fgetl(fdi) + "|95CI+Z|95CI-Z|99CI+Z|99CI-Z\n";
    fprintf(fdo, fgetl(fdi) + "|95CI+Z|95CI-Z|99CI+Z|99CI-Z\n");

    % Read line by line
    while ~feof(fdi)
        str = fgetl(fdi);
        % Tokenize by delimiter so we get different strings for each field
        remain = str;
        segments = strings(0);
        while (remain ~= "")
           [token,remain] = strtok(remain, '|');
           segments = [segments ; token];
        end
        % Depending on the test, n is 2e5 or 1e4 (BE or R)
        n_samples = 0;
        if contains(segments(1), 'best-effort', 'IgnoreCase', true)
               n_samples = 2e5;
        else
               n_samples = 1e4;
        end
        % Z values for 95 and 99 percent CI
        z_ci95 = 1.96;
        z_ci99 = 2.576;
        
        sample_m = double(segments(2));
        sample_std = double(segments(3));
        sample_err = double(segments(4));
        % 95 percent CI
        ci95_plusZ = sample_m + z_ci95 *(sample_std/sqrt(n_samples));
        ci95_minusZ = sample_m - z_ci95 *(sample_std/sqrt(n_samples));
        % 99 percent CI
        ci99_plusZ = sample_m + z_ci99 *(sample_std/sqrt(n_samples));
        ci99_minusZ = sample_m - z_ci99 *(sample_std/sqrt(n_samples));
        fprintf(fdo,"%s|%4.3f|%4.3f|%4.3f|%4.3f|%4.3f|%4.3f|%4.3f\n", ...
            segments(1), ...
            sample_m, ...
            sample_std, ...
            sample_err, ...
            ci95_plusZ, ...
            ci95_minusZ, ...
            ci99_plusZ, ...
            ci99_minusZ);
    end

    fclose(fdi);
    fclose(fdo);
end
% https://sphweb.bumc.bu.edu/otlt/mph-modules/bs/bs704_confidence_intervals/bs704_confidence_intervals_print.html