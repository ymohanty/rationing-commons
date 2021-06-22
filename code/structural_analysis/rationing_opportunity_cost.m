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
datapaths.sdo_init_conditions = [data, 'sdo_initial_conditions.txt'];
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

% Fix alpha and bootstrap over gamma only
for i = 1:length(beta)
    for j = 1:length(alpha)
        wd = waterDynamics(modelIvBoot,'rationing',datapaths,beta(i),alpha(j));
        wd = wd.estimateLawOfMotionBoot;
        opp_cost_alpha_fixed{i,j} = wd.oppCostWater;
    end
end

% Store opportunity cost of water
lambda_w_ltr.high = opp_cost_alpha_fixed{1,3};
lambda_w_ltr.med  = opp_cost_alpha_fixed{2,3};
lambda_w_ltr.low  = opp_cost_alpha_fixed{3,3};

% Estimate parameters under pigouvian
wd_pigouvian = waterDynamics(modelIvBoot, 'pigouvian', datapaths, beta(2), alpha(3));
wd_pigouvian = wd_pigouvian.estimateLawOfMotionBoot;

% Estimate parameters under rationing
wd_rationing = opp_cost_alpha_fixed{2,3};

% Estimate parameters by SDO
wd_sdo = cell(6);
sdo = {'Bansur','Dug','Hindoli','Kotputli','Mundawar','Nainwa'};
parfor i = 1:6
    wd_sdo{i} = waterDynamics(modelIvBoot, 'rationing', datapaths, beta(2), alpha(3), sdo{i});
    wd_sdo{i} = wd_sdo{i}.estimateLawOfMotionBoot;
end


%% Exhibits on opportunity cost 

% Estimates table
tabulateOppCostParameters(opp_cost_alpha_fixed,outpath,'kwh');
tabulateOppCostParameters(opp_cost_alpha_fixed,outpath,'liter');

% Plot of time path of depth, power use, and water use
wd_rationing.plotTimePath({'depth'},true,100,[figures '/fig_time_path_depth.eps'],optfig);
wd_rationing.plotTimePath({'power'},true,100,[figures '/fig_time_path_power.eps'],optfig);
wd_rationing.plotTimePath({'water'},true,100,[figures '/fig_time_path_water.eps'],optfig);

% Plot depth and water use together
wd_rationing.plotTimePath({'depth','water'},false,100,[figures '/fig_time_path_depth_water.eps'],optfig);

% Plot depth and water use by SDO
parfor i = 1:6
    sdo_name = lower(sdo{i})
    filepath = sprintf([figures '/fig_time_path_%s.eps'], sdo_name);
    wd_sdo{i}.plotTimePath({'depth','water'},false,100,filepath,optfig);
end

% Parameters table
tabulateWaterDynamicsParameters(opp_cost_alpha_fixed{1,3},outpath_param);


%% ========================================================================
%                                   END
%%=========================================================================










