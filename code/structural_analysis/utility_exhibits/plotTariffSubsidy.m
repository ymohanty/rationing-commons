function [] = plotTariffSubsidy(filename)
% Plots bar graph of tariffs and subsidies charged by discom 
% by year with a horizontal line indicating the maringal cost
%
% INPUTS:
%   None, data in place.
% OUTPUT: 
%   filename.pdf
    
    % Data
    tariff = [ 1.36 2.25 2.25 3.93 4.5 4.75 4.75 4.75]';
    subsidy =  [ 0.33 1.1 1.35 3.03 3.6 3.85 3.85 3.85]';
    nominal_price = tariff - subsidy;
    
    % X and Y axis
    bars = horzcat(nominal_price,subsidy);
    labels = [2010 2011 2012 2013 2014 2015 2016 2017]';
    
    % Stacked bar plot
    f0 = figure('Renderer', 'painters', 'Position', [10 10 900 600]);
    hold on;
    barFig = bar(labels,bars,'stacked','FaceColor','flat', 'LineWidth', 2);
    barFig(1).CData = [0 0 0];
    barFig(2).CData = [1 1 1]; 
    
    % Formatting plot
    textProp = {'fontsize'    , 24, ...
            'FontName'    , 'Times New Roman'};
        
    xticks([2010 2011 2012 2013 2014 2015 2016 2017])
    xticklabels({'2010', '2011', '2012', '2013', '2014', ...
        '2015','2016','2017'})
    
    yticks(0:1:7)
    
    set(gca,'XLim',[2009 2018],textProp{:})
    xlabel('Fiscal year beginning', textProp{:});
    ylabel('Price (INR/kWh)',textProp{:});
    
    % Horizontal line to indicate marginal cost
    mcLine = plot(xlim,[6.2 6.2],'LineWidth', 2, 'Color', 'black', 'LineStyle', '- -');
    text(2013,6.4,'Marginal cost','FontSize',18)
    hold off;
    
    % Legend
    legend([barFig(2), barFig(1)],'Subsidy','Price net of subsidy', ...
        'Location','southoutside',...
        'Orientation','vertical',...
        'FontName','Times New Roman',...
        'fontsize',18);
    legend boxoff;
    
    % Crop whitespace from output
    fig = gcf;
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    
    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4);
    ax.Position = [left bottom ax_width ax_height];
    
    % Write to disk
    fprintf(1,'Writing %s to file ...\n',filename);
    print(f0,'-depsc','-painters','-noui','-r600', filename);
end