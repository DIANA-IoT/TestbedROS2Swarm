% File name: get_total_losses.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%% get_total_losses: script that prints the overall losses in a test.
% Requires 'path' variable to be set
files = get_csv_files_from_path(path);

tx_packets = [];
loss = [];
ips_r = [];

for k = 1 : length(files)
    data = readtable(files(k), MissingRule="omitrow");
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    ips = unique(string(data.IP));
    [l_tx_packets, l_loss, l_ips_r] = get_losses_per_node(data, ips);
    tx_packets = [tx_packets; l_tx_packets];
    loss = [loss; l_loss];
    ips_r = [ips_r; l_ips_r];
    % If desired to print each node individually
    format_output(l_tx_packets, l_loss, l_ips_r, k)
end

localhost_indexes = contains(string(ips_r), "127.0.0.1");

fprintf('\n====================================================================\n')
fprintf('Rx Packets\t\t\tLoss\t\tType\n');
fprintf('====================================================================\n\n')
fprintf('%d\t\t%.4g\t\t%s\n', ...
    mean(tx_packets), ...
    mean(loss(~localhost_indexes)), ...
    "Wireless communications");

localhost_loss = (1 - loss(localhost_indexes));
fprintf('\n====================================================================\n')
fprintf('Rx Packets\t\t\tLoss\t\tType\n');
fprintf('====================================================================\n\n')
fprintf('%d\t\t%.4g\t\t%s\n', ...
    mean(tx_packets), ...
    mean(loss(localhost_indexes)), ...
    "Loopback");

function format_output(tx_packets, loss, ips_r, node)
    fprintf('\n====================================================================\n')
    fprintf('\t\t\t\tNode %d \n', node);
    fprintf('Tx Packets\tLoss\t\tIP\n');
    fprintf('====================================================================\n\n')
    for i = 1 : length(ips_r)
        fprintf('%d\t\t%.3f\t\t%s\n', ...
            tx_packets, ...
            loss(i), ...
            ips_r(i));
    end
end