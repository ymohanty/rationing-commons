%% ========================================================================
%                 Additional exhibits / code not used in paper
%%=========================================================================

%% Plot distributional impacts by other observables

% Profit by pump
outcome   = 'profit';
condition = 'pump';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

% Profit by depth
outcome   = 'profit';
condition = 'depth';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

%% Change in hours

% Hours by land
outcome   = 'Hours';
condition = 'Land';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

% Hours by land
outcome   = 'Hours';
condition = 'depth';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

%% Change in output

outcome   = 'Output';
condition = 'Land';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

outcome   = 'Output';
condition = 'pump';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

outcome   = 'Output';
condition = 'depth';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );

%% Plot mean profit change against land and productivity in two dimensions

cd(figures)
file = 'fig_reform_gain_by_land_X_omega.pdf';
plotReformGain2d( counters, file );

%% Plot joint distribution of change in profits and land size

cd(paper);
file = 'fig_density_profit_land.pdf';
plotReformDensity1d( [ counters(5) counters(8) ], file );

%% Counterfactual fit under status quo rationing regime
%    Take water and capital as endogenous

cd(tables);
file = 'tab_counterfactual_fit.tex';
counters{5}.tabulateFit( file );

cd(figures);
file_stub = ['fig_fit_',counters{5}.policy.regime];
counters{5}.plotFit( file_stub );

%% Plot distributional impact of reform by productivity

cd(figures);
file = 'fig_pigouvian_redistribution_byTFP.pdf';
plotReformRedistributionTFP( counters, file );

%% Minimize regret (transfer on observables to offset farmer losses)

counters{9} = counters{9}.findOptimalTransfers( counters{5} );

% Plot policy function
cd(figures);
file = 'fig_optimal_transfer_policy.pdf';
counters{9}.plotOptimalTransfers( file );

%% ========================================================================
%                                 END
%%=========================================================================