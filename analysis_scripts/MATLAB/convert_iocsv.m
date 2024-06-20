% File name: convert_iocsv.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%% Convert IOCSV: script to convert Wireshark CSV traces to vectorial figures
% It requires the variable 'data' to be set
indexes_greater5min = (data.IntervalStart > 300 & data.IntervalStart <= 1200);
figure;
hold on 
plot(data.IntervalStart(indexes_greater5min), ...
    data.AllPackets(indexes_greater5min));

plot(data.IntervalStart(indexes_greater5min), ...
    data.RTPS(indexes_greater5min));

% plot(data.IntervalStart(indexes_greater5min), ...
%     data.RTPSData(indexes_greater5min));

plot(data.IntervalStart(indexes_greater5min), ...
    data.BE(indexes_greater5min));

plot(data.IntervalStart(indexes_greater5min), ...
    data.Rel(indexes_greater5min));
hold off
legend('All Packets', 'RTPS', 'Best Effort', 'Reliable', 'Location','southeastoutside');
set(gca, 'YScale', 'log');
grid on
xlabel('Elapsed time (s)')
ylabel('Required bandwith (bytes/s)')
fontsize(gcf,scale=2.5)




