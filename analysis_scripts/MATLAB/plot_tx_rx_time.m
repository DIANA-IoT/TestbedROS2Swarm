% File name: plot_tx_rx_time.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%% plot_tx_rx_time: plots the transmission and reception time of each sequence number.
% 1 plot for each node. Requires 'path' variable with the directory
% containing the CSVs to be set.


%Define path
files = get_csv_files_from_path(path);
% Retrieve data from CSV files.
for k = 1 : length(files)
    data = readtable(files(k), MissingRule="omitrow");
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    fprintf('Reading and plotting file: %s\n', files(k));
    % Create a new figure
    f = figure;
    f.Name = files(k);
    plot_individual_tx_rx_time(data);
end