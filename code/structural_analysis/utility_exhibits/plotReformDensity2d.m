function [ ] = plotReformDensity2d( counters, file )
%plotReformDensity2d Plot 2-D distribution of land size and the change in
%  profits due to reform
%   
% INPUT :
%  obj         type model object with estimates of 2-D types
%
% OUTPUT :
%              Writes plot to file
if nargin < 2
    file = 0;
end

%% Formatting options
textProp = {'fontsize'    , 20, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
        
%% Data to plot

% Change in profit at farmer X simulation level
deltaProfit = counters{2}.farmer.profit - ...
              counters{1}.farmer.profit;
deltaProfitPct = 100* deltaProfit ./ counters{1}.farmer.profit;

% Deciles of land size distribution
tau        = [ 5:5:100 ];
land       = counters{1}.farmer.land;
quantiles  = prctile(land,tau);
land_qtile = repmat(land,1,length(quantiles)) > ...
             repmat(quantiles,length(land),1);       
land_qtile = sum(land_qtile,2) + 1;
display(accumarray(land_qtile,land,[],@mean));

land_qtile = tau(land_qtile)';

% Estimate kernel density on a grid
x = [ land deltaProfit ];
x = x( ~any(isnan(x),2), : );

%% Kernel density estimation on a grid

% Bandwidths and kernel
h_land   = 0.25;
h_profit = 5;

% Range over which to plot density
land_range   = [ -2:0.1:2 ]';
profit_range = [ -50:5:200 ]';
[ land0, profit0 ] = ndgrid(land_range,profit_range);

land0v   = land0(:)';
profit0v = profit0(:)';
P        = length(land0v);

% Set kernel
% K   = @(u) 0.75*(1-u.^2) .* (abs(u) <= 1); % Epanechnikov kernel
K   = @(u) 1/sqrt(2*pi)*exp(-u.^2/2);      % Normal kernel
n   = size(x,1);

% Calculate density for every point in grid
K_pi = 1/h_land*K( (x(:,ones(P,1))-land0v(ones(1,n),:))/h_land ) ...
    .* 1/h_profit .* K( (x(:,2*ones(P,1))-profit0v(ones(n,1),:))/h_profit ); 
fx0 = 1/n * sum( K_pi, 1);
fx0 = reshape(fx0',size(land0,1),[]);
       
%% Plot supply, demand and the clearing price
surf(land0,profit0,fx0);
hold on;
view(157,27);

xlim([0 25000]);
ylim([0 2]);

% Figure formatting
c = gray;
lightgray = c(33:end,:);
colormap(lightgray);

% c = autumn;
% lightautumn = c(6:end,:);
% colormap(lightautumn);

set(gcf, 'Color'       , 'w' );
set(gcf, 'units', 'points', 'position', [200,200,800,800] );
set(gca, textProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                );  
     
% Axis labels
xlabel('Heat rate $h_i$ (btu/kWh)',textProp{:},'Interpreter','latex')
ylabel('Bonus $\Delta_i$ (INR/kWh)',textProp{:},'Interpreter','latex')
% title('Joint Distribution of Bidder Types','Interpreter','latex');

hold off;

%% Export figure to file
if file
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end

end
