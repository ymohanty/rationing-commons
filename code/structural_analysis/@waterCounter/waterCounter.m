classdef waterCounter
    % waterCounter Object to run counterfactual simulations of a waterModel
    properties
        
        model;  % waterModel object
        policy; % waterPolicy object
        
        % Counterfactual options
        productivityDraws = 'simulated';
        % productivityDraws = 'estimated';
        seed = 20191205; % Seed for random number generator
        
        % Inputs to endogenize in counterfactual
        % endog = {'water'};
        endog = {'water','capital'};
        
        % Switch for whether to calculate outcomes in aggregate or also 
        %   across all farmers and simulations. The switch is useful to
        %   reduce computational time when searching for an optimal policy.
        aggregateOnly = false;
        
        % Dimensions
        N;        % Farmer X plots
        J = 5;    % Productivity shocks
        S = 200;  % Simulations
        % S = 20;
        
        % Trim tails of productivity draws at some percentile
        trim_tails = 1; % Trim 1 percent, 0.5 percent on each side
                
        % Constants
        rho;       % Extraction efficiency (liter '000s X feet / hours per day)
        rho_tilde; % Extraction efficiency (liter '000s X feet / 
                   %                        [kW X hours per day])
        days_use = 42; % Days of pump use in rabi season
        
        % Productivity components
        WBetaE;    % Observable                   [N X 1]
        omega;     % Unobservable                 [N X 1]
        
        % Counterfactual outcomes
        fp_idx;    % Indices to expand from farmer X crop to 
                   %   farmer X crop X simulation level
        fmplot;    % Data table at farmer X plot X simulation level
                   %   containing productivity, inputs, outputs, 
                   %   surplus, profits 
        farmer;    % Data table at farmer X simulation level
        
        outcomes_fp % Surplus for each farmer and plot averaged across 
                    %   simulations 
        outcomes_s  % Surplus for each simulation S averaged across farmers
                    %   and crops within that simulation
        outcomes    % Surplus averaged across farmers, crops and simulations
        
        % Redistribution
        budget;              % Per farmer budget in INR '000s
        transferOn = 'flat'; % Choices 'flat', 'pump', 'land' 
        transfers;
    end
    
    properties (Dependent)
        % Inputs treated as exogenous in counterfactual
        exog;
        exog_alphas;
        endog_alphas;
        prices;
        shrinkMatrix;
    end
    
    methods
                
        function exog = get.exog( obj )
            % Exogenous inputs
            endogi = ismember(obj.model.input,[ obj.endog 'water2' ]);
            exog   = obj.model.input(~endogi);
        end
        
        function alphas = getAlphas( obj, names )
            % Get the alpha names for an array of input names
            keySet   = obj.model.input;
            valueSet = obj.model.alpha;
            M = containers.Map(keySet,valueSet);
             
            alphas = zeros(size(names));
            for i = 1:length(names)
                alphas(i) = M(names{i});
            end
        end
       
        function obj = waterCounter( waterModel )
            % Initialize waterCounter object
            
            % Store data and model objects as part of counterfactual
            obj.model  = waterModel;
            obj.N      = size(obj.model.y,1);
            
            % Farmer observables and factor prices
            %   Uses waterModel data but does not depend on parameters
            obj        = obj.setup;
            
            % Productivity, both observed and unobserved
            %   Uses waterModel parameters to calculate productivity 
            obj        = obj.productivity;
                       
            % Set policy, if passed at initialization
            if exist('waterPolicy','var')
                obj.policy = waterPolicy;
            end 
        end
        
        function obj = setup( obj )
             % Set up counterfactuals 
             %   The set up draws farmer productivities but does not depend
             %   on the policy regime. Therefore the counterfactual object
             %   can be initialized once and the policy later altered.
             
             % Set singleton dimension of simulation if using residuals
             if strcmp(obj.productivityDraws,'estimated')
                 obj.S = 1;
             end
             
             % Identifiers for farmer X plot X simulation
             s_id           = repmat([1:obj.S]',obj.N,1);
             farmer_plot_id = repmat(obj.model.data.clean.farmer_plot_id',...
                                     obj.S,1);
             farmer_plot_id = farmer_plot_id(:);
             farmer_id      = floor(farmer_plot_id/10);
             obj.fmplot = table(farmer_id,farmer_plot_id,s_id);
             
             % Indices to index into farmer X plot level data to expand out
             %   to farmer X plot X simulation level data
             obj.fp_idx = repmat([1:obj.N],obj.S,1);
             obj.fp_idx = obj.fp_idx(:);
             
             % Calibrate extraction function
             obj              = obj.calibrateRho; 
             obj.fmplot.depth = obj.model.data.clean.depth(obj.fp_idx);
             obj.fmplot.pump  = obj.model.data.clean.pump_capacity(obj.fp_idx);
             
             % Factor prices
             %   All factor prices should in in '000s of Rs per unit
             %   The native units differ by input.
             %     Land:    Ha
             %     Labor:   person-day
             %     Capital: Rs '000s
             %     Water:   liters per season
             %   Capital input is natively in Rs '000s.  It therefore has a
             %   price of 1.  All other inputs need to have prices in the 
             %   correct units.
             obj.fmplot.p_land    = zeros(obj.N*obj.S,1);
             obj.fmplot.p_labor   = ...
                 obj.model.data.clean.median_wage_hrvst(obj.fp_idx)/1e3;
             obj.fmplot.p_capital = ones(obj.N*obj.S,1);
        end
                
        function obj = calibrateRho( obj )
            % Calibrate water extraction function to match mean extraction
            W_bar  = mean(obj.model.data.clean.Water);
            H_bar  = 5.5;
            PD     = obj.model.data.clean.pump_capacity./ ...
                           obj.model.data.clean.depth;
            PD     = PD(~isnan(PD));
            PD_bar = mean(PD);
            D_bar  = mean(1./obj.model.data.clean.depth);           
                       
            obj.rho_tilde = W_bar / (H_bar * PD_bar);
            obj.rho       = W_bar / (H_bar * D_bar);
        end
        
        function obj = productivity( obj )
            % Calculate productivity and store for each farmer X crop X s
            
            % Observable contribution to productivity
            obj.WBetaE        = obj.productivityObserved;
            obj.fmplot.WBetaE = obj.WBetaE(obj.fp_idx);
                                      
            % Unobservable contribution to productivity
            obj.omega            = obj.productivityShocks;
            obj.fmplot.omega_Eit = obj.fmplot.WBetaE + obj.omega; 
        end
           
        function [ WBetaE ] = productivityObserved( obj )
            % Use model to calculate observable portion of productivity
            % based on characteristics known early (hence E) in the season         
            WBetaE = obj.model.data.clean{:,obj.model.betaYENames} ...
                        * obj.model.betaYE;
        end
        
        function [ omega ] = productivityShocks( obj )
            % Draw productivity shocks for farmers according to
            %   empirical distribution of deflated TFP shocks
            
            % Select productivity term to draw from
            % omegas  = obj.model.omega_hatB;
            omegas  = obj.model.omega_hatC;
           
            switch obj.productivityDraws
                
                % Re-draw productivity residuals for simulation
                case 'simulated'

                    % Trim tails of productivity draws
                    prcTrim = [ obj.trim_tails/2 100-obj.trim_tails/2 ];
                    tails   = prctile( omegas, prcTrim );
                    keep    = omegas > tails(1) & omegas < tails(2);
                    omegas  = omegas(keep);

                    % Draw productivity shocks from trimmed distribution
                    rng(obj.seed);
                    try
                        oi    = randi(length(omegas),obj.N*obj.S,1); % Could draw once
                    catch ME
                        display(ME);
                    end
                    omega = omegas(oi);
                
                % Retain estimated productivity residual by farmer X crop
                case 'estimated'
                    omega = omegas;
                    
            end
        end
                
        function p_water = waterPrice( obj )
            % Water price per liter '000
             %   The water price is farmer specific due to heterogeneous 
             %   extraction technology (depth, pump capacity).
             %   To extract liter 1000 requires D / rho hours per day
             %   One hour per day costs P * days/season * p_E
             % Pump capacity does not affect the water
             % price. That is because both the cost of power and the amount
             % of water extracted are proportional to pump capacity.
             p_water = obj.model.data.clean.depth ./ obj.rho_tilde .* ...
                       obj.days_use .* obj.policy.power_price/1e3; 
             p_water = p_water(obj.fp_idx); % Rs '000s / liter '000s
        end
         
        function obj = solveFarmersProblem( obj )
             % Maximize profits given:
             %   Factor endowment L_i
             %   Factor prices including wage and rental rates
             %   Policy regime with ration H and price p_E
             %   Productivity - deterministic components
             %   Productivity - shocks drawn for farmer and plot
             % Return input choices, expected output and expected profit
             %   for all farmers and plots.            
             switch obj.policy.regime         
                 case {'rationing','private_cost','pigouvian'}
                     obj = obj.solveFarmersProblemOnce;
                 case 'block_pricing'
                     obj = obj.solveFarmersProblemTwice;
             end
                                       
             % Calculate profits net of input costs
             obj = obj.calculateProfits( '' );
             
             % Calculate social surplus 
             %   Contribution from each farmer and in aggregate
             obj = obj.socialSurplus;
        end
        
        function obj = solveFarmersProblemOnce( obj )
            % Solve farmer's problem when regime is a {price,ration} bundle
            
            % Water price
            %   Water price is set here rather than in set-up since it 
            %   must be updated for each counterfactual as p_E changes.
            obj.fmplot.p_water = obj.waterPrice;

            % Solve unconstrained problem
            obj = obj.solveFarmersProblemGivenRation( 'unconstrained' );

            % Solve constrained problem
            obj = obj.solveFarmersProblemGivenRation( 'constrained' );

            % Select between unconstrained and constrained problems
            %   based on whether ration binds for each farmer X plot X sim
            obj = obj.solveFarmersProblemReconcile;        
        end
        
        function obj = solveFarmersProblemTwice( obj )
            % Solve farmer's problem when regime includes block pricing
            %   The problem is solved twice since there are two steps on
            %   the block price schedule.
            
            % Solve problem on lower step (rationing price)
            obj.policy.ration      = obj.policy.ration_steps(1);
            obj.policy.power_price = obj.policy.price_steps(1);
            cfStep1                = obj.solveFarmersProblemOnce;
            
            % Solve problem on upper step (Pigouvian price)
            obj.policy.ration      = obj.policy.ration_steps(2);
            obj.policy.power_price = obj.policy.price_steps(2);
            cfStep2                = obj.solveFarmersProblemOnce;
            
            % Select regime (hours, input choice) based on whether
            %   Pigouvian quantity exceeds ration of hours
            obj = cfStep1.solveFarmersProblemReconcileCf( cfStep2 );    
        end
        
        function obj = solveFarmersProblemGivenRation( obj, ration )
            % Solve farmer's problem
            
            % Under Cobb-Douglas production function
            if ~obj.model.translogTerms
                obj = solveFarmersProblemGivenRationCobbDoug( obj, ration );
                
            % Under Translog production function
            else
                obj = solveFarmersProblemGivenRationTranslog( obj, ration );
                
            end
        end
                
        function obj = solveFarmersProblemGivenRationCobbDoug( obj, ration )
            % Solve farmer's problem with Cobb-Douglas production
            switch ration
                case 'constrained'
                    suffix = '_con';
                case 'unconstrained'
                    suffix = '_unc';
            end
            
            % Exogenous inputs: Fix at levels in the data
            exog_names = strcat(obj.exog,suffix);
            obj.fmplot(:,exog_names) = ...
                obj.model.data.clean(obj.fp_idx,obj.exog); 
            exog_inputs = obj.fmplot{:,exog_names};
            exog_alphaj = obj.getAlphas(obj.exog);
            
            % Endogenous inputs: Solve for input demands
            endog_names  = obj.endog;
            endog_alphaj = obj.getAlphas(obj.endog);
            endog_prices = obj.fmplot{:,obj.getPrices(obj.endog)};
            sum_endog_alphaj = sum(endog_alphaj);
            
            % Rationed inputs: Fix at ration, treat as exogenous
            if strcmp(ration,'constrained')
                
                % Convert ration from hours to log('000 liters)
                Water_con = obj.rho_tilde .* obj.fmplot.pump * ...
                            obj.policy.ration ./ obj.fmplot.depth;
                obj.fmplot.water_con = log(Water_con);
                
                % Add water ration to exogenous inputs
                exog_inputs = [ exog_inputs obj.fmplot.water_con ];
                exog_alphaj = [ exog_alphaj ...
                    obj.model.alpha(ismember(obj.model.input,{'water'}))' ];
                
                % Remove water ration from endogenous inputs; update prices
                endog_names = obj.endog(~ismember(obj.endog,{'water'}));
                endog_alphaj = obj.model.alpha(...
                    ismember(obj.model.input,endog_names))';
                endog_prices = obj.fmplot{:,obj.getPrices(endog_names)};
                sum_endog_alphaj = sum(endog_alphaj);
                
            end
               
            % Expected output y_Eit = z_it 
            if isempty( endog_names )
                yEit = 1/(1-sum_endog_alphaj) * ...           
                        ( obj.fmplot.omega_Eit + ...
                          exog_inputs*exog_alphaj' );
            else
                yEit = 1/(1-sum_endog_alphaj) * ...            
                        ( obj.fmplot.omega_Eit + ...
                          exog_inputs*exog_alphaj' + ...
                          log(endog_alphaj(ones(obj.N*obj.S,1),:) ./ ...
                              endog_prices) * endog_alphaj' );
            end
            obj.fmplot(:,['output' suffix]) = array2table(yEit);

            % Endogenous input choices
            if ~isempty( endog_names )
                endog_wsuffix = strcat(endog_names,suffix);
                obj.fmplot(:,endog_wsuffix) = array2table(...
                            log(endog_alphaj(ones(obj.N*obj.S,1),:) ./...
                                endog_prices) + ...
                            repmat(yEit,1,length(endog_alphaj)) );
            end
       
            % Calculate hours of pump use 
            obj = obj.calculateHours( suffix );
        end
        
        function obj = solveFarmersProblemGivenRationTranslog( obj, ration )
            % Solve farmer's problem under Cobb-Douglas with additional
            %   translog term (log W)^2
            switch ration
                case 'constrained'
                    suffix = '_con';
                case 'unconstrained'
                    suffix = '_unc';
            end
            
            % Exogenous inputs: Fix at levels in the data
            exog_names = strcat(obj.exog,suffix);
            obj.fmplot(:,exog_names) = ...7
                obj.model.data.clean(obj.fp_idx,obj.exog); 
            exog_inputs = obj.fmplot{:,exog_names};
            exog_alphaj = obj.getAlphas(obj.exog);
            
            % Endogenous inputs: Solve for input demands
            endog_names  = obj.endog;
            endog_alphaj = obj.getAlphas(obj.endog);
            endog_prices = obj.fmplot{:,obj.getPrices(obj.endog)};
            sum_endog_alphaj = sum(endog_alphaj);
            
            % Rationed inputs: Fix at ration, treat as exogenous
            if strcmp(ration,'constrained')
                
                % Convert ration from hours to log('000 liters)
                Water_con = obj.rho_tilde .* obj.fmplot.pump * ...
                            obj.policy.ration ./ obj.fmplot.depth;
                obj.fmplot.water_con = log(Water_con);
                
                % Add water ration to exogenous inputs
                exog_inputs = [ exog_inputs obj.fmplot.water_con ];
                exog_alphaj = [ exog_alphaj ...
                    obj.model.alpha(ismember(obj.model.input,{'water','water2'}))' ];
                
                % Remove water ration from endogenous inputs; update prices
                endog_names = obj.endog(~ismember(obj.endog,{'water','water2'}));
                endog_alphaj = obj.model.alpha(...
                    ismember(obj.model.input,endog_names))';
                endog_prices = obj.fmplot{:,obj.getPrices(endog_names)};
                sum_endog_alphaj = sum(endog_alphaj);
            end
               
            % Expected output y_Eit = z_it
            %   Only exogenous inputs
            if isempty( endog_names ) 
                yEit = 1/(1-sum_endog_alphaj) * ...           
                        ( obj.fmplot.omega_Eit + ...
                          exog_inputs*exog_alphaj(1:end-1)' + ...
                          exog_inputs(:,end).^2*exog_alphaj(end) );   

            %   Capital endogenous
            elseif all(strcmp( endog_names, 'capital' ))
                capital_prices = obj.fmplot{:,obj.getPrices(endog_names)};
                capital_alphaj = obj.model.alpha(...
                    ismember(obj.model.input,{'capital'}));
                
                logCits = obj.fmplot.omega_Eit + ...
                    exog_inputs*exog_alphaj(1:3)' + ...
                    exog_alphaj(end).*exog_inputs(:,3).^2;
                kit = 1/(1-capital_alphaj) * ( log(capital_alphaj) + ...
                    logCits - log(capital_prices) );
                
                Kit  = exp(kit);
                yEit = logCits + capital_alphaj*kit;
                
            %   Water or water and capital endogenous
            else
                % Contribution of productivity and exogenous inputs to 
                %   the expected value of output
                endog_names_exwater = ...
                    obj.endog(~ismember(obj.endog,{'water'}));
                endog_alphaj = obj.model.alpha(...
                    ismember(obj.model.input,endog_names_exwater))';
                endog_prices = obj.fmplot{:,obj.getPrices(endog_names_exwater)};

                % Calculate the constant in the water equation
                water_prices = obj.fmplot{:,obj.getPrices({'water'})};
                water_alphaj = [ obj.model.alpha(...
                    ismember(obj.model.input,{'water'}))' ...
                    obj.model.alpha(end) ];

                if isempty(endog_alphaj)
                    endog_alphaj = 0;
                end
                logCits = obj.fmplot.omega_Eit + ...
                    exog_inputs*exog_alphaj' + ...
                    (endog_alphaj-1)*log(water_prices);    
                Cits = exp(logCits);
                
                if any(~isreal(Cits))
                    display(Cits);
                end
                
                % Solve for expected output and endogenous demands
                [ Wit, Kit ] = solveFarmersDemandTranslog( ...
                    Cits, endog_alphaj, water_alphaj );
                
                % Rescale constant to INR '000s
                logCits = logCits - (endog_alphaj-1)*log(water_prices);
                
                % Calculate log expected output yEit
                if isempty(endog_names_exwater)
                    yEit = logCits + ...
                        + water_alphaj(1)*log(Wit) + ...
                        + water_alphaj(2)*log(Wit).^2;
                else
                    % Rescale capital input to INR '000s
                    Kit = Kit .* water_prices;
                    
                    yEit = logCits ...
                        + water_alphaj(1)*log(Wit) + ...
                        + water_alphaj(2)*log(Wit).^2 + ...
                        endog_alphaj*log(Kit);            
                end            
            end
            obj.fmplot(:,['output' suffix]) = array2table(yEit);

            % Endogenous input choices
            if ~isempty( endog_names )
                
                endog_names_exwater = ...
                    obj.endog(~ismember(obj.endog,{'water'}));
                if ~isempty( endog_names_exwater )               
                    endog_wsuffix = strcat(endog_names_exwater,suffix);
                    obj.fmplot(:,endog_wsuffix) = array2table(log(Kit));
                end

                if any(ismember(endog_names,{'water'}))
                    endog_wsuffix = strcat('water',suffix);
                    obj.fmplot(:,endog_wsuffix) = array2table(log(Wit));
                end
            end

            % Calculate hours of pump use 
            obj = obj.calculateHours( suffix );
        end
        
        function obj = solveFarmersProblemReconcile( obj )
            % Solve farmer's problem based on whether ration binds, 
            %  for each farmer and productivity draw
            
            % Check whether constraint binds
            binding = obj.fmplot.water_unc >= obj.fmplot.water_con;
            
            % Choose constrained or unconstrained input set, output, etc.
            inputs      = obj.model.inputUnc;
            allvars     = [ inputs 'Hours' 'Power' 'output' ];
            allvars_unc = strcat(allvars,'_unc');
            allvars_con = strcat(allvars,'_con');
            
            obj.fmplot(:,allvars) = ...
                array2table(NaN(length(binding),length(allvars)));
            obj.fmplot(~binding,allvars) = obj.fmplot(~binding,allvars_unc);
            obj.fmplot(binding,allvars)  = obj.fmplot(binding,allvars_con);
            obj.fmplot.rationBinds = binding;
            
            % Calculate absolute (as opposed to log) levels of input use
            Inputs = proper([ inputs 'output' ]);  
            obj.fmplot(:,Inputs) = ...
                array2table(exp(obj.fmplot{:,[inputs 'output']}));
        end
        
        function obj = solveFarmersProblemReconcileCf( obj, cf )
            % Reconcile farmer's problem across counterfactuals with
            %   possibly different policy regimes.  Used mainly for the
            %   case of block pricing.  
            %   obj - Counterfactual object 
            %   cf  - Counterfactual object under alternative policy / step
            
            % Check whether farmer is on second step
            onSecondStep = cf.fmplot.Hours > obj.policy.ration_steps(1);
            
            % Outcome variables to copy (input and output choices)
            inputs      = obj.model.inputUnc;
            allvars     = [ inputs 'Hours' 'Power' 'output' ];
            
            % For farmer-plots on second step, who choose a quantity that
            %   exceeds the first step quantity, even at the higher price, 
            %   assign variables based on second-step choices
            obj.fmplot(onSecondStep,allvars) = ...
                cf.fmplot(onSecondStep,allvars);
            
            % Calculate absolute (as opposed to log) levels of input use
            Inputs = proper([ inputs 'output' ]);  
            obj.fmplot(:,Inputs) = ...
                array2table(exp(obj.fmplot{:,[inputs 'output']}));
            obj.fmplot.secondStep = onSecondStep;
        end
        
        function obj = calculateHours( obj, suffix )
            % Calculate hours of pump use and power input
            obj.fmplot(:,['Hours' suffix]) = array2table( ...
                exp(obj.fmplot{:,['water' suffix]}) .* ...
                obj.fmplot.depth ./ (obj.rho_tilde * obj.fmplot.pump) );
           
            obj.fmplot(:,['Power' suffix]) = array2table( ...
                obj.fmplot{:,['Hours' suffix]} .* ...
                obj.fmplot.pump * obj.days_use );        
        end
        
        function obj = calculateProfits( obj, suffix )
            % Calculate profits net of input cost for given input choices
            
            % Calculate profits 
            input_names  = obj.model.input(~ismember(obj.model.input,{'water2'}));
            inputs       = obj.fmplot{:,strcat(input_names,suffix)};
            input_prices = obj.fmplot{:,obj.getPrices(input_names)};
            obj.fmplot(:,['profit' suffix]) = array2table( ...
                exp(obj.fmplot{:,['output' suffix]}) - ...
                sum(exp(inputs).*input_prices,2) );
            
            % Under block pricing, reduce profits for cost of power on the 
            %   second step of the block
            if strcmp(obj.policy.regime,'block_pricing')
                obj.fmplot.Hours2 = max(obj.fmplot.Hours - ...
                    obj.policy.ration_steps(1),0);
                obj.fmplot.Power2 = obj.fmplot.Hours2 .* ...
                    obj.fmplot.pump * obj.days_use; 
                obj.fmplot.PowerSurcharge = obj.fmplot.Power2 * ...
                    diff(obj.policy.price_steps) /1e3; % INR '000s
                obj.fmplot(:,['profit' suffix]) = ...
                    array2table( obj.fmplot{:,['profit' suffix]} ...
                    - obj.fmplot.PowerSurcharge );
            end   
        end
                
        function obj = socialSurplus( obj )
            % Calculate social surplus due to a given policy
            %   Social surplus is equal to expected farmer profits
            %   less expected costs of water and electricity supply
            
            % Calculate unpriced cost of power used by each farmer
            obj.fmplot.power_cost = obj.fmplot.Power * ...
                (obj.policy.power_cost-obj.policy.power_price) /1e3;
            
            % Under block pricing, deduct from unpriced power cost the
            %   surcharge for power bought on the second step
            if strcmp(obj.policy.regime,'block_pricing')
                obj.fmplot.power_cost = obj.fmplot.power_cost - ...
                    obj.fmplot.PowerSurcharge;
            end
            
            % Calculate contribution to social surplus from each farmer
            obj.fmplot.water_cost = exp(obj.fmplot.water)*obj.policy.water_cost;
            obj.fmplot.surplus = obj.fmplot.profit ...
                 - obj.fmplot.power_cost - obj.fmplot.water_cost;
            
            % Designate outcomes of interest
            vars = {'surplus','profit','Output','power_cost','water_cost'};
            Inputs = [ proper(obj.model.inputUnc) 'Hours' 'Power' ];
            vars = [ vars Inputs ];
                        
            % Aggregate surplus 
            %  obj.outcomes = grpstats(obj.fmplot(~obj.fmplot.irs,vars),[]);
            obj.outcomes = accumTable(obj.fmplot(:,vars),{});
            
            % Add productivity measures to outcomes
            obj = obj.aggregateProductivity;
            
            % Assign row names to outcomes
            obj.outcomes.Properties.RowNames = {};
            obj.outcomes.regime = obj.policy.regime;
                        
            % Skip intermediate levels of aggregation
            %   This option speeds up execution if the surplus function is
            %   being used as the objective in a maximization problem
            if obj.aggregateOnly
                return
            end
            
            % Aggregate to farmer-plot-level
            obj.outcomes_fp = accumTable( ...
                obj.fmplot(:,['farmer_plot_id' vars]),{'farmer_plot_id'});
            
            % Aggregate to simulation-level
            % obj.outcomes_s = accumTable( obj.fmplot(:,['s_id' vars]),{'s_id'});
        end
        
        function obj = shadowValueOfRation( obj )
            % Calculate shadow value of ration
            
            % Calculate shadow value of ration
            %   Units of water: INR '000s / Liter '000s
            alphaW = obj.model.alpha(ismember(obj.model.input,{'water'}));
            MPW = alphaW .* ...
                exp(obj.fmplot.output_con - obj.fmplot.water_con);
            obj.fmplot.lambda_con_w = MPW - obj.fmplot.p_water; 
            
            %  Units of power: INR / kWh
            MPE = MPW * obj.rho_tilde./obj.fmplot.depth .* ...
                1e3./obj.days_use;
            obj.fmplot.lambda_con_h = MPE - obj.policy.power_price;
        end
        
        function obj = shadowValueAtMean( obj )
            % Calculate shadow value of ration if farmer had mean
            %   observable characteristics
            
            % Duplicate counterfactual object in order to replace key
            %   variables with their means
            dup = obj;
            
            % Replace pump, depth with means
            M = size(obj.fmplot,1);
            dup.fmplot.pump  = repmat(mean(obj.fmplot.pump),M,1);
            dup.fmplot.depth = repmat(mean(obj.fmplot.depth),M,1);
            
            % Replace exogenous input variables with means
            exog_inputs = mean(obj.fmplot{:,obj.exog},1);
            dup.fmplot(:,obj.exog) = array2table(repmat(exog_inputs,M,1));
            
            % Replace prices of endogenous variables with means
            endog_prices = obj.fmplot{:,obj.getPrices(obj.endog)};
            dup.fmplot(:,obj.getPrices(obj.endog)) = ...
                array2table(repmat(mean(endog_prices,1),M,1));
                
            % Replace productivity draw with part due to unobservable shock
            %   alone, replacing effects of observed vars with their mean
            dup.fmplot.omega_Eit = repmat(mean(obj.fmplot.WBetaE,1),M,1) ...
                                    + obj.omega;
            
            % Solve for output choices within duplicate counterfactual
            dup = dup.solveFarmersProblemGivenRation( 'unconstrained' );
            dup = dup.solveFarmersProblemGivenRation( 'constrained' );
            dup = dup.solveFarmersProblemReconcile;
            
            % Calculate shadow value of ration and transcribe value back 
            %   to original counterfactual object
            dup = dup.shadowValueOfRation;
            obj.fmplot.lambda_con_w_mean = dup.fmplot.lambda_con_w;
            obj.fmplot.lambda_con_h_mean = dup.fmplot.lambda_con_h;
        end
        
        function [ dPidH, dPidHi ] = marginalBenefit( obj, alphaW )
            % Calculate the marginal benefit of relaxing the ration
            
            % Calculate marginal benefit at any alphaW passed
            if nargin > 1
                obj.model.alpha(end) = alphaW;
            end
            
            % Water price
            obj.fmplot.p_water = obj.waterPrice;

            % Solve constrained problem
            obj = obj.solveFarmersProblemGivenRation( 'constrained' );
            
            % Choose constrained input set
            inputs     = obj.model.inputUnc;            
            inputs_con = obj.fmplot{:,strcat(inputs,'_con')};
            alpha      = obj.model.alpha;
            
            % Calculate marginal profit
            if ~obj.model.translogTerms
                logdFdW = obj.fmplot.omega_Eit + ...
                    inputs_con(:,1:3)*alpha(1:3) + log(alpha(end)) + ...
                    (alpha(end)-1)*inputs_con(:,end);
                dFdW = exp(logdFdW);
            else
                dFdW = exp(obj.fmplot.output_con) .* ...
                    1./exp(inputs_con(:,end)) .* ...
                    ( alpha(4) + 2*alpha(end)*inputs_con(:,end) );
            end
            
            dWdH = obj.rho_tilde .* obj.fmplot.pump ./ obj.fmplot.depth;
            dPidHi = dFdW .* dWdH - ...
                obj.days_use * obj.policy.power_price/1e3 * obj.fmplot.pump;
            dPidHi = dPidHi / mean(obj.model.data.clean.Land);
            
            % Average over farmers
            dPidH = mean(dPidHi,1);
            
            % Calculate marginal profit for a farmer with average chars.
%             logdFdW = mean(obj.fmplot.omega_Eit) + ...
%                 mean(inputs_con(:,1:3),1)*alpha(1:3) + log(alpha(end)) + ...
%                 (alpha(end)-1)*mean(inputs_con(:,end),1);
%             dFdW = exp(logdFdW);
%             dWdH = obj.rho_tilde * mean(obj.fmplot.pump) ./ ...
%                 mean(obj.fmplot.depth);
%             dPidH_bar = dFdW * dWdH - obj.days_use*obj.policy.power_price/1e3 ...
%                 * mean(obj.fmplot.pump);
%             dPidH_bar = dPidH_bar / mean(obj.model.data.clean.Land);
        end
        
        function [ dCdH, dCdHi, dEdH, dWdH, dSdH, dEdHse, dWdHse, Cov_dWdH_dEdH ] = ...
                marginalCost( obj, water_opp_cost )
            % Calculate the marginal cost of relaxing the ration
            if nargin < 2
                water_opp_cost = obj.policy.water_cost;
            end
            
            % Private cost of power (to the state, excluding the part paid
            %   for by the farmer)
            dEdHi = obj.days_use * obj.fmplot.pump / ...
                mean(obj.model.data.clean.Land);
            dEdH = mean(dEdHi);
            dPCdHi = dEdHi * ...
                (obj.policy.power_cost - obj.policy.power_price)/1e3;
                        
            % Social cost of water
            dWdHi = obj.rho_tilde .* obj.fmplot.pump ./ obj.fmplot.depth ...
                / mean(obj.model.data.clean.Land);
            dWdH = mean(dWdHi);
            dSCdHi = dWdHi * water_opp_cost;
            dSdH = mean(dSCdHi);
            
            Cov_dWdH_dEdH = cov(dEdHi,dWdHi);
            Cov_dWdH_dEdH = Cov_dWdH_dEdH(1,2)/length(dEdHi);
                
            % Total marginal cost
            dCdHi = dPCdHi + dSCdHi;
            dCdH  = mean(dCdHi);
            
            % Standard errors 
            dEdHse = std(dEdHi)/sqrt(length(dEdHi));
            dWdHse = std(dWdHi)/sqrt(length(dWdHi));
        end
        
        function [ alphaWcalib ] = calibrateAlpha( obj, rf_mb )
            % Calibrate alphaW such that marginal benefit of relaxing the
            %   ration in the model equals the estimated marginal benefit
            options = optimoptions(@fminunc,...
                                   'MaxIter',200,...
                                   'Algorithm','quasi-newton',...
                                   'display','none');

            % Objective is difference between modeled and estimated 
            %   marginal benefit
            mb_estim = rf_mb;
            mb_model = @( alphaW ) obj.marginalBenefit( alphaW );
            objective = @( alphaW ) ( mb_model(alphaW) - mb_estim )^2;
            try
                [ alphaWcalib ] = fminunc( objective, 0.3, options );
            catch ME
                display(ME);
            end
    
            fprintf(1,'Estimated alphaW:  %4.3f\n',obj.model.alpha(end));
            fprintf(1,'Calibrated alphaW: %4.3f\n',alphaWcalib);
        end

        function obj = aggregateAcrossPlots( obj )
            % Aggregate farmer-plot-simulation table to farmer-simulation
            
            % Designate outcomes of interest
            vars = {'surplus','profit','Output','power_cost','water_cost',...
                'pump','Land','transfer','profit_net'};
            Inputs = [ proper(obj.model.inputUnc) 'Hours' 'Power' ];
            vars = [ vars Inputs ];
            
            obj.farmer = accumTable( ...
                           obj.fmplot(:,['farmer_id' 's_id' vars]),...
                           {'farmer_id','s_id'},@sum);
            
            % Outcomes for which to take mean, not sum     
            varsMn = {'depth','omega_Eit'};
            farmerMn = accumTable( ...
                           obj.fmplot(:,['farmer_id' 's_id' varsMn]),...
                           {'farmer_id','s_id'},@mean);
            
            obj.farmer = [ obj.farmer farmerMn(:,varsMn) ];
        end
        
        function obj = aggregateProductivity( obj )
            % Aggregate productivity by weighting across farmers
            YEit             = obj.fmplot.Output;
            Omega_Eit        = exp(obj.fmplot.omega_Eit);
            % obj.outcomes.TFP = YEit'/sum(YEit)* Omega_Eit;
            obj.outcomes.TFP = sum(YEit)/sum(YEit./Omega_Eit);
            
            % Covariance of productivity and effective water input
            waterIdx         = ismember(obj.model.input,'water');
            alphaW           = obj.model.alpha(waterIdx);    
            if ~obj.model.translogTerms
                CovOmegaWMat = cov(Omega_Eit,obj.fmplot.Water.^alphaW);
            else
                waterIdx2    = ismember(obj.model.input,'water2');
                alphaW2      = obj.model.alpha(waterIdx2);
                CovOmegaWMat = cov(Omega_Eit,...
                    obj.fmplot.Water.^alphaW.*exp(alphaW2*obj.fmplot.water.^2)); 
            end
            obj.outcomes.CovOmegaW = CovOmegaWMat(1,2);
        end
                
        function prices = getPrices( obj, inputs )
             % Get the names of prices for a given set of inputs
             keySet   = obj.model.inputUnc;
             valueSet = {'p_land','p_labor','p_capital','p_water'};
             M = containers.Map(keySet,valueSet);

             prices = cell(size(inputs));
             for i = 1:length(inputs)
                 prices{i} = M(inputs{i});
             end
        end
        
        function obj = enactTransfers( obj )
            % Create transfers to redistribute revenue from Pigouvian
            %   pricing. Store results in outcome tables
            vars = {'pump' 'Land'};
            proxies_fp = accumTable( ...
                obj.fmplot(:,['farmer_plot_id' vars]),{'farmer_plot_id'});           
            
            proxies_fp  = table2array( proxies_fp(:,2:3) );
            proxies_sum = sum(proxies_fp,1);
            proxy_share = proxies_fp ./ proxies_sum(ones(obj.N,1),:);
            
            switch obj.transferOn
                case 'none'
                    obj.fmplot(:,'transfer') = array2table( ...
                        zeros(obj.N*obj.S,1) );
                
                case 'flat'
                    obj.fmplot(:,'transfer') = array2table( ...
                        obj.budget(ones(obj.N*obj.S,1)));
                    
                case 'pump'
                    transfer_fp = obj.budget*obj.N*proxy_share(:,1);
                    assert(abs(mean(transfer_fp,1)-obj.budget) < 1e-4);
                    obj.fmplot(:,'transfer') = ...
                        array2table(transfer_fp(obj.fp_idx,:));
                    
                case 'land'
                    transfer_fp = obj.budget*obj.N*proxy_share(:,2);
                    assert(abs(mean(transfer_fp,1)-obj.budget) < 1e-4);
                    obj.fmplot(:,'transfer') = ...
                        array2table(transfer_fp(obj.fp_idx,:));
            end
            
            obj.fmplot(:,'profit_net') = array2table( ...
                    obj.fmplot.profit + obj.fmplot.transfer );
        end
        
        [ ] = tabulateFit( obj, file );
        
        [ ] = plotFit( obj, file_stub );
        
        [ ] = plotShadowValue( obj, file, price_pigou, plotAtMeanObs );
        
        [ ] = scatterValue( obj, xval, yval, xscale, yscale, xlab, ylab, series, wins, loess, file, optfig); 
        
        [ obj ] = findOptimalTransfers( obj, exAnteRegime );
        
        [ ] = plotOptimalTransfers( obj, file );
        
    end
     
end

function [ Wit, Kit ] = solveFarmersDemandTranslog( Cits, ...
                                    endog_alphaj, water_alphaj )
    % Solve farmers' demand for endogenous inputs w/ translog terms

    % Solve farmers' demand for water on a grid of productivities
    [ Cg, Xg ] = solveWaterDemandOngrid( Cits, ...
                                endog_alphaj, water_alphaj );

    % Solve farmers' demand for water at actual values for the
    %   constant for each farmer X crop X simulation
    [ Wit ]  = interp1( Cg, Xg(:,1), Cits, 'linear' ); 
    if endog_alphaj ~= 0
        [ Kit ]  = interp1( Cg, Xg(:,2), Cits, 'linear' ); 
    else
        Kit = [];
    end
end

function [ Cg, Xg ] = solveWaterDemandOngrid( Cits, endog_alphaj, ...
                                                water_alphaj )
    % Solve equation for farmer's water demand on a grid
    %   where the grid is over the constant term in the nonlinear
    %   equation that implicitly defines water demand

    % Define grid points and output vector
    Npoints = 101;
    Cg = prctile( Cits, [ 0:(Npoints-1)/100:100 ])';
    
    % Water, capital endogenous
    if endog_alphaj ~= 0
        X0 = exp([ 4; 3 ]);
        Xg = zeros(size(Cg,1),2);
    % Only water endogenous
    else
        X0 = exp([ 4 ]);
        Xg = zeros(size(Cg,1),1);
    end
    
    % Options for profit maximization
    options = optimoptions(@fmincon,'Display','none',...
                                    'MaxIter',200,...
                                    'TolX',1e-12);
    LB = zeros(size(X0));
    UB = 2e4*ones(size(X0));
    W  = [ 0:2e2:2e4 ];
    
    % Solve water demand at each grid point    
    for g = 1:length(Cg)
        % fprintf('Iteration %3.0f, constant %6.2f\n',g,Cg(g));
        if g > 1
            X0 = max(Xg(g-1,:)',X0);
        end
        
        if endog_alphaj ~= 0
            profit = @( X ) - ( Cg(g) * X(2).^endog_alphaj .* ...
                X(1).^water_alphaj(1) .* exp(water_alphaj(2)*log(X(1))^2) ...
                - X(1) - X(2));
        else
            profit = @( X ) - ( Cg(g) * X.^water_alphaj(1) .* ...
                exp(water_alphaj(2)*log(X).^2) - X);
        end
        
        try
            [ Xg(g,:) ] = fmincon(profit,X0,[],[],[],[],LB,UB,[],options);
        catch ME
            display(ME);
        end
        
        % production = @( X) Cg(g) * X.^water_alphaj(1) .* exp(water_alphaj(2)*log(X).^2);
        % profit = @( X) Cg(g) * X.^water_alphaj(1) .* exp(water_alphaj(2)*log(X).^2) - X;
        
%         plot(W,-profit(W)); hold on;
%         plot(Xg(g,1),-profit(Xg(g,1)),'o');
        
%         plot(w,zeros(length(w)));   
        
%         LHS = @( w ) log(water_alphaj(1) + 2*water_alphaj(2)*w);
%         RHS = @( w ) Cg(g) + ...
%            (1-sum_endog_alphaj_exwater-water_alphaj(1))*w - ...
%            water_alphaj(2)*w.^2;
    end
    
end

function outcell = proper( cell )
    % Make string entries in a cell array proper case
    properString = @(s) regexprep(lower(s),'(\<[a-z])','${upper($1)}');
    outcell = cellfun(properString,cell,'UniformOutput', false); 
end

function outtab = accumTable( table, groupvar, funcToAccum )
    % Function to take mean values of variable in a table over some 
    %   group identifier variable groupvar
    if nargin < 3
        funcToAccum = @mean;
    end
    
    % Select data array excluding identifier variables
    varsInTable = table.Properties.VariableNames;
    varsInData  = varsInTable(~ismember(varsInTable,groupvar));
    data        = table{:,varsInData};
    columns     = size(data,2);
    
    % For non-trivial groups
    if ~isempty( groupvar )

        % Get unique identifiers for groups
        [ ids, ~, pos ] = unique(table{:,groupvar},'rows');

        % Create index variables
        [ col, row ] = meshgrid(1:columns,pos);

        % Accumulate
        outmatrix = accumarray([row(:) col(:)], reshape(data,[],1),[],...
                                funcToAccum);       
        outarray  = [ ids outmatrix ];
        
    % Simple accumulate for trivial groups
    else
        
        % Create index variables
        N           = size(data,1);
        [ col, row ] = meshgrid(1:columns,ones(N,1));
        
        % Accumulate
        outmatrix = accumarray([row(:) col(:)], reshape(data,[],1),[],...
                                funcToAccum);       
        outarray  = [ outmatrix ];
        
    end
        
    outtab                          = array2table(outarray);
    outtab.Properties.VariableNames = varsInTable;
end