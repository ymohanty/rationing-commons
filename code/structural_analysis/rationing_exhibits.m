 %% ========================================================================
%                 Estimation results
%%=========================================================================

%% Plot distributions of productivity
cd(figures)
file = 'fig_tfp_distribution.eps';
model.plotTFPDistribution( file );

%% Tabulate production function

cd(tables)
estimates = { modelOls, modelIvWat, modelIvAll, modelIvBoot };
file = 'tab_production_estimates.tex';

tabulateProductionEstimates( estimates, file );

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
cd(figures)
file = sprintf('fig_shadow_value_ration%s.eps',suffix);
plotAtMeanObs = true;
counters{5}.plotShadowValue( file, planner.opt_price, plotAtMeanObs );

%% Comparison of shadow value of ration and profit
file = [figures '/fig_shadow_value_profit.eps'];
counters{5}.scatterValue('profit','lambda_con_h', 1/20, 1/10, 'Profit (INR ''000/ha)','Shadow cost of ration (INR/kWh)', 'fp', true, true, file, optfig);

%% Counterfactual input use

keys = {'rationing','pigouvian'};
vals = {counters{5},counters{8}};
counters_map = containers.Map(keys,vals);

% Log of water use
lab = 'log(Water)';
filename = [figures '/fig_water_rationing_pigouvian'];
plotCounterFactualInputUse(counters_map, 'fp', 'water', true, 1/2, lab, filename, optfig);

% Log of capital use
lab = 'log(Capital)';
filename = [figures '/fig_capital_rationing_pigouvian'];
plotCounterFactualInputUse(counters_map, 'fp', 'capital', true, 1/2, lab, filename, optfig);

% Log of output
lab = 'log(Output)';
filename = [figures '/fig_output_rationing_pigouvian'];
plotCounterFactualInputUse(counters_map, 'fp','output', true, 1, lab, filename, optfig);

% Hours
lab = 'Hours of use';
filename = [figures '/fig_hours_rationing_pigouvian'];
plotCounterFactualInputUse(counters_map, 'fp','Hours', false, 1/4, lab, filename, optfig);



%% Tabulate counterfactual mean outcomes

cd(tables)
file = sprintf('tab_counterfactual_outcomes%s.tex',suffix);
tabulateCounterfactuals( counters(5:8), file );

file = sprintf('tab_counterfactual_outcomes_wblock%s.tex',suffix);
tabulateCounterfactuals( [ counters(5:8); counters(13) ], file );

%% Tabulate distributional impacts of reform with transfers

cd(tables)
file_stub = sprintf('tab_counterfactual_redistribution%s',suffix);

level     = 'fmplot';
tabulateRedistribution( [counters(5); counters(9:12)], level, file_stub );

level     = 'farmer';
tabulateRedistribution( [counters(5); counters(9:12)], level, file_stub );

%% Plot distributional impact of reform by land size

cd(figures)
file = sprintf('fig_pigouvian_redistribution%s.eps',suffix);

outcome   = 'profit';
condition = 'Land';
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 3 );
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 2 );
plotReformRedistribution( counters, file, outcome, condition, 'kernel', 1 );


%% ========================================================================
%     Descriptive exhibits and exhibits based on marginal analysis 
%%=========================================================================

%% Regimes, prices and rations

% ADD CODE HERE


%% Components of optimal ration table

% Marginal benefit estimates (reduced form)
benefits.d_Pi_d_D         = 8.44;
benefits.d_Pi_d_D_SE      = 2.41;
benefits.D_bar_over_H_bar = 46.2/186.5;

% Create table
filepath = [tables '/tab_optimal_ration_inner'];
tabulateOptimalRation( benefits, counters{5}, lambda_w_ltr.med, filepath );


%% Bar chart of marginal benefits and costs of increasing ration

% Plot
filepath = [figures '/fig_optimal_ration.eps'];
plotOptimalRation( benefits, counters{5}, lambda_w_ltr, filepath );

% Value of discount rate that equates marginal benefit to marginal social
% cost
objective = @(beta) marginalBenefitMinusCost(benefits,lambda_w_ltr.med,counters{5},beta);
beta_0 = fzero(objective,1);
fprintf('MB = MSC for beta = %1.4f\n',beta_0);


%% Tariff and subsidy by year
plotTariffSubsidy([figures '/fig_tariff.eps'])
 


%% ========================================================================
%                                 END
%%=========================================================================
