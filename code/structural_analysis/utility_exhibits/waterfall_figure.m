%% Housekeeping

clear all;
clc;

root = sprintf('/Users/%s/Dropbox/water_scarcity/', getenv('USER'));

code = [root, 'analysis/code/model/'];
addpath(genpath(code));
figures = [root, 'analysis/output/figures/'];
%% Plotting the figure

values = 2.3*[20.83; -5.36; -5.33];
names = {{'Farmer';'Profit'} {'Power';'Cost'} {'Water';'Cost'} {'Social';'Surplus'}};

figure(1);
ax = gca;
file = [figures "status_quo_decomp1.pdf"];
water_fall = plotWaterFall1(ax, values, names);
export_fig(file, '-painters', '-m2');

figure(2);
ax = gca;
file = [figures "status_quo_decomp2.pdf"];
water_fall = plotWaterFall2(ax, values, names);
export_fig(file, '-painters', '-m2');

figure(3);
ax = gca;
file = [figures "status_quo_decomp3.pdf"];
water_fall = plotWaterFall3(ax, values, names);
export_fig(file, '-painters', '-m2');

figure(4);
ax = gca;
file = [figures "status_quo_decomp4.pdf"];
water_fall = plotWaterFall(ax, values, names);
export_fig(file, '-painters', '-m2');


values = 2.3*[15.11; 4.85; -5.19];

figure(5)
ax = gca;
water_fall = plotWaterFall1(ax, values, names);
file = "piguovian_decomp1.pdf";
export_fig(file, '-painters', '-m2');

figure(6)
ax = gca;
water_fall = plotWaterFall2(ax, values, names);
file = "piguovian_decomp2.pdf";
export_fig(file, '-painters', '-m2');

figure(7)
ax = gca;
water_fall = plotWaterFall3(ax, values, names);
file = "piguovian_decomp3.pdf";
export_fig(file, '-painters', '-m2');

figure(8)
ax = gca;
water_fall = plotWaterFall(ax, values, names);
file = "piguovian_decomp4.pdf";
export_fig(file, '-painters', '-m2');

%% Plotting the figures

cd(figures);

values = 2.3*[4.18; -5.40; -4.80];
names = {{'Farmer';'Profit'} {'Power';'Cost'} {'Water';'Cost'} {'Social';'Surplus'}};

figure(1);
ax = gca;
file = "status_quo_decomp1.pdf";
water_fall = plotWaterFall1(ax, values, names);
export_fig(file, '-painters', '-m2');

figure(2);
ax = gca;
file = "status_quo_decomp2.pdf";
water_fall = plotWaterFall2(ax, values, names);
export_fig(file, '-painters', '-m2');

figure(3);
ax = gca;
file = "status_quo_decomp3.pdf";
water_fall = plotWaterFall3(ax, values, names);
export_fig(file, '-painters', '-m2');

figure(4);
ax = gca;
file = "status_quo_decomp4.pdf";
water_fall = plotWaterFall(ax, values, names);
export_fig(file, '-painters', '-m2');


values = 2.3*[0.06; 5.50; -6.58];

figure(5)
ax = gca;
water_fall = plotWaterFall1(ax, values, names);
file = "piguovian_decomp1.pdf";
export_fig(file, '-painters', '-m2');

figure(6)
ax = gca;
water_fall = plotWaterFall2(ax, values, names);
file = "piguovian_decomp2.pdf";
export_fig(file, '-painters', '-m2');

figure(7)
ax = gca;
water_fall = plotWaterFall3(ax, values, names);
file = "piguovian_decomp3.pdf";
export_fig(file, '-painters', '-m2');

figure(8)
ax = gca;
water_fall = plotWaterFall(ax, values, names);
file = "piguovian_decomp4.pdf";
export_fig(file, '-painters', '-m2');

