%% ========================================================================
%
%   Rationing the Commons -- Dynamic Analysis
%
%   Calculating the opportunity cost of water under different choices of
%   model parameters.
%
%%=========================================================================

% Paths for data and exhibits
if sendToPaper
    outpath                   = [paper,'/tab_opp_cost'];
    outpath_param             = [paper '/tab_dynamic_parameters'];
else
    outpath                   = [tables,'/tab_opp_cost'];
    outpath_param             = [tables '/tab_dynamic_parameters'];
end

datapaths.init_conditions = [data,'mean_init_conditions.txt'];
datapaths.depth_data      = [data,'depth_data.txt'];
datapaths.production_inputs_outputs = [data,'production_inputs_outputs.txt'];

%% Estimation of opportunity cost

% Parameter vectors
alpha = [0.12,0.15,0.18,0.21,0.24]; % Concavity of the production function
beta  = [0.95,0.90,0.75];           % Discount rate

% Set single alpha
% alpha = modelIvBoot.iv.coef(ismember(modelIvBoot.iv.xnames,'water'));

% Estimation
opp_cost_alpha_fixed = cell(length(beta),length(alpha));
opp_cost_alpha_estim = cell(length(beta),1);

% % Sampling error in alpha and gamma both
% for i = 1:length(beta)
%     wd = waterDynamics(modelIvBoot,datapaths,beta(i));
%     wd = wd.estimateLawOfMotionBoot;
%     opp_cost_alpha_estim{i,j} = wd.oppCostWater;
% end

% Fix alpha and bootstrap over gamma only
for i = 1:length(beta)
    for j = 1:length(alpha)
        wd = waterDynamics(modelIvBoot,datapaths,beta(i),alpha(j));
        wd = wd.estimateLawOfMotionBoot;
        opp_cost_alpha_fixed{i,j} = wd.oppCostWater;
    end
end

% Store opportunity cost of water
lambda_w_ltr.high = opp_cost_alpha_fixed{1,3};
lambda_w_ltr.med  = opp_cost_alpha_fixed{2,3};
lambda_w_ltr.low  = opp_cost_alpha_fixed{3,3};

%% Exhibits on opportunity cost 

% Estimates table
tabulateOppCostParameters(opp_cost_alpha_fixed,outpath,'kwh');
tabulateOppCostParameters(opp_cost_alpha_fixed,outpath,'liter');

% Parameters table
tabulateWaterDynamicsParameters(opp_cost_alpha_fixed{1,3},outpath_param);


%% ========================================================================
%                                   END
%%=========================================================================










