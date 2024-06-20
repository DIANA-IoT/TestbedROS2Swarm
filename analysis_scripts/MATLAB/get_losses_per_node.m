% File name: get_losses_per_node.m
% Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
% copyright: University of Malaga
% License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
function [tx_packets, loss, ips] = get_losses_per_node(data, ips)
%GET_LOSSES_PER_IP returns the percentage of packet losses for each IP
% loss -> losses per IP delta(MaxSN-MinSN)
% duplicate -> duplicates per IP (relative to those transmitted by these
% address)

% Distinguish between localhost and outsiders packets.
localhost_indexes = contains(string(data.IP), "127.0.0.1");
% Count the amount of different packets TX
[C, ia, ic] = unique(data.SN(localhost_indexes));
localhost_packets = length(data.SN(localhost_indexes));
if localhost_packets ~= length(C)
    disp('WARN: Localhost has retransmitted packets. Check this');
end
clear C ia ic;

% My own way of defining the amount of TX packets: 
tx_packets = max(data.SN) - min(data.SN) + 1;

ips_length = length(ips);
loss = zeros(ips_length, 1);

acc = 0;

for k = 1 : ips_length
    % Indexes for the current IP
    current_indexes = contains(string(data.IP), ips(k));
    % Amount of packets coming from that IP
    tx_current_ip = length(data.SN(current_indexes));
    % Amount of different packets
    different_ip = length(unique(data.SN(current_indexes)));
    loss(k) = (tx_packets - different_ip) / tx_packets;
    % Just for checking:
    acc = acc + tx_current_ip;
end

if acc ~= length(data.SN)
    fprintf('WARN: Incoherence at data filtering post-check\n');
end
ips = ips;
end

