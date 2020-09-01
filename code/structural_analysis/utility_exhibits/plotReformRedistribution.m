function [ ] = plotReformRedistribution( counters, file, outcome, ...
                                         condition, smoothing, panel )
% plotReformRedistribution Plot distributional effects of reform from
%     rationing regime to Pigouvian regime
%
% INPUT :
%  counters     cell array of counterfactuals to compare
%  file         name of file to write plot
%
% OUTPUT :
%               Writes plot to file

%% Formatting options
textProp = {'fontsize'    , 18, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};

%% Data options

% Outcome variable 
%   Examples : 'profit', 'Output' 
if nargin < 3
    outcome = 'profit';
end

% Conditioning variable
%   Examples : 'Land', 'pump', 'depth'
%              Need to check omega_Eit for TFP
if nargin < 4
    condition = 'Land';
end
    
switch condition
    case 'Land'
        tau     = [ [10:15:70] [80:5:100] ];
    case {'pump','depth','omega_Eit'}
        tau     = [ 10 : 10 : 100 ];
end

% Method of aggregation / smoothing
if nargin < 5
    % smoothing = 'binned';
    smoothing = 'kernel';
end

% Panel of animation
if nargin < 6
    panel = 3;
end

% Policy regimes
exante = counters{5};
reform = counters{8};
        
%% Data to plot

% Change in outcome
% delta = table2array(reform.outcomes_fp(:,outcome)) - ...
%         table2array(exante.outcomes_fp(:,outcome));
delta = table2array(reform.fmplot(:,outcome)) - ...
        table2array(exante.fmplot(:,outcome));
% delta = delta >= 0;

% Quantiles of conditioning variable
cond       = table2array(exante.fmplot(:,condition));
quantiles  = prctile(cond,tau);

% Assign quantile to each observation
cond_qtile = repmat(cond,1,length(quantiles)) > ...
             repmat(quantiles,length(cond),1);
cond_qtile = sum(cond_qtile,2) + 1;

% Examine quantiles
fprintf(1,'\nObservations in each quantile of %s distribution\n',condition);
tabulate(cond_qtile);
fprintf(1,'\nMean value of %s in each quantile\n',condition);
display(accumarray(cond_qtile,cond,[],@mean));

% Aggregate data to plot
deltaM = accumarray(cond_qtile,delta,[],@mean);

%% Split mean outcome by productivity quantiles

% Quantiles of productivity
tau_omega  = [ 25 75 ];
qt_omega   = prctile(exante.fmplot.omega_Eit,tau_omega);

% Assign quantile to each observation
omega_qtile = repmat(exante.fmplot.omega_Eit,1,length(qt_omega)) > ...
              repmat(qt_omega,length(exante.fmplot.omega_Eit),1);
omega_qtile = sum(omega_qtile,2) + 1;

deltaH = accumarray(cond_qtile(omega_qtile==3),delta(omega_qtile==3),[],@mean);
deltaL = accumarray(cond_qtile(omega_qtile==1),delta(omega_qtile==1),[],@mean);


%% Calculate smoothed values using local linear regression

% Quantiles of conditioning variable
tau        = [ 0.5 : 0.5 : 100 ];
cond       = table2array(exante.fmplot(:,condition));
quantiles  = prctile(cond,tau);

% Assign quantile to each observation
cond_qtile = repmat(cond,1,length(quantiles)) > ...
             repmat(quantiles,length(cond),1);
cond_qtile = (sum(cond_qtile,2) + 1)/length(tau);

h = 0.075;
kfitDelta  = ksrlin(cond_qtile,delta,h);
kfitDeltaH = ksrlin(cond_qtile(omega_qtile==3),delta(omega_qtile==3),h);
kfitDeltaL = ksrlin(cond_qtile(omega_qtile==1),delta(omega_qtile==1),h);


%% Main plot
f0 = figure;
width = 2;
switch smoothing
    
    case 'binned'
        p1 = plot(tau,deltaL,'b--','LineWidth',width);  
        hold on;
        p2 = plot(tau,deltaH,'b-.','LineWidth',width);
        p3 = plot(tau,deltaM,'b-','LineWidth',width);
        
        if panel == 1
            set(p2,'LineStyle','none');
            set(p3,'LineStyle','none');
        elseif panel == 2
            set(p3,'LineStyle','none');
        end
        
    case 'kernel'
        p1 = plot(kfitDeltaL.x*100,kfitDeltaL.f,'b--','LineWidth',width);  
        hold on;
        p2 = plot(kfitDeltaH.x*100,kfitDeltaH.f,'b-.','LineWidth',width);  
        p3 = plot(kfitDelta.x*100,kfitDelta.f,'b-','LineWidth',width);  
        
        if panel == 1
            set(p2,'LineStyle','none');
            set(p3,'LineStyle','none');
        elseif panel == 2
            set(p3,'LineStyle','none');
        end
end

%% Formatting and labels

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gcf, 'Position',  [1000, 1000, 600, 500])

set(gca, labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                , ...
         'XTick'       , [10:10:100]        , ...
         'PlotBoxAspectRatio', [1 0.85 0.85]);  
     
% Axis labels
if strcmp('Land',condition)
    conditionLabel = 'plot size';
else
    conditionLabel = condition;
end
xlabel(sprintf('Percentile of %s distribution',conditionLabel),textProp{:},'Interpreter','latex')
ylabel(sprintf('Change in %s (INR thousands)',outcome),textProp{:},'Interpreter','latex')
% ylabel('Gain from reform (\%)',textProp{:},'Interpreter','latex')

properString = @(s) regexprep(lower(s),'(\<[a-z])','${upper($1)}');


% Horizontal line
plot([0,100],[0,0],':','LineWidth',1.5,'Color',[0.3 0.3 0.3]);
hold off;

% Legend
legend([p1,p2,p3],sprintf('Mean change in %s if low productivity (bottom quartile)',outcome),...
       sprintf('Mean change in %s if high productivity (top quartile)',outcome),...
       sprintf('Mean change in %s',outcome),...
       'Location','southoutside',...
       'Orientation','vertical',...
       'FontName','Times New Roman',...
       'fontsize',18);
legend boxoff;

%% Export figure to file
file = strrep(file,'.pdf',...
        sprintf('_%s_by%s_panel%1.0f.pdf',outcome,condition,panel));

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
print(f0,'-dpdf','-painters','-noui','-r600', file);

% if file
%     fprintf(1,'Writing %s to file ...',file);
%     export_fig(file,'-painters','-m2');
%     fprintf(1,' complete.\n');
% end

end
