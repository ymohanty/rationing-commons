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

%% Water, capital endogenous
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

% planner.plotPlannersObjective( [0.5:0.5:15 ] );

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

% Aggregate outcomes to the farmer X simulation level
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
%                                 END
%%=========================================================================