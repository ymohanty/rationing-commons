function [ ] = plotTFPDistribution( obj, file )
% plotTFPDistribution  Plot distribution of TFP
%
% INPUT :
%  obj          waterModel object in which TFP is estimated
%  write        dummy for whether to write the bid object to a file
%
% OUTPUT :
%               Writes plot to file

%% Formatting options
textProp = {'fontsize'    , 18, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
                
%% Data to plot
tfpA = obj.omega_hatA;
% tfpB = obj.omega_hatB;
tfpC = obj.omega_hatC;

% fprintf(1,['The variance of Gollin-Udry deflated TFP is %3.2f ' ...
%     'as large as the variance of raw TFP\n'],var(tfpB)/var(tfpA));

fprintf(1,['The variance of TFP-shock-only deflated TFP is %3.2f ' ...
    'as large as the variance of raw TFP\n'],var(tfpC)/var(tfpA));
fprintf(1,['The log difference of 90th and 10th percentile of the TFP-shock-only deflated' ...
    'TFP is %3.2f\n'], prctile(tfpC,90) - prctile(tfpC,10))

N = 400;
x = linspace(-2,2,N);
[ fa ] = ksdensity( tfpA, x );
% [ fb ] = ksdensity( tfpB, x );
[ fc ] = ksdensity( tfpC, x );

%% Plot PDF first
f0 = figure;
plot(x,fc,'b-' ,'LineWidth',2);  
hold on;
% plot(x,fb,'b--','LineWidth',2);  
plot(x,fa,'b:' ,'LineWidth',2);  

ymax = ceil(4*max(fc))/4;
ylim([0 ymax]);

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gca, labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                , ...
         'YTick'       , [0:0.25:ymax]      , ...
         'XTick'       , [-2:1:2]      , ...
         'PlotBoxAspectRatio', [1 0.62 0.62]);  
     
% Axis labels
xlabel('log(TFP)',textProp{:},'Interpreter','latex')
ylabel('Probability density',textProp{:},'Interpreter','latex')

legend('Deflated to remove measurement error',...
    'Raw',...
    'Location','southoutside',...
    'Orientation','vertical',...
    'FontName','Times New Roman',...
    'fontsize',18);
% 'Deflated (Productivity shocks to TFP and factors)',...
  
legend boxoff;
hold off;

%% Export figure to file

% Crop whitespace 
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
fprintf(1,'Writing %s to file ...\n',file);
print(f0,'-depsc','-painters','-noui','-r600', file);


% if file
%     fprintf(1,'Writing %s to file ...',file);
%     export_fig(file,'-painters','-m2');
%     fprintf(1,' complete.\n');
% end

end
