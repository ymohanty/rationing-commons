%% ========================================================================
%          Estimation of water scarcity production model
%%=========================================================================
clear;
root = sprintf('/Users/%s/Dropbox/water_scarcity',getenv('USER'));
cd(root);

code     = [root,'/analysis/code/model/'];
panel_data_toolbox = [code, '/panel_data_toolbox/'];
data     = [root,'/analysis/data/work/'];
figures  = [root,'/analysis/output/figures'];
tables   = [root,'/analysis/output/tables'];
paper    = [root,'/documents/paper/exhibits'];

addpath(code);
addpath(genpath(panel_data_toolbox));


%% ========================================================================
%           Data preparation
%%=========================================================================

%% Read production function input data

cd(data);
file  = 'production_inputs_outputs.txt';
water = waterData(file);
water.correlations;


%% ========================================================================
%                 Estimate model objects
%%=========================================================================

%% Fit production function model by OLS
model = waterModel(water);

% Set estimation options
model.estimationMethod = 'ols';

% Estimate model
model = model.estimateOLS;
model = model.decomposition;
modelOls = model;


%% Fit production function model by IV (only water endogenous)
model = waterModel(water);

% Set estimation options
model.estimationMethod = 'iv';
model.waterEndogOnly   = true;
model.ivSet            = 'water';
model.constrainLabor   = false;

% Estimate model
model = model.estimateIV;
model = model.decomposition;
model = model.residuals;
modelIvWat = model;


%% Fit production function model by IV (all inputs endogenous)
model = waterModel(water);

% Set estimation options
model.estimationMethod = 'iv';
% model.ivSet            = 'full';
model.ivSet            = 'logInvDepthPDS';
% model.printFirstStage  = true;
model.constrainLabor   = false;

% Estimate model
model = model.estimateIV;
model = model.decomposition;
model = model.residuals;
modelIvAll = model;


%% Fit production function model by IV (all inputs endogenous, translog)

% Set model.translogTerms = true at initialization
translogTerms = 1;
model = waterModel(water,translogTerms);

% Set estimation options
model.estimationMethod = 'iv';
model.ivSet            = 'logInvDepthPDS';
model.translogTerms    = true;

% Estimate model
model = model.estimateIV;
model = model.decomposition;
model = model.residuals;
modelIvTlog = model;



%% Fit production model by GMM (all inputs endogenous)

% Set estimation options
model.estimationMethod = 'gmm';
model.ivSet            = 'logInvDepthPDS';
model.gmmAddMoment     = false;

% Estimate model
model = model.estimateGMM;
model = model.decomposition;
model = model.residuals;


%% Fit production model by GMM (Stone-Geary production in water)

% Set estimation options
model.estimationMethod = 'gmm';
model.ivSet            = 'logInvDepthPDS';
model.stoneGeary       = true;

% Estimate model
model = model.estimateGMM;
model = model.decomposition;
model = model.residuals;


%% Fit production model by GMM (all inputs endogenous)
%    Add moment to match estimated return to increasing the ration

% Set estimation options
model.estimationMethod = 'gmm';
model.ivSet            = 'logInvDepthPDS';
model.gmmAddMoment     = true;

% Estimate model
model = model.estimateGMM;
model = model.decomposition;
model = model.residuals;


%% Calibrate alpha_W to match reduced-form effect of relaxing the ration

model.calibrateAlpha = true;

% Create counterfactual function that yields marginal benefit given alphaW
counter        = waterCounter( model );
counter.policy = waterPolicy('rationing');
model.alpha(end) = counter.calibrateAlpha;

% model.bootstrapWaterSE = bootstrapAlpha(model,2.190,0.609,100);


%% Compare marginal benefit calculated from finite difference 
%    to true marginal benefit

% Finite difference

% 1.00 hour
rationIncrease = 1.00;
mb_fd = marginalBenefitOneHour( model, model.alpha(end), rationIncrease );
fprintf(1,'Marginal benefit (%3.2f hour difference): %4.2f INR per hour\n',...
        rationIncrease,mb_fd*1e3);

% 0.10 hour
rationIncrease = 0.10;
mb_fd = marginalBenefitOneHour( model, model.alpha(end), rationIncrease );
fprintf(1,'Marginal benefit (%3.2f hour difference): %4.2f INR per hour\n',...
        rationIncrease,mb_fd*1e3);
    
% True marginal benefit
counter        = waterCounter( model );
counter.policy = waterPolicy('rationing');
mb_tr = counter.marginalBenefit;
fprintf(1,'Marginal benefit (at the margin): %4.2f INR per hour\n',...
    mb_tr*1e3);


%% Calculate marginal cost of an expansion

[ mc, mci ] = counter.marginalCost; 
fprintf(1,'Marginal cost (at the margin): %4.2f INR per hour\n',mc*1e3);
    

%% ========================================================================
%                 Present estimation results
%%=========================================================================

%% Plot distributions of productivity

cd(paper);
file = 'fig_tfp_distribution.pdf';
model.plotTFPDistribution( file );


%% Tabulate production function

cd(tables);
estimates = { modelOls, modelIvWat, modelIvAll };
file = 'tab_production_estimates.tex';

