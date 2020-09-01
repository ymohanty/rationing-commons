function h = plotWaterFall3( ax, y, names )

if nargin == 1
    y = ax;
    ax = gca;
end
if ~strcmp(ax.NextPlot, 'add')
    fprintf('hold on not set for current axes. Overriding.\n');
    hold(ax, 'on');
end

y = y(:); % column vector
n = length(y);
cumy = cumsum(y);

yaxis_ticks = linspace(-10, 50, 60/2.5 + 1);
%yaxis_ticks = linspace(5*fix(min(min(cumy)-5, 0)/5), 5*fix(max(max(cumy)+5, 0)/5), ...
%    (5*fix(max(max(cumy)+5, 0)/5)-5*fix(min(min(cumy)-5, 0)/5))/2.5 + 1);
%set(ax, 'XLim', [0, n+1]+0.5, 'YLim', [min(min(cumy)-5, 0), max(max(cumy)+5, 0)]);
set(ax, 'XLim', [0, n+1]+0.5, 'YLim', [-12, 50]);
set(ax, 'YTick', yaxis_ticks);
yaxis_ticks = sprintfc('%d', yaxis_ticks);
for i = 1:length(yaxis_ticks)
    if mod(i,2) == 0
        yaxis_ticks{i} = ''
    end
end
set(ax, 'YTickLabel', yaxis_ticks);
%set(ax, 'XTick', linspace(min(ax.XLim)+0.5, max(ax.XLim)-0.5, length(names)));
set(ax, 'XTick', linspace(1, 3, 3));
%set(ax, 'XTickLabel', names);
t = my_xticklabels(ax, linspace(1, 3, 3), names(1:3));
% colors:
% decrease - red - code as -1
% total - black - code as 0
% increase - blue - code as 1
set(ax, 'CLim', [-1, 1], 'ColorMap', [1 0 0; 0 0 0; 0 0 1]);

% copy a bunch of axes
for i = 1:n
    ax(i+1) = copyobj(ax(1), ax(1).Parent);
end
% Make all subsequent axes invisible
% Make sure all axes will always be the same size by linking properties
set(ax(2:end), 'Color', 'none', 'XColor', 'none', 'YColor', 'none');
linkprop(ax, {'XLim', 'YLim', 'Position', 'DataAspectRatio'});

% define from/to of each bar (except 1st and last)
from = cumy(1:n-1);
to = cumy(2:n);

% color of each bar (except 1st and last)
c = double(y>0) - double(y<0);
c(1) = [];

% first total bar
h = bar(ax(1), 1, from(1), 0.6, 'CData', 0, 'BaseValue', 0, 'LineWidth', 2.5);
% 2nd to 2nd last bars
for i = 1:2
    h(end+1) = bar(ax(i+1), i+1, to(i), 0.6, 'CData', c(i), 'BaseValue', from(i), 'ShowBaseLine', 'off', 'LineWidth', 2.5);
end
% last total bar
set(ax, 'TickLength', [0.02 0.02]);
ylabel(ax(1), 'INR (000s) per farmer');

plot([1.3 1.7], [from(1) from(1)], ':', 'LineWidth', 2.5, 'Color', [0.5 0.5 0.5]);
plot([2.3 2.7], [to(1) to(1)], ':', 'LineWidth', 2.5, 'Color', [0.5 0.5 0.5]);

for i = 1:3
    if i == 1
        if y(i) > 0
            %text(i, from(i)+1, sprintf('%0.1f', y(i)));
            text(i, from(i)+4.5, sprintf('%0.1f', y(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                'top', 'fontsize', 18, 'FontName', 'Times New Roman');
        else
            %text(i, from(i)-1, string(round(y(i),2)));
            text(i, from(i)-4.5, sprintf('%0.1f', y(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                'bottom', 'fontsize', 18, 'FontName', 'Times New Roman');
        end
    elseif i ~= (n+1)
        if y(i) > 0
            %text(i-0.25, to(i-1)+1, string(round(y(i),2)));
            text(i, to(i-1)+4.5, sprintf('%0.1f', y(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                'top', 'fontsize', 18, 'FontName', 'Times New Roman');
        else
            %text(i-0.25, to(i-1)-1, string(round(y(i),2)));
            text(i, to(i-1)-4.5, sprintf('%0.1f', y(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                'bottom', 'fontsize', 18, 'FontName', 'Times New Roman');
        end
    else
        if cumy(i-1) > 0
            text(i, to(i-2)+4.5, sprintf('%0.1f', cumy(i-1)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                'top', 'fontsize', 18, 'FontName', 'Times New Roman');
        else
            text(i, to(i-2)-4.5, sprintf('%0.1f', cumy(i-1)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                'bottom', 'fontsize', 18, 'FontName', 'Times New Roman');
        end
    end
    
        
end
zero_line = yline(0);
set(zero_line, 'LineWidth', 2.5, 'Color', [0 0 0]);

% Formatting options
set(gcf, 'Color', 'w');
set(ax, 'LineWidth', 1.5);
textProp = {'fontsize'    , 18, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
set(gca, textProp{:}, 'Box', 'off');
pbaspect([0.5 0.5 0.5]);


% setting FaceColor flat makes the Bars use the CData property
set(h, 'FaceColor', 'flat') 