function [ ] = plotOptimalTransfers( obj, file )
%plotOptimalTransfers Plot transfer policy that minimizes losers
% 
% INPUT:
%   obj - Counterfactual object with transfer policy as table property
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
        
%% Assign data

x1 = unique(table2array(obj.transfers(:,1)));
x2 = unique(table2array(obj.transfers(:,2)));
Q  = length(x1);

T  = reshape(obj.transfers.Transfer,Q,Q);

%% Plot supply, demand and the clearing price

surf(x1,x2,T);
hold on;
view(45,38);

% xlim([0 25000]);
% ylim([0 2]);
zlim([0 60]);

% Figure formatting
c = gray;
lightgray = c(33:end,:);
colormap(lightgray);

% c = autumn;
% lightautumn = c(6:end,:);
% colormap(lightautumn);

set(gcf, 'Color'       , 'w' );
% set(gcf, 'units', 'points', 'position', [200,200,800,800] );
set(gca, textProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                );  
     
% Axis labels
xlabel('Land size',textProp{:},'Interpreter','latex')
ylabel('Pump size',textProp{:},'Interpreter','latex')
title('Optimal transfer policy','Interpreter','latex');

hold off;

%% Export figure to file
if file
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end

end

