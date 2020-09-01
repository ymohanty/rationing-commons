%% Setup
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


%% Read production function input data
cd(data);
file  = 'production_inputs_outputs.txt';
water = waterData(file);

%% Prepare for IV

% Dependent variable
    yname = {'profit_total_t'};

    % The design matrix
    soil = {'missing_soil_controls','prop_acidic',...
                    'prop_mildly_alkaline','prop_high_k',...
                    'prop_med_k','prop_high_p','prop_med_p',...
                    'prop_sufficient_zn',...
                    'prop_sufficient_fe','prop_sufficient_cu',...
                    'prop_sufficient_mn'};

    topos = {'elevation','slope', 'missing_topos'};

    SDOs = {'x_Isdsdo_2','x_Isdsdo_3','x_Isdsdo_4',...
                    'x_Isdsdo_5','x_Isdsdo_6'};           
    controls = [soil topos SDOs];

    endog = {'depth'};

    Xnames = [endog controls];

    % The instrument matrix
    Znames = {'rock_area_1','rock_area_4','rock_area_6',...
                                  'rock_area_9','rock_area_15','rock_area_20',...
                                  'aquifer_type_4','rock_area2_4','rock_area2_10',...
                                  'ltot5km_area1115','dist2fault_area112',...
                                  'dist2fault_area116','dist2fault_area1114',...
                                  'dist2fault_area1120','dist2fault_area1146'};
                          
% Run the bootstrap
bootcoefs = bootstrap_iv(water,yname,Xnames,Znames,endog,'sdo_feeder_code',1000);
bootstrap_relaxing_ration = -46.2*1000*bootcoefs(1,:);
main_relaxing_ration = -46.2*1000*coef(1);
analytical_se = 46.2*1000*se(1);


% Histgoram of the effect of relaxing the ration
textProp = {'FontSize'    , 16, ...
            'FontName'    , 'Times New Roman'};
histogram(bootstrap_relaxing_ration);
xlabel('Effect of relaxing the ration (INR per hour)',textProp{:});



                          
                          


            



