classdef waterDynamics_ym
    %
    % waterDynamics
    % 
    % The waterDynamics class contains a dynamic extension of the
    % production function model.  We use this model to calculate the 
    % opportunity cost of water.  The key additional data inputs are the  
    % time paths of water depth, extraction and hours of operation
    % with initial conditions calculated from the farmer survey. 
    % 
    properties
        
        % Data dependent properties
        P;                          % Pump capacity 
        D_0;                        % Average starting depth
        gamma;                      % Unit conversion in groundwater law of motion 
        
        % Constant properties
        delta = 1.4;                % Water extraction rate by sustainable rate
        alpha_w;                    % Output elasticity of water (Estimated from main model)
        c_E = 6.2;                  % Marginal cost of electricity
        p_E = 0.9;                  % Price of electricity per unit
        beta;                       % Discount parameter
        H_bar = 6;                  % Electricity ration 
        days = 42;                  % Irrigation days in Rabi season
        omega;                      % TFP
        
        % Implied and observed initial conditions 
        R;                          % Implied rainfall
        W_0;                        % Vector of observed starting water extraction
        H_0;                        % Observed starting electricity use
        rho_tilde=8.8*10e+3;        % Frictional loss  
        rho;                        % Pump efficiency
        
        % Data
        data_paths;                 % Struct of paths to data {initial conditions, depth data, production function}
        depth_data;                 % Matrix containing depths of wells dug by farmers
        
        % Opportunity cost of water
        lambda_w_kwh;               % Opp cost (INR/KwH)
        lambda_w_kwh_se;            % Standard error (INR/KwH)
        lambda_w_ltr;               % Opp cost (INR/ltr)
        lambda_w_ltr_se;            % Standard error (INR/ltr)
        
    end
    
    methods
        
        function obj = waterDynamics(beta,alpha,data_paths)
            if nargin > 0
                %% Constructor for model object
                
                % Read in the data on well depths
                obj.data_paths = data_paths;
                obj.depth_data = readtable( obj.data_paths.depth_data, ...
                                            'Delimiter', ',' );
                
                % Assign discount rate
                obj.beta = beta;

                % Assign inputs/parameters
                init_conditions = readtable(obj.data_paths.init_conditions, ... ,
                                            'Delimiter', ',');
                obj.D_0 = init_conditions.depth;
                obj.P = init_conditions.mean_pump_capacity_farmer;
               
                % Use estimated TFP and alpha
                obj = obj.getAlphaOmega;
                obj.alpha_w = alpha;

                % Calculate initial electricity and water use
                obj.H_0 = min(1./obj.days.*1./obj.P.*(obj.omega.*obj.alpha_w/obj.p_E).^(1/(1-obj.alpha_w)) ...
                      .*(obj.rho_tilde./obj.D_0).^(obj.alpha_w/(1-obj.alpha_w)),obj.H_bar);                  
         
                obj.W_0 = obj.days.*obj.rho_tilde.*obj.P.*obj.H_0./obj.D_0;

                % Calculate implied rainfall
                obj.R = obj.W_0./obj.delta;

                % Calculate rho
                obj.rho = obj.rho_tilde.*obj.P;
                 
            end
        end
        
        function obj = getAlphaOmega(obj)
            %% Get output elasticity of water and TFP from main model
            
            % Get estimates for \Omega and \Alpha_w from main model
            water = waterData(obj.data_paths.production_inputs_outputs);
            water.clean.water = log(water.clean.Water*1000);
            wmodel = waterModel(water);

            % With soil controls
            wmodel.addSoil = true;
            wmodel.noisyEstimates = false;
            wmodel = wmodel.estimateIV;
            wmodel = wmodel.decomposition;
            wmodel = wmodel.residuals;

            % ALPHA_W
            obj.alpha_w = wmodel.iv.coef(4);

            % OMEGA = e^(W_e\beta_e)*(L^alpha_L*K^alpha_K*X^alpha_X) 
            obj.omega = 1000*mean(exp(table2array(wmodel.data.clean(:,wmodel.betaYENames)) ...
                                    * wmodel.betaYE)).*mean(water.clean.Land).^wmodel.iv.coef(1).*mean(water.clean.Labor) ...
                                    .^wmodel.iv.coef(2).*mean(water.clean.Capital).^wmodel.iv.coef(3);
        end
        
        function obj = estimateLawOfMotion(obj,N)
            %% Estimate the rate of recharge from data on wells dug
            
            % Set up loss function handle and the optimizer
            loss_fun = @(x) lossFunction(obj,x);
            options = optimset('TolFun',1e-9);
            
            % Get point estimate
            gamma_hat = fminsearch(loss_fun, 0, options);

            % Create bootstrap sample
            years = unique(obj.depth_data.year_dug); % The years in the sample (cluster)
            seed = RandStream('mlfg6331_64'); % For consistent randomization.
            gamma_hat_boot = zeros(N,1); % Empty vector to store bootstrapped estimates
            
            for iter = 1:N
                C = cell(length(years),1); % Cell array to hold bootsamples within each block (year).
                
                for j = 1:length(years)
                    depths_in_year_j = obj.depth_data(obj.depth_data.year_dug == years(j),:);
                    sample_size = length(depths_in_year_j.year_dug);
                    C{j} = sortrows(depths_in_year_j(randsample(seed,sample_size,sample_size,true),:)); % Sample with replacement within year
                end
                
                % Store estimate from bootstrap sample
                obj.depth_data = cat(1,C{:}); % Concatenate the year-by-year depth values
                
                % Reset loss function handle 
                loss_fun = @(x) lossFunction(obj,x);
                gamma_hat_boot(iter) = fminsearch(loss_fun, 0, options);
            end
   
            % Concatenate point estimate and bootsample estimates
            obj.gamma = vertcat(gamma_hat,gamma_hat_boot);
            
            % Reset depth data
            obj.depth_data = readtable(obj.data_paths.depth_data,'Delimiter',',');
        end
        
        function sse = lossFunction(obj,gamma)
            %% Loss function for estimating the groundwater law of motion
            
            % Turn data table into vectors
            vec_real_depths = table2array(obj.depth_data(:,'depth'));
            vec_real_years = table2array(obj.depth_data(:,'year_dug'));
            
            % Get unique years (along with their respective frequencies) in the dataset and get total length of time
            % in sample.
            [years, ~, ic] = unique(vec_real_years);
            freq = accumarray(ic,1); 
            T = max(years) - min(years) + 1;

            % Rescale years to begin at 1
            start_year = min(years);
            end_year = max(years);
            years = years - start_year + 1;

            % Set up the time paths
            H_t = zeros(1,T); % Time path of electricity use
            W_t = zeros(1,T); % Time path of water extraction
            D_t = zeros(1,T); % Time path of groundwater depth

            % Initial conditions
            D_t(1) = mean(vec_real_depths(vec_real_years == end_year)); % Mean of the last year of data
            H_t(1) = min(1/obj.days*1/mean(obj.P)*(obj.omega*obj.alpha_w/obj.p_E)^(1/(1-obj.alpha_w)) ...
                              *(obj.rho_tilde/D_t(1))^(obj.alpha_w/(1-obj.alpha_w)),obj.H_bar);
            W_t(1) =  obj.days.*obj.rho_tilde.*mean(obj.P).*H_t(1)./D_t(1);
            R = W_t(1)./1.4;

            % Project backwards
            for i=2:T
                D_t(:,i) = max(0.000001,D_t(:,i-1) - gamma.*(W_t(:,i-1) - R));
                H_t(:,i) = min(1/obj.days.*1./mean(obj.P).*(obj.omega.*obj.alpha_w./obj.p_E).^(1/(1-obj.alpha_w)) ...
                          .*(obj.rho_tilde./D_t(:,i)).^(obj.alpha_w/(1-obj.alpha_w)),obj.H_bar);
                W_t(:,i) = obj.days.*obj.rho_tilde.*mean(obj.P).*H_t(:,i)./D_t(:,i);
            end

            % Flip the vector of depths to be in the chronological order
            D_t = flip(D_t);

            % Compute difference between projected and actual depth
            diff = zeros(length(vec_real_depths),1);
            for j = 1:length(years) 
                for k = 1:freq(j)
                    index = sum(freq(1:j-1)) + k;
                    diff(index) = (vec_real_depths(index) - D_t(years(j))).^2; 
                end 
            end

            % Sum of squared error of model predictions and actual depth
            sse = sum(diff);
            
        end
        
        
        function [welfare, H_t, W_t, D_t, S_t] = calcTimePaths(obj, T, inc_water, inc_elec)
            %% Calculate the time-paths for electricity, water, depth and surplus
            H_t = zeros(length(obj.P),length(obj.gamma), T); % Time path of electricity use
            W_t = zeros(length(obj.P),length(obj.gamma), T); % Time path of water extraction
            D_t = zeros(length(obj.P),length(obj.gamma), T); % Time path of groundwater depth
            S_t = zeros(length(obj.P),length(obj.gamma), T); % Time path of surplus
            
            % Initial electricity use
            H_t(:,:,1) = repmat(obj.H_0,1,length(obj.gamma));
            
            
            % Initial water use (cases for opp. cost calculation)
            if inc_water
                W_t(:,:,1) = repmat(obj.W_0,1,length(obj.gamma)) + 1;
            elseif inc_elec
                W_t(:,:,1) = repmat(obj.rho_tilde.*(obj.days.*obj.P.*H_t(1)+1)./obj.D_0,1,length(obj.gamma));
            else
                W_t(:,:,1) = repmat(obj.W_0,1,length(obj.gamma));
            end
            
            % Initial depth
            D_t(:,:,1) = repmat(obj.D_0,1,length(obj.gamma)); 
            
            % Initial welfare
            S_t(:,:,1) = repmat(obj.omega.*(obj.rho_tilde.*obj.H_0./obj.D_0).^obj.alpha_w ...
                    - obj.c_E.*obj.P.*obj.H_0,1,length(obj.gamma));
                
            for t=2:T
                D_t(:,:,t) = max(D_t(:,:,t-1) + obj.gamma.'.*(W_t(:,:,t-1) - obj.R),0);
                H_t(:,:,t) = min(1/obj.days.*1./obj.P.*(obj.omega.*obj.alpha_w./obj.p_E).^(1/(1-obj.alpha_w)) ...
                  .*(obj.rho_tilde./D_t(:,:,t)).^(obj.alpha_w./(1-obj.alpha_w)),obj.H_bar);
                W_t(:,:,t) = obj.days.*obj.rho_tilde.*obj.P.*H_t(:,:,t)./D_t(:,:,t);
                S_t(:,:,t) = obj.beta.^(t-1).*(obj.omega.*(W_t(:,:,t)).^(obj.alpha_w) ...
                       - obj.c_E.*obj.P.*H_t(:,:,t));
            end
            
            % Convert water use to '000000 liters
            W_t = 1/1000000.*W_t;
            
            % Get total welfare
            welfare = sum(S_t,3);
            welfare(welfare == Inf) = NaN;
            welfare = nanmean(welfare,1);
            
        end
        
        function obj = oppCostWater(obj, T)
            %% Calculate the opportunity cost of water (see document)
            obj = obj.oppCostWaterKwH(T);
            obj = obj.oppCostWaterLtr(T);   
            
            obj.printOppCost;
        end
        
        function obj = printOppCost(obj)
            %% Print estimation results
            fprintf(1,'\n\nEstimates of the opportunity cost of water for parameters\n\n');
            fprintf(1,'\t alpha = %1.2f\n',obj.alpha_w);
            fprintf(1,'\t beta = %1.2f\n\n',obj.beta);
            fprintf(1,'-----------------------------------\n');
            fprintf(1,'\tINR/kWh\t\tINR/ltr\t\n');
            fprintf(1,'-----------------------------------\n');
            fprintf(1,'\t%1.2f\t\t%1.4g\t\n',obj.lambda_w_kwh,obj.lambda_w_ltr);
            fprintf(1,'\t(%1.2f)\t\t(%1.4f)\t\n',obj.lambda_w_kwh_se,obj.lambda_w_ltr_se);
            fprintf(1,'-----------------------------------\n');
        end
        
        function obj = oppCostWaterKwH(obj,T)
            %% Calculate the opportunity cost of water in INR/KwH terms
            [welfare_1, ~, ~, ~, ~] = calcTimePaths(obj,T,0,1);
            [welfare_0, ~, ~, ~, ~] = calcTimePaths(obj, T, 0, 0);
            
            lambda_w = welfare_0 - welfare_1;
            
            obj.lambda_w_kwh = lambda_w(1);
            obj.lambda_w_kwh_se = std(lambda_w(2:end));
        end
        
        function obj = oppCostWaterLtr(obj,T)
            %% Calculate the opportunity cost of water in INR/ltr terms
            [welfare_1, ~, ~, ~, ~] = calcTimePaths(obj,T,1,0);
            [welfare_0, ~, ~, ~, ~] = calcTimePaths(obj, T, 0, 0);
            
            lambda_w = welfare_0 - welfare_1;
            
            obj.lambda_w_ltr = lambda_w(1);
            obj.lambda_w_ltr_se = std(lambda_w(2:end));
        end
   
    end % methods 
    
end
    
      