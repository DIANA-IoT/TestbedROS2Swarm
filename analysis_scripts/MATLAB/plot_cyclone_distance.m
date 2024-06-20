% File name: plot_cyclone_distance.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
paths = [
    "D:\pruebas_cyclone_distancia\unicast_15PS_15P1S_net_2",
    "D:\pruebas_cyclone_distancia\unicast_15PS_15P1S_d5m_net",
    "D:\pruebas_cyclone_distancia\unicast_15PS_15P1S_d10m_net",
    "D:\pruebas_cyclone_distancia\ofdm54_15PS_15P1S_net",
    "D:\pruebas_cyclone_distancia\ofdm54_15PS_15P1S_d5m_net3",
    "D:\pruebas_cyclone_distancia\ofdm54_15PS_15P1S_d10m_net2"];

infos = ["Unicast: R2R at d=0m",
    "Unicast: R2R at d=5m",
    "Unicast: R2R at d=10m",
    "Multicast: R2R at d=0m",
    "Multicast: R2R at d=5m",
    "Multicast: R2R at d=10m",
    "Unicast: R2C at d=0m",
    "Unicast: R2C at d=5m",
    "Unicast: R2C at d=10m",
    "Multicast: R2C at d=0m",
    "Multicast: R2C at d=5m",
    "Multicast: R2C at d=10m"];

global path;

[b, stdL, meanL, err] = plot_box_chart_set(paths, infos, false, false);
f = gcf;
f.WindowState = 'maximize';
a = gca;

title('CycloneDDS at different distances')

% dump_stats_to_file("D:\resultados_cyclonedds_distances.txt", infos, meanL, stdL, err);

% exportgraphics(gcf,  "D:\cycloneddsdistance.eps", 'ContentType','vector');