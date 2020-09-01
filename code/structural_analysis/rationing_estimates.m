%% ========================================================================
%          Estimation of water scarcity production model
%%=========================================================================


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
model    = model.estimateOLS;
model    = model.decomposition;
modelOls = model;


%% Fit production function model by IV (only water endogenous)
model = waterModel(water);

% Set estimation options
model.estimationMethod = 'iv';
model.waterEndogOnly   = true;
model.ivSet            = 'water';
model.printFirstStage  = false;

% Estimate model
model      = model.estimateIV;
model      = model.decomposition;
model      = model.residuals;
modelIvWat = model;


%% Fit production function model by IV (all inputs endogenous)
model = waterModel(water);

% Set estimation options
model.estimationMethod = 'iv';
model.ivSet            = 'logInvDepthPDS';
model.printFirstStage  = false;

% Estimate model
model      = model.estimateIV;
model      = model.decomposition;
model      = model.residuals;
modelIvAll = model;


%% Calibrate alpha_W to match reduced-form effect of relaxing the ration
model.calibrateAlpha = true;

% Create counterfactual function that yields marginal benefit given alphaW
counter        = waterCounter( model );
counter.policy = waterPolicy('rationing');
model.alpha(end) = counter.calibrateAlpha( 2.190 );


%% Fit production function model by IV (all inputs endog, bootstrap SEs)

% Set estimation options
model.estimationMethod = 'iv';
model.ivSet            = 'logInvDepthPDS';
model.printFirstStage  = false;
model.noisyEstimates   = false;
model.noisy            = false;

% Estimate model
modelIvBoot = model.estimateIVBoot;
modelIvBoot.iv.coef(strcmp(modelIvBoot.iv.xnames,'water')) = model.alpha(end);


%% Fit production function model by IV (all inputs endogenous, translog)

% Set model.translogTerms = true at initialization
translogTerms = 1;
modelIvTlog = waterModel(water,translogTerms);

% Set estimation options
modelIvTlog.estimationMethod = 'iv';
modelIvTlog.ivSet            = 'logInvDepthPDS';
modelIvTlog.translogTerms    = true;

% Estimate model
modelIvTlog = modelIvTlog.estimateIV;
modelIvTlog = modelIvTlog.decomposition;
modelIvTlog = modelIvTlog.residuals;


%% Store production function estimates

cd(data);
filename = 'production_function_estimates.mat';
save(filename);

% Store TFP data for reduced form estimation 
modelIvBoot.saveProductivityData('tfp_by_farmer_crop.csv')

%% ========================================================================
%                                 END
%%=========================================================================