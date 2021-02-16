classdef waterDynamics
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
        % Estimation parameters
        B = 100;                    % Number of bootstrap iterations
        noisy = false;
        noisyEstimates = true;
        
        % Data dependent properties
        P;                          % Pump capacity 
        D_0;                        % Average groundwater depth
        gamma_hat;                  % Law of motion point estimate
        gamma_b;                    % Law of motion bootstrap estimate
        
        % Constant properties
        delta = 1.4;                % Water extraction rate by sustainable rate
        rho_tilde;                  % Extraction efficiency (liter '000s X feet / 
                                    %                       [kW X hours per day])
        days_use = 42;              % Days of pump use in rabi season
        beta;                       % Discount parameter
        omega;                      % TFP
        horizon = 100;              % Years over which to calculate opp. cost
        
        % Water elasticity of output
        alpha_w_hat;                % Water elasticity, point estimate
        alpha_w_b;                  % Water elasticity, bootstrap estimate
        alpha_w;                    % Water elasticity of output

        % Groundwater policy
        policy;
        
        % Initial groundwater conditions 
        R;                          % Implied recharge of water
        W_0;                        % Observed starting water extraction
        H_0;                        % Observed starting electricity use
        
        % Data
        data_paths;                 % Struct of paths to data {initial conditions, depth data, production function}
        depth_data;                 % Table containing depths of wells dug by farmers
        
        % Opportunity cost of water
        lambda_w_kwh;               % Opp cost (INR/KwH)
        lambda_w_kwh_se;            % Standard error (INR/KwH)
        lambda_w_ltr;               % Opp cost (INR/ltr)
        lambda_w_ltr_se;            % Standard error (INR/ltr)
    end
    
    methods
        
        function obj = waterDynamics(model,policy,data_paths,beta,alpha)
            if nargin > 0
                %% Constructor for waterDynamics object
                    
                % Assign discount rate and elasticity of output wrt water
                if nargin > 1
                    obj.beta = beta;
                end
                
                % Read in data on well depths over time
                obj.data_paths = data_paths;
                obj.depth_data = readtable( obj.data_paths.depth_data, ...
                                            'Delimiter', ',' );
                                            
                % Assign groundwater policy and model
                obj.policy = waterPolicy(policy);
                
                % Assign productivity from estimated production model
                obj = obj.assignProductionModel( model );
                
                % Assign elasticity of output with respect to water
                if nargin > 3 
                    obj.alpha_w = alpha; % If alpha passed, use that one
                else
                    waterIdx        = ismember(model.iv.xnames,'water');
                    obj.alpha_w_hat = model.iv.coef(waterIdx);
                    obj.alpha_w_b   = model.ivb(waterIdx,:)'; 
                    obj.alpha_w     = obj.alpha_w_hat;
                end
                
                % Assign rho using 'calibrateRho' method of counter object
                counter = waterCounter( model );
                obj.rho_tilde = counter.rho_tilde;
                
                % Assign initial groundwater conditions
                obj = obj.assignGroundwaterConditions; 
            end
        end
        
        function obj = assignProductionModel( obj, model )
            %% Assign production model parameters from waterModel object
            
            % Contribution of exogenous (non-water) inputs to productivity
            keySet   = model.input;
            valueSet = model.alpha;
            M        = containers.Map(keySet,valueSet);
            inputs   = {'land','labor','capital'};    
            alphaJ   = cell2mat(cellfun(@(k) M(k), inputs, ...
                                'UniformOutput', false));
            JalphaJ  = model.data.clean{:,inputs} * alphaJ';
            
            % Productivity omega = e^(W_e\beta_e)*(L^alpha_L*K^alpha_K*X^alpha_X) 
            WBetaE = model.data.clean{:,model.betaYENames} ...
                        * model.betaYE;
            obj.omega = 1000 * mean( exp(WBetaE + JalphaJ) );
        end
        
        function obj = assignGroundwaterConditions( obj )
            %% Assign initial conditions of depth and water use

            init_conditions = readtable(obj.data_paths.init_conditions, ... ,
                                        'Delimiter', ',');
            obj.D_0 = init_conditions.depth;
            obj.P   = init_conditions.mean_pump_capacity_farmer;
            
            % Initial electricity use
            H_unc = (obj.omega.*obj.alpha_w/...
                (obj.policy.power_price*obj.days_use)).^(1./(1-obj.alpha_w)) .* ...
                (obj.rho_tilde./obj.D_0).^(obj.alpha_w./(1-obj.alpha_w)) .* ...
                1./obj.P;
            obj.H_0 = min(H_unc,obj.policy.ration);
            
            % Initial water use (rho_tilde contains days of use)
            obj.W_0 = obj.rho_tilde .* obj.P .* obj.H_0 ./ obj.D_0;

            % Calculate implied recharge rate
            obj.R = obj.W_0 / obj.delta;
        end
        
        function obj = estimateLawOfMotionBoot( obj )
            %% Estimate the groundwater law of motion repeatedly
            
            % Point estimate of law of motion
            obj.gamma_hat = obj.estimateLawOfMotion;
            
            % Draw bootstrap sample
            years = unique(obj.depth_data.year_dug); 
            seed  = RandStream('mlfg6331_64');   
            obj.gamma_b = zeros(obj.B,1); % Empty vector to store bootstrapped estimates
            depth_data_original = obj.depth_data;
            
            % Bootstrap estimate of law of motion
            if obj.noisy
                fprintf(1,'\nBootstrapping estimates of gamma:\n');
            end
            for b = 1:obj.B
                C = cell(length(years),1); % Cell array to hold bootsamples within each block (year).
                
                % Resample wells within years
                for j = 1:length(years)
                    depths_in_year_j = depth_data_original(...
                        depth_data_original.year_dug == years(j),:);
                    sample_size = length(depths_in_year_j.year_dug);
                    index_drawn = randsample(seed,sample_size,sample_size,true);
                    C{j} = depths_in_year_j(index_drawn,:); 
                end
                
                % Assign alpha_w corresponding to this bootstrap iteration
                if ~isempty( obj.alpha_w_b )
                    obj.alpha_w = obj.alpha_w_b(b);
                end
                   
                % Estimate gamma in bootstrap sample of depths
                obj.depth_data = cat(1,C{:}); 
                obj.gamma_b(b) = obj.estimateLawOfMotion;
                
                if obj.noisy
                    fprintf(1,'\tb = %3.0f, g = %4.3f',b,obj.gamma_b(b));
                    if mod(b,4) == 0
                        fprintf(1,'\n');
                    end
                end
            end
            
            % Reset alpha_w to point estimate
            if ~isempty( obj.alpha_w_b )
                    obj.alpha_w = obj.alpha_w_hat;
            end
            
            % Reset depth data
            obj.depth_data = depth_data_original;
        end
               
        function gamma_hat = estimateLawOfMotion( obj )
            %% Estimate the groundwater law of motion once
        
            % Set up loss function handle and the optimizer
            options   = optimset('TolFun',1e-9);
            objective = @(x) lawOfMotionObjective(obj,x);
            
            % Get point estimate
            gamma0    = -0.10;
            gamma_hat = fminsearch(objective, gamma0, options);
        end
                
        function mse = lawOfMotionObjective( obj, gamma )
            %% Loss function for estimating the groundwater law of motion
            
            % Turn data table into vectors
            real_depths = obj.depth_data{:,'depth'};
            real_years  = obj.depth_data{:,'year_dug'};
            
            % Unique years of drilling in sample
            [ years, ~, ic ] = unique(real_years);
            T                = max(years) - min(years) + 1;

            % Rescale years to begin at 1
            start_year = min(years);
            end_year   = max(years);

            % Predict initial depth given candidate gamma parameter
            DT = mean(real_depths(real_years == end_year));
            [ ~, ~, ~, D_t ] = projectDepth( obj, 'backwards', ...
                                             T, DT, gamma );

            % Sum of squared depth errors
            depth_error = real_depths - D_t(ic)';
            mse         = sum(depth_error.^2)/length(real_depths);
        end
        
        function [ S_t, H_t, W_t, D_t ] = projectDepth( obj, ...
                direction, T, D0, gamma, increment )
            % Project depth given initial condition
            %   - direction = 'backwards' to fit gamma parameter
            %   - direction = 'forwards' to project future depletion
            %   gamma may be a scalar or a vector     
            if nargin < 6
                increment = 'none';
            end
            
            % Initialize output
            D_t = zeros(length(gamma),T); % Groundwater depth
            H_t = zeros(length(gamma),T); % Electricity use
            W_t = zeros(length(gamma),T); % Water extraction
            S_t = zeros(length(gamma),T); % Social surplus
            
            % Set initial conditions (hours of use, water use) given depth
            D_t(:,1) = D0;
            H_unc = (obj.omega.*obj.alpha_w/...
                (obj.policy.power_price*obj.days_use)) ...
                .^(1./(1-obj.alpha_w)) .* ...
                (obj.rho_tilde./D_t(:,1)).^(obj.alpha_w./(1-obj.alpha_w)) .* ...
                1./mean(obj.P);
            H_t(:,1) = min(H_unc,obj.policy.ration);
            W_t(:,1) = obj.rho_tilde .* mean(obj.P) .* H_t(:,1)./D_t(:,1);
            S_t(:,1) = obj.beta.^(1-1) .* ...
                    ( obj.omega.*(W_t(:,1)).^(obj.alpha_w) ...
                      - obj.policy.power_cost.*obj.P.*H_t(:,1)*obj.days_use);
            R0 = W_t(:,1) ./ 1.4;
            
            % Increment initial water/power usage if passed
            switch increment
                case 'water' % Increase use 1000 liters per season
                    W_t(:,1) = W_t(:,1) + 1;
                case 'power' % Increase use 1 kWh per season
                    W_t(:,1) =  obj.rho_tilde .* ...
                        (obj.P.*H_t(:,1) + 1/obj.days_use)./D_t(:,1);
            end
            
            % Project path of depth and endogenous variables
            for t = 2:T
                
                % Depth from law of motion
                switch direction
                    case 'backwards'
                        D_t(:,t) = max(1,D_t(:,t-1) - gamma.*(W_t(:,t-1) - R0));
                    case 'forwards'
                        D_t(:,t) = max(1,D_t(:,t-1) + gamma.*(W_t(:,t-1) - R0));
                end

                % Hours of use
                H_unc = (obj.omega.*obj.alpha_w/...
                    (obj.policy.power_price*obj.days_use)) ...
                    .^(1./(1-obj.alpha_w)) .* ...
                    (obj.rho_tilde./D_t(:,t)).^(obj.alpha_w./(1-obj.alpha_w)) .* ...
                    1./mean(obj.P);
                H_t(:,t) = min(H_unc,obj.policy.ration);
                
                % Water extraction
                W_t(:,t) = obj.rho_tilde .* mean(obj.P) .* H_t(:,t)./D_t(:,t);
                
                % Social surplus contribution within-period
                S_t(:,t) = obj.beta.^(t-1) .* ...
                    ( obj.omega.*(W_t(:,t)).^(obj.alpha_w) ...
                      - obj.policy.power_cost.*obj.P.*H_t(:,t)*obj.days_use);
            end
            
            % Make time run forwards 
            if strcmp(direction,'backwards')
                D_t = flip(D_t,2);
                H_t = flip(D_t,2);
                W_t = flip(D_t,2);
                S_t = flip(D_t,2);
                return;
            end
            %plot(1:obj.horizon,-D_t(1,:))
        end
                
        function obj = oppCostWater( obj )
            %% Calculate the opportunity cost of water 
            
            % Concatenate point estimate and bootstrap estimates of gamma
            gamma = [ obj.gamma_hat; obj.gamma_b ]; 
            
            % Assign vector alpha_w if bootstrapping over alpha_w
            if ~isempty( obj.alpha_w_b )
                obj.alpha_w = [ obj.alpha_w_hat; obj.alpha_w_b ];
            end
            
            % Per liter
            [ S_t0 ] = projectDepth( obj, 'forwards', obj.horizon, ...
                                     obj.D_0, gamma, 'none' );
            [ S_t1 ] = projectDepth( obj, 'forwards', obj.horizon, ...
                                     obj.D_0, gamma, 'water' );
            
            lambda_w = (sum(S_t0,2) - sum(S_t1,2))/1000; % INR / liter
            obj.lambda_w_ltr    = lambda_w(1);
            obj.lambda_w_ltr_se = std(lambda_w(2:end));
            
            % Per kWh
            [ S_t1 ] = projectDepth( obj, 'forwards', obj.horizon, ...
                                     obj.D_0, gamma, 'power' );
            
            lambda_w = (sum(S_t0,2) - sum(S_t1,2))/1; % Per kWh
            obj.lambda_w_kwh    = lambda_w(1);
            obj.lambda_w_kwh_se = std(lambda_w(2:end));
            
            % Reset scalar alpha_w
            if ~isempty( obj.alpha_w_b )
                obj.alpha_w = obj.alpha_w_hat;
            end
            
            % Print estimates
            if obj.noisyEstimates
                obj.printOppCost;
            end
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
        
       [] = plotTimePath(obj, type, both, T, filename, optfig)
        
    end % methods 
    
end        