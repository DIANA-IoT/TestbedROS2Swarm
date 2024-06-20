% File name: plot_cyclonedds_multicast_ofdm54.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.


paths = [
    "D:\pruebas_swarm_mcast_ofdm54\cyclone_2Topics_5PS_5P1S_net",
    "D:\pruebas_swarm_mcast_ofdm54\cyclone_2Topics_10PS_10P1S_net2",
    "D:\pruebas_swarm_mcast_ofdm54\cyclone_2Topics_15PS_15P1S_net",
    "D:\pruebas_swarm_mcast_ofdm54\cyclone_2Topics_20PS_20P1S_net",
    "D:\pruebas_swarm_mcast_ofdm54\cyclone_2Topics_25PS_25P1S_net2"];

infos = ["5 nodes, R2R",
    "10 nodes, R2R",
    "15 nodes, R2R",
    "20 nodes, R2R",    
    "25 nodes, R2R",
    "5 nodes, R2C",
    "10 nodes, R2C",
    "15 nodes, R2C",
    "20 nodes, R2C",
    "25 nodes, R2C"];

global path;

[b, stdL, meanL, err] = plot_box_chart_set(paths, infos, false, false);
f = gcf;
f.WindowState = 'maximize';
a = gca;

title('CycloneDDS using multicast and OFDM54 modulation')

% dump_stats_to_file("D:\resultados_cyclonedds_multicastOFDM54.txt", infos, meanL, stdL, err);

exportgraphics(gcf,  "D:\cycloneddsmulticastofdm54_scale25.eps", 'ContentType','vector');

% Uncomment to get different figures for each test

% fig_titles = [
%     "CycloneDDS: 5 PS, 5P, 1S",
%     "CycloneDDS: 10 PS, 10P, 1S",
%     "CycloneDDS: 15 PS, 15P, 1S",
%     "CycloneDDS: 20 PS, 20P, 1S",
%     "CycloneDDS: 25 PS, 25P, 1S",
%     ];
% 
% for j = 1 : length(paths)
%     path = paths(j);
%     plot_box_chart_all1plot;
%     fig = gcf;
%     fig.Name = fig_titles(j);
%     path = paths(j) + "\run0_be";
%     fprintf('Statistics for run %s\n', path);
%     stats_per_run
%     get_total_losses
%     path = paths(j) + "\run0_r";
%     fprintf('Statistics for run %s\n', path);
%     stats_per_run
%     get_total_losses
% end

