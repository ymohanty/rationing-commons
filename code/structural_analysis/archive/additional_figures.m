%% =========================================================================
%                        Ancillary figures 
%%=========================================================================


%% Tariff and subsidy by year
plotTariffSubsidy([figures,'/fig_tariff.pdf'])

%% Optimal ration

% Generate struct -- Marginal benefits
benefits.d_pi_d_D = 47.4;
benefits.d_pi_d_D_SE = 13.2;
benefits.d_bar_over_h_bar = 46.2;

% Generate struct -- Marginal cost
costs.pump_capacity = 5.03;
costs.land_pump_ratio_SE = 0.15;
costs.lambda_SE = 0.19;
costs.mean_land = 0.65;
costs.days = 42;

% Plot
plotOptimalRation(benefits,costs,[figures,'/fig_optimal_ration.pdf'])