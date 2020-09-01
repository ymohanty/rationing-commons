%% ========================================================================
%          Rationing the Commons
%            
%          Main file for structural analysis.  
%            * Production function estimates
%            * Opportunity cost estimates
%            * Counterfactual runs
%            * Paper and appendix exhibits
%
%%=========================================================================

run('rationing_setup.m');

% Switches for what to run
runEstimates = ~exist([data 'production_function_estimates.mat'], 'file');
sendToPaper  = false;

%% ========================================================================
%                 Estimation
%%=========================================================================

if runEstimates
    run('rationing_estimates.m');
else
    cd(data);
    filename = 'production_function_estimates.mat';
    load(filename);
    run('rationing_setup.m');
end


%% ========================================================================
%                 Calculate opportunity cost of water
%%=========================================================================

run('rationing_opportunity_cost.m');


%% ========================================================================
%                 Calculate marginal benefit of ration increase
%%=========================================================================

% run('rationing_setup.m');

% Calculate marginal benefit and cost of increase
run('rationing_marginal_benefit.m');


%% ========================================================================
%                 Counterfactuals
%%=========================================================================

% Select model
% model = model; 
% model = modelIvAll;   % Without calibration of alpha_W
% model = modelIvTlog;  % With translog production function

run('rationing_counterfactuals.m');


%% ========================================================================
%                 Exhibits
%%=========================================================================

run('rationing_exhibits.m');


%% ========================================================================
%                                 END
%%=========================================================================
