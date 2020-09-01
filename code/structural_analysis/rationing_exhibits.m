 %% ========================================================================
%                 Estimation results
%%=========================================================================

%% Plot distributions of productivity
cd(figures)
file = 'fig_tfp_distribution.pdf';
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
file = sprintf('fig_shadow_value_ration%s.pdf',suffix);
plotAtMeanObs = false;
counters{5}.plotShadowValue( file, planner.opt_price, plotAtMeanObs );

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
file = sprintf('fig_pigouvian_redistribution%s.pdf',suffix);

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

% Marginal benefit estimates
benefits.d_Pi_d_D         = 8.87;
benefits.d_Pi_d_D_SE      = 2.47;
benefits.D_bar_over_H_bar = 0.24652;

% Create table
filepath = [tables '/tab_optimal_ration_inner'];
tabulateOptimalRation( benefits, counters{5}, lambda_w_ltr.med, filepath );


%% Bar chart of marginal benefits and costs of increasing ration

% Plot
filepath = [figures '/fig_optimal_ration.pdf'];
plotOptimalRation( benefits, counters{5}, lambda_w_ltr, filepath );

% Value of discount rate that equates marginal benefit to marginal social
% cost
objective = @(beta) marginalBenefitMinusCost(benefits,lambda_w_ltr.med,counters{5},beta);
beta_0 = fzero(objective,1);
fprintf('MB = MSC for beta = %1.4f\n',beta_0);


%% Tariff and subsidy by year
plotTariffSubsidy([figures '/fig_tariff.pdf'])
 


%% ========================================================================
%                                 END
%%=========================================================================
