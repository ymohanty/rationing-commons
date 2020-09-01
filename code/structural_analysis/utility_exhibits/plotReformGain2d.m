function [ ] = plotReformGain2d( counters, file )
%plotOptimalTransfers Plot transfer policy that minimizes losers
% 
% INPUT:
%   obj - Counterfactual objects
%
% OUTPUT:
%   Graph of 2-d policy function
if nargin < 2
    file = 0;
end

%% Formatting options
textProp = {'fontsize'    , 20, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
        
%% Data options

% Policy regimes
exante = counters{5};
reform = counters{8};
        
Xvars = {'Land','omega_Eit'};
X     = table2array(exante.fmplot(:,Xvars));

% Percentiles of X distribution
tau       = [ 10:10:100 ];
quantiles = prctile(X,tau);

N = size(X,1);
Q = size(quantiles,1);
J = size(quantiles,2);
j = zeros(N,J+1);
for jdim = 1:J
    jGtQuant  = repmat(X(:,jdim),1,Q) > ...
                repmat(quantiles(:,jdim)',N,1);
    j(:,jdim) = sum(jGtQuant,2) + 1; 
end

% Unique group IDs and group counts
j(:,end) = 100*j(:,1) + j(:,2);
[ jcode, ~, jid ] = unique(j(:,end));

% jids = jid(:,ones(1,counters{5}.S))';
% jids = jids(:);
% nj = accumarray(jid,ones(size(jid)),[],@sum);


%% Mean change in profit by group

deltaProfit   = reform.fmplot.profit - exante.fmplot.profit;
meanProfitBin = accumarray(jid,deltaProfit,[],@mean);

landQt  = unique(floor(jcode/100));
omegaQt = unique(mod(jcode,100));

% Matrix where . . 
%   Each column is productivity quantile
%   Each row is land quantile
meanProfitBin = reshape(meanProfitBin,length(omegaQt),length(landQt))';


%% Plot supply, demand and the clearing price

S = surf(omegaQt,landQt,meanProfitBin);
hold on;
view(113,13);

zlim([-15 65]);
set(gca, 'XDir','reverse');

% Figure formatting
% c = gray;
% lightgray = c(33:end,:);
% colormap(lightgray);

% autumn
c = hot(256);
colormap(c);
caxis([-10 0]);

set(gcf, 'Color'       , 'w' );
% set(gcf, 'units', 'points', 'position', [200,200,800,800] );
set(gca, textProp{:}, ...
         'Box'         , 'off'              , ...
         'ZTick'       , [-10:10:60]        , ...
         'LineWidth'   , 1.5                );  
     
% Axis labels
xlabel('Productivity ',textProp{:},'Interpreter','latex');
ylabel('Land',textProp{:},'Interpreter','latex');
zlabel('$\Delta \Pi_{ic}$ (INR 000s)','Interpreter','latex');
title('Change in Profit Due to Reform','Interpreter','latex');

hold off;

%% Export figure to file
if file
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end

end