tabulateProductionEstimates( estimates, file );


%% ========================================================================
%                 Counterfactual model runs
%%=========================================================================

% Initialize counterfactual object
counter = waterCounter( model );
counter.productivityDraws = 'simulated';
counters = cell(13,1);


%% Water the only endogenous input
counter.endog = {'water'};

% Rationing: status quo regime
counter.policy = waterPolicy('rationing');
counters{1}    = counter.solveFarmersProblem;

% Rationing: optimal regime
planner        = waterPlanner( counter );
planner        = planner.solvePlannersProblem;
counter.policy.ration = planner.opt_ration;
counters{2}    = counter.solveFarmersProblem;

% Pricing: private cost
counter.policy = waterPolicy('private_cost');
counters{3} = counter.solveFarmersProblem;

% Pricing: Pigouvian regime
counter.policy = waterPolicy('pigouvian');
planner        = waterPlanner( counter );
planner        = planner.solvePlannersProblem;
counter.policy.power_price = planner.opt_price;
counters{4}    = counter.solveFarmersProblem;

% planner.plotPlannersObjective( [0.5:0.5:15 ] );


%% Water, capital and labor all endogenous
counter.endog = {'water','capital'};

% Rationing: status quo regime
counter.policy = waterPolicy('rationing');
counters{5}    = counter.solveFarmersProblem;

% Rationing: optimal regime
planner        = waterPlanner( counter );
planner        = planner.solvePlannersProblem;
counter.policy.ration = planner.opt_ration;
counters{6}    = counter.solveFarmersProblem;

% Pricing: private cost
counter.policy = waterPolicy('private_cost');
counters{7} = counter.solveFarmersProblem;

% Pricing: Pigouvian regime
counter.policy = waterPolicy('pigouvian');
planner        = waterPlanner( counter );
planner        = planner.solvePlannersProblem;
counter.policy.power_price = planner.opt_price;
counters{8}    = counter.solveFarmersProblem;

planner.plotPlannersObjective( [0.5:0.5:15 ] );


%% Redistribution of transfers

% Calculate net revenue under the two regimes
deltaRevenue = -counters{8}.outcomes.power_cost - ...
              (-counters{5}.outcomes.power_cost);
counters{8}.budget = deltaRevenue;

% Redistribute to farmers
counters{5} = counters{5};
counters{5}.budget = deltaRevenue;
counters{5}.transferOn = 'none';
counters{5} = counters{5}.enactTransfers;

counters{9} = counters{8};
counters{9}.transferOn = 'none';
counters{9} = counters{9}.enactTransfers;

counters{10} = counters{8};
counters{10}.transferOn = 'flat';
counters{10} = counters{10}.enactTransfers;

counters{11} = counters{8};
counters{11}.transferOn = 'pump';
counters{11} = counters{11}.enactTransfers;

counters{12} = counters{8};
counters{12}.transferOn = 'land';
counters{12} = counters{12}.enactTransfers;


%% Aggregate outcomes to the farmer X simulation level
scenarios = [ 5 9 10 11 12 ];
for i = 1:length(scenarios)
    fprintf(1,'Aggregating for scenario %3.0f . . . \n',scenarios(i));
    counters{scenarios(i)} = counters{scenarios(i)}.aggregateAcrossPlots;
end


%% Hybrid regime (increasing block pricing)
counter.endog = {'water','capital'};

% Rationing: status quo regime
counter.policy = waterPolicy('block_pricing');
counter.policy.power_price    = planner.opt_price;
counter.policy.price_steps(2) = planner.opt_price;

counters{13} = counter.solveFarmersProblem;


%% ========================================================================
%                 Exhibits based on counterfactuals
%%=========================================================================

% Suffix for filenames based on model used
if model.calibrateAlpha == 0 && model.translogTerms == 0
    suffix = '_nocalib';
elseif model.translogTerms == 1
    suffix = '_translog';
else
    suffix = '';
end


%% Shadow value of ration under status quo regime

cd(tables);
file = sprintf('fig_shadow_value_ration%s.pdf',suffix);
plotAtMeanObs = false;
counters{5}.plotShadowValue( file, planner.opt_price, plotAtMeanObs );


%% Tabulate counterfactual mean outcomes

cd(tables);
file = sprintf('tab_counterfactual_outcomes%s.tex',suffix);
tabulateCounterfactuals( counters(5:8), file );

cd(tables);
file = sprintf('tab_counterfactual_outcomes_wblock%s.tex',suffix);
tabulateCounterfactuals( [ counters(5:8); counters(13) ], file );


%% Tabulate distributional impacts of reform with transfers

cd(tables);
file_stub = sprintf('tab_counterfactual_redistribution%s',suffix);

level     = 'fmplot';
tabulateRedistribution( [counters(5); counters(9:12)], level, file_stub );

level     = 'farmer';
tabulateRedistribution( [counters(5); counters(9:12)], level, file_stub );


%% Plot distributional impact of reform by land size

cd(figures);
file = sprintf('fig_pigouvian_redistribution%s.pdf',suffix);

outcome   = 'profit';
condition = 'Land';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 2 );
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 1 );


%% ========================================================================
%                 Additional exhibits
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



