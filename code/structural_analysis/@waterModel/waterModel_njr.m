classdef waterModel
    % waterModel Model for farmer production function
    properties
                    
        % Estimation options
        cropEffects      = 0;
        estimationMethod = 'iv';  % ols, iv, ivWater, gmm
        ivSet            = 'full'; % {'null','sparse','main','full'}
        
        inputForSigmaZ   = 'labor'; % Input to use to estimate sigma^2_Z
        clusterVar       = 'sdo_feeder_code' % clustered std errors for ols/iv
        constrainLabor   = false; % Whether to constrain alpha_X = alpha_K
        
        waterEndogOnly   = false; % Treat only water as endogenous
        calibrateAlpha   = false; % Calibrate alpha_W parameter
        gmmConstrained   = false; % Constrain estimates with marginal profit
        gmmAddMoment     = false; % Add moment on marginal profit
        stoneGeary       = false; % Estimate Stone-Geary production func
        translogTerms    = false;
        
        % Formatting / display options
        printFirstStage  = false;
        noisy            = false;
        gollinUdry       = false;

        % Specification of inputs
        inputUnc = {'land','labor','capital','water'};
        endogUnc = {'land','labor','capital','water'};
        
        inputCon = {'land','laborAndCapital','water'}; 
        endogCon = {'land','laborAndCapital','water'}; 
        
        inputX   = {};
        input2   = {'water2'};
        
        endogWat = {'water'};
        output   = {'revenue'};
        
        % Specification of exogenous controls
        addSoil = true;
        addTemp = false;
        
        % Data
        data;
        
        % Inputs and output tables
        Y; % Table of value of output
        
        % Observables that change effective factor inputs
        Soil_short = {'missing_soil_controls','prop_acidic',...
                      'prop_mildly_alkaline','prop_high_p','prop_med_p'};
        Soil = {'missing_soil_controls','prop_acidic',...
                'prop_mildly_alkaline','prop_high_k',...
                'prop_med_k','prop_high_p','prop_med_p',...
                'prop_sufficient_zn',...
                'prop_sufficient_fe','prop_sufficient_cu',...
                'prop_sufficient_mn'};
                    
        Temperature = {};
        Topo = {'elevation','slope'};
        SDOs = {'x_Isdsdo_2','x_Isdsdo_3','x_Isdsdo_4',...
                'x_Isdsdo_5','x_Isdsdo_6'};
        
        % Observables realized at harvest
        % Losses = {'crop_lost_preharvest','crop_lost_postharvest'};
        Losses = {};
  
        WL     = [];
        WX     = [];
        WK     = [];
        WW     = [];
        WEmiss = []; % Dummy variables added to account for missing obs
        WHmiss = [];
        Wtype = {'wheat','fielspea','mustard','lentil','bengalgram',...
                 'coriander','barley','fenugreek','garlic',...
                 'sugarcane','other'}; % Crop types (wheat to be omitted)
                    
        % Labels for observables
        Wlabels;
        
        % Instrumental variables
        Z; % Data table of instrumental variables
        ZL;
        ZX;
        ZK;
        ZW;
        Zmiss = {}; % Dummy variables added to account for missing obs
       
        % Labels for instrumental variables
        Zlabels;                   

        % OLS estimates 
        ols;       % OLS estimates of factor elasticities
        olspl;     % OLS estimates per unit land
        
        % IV estimates
        fs;        % Cell array containing first stage estimates
        iv;        % 2SLS estimates of factor elasticities
        
        % GMM estimates
        gmm;       % GMM estimates of factor elasticities
        
        % Objects dependent on estimates
        yx_deviations % Factor deviations from within-farmer means
        S;         % Covariance matrix of factor deviations from within-farm means
        omega_hatA % Simple TFP inferred from production residual
        omega_hatB % TFP re-scaled to take out measurement error
        omega_hatC % TFP re-scaled to take out measurement error, in the 
                   %   model with only TFP shocks (as opposed to
                   %   factor-specific productivity shocks also)
        
        % Matrix used in identification of productivity shocks
        IM; % Matrix such that IM Sigma = S
                
        % Model parameters
        alpha;
        bootstrapWaterSE;
        
        betaY = [];
        betaYNames = {};
        betaYH = [];
        betaYHNames = {};
        betaYE = [];
        betaYENames = {};
        
        betaL = [];
        betaLNames = {};
        betaX = [];
        betaXNames = {};
        betaK = [];
        betaKNames = {};
        betaW = [];
        betaWNames = {};
        
        % Matrices to store variance decomposition of productivity shocks
        %   in the full Gollin-Udry decomposition
        Sigma_vec;
        Sigma_omega;
        Sigma_epsilon;
        
        % Matrices to store variance decomposition in the simpler model
        %   with only TFP shocks and measurement error
        Sigma_omega_c;
        Sigma_epsilon_c;
    end
    
    properties (Dependent)
        W;      % All observable variables in the production function
        WE;     % Early-season observables
        WH;     % Late-season observables
        WY;     % Observable variables that affect total factor productivity
        Znames; % Names of instrumental variables used to estimate model
        
        X;     % Data table for design matrix
        y;     % Matrix of log value of output
        x;     % Matrix of log inputs
        input; % Names of inputs used in estimation
        
        endog; % Endogenous variables in estimation
        exog; % Exogenous variables in production function model
    end
    
    methods
        
        function obj = waterModel( waterData, translog )
            % Initialize waterModel object
            
            % Store bids data table as part of scoreModel object
            obj.data = waterData;
            
            % Set translog flag to value passed
            if nargin > 1
                obj.translogTerms = translog;
            end
            
            % Clean data to ensure no missing X or Z variables
            obj = obj.cleanData;
            obj.data.clean.intercept = ones(size(obj.data.clean,1),1);
            
            % Create data tables used in production function specification
            obj.Y = obj.data.clean(:,obj.output);
            obj.Z = obj.data.clean(:,obj.Znames);
        end
        
        function W = get.W( obj )
           % Get observables that affect output via TFP or any factor
           W = [ obj.WY obj.WL obj.WX obj.WK obj.WW ];
        end
        
        function WE = get.WE( obj )
            % Get observable variables that affect output via TFP
            %   early in the season
            if obj.addSoil && obj.addTemp
                WE = [ obj.SDOs obj.Topo obj.Soil obj.Temperature ];
            elseif obj.addSoil
                WE = [ obj.SDOs obj.Topo obj.Soil ];                   
            elseif obj.addTemp
                WE = [ obj.SDOs obj.Topo obj.Temperature ];
            else
                WE = [ obj.SDOs obj.Topo ];
            end       
           
            % Dummy out any missing observations for controls
            WE = [ WE obj.WEmiss ];
        end
        
        function WH = get.WH( obj )
            % Get observable variables that affect output via TFP
            %   at harvest
            WH = [ obj.Losses obj.WHmiss ];
        end
        
        function WY = get.WY( obj )
           % Get observable variables that affect output via TFP
           if obj.cropEffects
               WY = [ obj.WE obj.WH obj.Wtype ]; 
           else
               WY = [ obj.WE obj.WH ]; 
           end
        end
        
        function Znames = get.Znames( obj )
            % Get full set of instrumental variables
            %   Instrument set to use set by model property ivSet
            
            % Instruments that vary by set
            switch obj.ivSet
                case 'null'
                    obj.ZX = {};
                    obj.ZL = {};
                    obj.ZW = {};
                    obj.ZK = {};
                    
                case 'sparse'
                    obj.ZX = {'hh_adult_males','sq_hh_adult_males'};
                    obj.ZL = {'land_owned_pakka','land_owned_pakka2'};
                    obj.ZW = {'rock_area2_4','aquifer_type_4',...
                              'ltot1km_area1140','ltot5km_area1140'};
                    obj.ZK = {};

                case 'main'
                    obj.ZX = {'hh_adult_males','sq_hh_adult_males'};
                    obj.ZL = {'size_largest_parcel_1','size_largest_parcel_2',...
                              'size_largest_parcel_3'};
                    obj.ZW = {'rock_area2_4','aquifer_type_4',...
                              'ltot1km_area1130','ltot5km_area119',...
                              'ltot5km_area1115'};
                    obj.ZK = {'seed_price_across_farmer',...
                              'seed_price_sq_across_farmer'};
                    
                case 'full'
                    obj.ZX = {'hh_adult_males','sq_hh_adult_males'};
                    obj.ZL = {'size_largest_parcel_1','size_largest_parcel_2',...
                              'size_largest_parcel_3','sq_size_largest_parcel_1',...
                              'sq_size_largest_parcel_2','sq_size_largest_parcel_3'};
                    obj.ZW = {'rock_area_14','rock_area_15','aquifer_type_4',...
                              'dist2fault_area116','water_sellers'};
                    obj.ZK = {'seed_price_across_farmer',...
                              'seed_price_sq_across_farmer'};
                          
                case 'water'
                    obj.ZW = {'rock_area_14','rock_area_15','aquifer_type_4',...
                              'dist2fault_area116','water_sellers'};
                          
                case 'depthPDS'
                    obj.ZX = {'hh_adult_males','sq_hh_adult_males'};
                    obj.ZL = {'size_largest_parcel_1','size_largest_parcel_2',...
                              'size_largest_parcel_3','sq_size_largest_parcel_1',...
                              'sq_size_largest_parcel_2','sq_size_largest_parcel_3'};
                    obj.ZW = {'rock_area_1','rock_area_4','rock_area_6',...
                              'rock_area_9','rock_area_15','rock_area_20',...
                              'aquifer_type_4','rock_area2_4','rock_area2_10',...
                              'ltot5km_area1115','dist2fault_area112',...
                              'dist2fault_area116','dist2fault_area1114',...
                              'dist2fault_area1120','dist2fault_area1146'};
                    obj.ZK = {'seed_price_across_farmer',...
                              'seed_price_sq_across_farmer'};
                    
                case 'logDepthPDS'
                    obj.ZX = {'hh_adult_males','sq_hh_adult_males'};
                    obj.ZL = {'size_largest_parcel_1','size_largest_parcel_2',...
                              'size_largest_parcel_3','sq_size_largest_parcel_1',...
                              'sq_size_largest_parcel_2','sq_size_largest_parcel_3'};
                    obj.ZW = {'rock_area_4','rock_area_6','rock_area_14',...
                              'rock_area_15','rock_area_20','aquifer_type_4',...
                              'rock_area2_10','ltot1km_area1130','ltot5km_area119',...
                              'ltot5km_area1115','dist2fault_area1114',...
                              'dist2fault_area1146'};
                    obj.ZK = {'seed_price_across_farmer',...
                              'seed_price_sq_across_farmer'};
                          
                case 'logInvDepthPDS'
                    obj.ZX = {'hh_adult_males','sq_hh_adult_males'};
                    obj.ZL = {'size_largest_parcel_1','size_largest_parcel_2',...
                              'size_largest_parcel_3','sq_size_largest_parcel_1',...
                              'sq_size_largest_parcel_2','sq_size_largest_parcel_3'};
                    obj.ZW = {'rock_area_4','rock_area_6','rock_area_14',...
                              'rock_area_15','rock_area_20','aquifer_type_4',...
                              'rock_area2_10','ltot1km_area1130','ltot5km_area119',...
                              'ltot5km_area1115','dist2fault_area1114',...
                              'dist2fault_area1146'};
                    obj.ZK = {'seed_price_across_farmer',...
                              'seed_price_sq_across_farmer'};
                          
            end
            
            Znames = [ obj.ZL obj.ZX obj.ZK obj.ZW obj.Zmiss ];
        end
        
        function y = get.y( obj )
            % Select log y from output matrix 
            y = table2array(obj.Y);
        end
        
        function X = get.X( obj )
            % Data table of design matrix for production function estimate 
            X = obj.data.clean(:,[obj.input obj.W]);
        end    
        
        function x = get.x( obj )
            % Select log x (inputs, not exogenous variables) 
            x = table2array(obj.X(:,obj.input));
        end    
        
        function endog = get.endog( obj )
            % Select endogenous variables in production function estimation
            if obj.constrainLabor
                endog = obj.endogCon;
            elseif obj.waterEndogOnly
                endog = obj.endogWat;
            else
                endog = obj.endogUnc;
            end 
            
            % Add interaction terms if included
            if obj.translogTerms
                endog = [ endog obj.inputX obj.input2 ];
            end
        end
        
        function exog = get.exog( obj )
            % Names of variables treated as exogenous in production 
            %   function model, as complement of endogenous variables
            exogi = ~ismember(obj.X.Properties.VariableNames,obj.endog);
            exog  = obj.X.Properties.VariableNames(exogi);
        end
        
        function input = get.input( obj )
            % Names of inputs, choice among unconstrained or constrained
            if obj.constrainLabor
                input = [ obj.inputCon ];
            else
                input = [ obj.inputUnc ];
            end
            
            if obj.translogTerms
                input = [ input obj.inputX obj.input2 ];
            end 
        end
        
        function obj = cleanCropTypes( obj )
            % Clean crop type dummy variables 
            anyCrop = any(table2array(obj.data.clean(:,obj.Wtype)),1);
            obj.Wtype = obj.Wtype(anyCrop);
            obj.Wtype = obj.Wtype( ~ismember(obj.Wtype,'wheat') );
        end
        
        function obj = generateInputInteractions( obj )
            % Generate interactions between input variables and squares
             
            for t = 1:length(obj.inputX)
                inputsToCross = strsplit(obj.inputX{t},'X');
                obj.data.clean(:,obj.inputX{t}) = array2table( ... 
                    table2array(obj.data.clean(:,inputsToCross{1})) .* ...
                    table2array(obj.data.clean(:,inputsToCross{2})) );
            end
            
            for t = 1:length(obj.input2)
                inputsToSquare = strsplit(obj.input2{t},'2');
                obj.data.clean(:,obj.input2{t}) = array2table( ...
                    table2array(obj.data.clean(:,inputsToSquare{1})).^2 );
            end
            
        end
        
        function obj = cleanData( obj )
            % Clean data to assure that inputs and instrumental variables 
            %   Have non-missing values for all farmer X crops.  
            %   Zero out any missing observations, so that instruments do 
            %   not affect the number of farmer X crop observations used in 
            %   estimation
            
            % Clean crop types
            obj = cleanCropTypes( obj );
            
            % Clean exogenous control variables WE and WH    
            [ obj.data.clean, obj.WEmiss ] = ...
                dummyOutMissing( obj.data.clean, obj.WE );
             [ obj.data.clean, obj.WHmiss ] = ...
                dummyOutMissing( obj.data.clean, obj.WH );
            
            % Clean instruments Z
            [ obj.data.clean, obj.Zmiss ] = ...
                dummyOutMissing( obj.data.clean, obj.Znames );
            
            % Generate interactions of inputs, if estimating production
            %   function with translog terms
            if obj.translogTerms
                obj = obj.generateInputInteractions;
            end
            
            % Re-order variables for easy reading
            obj.data.clean = reorderVars( obj.data.clean, ...
                [ obj.output obj.input obj.WY obj.Znames ]);
        end
        
        function obj = estimateOLS( obj )
            % Estimate waterModel by OLS
%             independent   = strjoin(obj.X.Properties.VariableNames,' + ');
%             specification = [ obj.output{1} ' ~ ' independent ];
%             obj.ols = fitlm(obj.data.clean,specification);
%             
%             display(obj.ols);
            obj.ols = ols(obj.y, obj.X, 'vartype', 'cluster', 'clusterid', ...
                table2array(obj.data.clean(:,obj.clusterVar))); %#ok<CPROP>
            
            obj.printOLS;
        end
        
        function obj = estimateIV( obj )
            % Estimate waterModel by 2SLS
            
            % Estimate first-stage equations for each endogenous variable
            obj = obj.firststage;

            % Estimate production function by 2SLS
            endogi = ismember(obj.X.Properties.VariableNames,obj.endog);
            endogi = find(endogi);
            obj.iv = iv2sls( obj.y, obj.X, obj.Z, ...
                             'endog', endogi, 'vartype', 'cluster', 'clustervar', obj.data.clean(:,obj.clusterVar));  
            obj.printIV;
        end
        
        function obj = estimateGMM( obj )
            % Estimate waterModel by GMM

            % Estimation options
            options = optimoptions(@fminunc,'Display','iter',...
                                   'MaxIter',3000,'MaxFunEvals',1e5,...
                                   'TolX',1e-8,'TolFun',1e-8,...
                                   'Algorithm','quasi-newton');
            
            % Store data in matrices, not tables
            obj.gmm.N = size(obj.y,1);
            y = obj.y;  %#ok<*PROP>
            X = [ table2array(obj.X) ones(obj.gmm.N,1) ];
            
            % Form instruments for GMM
            exog = ~ismember(obj.X.Properties.VariableNames,obj.endog);
            Z    = [ X(:,exog) table2array(obj.Z) ones(obj.gmm.N,1) ];
            
            % Retrieve variable names
            obj.gmm.xnames = [ obj.X.Properties.VariableNames'; 'constant' ];
            obj.gmm.znames = [ obj.Z.Properties.VariableNames'; 'constant' ];
            
            % Estimate 2SLS coefficients for initial parameter values
            obj   = obj.estimateIV;
            beta0 = obj.iv.coef;  
            
            % Two-step optimal GMM estimator
            if ~obj.gmmAddMoment

                % Weighting matrix
                eps_hat      = y - X*beta0;
                Omega_hat    = Z'*Z*(eps_hat'*eps_hat)/obj.gmm.N;

                % Cobb-Douglas production function
                if ~obj.stoneGeary
                                       
                    % Two-step optimal GMM estimator
                    gmmObjective = @( beta ) ((y-X*beta)'*Z/obj.gmm.N)*...
                                   inv(Omega_hat)*(Z'*(y-X*beta)/obj.gmm.N); %#ok<*MINV>
                    [ obj.gmm.coef ] = fminunc( gmmObjective, beta0, options );
                    
                % Stone-Geary production function (in water, CD otherwise)
                else
                    
                    % Pick out water input to add threshold
                    wpos = find(ismember(obj.input,'water'));
                    W    = exp(X(:,wpos));
                    
                    % GMM estimator
                    gmmObjective = @( beta ) gmmObjectiveSG( beta, y, X, ...
                                            Z, obj.gmm.N, Omega_hat, W, wpos );
                    [ obj.gmm.coef ] = fminunc( gmmObjective, [ beta0; 0], options );
                end
            
            % Two-step optimal GMM estimator
            %   with additional moment based on dPi/DH
            else
                
                % Return to increasing the ration
                dPidHhat = 2190; % INR per Hour per Ha

                % Instantiate counterfactual object, for use in calculating
                %   the additional moment
                counter        = waterCounter( obj );
                counter.policy = waterPolicy('rationing');

                % Weighting matrix (w/ additional moment) at initial estimates
                [ ~, giHat ] = gMoments( beta0, y, X, Z, obj.gmm.N, ...
                                           dPidHhat, obj, counter );
                Omega_hat    = giHat'*giHat/obj.gmm.N;
                display(Omega_hat);
            
                % Two-step optimal GMM estimator
                gmmObjective = @( beta ) gmmObjectiveExtra( beta, y, X, ...
                    Z, obj.gmm.N, dPidHhat, obj, counter, Omega_hat );                       
                [ obj.gmm.coef ] = fminunc( gmmObjective, beta0, options );
            end            
            
            % Store results of GMM
            obj.gmm.y = obj.y;
            obj.gmm.X = X;
            obj.gmm.Z = Z;
            
            if ~obj.stoneGeary
                obj.gmm.res = y - X*obj.gmm.coef;
            else
                X(:,wpos) = log(W-obj.gmm.coef(end));
                obj.gmm.res = y - X*obj.gmm.coef(1:end-1);
            end
                        
            % Variance estimate
            % V_hat = inv((X'*Z/obj.gmm.N)*inv(Omega_hat)*(Z'*X/obj.gmm.N));
           
            % obj.gmm.stderr = sqrt(diag(V_hat));
            % obj.gmm.tStat  = obj.gmm.coef ./ obj.gmm.stderr;
            % obj.gmm.pValue = 2*(1-tcdf(abs(obj.gmm.tStat),obj.gmm.N));
            
            obj.printGMM;
        end
        
        function [ C, Ceq ] = gmmConstraint( beta, model, counter )
           % Constraint function to impose the constraint that marginal 
           %   benefits of relaxing the ration be equal to reduced-form
           %   empirical estimate
           
           % Store current coefficient estimates and calculate residuals
           model.gmm.coef = beta;
           model          = model.decomposition;
           model          = model.residuals;
           
           % Update model parameters in counterfactual object
           % counter.model = obj; % Could update only parameters here
           counter.model.alpha  = model.alpha;
           counter.model.betaYE = model.betaYE; 
           counter.model.betaYH = model.betaYH;
           
           % Update residuals in counterfactual object, if desired, and
           %   pass through the updated residuals to productivity
           counter.model.yx_deviations = model.yx_deviations;
           counter.model.S             = model.S;
           counter.model.omega_hatA    = model.omega_hatA;
           counter.model.omega_hatC    = model.omega_hatC;
           counter                     = counter.productivity;
            
           % Marginal benefit of relaxing the ration
           mb = counter.marginalBenefit;

           % Store inequality and equality constraints for output
           C   = []; % No inequality constraints
           Ceq = mb; % Marginal benefit
           
           if ~isreal(mb)
               display('Complex constraint!');
           end
        end
        
        function obj = printOLS( obj )
            % Print OLS estimates
            olsTable = ...
                table(obj.ols.coef, obj.ols.stderr, obj.ols.tStat,...
                    obj.ols.pValue,...
                    'VariableNames',{'Coefficient','SE','tStat','pValue'}, ...
                    'RowNames',obj.ols.xnames);
            
            display(olsTable);
            
            fprintf(1,['Number of observations: %5.0f, ', ...
                       'Error degrees of freedom: %5.0f\n'], ...
                       obj.ols.N, obj.ols.resdf);
            fprintf(1,'Root Mean Squared Error: %4.3f\n',...
                       sqrt(obj.ols.RSS/obj.ols.N));
            fprintf(1,'R-squared: %4.3f, Adjusted R-Squared: %4.3f\n',...
                       obj.ols.r2,obj.ols.adjr2);
        end
        
        function obj = printIV( obj )
           % Print IV estimates
           
           ivTable = ...
               table(obj.iv.coef,obj.iv.stderr,obj.iv.tStat,...
                 obj.iv.pValue,...
                 'VariableNames',{'Coefficient','SE','tStat','pValue'}, ...
                 'RowNames',obj.iv.xnames);
             
            display(ivTable);
            
            fprintf(1,['Number of observations: %5.0f, ',...
                       'Error degrees of freedom: %5.0f\n'],...
                       obj.iv.n,obj.iv.resdf);
            fprintf(1,'Root Mean Squared Error: %4.3f\n',...
                       sqrt(obj.iv.RSS/obj.iv.n));
            fprintf(1,'R-squared: %4.3f, Adjusted R-Squared: %4.3f\n',...
                       obj.iv.r2,obj.iv.adjr2);
            % fprintf(1,['F-statistic vs. constant model: ,',...
            %            'p-value = 0\n'],    );

        end
        
        function obj = printGMM( obj )
            % Print GMM estimates
            
            ivTable = ...
               table(obj.gmm.coef,'VariableNames',{'Coefficient'}, ...
                 'RowNames',[obj.gmm.xnames; {'W_bar'}]);
             
            display(ivTable);
            
            fprintf(1,['Number of observations: %5.0f\n'],...
                       obj.gmm.N);
            % fprintf(1,'Root Mean Squared Error: %4.3f\n',...
            %            sqrt(obj.iv.RSS/obj.iv.n));
            % fprintf(1,'R-squared: %4.3f, Adjusted R-Squared: %4.3f\n',...
            %            obj.iv.r2,obj.iv.adjr2);
        end
       
        function obj = firststage( obj )
            % Estimate input demand equations that comprise the first stage            
            obj.fs = cell(size(obj.endog));
            for i = 1:length(obj.endog)
                
               % Estimate first stage equation
               independent   = strjoin([ obj.exog obj.Znames ],' + ');
               specification = [ obj.endog{i} ' ~ ' independent ];
               obj.fs{i} = fitlm(obj.data.clean,specification);
               
               % Print first stage equation
               fprintf(1,'\nFirst stage: %s input demand\n',obj.endog{i});
               if obj.printFirstStage
                   display(obj.fs{i});
               end
            end
        end
        
        function obj = parseProductionCoefficients( obj )
            % Parse production function coefficients on observable
            %   characteristics
            
            % Pick coefficients from OLS or IV
            switch obj.estimationMethod
                case 'ols'
                    coefNames    = obj.ols.xnames;
                    coefficients = obj.ols.coef;
                    intercept    = '(Intercept)';
                case 'iv'
                    coefNames    = obj.iv.xnames;
                    coefficients = obj.iv.coef;  
                    intercept    = 'CONST';
                case 'gmm'
                    coefNames    = obj.gmm.xnames;
                    coefficients = obj.gmm.coef;
                    intercept    = 'constant';
            end
            
            % Store output elasticities with respect to each input
            alphaIndex = [ find(ismember(coefNames,obj.input)) ];
            alphaNames = coefNames(alphaIndex);
            obj.alpha  = coefficients(alphaIndex);
            
            % Apply constrained coefficient to both capital and labor
            if obj.constrainLabor
                laborCapitalIdx = find(strcmp(alphaNames,'laborAndCapital'));
                alphaNames = [ alphaNames(1:laborCapitalIdx-1) ...
                               {'labor','capital'} ...
                               alphaNames(laborCapitalIdx+1:end) ];
                alphaIndex = [ alphaIndex(1:laborCapitalIdx-1) ...
                               repmat(alphaIndex(laborCapitalIdx),1,2) ...
                               alphaIndex(laborCapitalIdx+1:end) ];
                obj.alpha  = coefficients(alphaIndex);
                obj.constrainLabor = false;
            end
               
            % Coefficients on factor-specific observables
            
            % Output
            betaIndex      = find(ismember(coefNames,[ obj.WY intercept ]));
            obj.betaY      = coefficients(betaIndex);
            obj.betaYNames = coefNames(betaIndex);
            obj.betaYNames{end} = 'intercept';
            
            betaIndex       = find(ismember(coefNames,obj.WH));
            obj.betaYH      = coefficients(betaIndex);
            obj.betaYHNames = coefNames(betaIndex);
            
            betaIndex       = find(ismember(coefNames,[ obj.WE intercept ]));
            obj.betaYE      = coefficients(betaIndex);
            obj.betaYENames = coefNames(betaIndex);
            obj.betaYENames{end} = 'intercept';
            
            % Land
            if ~isempty( obj.WL );
                alphaL     = obj.alpha(ismember(alphaNames,'land'));
                betaIndex  = find(ismember(coefNames,obj.WL));
                obj.betaL      = coefficients(betaIndex) / alphaL;
                obj.betaLNames = coefNames(betaIndex);  
            end
            
            % Labor 
            if ~isempty( obj.WX );                
                alphaX     = obj.alpha(ismember(alphaNames,'labor'));
                betaIndex  = find(ismember(coefNames,obj.WX));
                obj.betaX      = coefficients(betaIndex) / alphaX;
                obj.betaXNames = coefNames(betaIndex);  
            end
            
            % Capital 
            if ~isempty( obj.WK );
                alphaK     = obj.alpha(ismember(alphaNames,'capital'));
                betaIndex  = find(ismember(coefNames,obj.WK));
                obj.betaK      = coefficients(betaIndex) / alphaK;
                obj.betaKNames = coefNames(betaIndex);  
            end

            % Water
            if ~isempty( obj.WW );
                alphaW     = obj.alpha(ismember(alphaNames,'water'));
                betaIndex  = find(ismember(coefNames,obj.WW));
                obj.betaW      = coefficients(betaIndex) / alphaW;
                obj.betaWNames = coefNames(betaIndex);  
            end
        end
        
        function obj = adjustObservedInputs( obj )
            % Adjust observable inputs for effective inputs using the
            %   estimated model parameters and subtract farmer means.
            obj = parseProductionCoefficients( obj );
            
            % Adjust observed log value of output and log input values for
            %   observable characteristics at farmer X crop level
            yAdj = obj.y - ...
                table2array(obj.data.clean(:,obj.betaYHNames)) * obj.betaYH;
            
            input_adjustments = zeros(size(yAdj,1),length(obj.inputUnc));
            if ~isempty( obj.betaLNames )
               input_adjustments(:,1) = ...
                   table2array(obj.data.clean(:,obj.betaLNames)) * obj.betaL;
            end
            
            if ~isempty( obj.betaXNames )
               input_adjustments(:,2) = ...
                   table2array(obj.data.clean(:,obj.betaXNames)) * obj.betaX;
            end
            
            if ~isempty( obj.betaKNames )
               input_adjustments(:,3) = ...
                   table2array(obj.data.clean(:,obj.betaKNames)) * obj.betaK;
            end
            
            if ~isempty( obj.betaWNames )
               input_adjustments(:,4) = ...
                   table2array(obj.data.clean(:,obj.betaWNames)) * obj.betaW;
            end
           
            xAdj = table2array(obj.data.clean(:,obj.inputUnc)) - ...
                   input_adjustments;
            
            % Farmer log value of output and log input mean values
            [ ~, ~, cfi ] = unique(obj.data.clean.farmer_id);
            yx_bar        = grpstats([ yAdj xAdj ],cfi,'mean');
            
            % Deviations of log value of output and log input from means
            obj.yx_deviations = [ yAdj xAdj ] - yx_bar(cfi,:); 
            
        end
        
        function obj = decomposition( obj )
            % Decomposition of variance using adjusted input demands and 
            %   output from the estimated production function model. Breaks 
            %   down simple TFP into components of factor-specific 
            %   productivity shocks and measurement error.
            
            % Within-farmer deviations from mean adjusted log output and 
            %   adjusted log inputs
            obj = obj.adjustObservedInputs;

            % Calculate covariance matrix of within-farm deviations from
            %   mean adjusted log output and adjusted log inputs
            obj.S = cov(obj.yx_deviations);
            D     = size(obj.S,1);
            if obj.noisy
                fprintf(1,'\nCovariance of [y x] deviations\n');
                display(obj.S); 
            end
            
            if obj.gollinUdry
                if obj.noisy
                    fprintf(1,'**************************************\n');
                    fprintf(1,'a. Gollin-Udry (2019) decomposition\n');
                end

                % Use linear system to solve for unobserved shock parameters as
                %   a function of the estimated covariance matrix
                S_vec         = drawVectorFromDiags( obj.S );
                obj.IM        = identificationMatrix( D );
                obj.Sigma_vec = obj.IM \ [ S_vec; zeros(D,1) ];

                % Transform vector of parameters into matrices Sigma_omega and
                %   Sigma_epsilon that hold productivity variances and
                %   measurement error variances, respectively.      
                obj.Sigma_omega   = putVectorOnDiags( obj.Sigma_vec(1:end-D) );
                if obj.noisy
                    fprintf(1,'\nProductivity shocks\n');
                    display(obj.Sigma_omega);
                end

                obj.Sigma_epsilon = diag( obj.Sigma_vec(end-D+1:end) );
                if obj.noisy
                    fprintf(1,'\nMeasurement error\n');
                    display(obj.Sigma_epsilon);
                end
            end
                
            if obj.noisy
                fprintf(1,'**************************************\n');
                fprintf(1,'b. TFP-only productivity decomposition\n');
            end
            
            inputIdx = find(ismember(obj.input,obj.inputForSigmaZ));
            obj.Sigma_omega_c = obj.S(1,inputIdx+1);
            if obj.noisy
                fprintf(1,'\nProductivity shocks\n');
                display(obj.Sigma_omega_c);
            end
            
            epsilonJ = diag(obj.S) - obj.Sigma_omega_c;
            obj.Sigma_epsilon_c = diag( epsilonJ );
            if obj.noisy
                fprintf(1,'\nMeasurement error\n');
                display(obj.Sigma_epsilon_c);
            end
        end
        
        function obj = residuals( obj )
            % Store and deflate production function residuals
            obj = obj.residualsStore;
            obj = obj.residualsDeflate;
        end
                
        function obj = residualsStore( obj )
            % Infer production residuals using production coefficients
            
            % Simple estimate of TFP
            %   Pick coefficients from OLS or IV
            %   Residual of production function, or TFP^a in Gollin and
            %   Udry's (2019) terminology
            switch obj.estimationMethod
                case 'ols'
                    obj.omega_hatA = obj.ols.Residuals.Raw;
                case 'iv'
                    obj.omega_hatA = obj.iv.res;
                case 'gmm'
                    obj.omega_hatA = obj.gmm.res;
            end
        end
        
        function obj = residualsDeflate( obj )
            % Deflate production function residuals to account for
            %   measurement error 
        
            % Deflated estimate of TFP
            %   Deflate TFP^a to account for measurement error in inputs
            %   and output. 
            varTFPa = var(obj.omega_hatA);
            muTFPa  = mean(obj.omega_hatA);
                       
            % TFB^b is the full Gollin-Udry model, which
            %   allows for factor-specific productivity shocks as well as
            %   measurement error.
            if obj.gollinUdry
                sigEps  = diag(obj.Sigma_epsilon);
                varTFPb = (varTFPa - sigEps(1) - sigEps(2:end)'*obj.alpha.^2 );
                TFPb    = muTFPa + (obj.omega_hatA - muTFPa) * ...
                            sqrt( varTFPb/varTFPa );
                obj.omega_hatB = TFPb;
            end
            
            % TFB^c is the deflated TFP from a simpler model, which allows
            %   for measurement error but not factor-specific productivity
            %   shocks.
            sigEps  = diag(obj.Sigma_epsilon_c);
            if ~obj.translogTerms
                varTFPc = (varTFPa - sigEps(1) - sigEps(2:end)'*obj.alpha.^2 );
            else
                varTFPc = (varTFPa - sigEps(1) - ...
                    sigEps(2:end-1)'*obj.alpha(1:end-2).^2 - ...
                    sigEps(end)*(obj.alpha(end-1)+...
                            2*obj.alpha(end)*mean(obj.data.clean.water)).^2);
            end
            
            varWght = normcdf((varTFPc-0.2*varTFPa)/(0.025*varTFPa));
            varTFPc = varWght*varTFPc + (1-varWght)*0.2*varTFPa;
            TFPc    = muTFPa + (obj.omega_hatA - muTFPa) * ...
                        sqrt( varTFPc/varTFPa );
            obj.omega_hatC = TFPc;
            
            if any(~isreal(obj.omega_hatC))
                fprintf(1,'Complex productivity!\n');
            end
                       
            if obj.noisy
                fprintf(1,'**************************************\n');
                fprintf(1,'c. Variance of TFP shocks\n');
                fprintf(1,'  TFPa (raw residual)   : %4.3f\n',varTFPa);
                if obj.gollinUdry
                    fprintf(1,'  TFPb (Gollin-Udry)    : %4.3f\n',varTFPb);
                end
                fprintf(1,'  TFPc (TFP shocks only): %4.3f\n\n',varTFPc);
            
                % 90-10 log differences in productivity
                logdiff9010a = diff(prctile(obj.omega_hatA,[10 90]));
                logdiff9010b = diff(prctile(TFPb,[10 90]));
                logdiff9010c = diff(prctile(TFPc,[10 90]));
                
                fprintf(1,'90-10 log difference in TFP\n');
                fprintf(1,'  TFPa (raw residual)   : %4.3f\n',logdiff9010a);
                if obj.gollinUdry
                    fprintf(1,'  TFPb (Gollin-Udry)    : %4.3f\n',logdiff9010b);
                end
                fprintf(1,'  TFPc (TFP shocks only): %4.3f\n\n',logdiff9010c);
            end
        end
        
        function obj = residualsRefresh( obj )
            % Refresh production function residuals after calibration of
            %   alphaW coefficient, which changes residual estimates
            wIdx = find(ismember(obj.iv.xnames,'water'));
            obj.iv.coef(wIdx) = obj.alpha(end);
            obj.iv.res = obj.iv.y - obj.iv.X*obj.iv.coef(1:end-1) - ...
                obj.iv.coef(end);
            obj = obj.residuals;
        end      
        
        [ ] = plotTFPDistribution( obj, file );
        
        [ ] = tabulate( obj, file );
    
    end % methods
        
end % class waterModel

function A = identificationMatrix( N )
   % Produce matrix A such that A Sigma = S where
   %   Sigma is the vector consisting of the structural parameters, 
   %     namely factor-specific productivity shocks and factor-
   %     specific measurement error.
   %   S is the vector with elements drawn from the estimated
   %     covariance matrix of deviations of input and output from
   %     their farmer-specific means
   switch N

       case 5                  
           A =   [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0;
                  1,1,0,0,0,2,0,0,0,0,0,0,0,0,0,0,1,0,0,0;
                  1,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0,1,0,0;
                  1,0,0,1,0,0,0,0,0,0,0,0,2,0,0,0,0,0,1,0;
                  1,0,0,0,1,0,0,0,0,0,0,0,0,0,2,0,0,0,0,1;
                  1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
                  1,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0,0;
                  1,0,0,0,0,0,0,1,0,1,0,0,1,0,0,0,0,0,0,0;
                  1,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0;
                  1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0;
                  1,0,0,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,0,0;
                  1,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0;
                  1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0;
                  1,0,0,0,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0;
                  1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0;
                  0,0,0,0,0,1,0,0,0,1,0,0,1,0,1,0,0,0,0,0;
                  0,1,1,1,1,0,1,1,1,0,1,1,0,1,0,0,0,0,0,0;
                  0,-1,1,1,1,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0;
                  0,1,-1,1,1,0,0,0,1,0,1,0,0,1,0,0,0,0,0,0;
                  0,1,1,-1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

       otherwise
           A = [];

   end
end

function S_vec = drawVectorFromDiags( S ) 
   % Parse a matrix into a vector
   %   Draw the elements from from the upper diagonals of the 
   %   input matrix in sequence from the main diagonal upwards
   D     = size(S,1);
   S_vec = zeros( D*(D+1)/2, 1 );
   is    = 1;
   for d = 0:D-1
       ie = is + (D-1-d);
       S_vec(is:ie) = diag(S,d);
       is = ie + 1;
   end 
end

function S = putVectorOnDiags( S_vec ) 
    % Parse a vector into a matrix
    %   The matrix is upper triangular with the diagonal elements
    %   of the matrix drawn from the vector. The diagonals are
    %   populated from the main diagonal upwards.

    % Extract length of vector and calculate size of matrix
    L = length(S_vec);
    D = 1/2*( -1 + sqrt( 1 + 8*L ) );

    % Populate diagonals of resulting matrix with elements drawn
    %   from vector
    S  = zeros(D,D);
    is = 1;
    for d = 0:D-1
        ie = is + (D-1-d);
        S  = full(spdiags(S_vec(is:ie),-d,S));
        is = ie + 1;
    end
    S = S';
end

function [ D, newMissingDums ] = dummyOutMissing( D, names )
    % Dummy out missing values of variables in a data table
    %   Replace all missing values with zero, and add a dummy variable
    %   equal to one if the variable was initially missing
    
    % Flag variables missing any observations
    missing        = any(isnan(table2array(D(:,names))),1);
    varsMissingAny = names(missing);
    
    % Quit if nothing to replace
    if isempty(varsMissingAny)
        newMissingDums = {};
        return
    end
    
    % Set missing values to zero
    varsMissingMat = D{:,varsMissingAny};
    missingObs     = isnan(varsMissingMat);
    varsMissingMat(missingObs) = 0;
    D{:,varsMissingAny} = varsMissingMat;
    
    % Create names of new variables
    uniqueDummies    = rank(double(missingObs));
    newMissingDums   = cell(1,uniqueDummies);
    missingObsUnique = zeros(size(missingObs,1),uniqueDummies);
    j                = 1;
    for i = 1:length(varsMissingAny)
        
        % Whether column is collinear with those added before
        if i == 1
            fullRank = 1;
        else
            fullRank = rank([missingObsUnique(:,1:j-1) missingObs(:,i)]) == ...
                       size([missingObsUnique(:,1:j-1) missingObs(:,i)],2);
        end
        
        % If dummy is not collinear, add it to matrix of dummies
        if fullRank
            missingObsUnique(:,j) = missingObs(:,i);
            newMissingDums{j} = [ varsMissingAny{i} '_miss' ];
            j = j + 1;
        else
            continue;
        end
        
    end
    
    % Append new dummy variables to data table
    missingDummy = array2table(missingObsUnique,'VariableNames',...
                               newMissingDums);
    D = [ D missingDummy ];
end

function [ D ] = reorderVars( D, varNamesToMove )
    % Reorder variables in table to put varNamesToMove in front
    varNames = D.Properties.VariableNames;
    moveCols = ismember( varNames, varNamesToMove );
    varNamesAtEnd = varNames( ~moveCols );
    D = [ D(:,varNamesToMove) D(:,varNamesAtEnd) ];
end

function [ fval ] = gmmObjectiveExtra( beta, y, X, Z, N, ...
                           dPidHhat, obj, counter, Omega_hat )
    % Calculate GMM objective function value with extra moment
    gbeta = gMoments( beta, y, X, Z, N, ...
                      dPidHhat, obj, counter );
    fval = gbeta'* inv(Omega_hat) * gbeta; 
end

function [ g, gi ] = gMoments( beta, y, X, Z, N, ...
                               dPidHhat, model, counter )
    % Calculate sample moments 

    % Instrumental variables moments
    [ g1, ~ ] = g1Moments( beta, y, X, Z, N );

    % Counterfactual moment based on dPi/dH
    [ g2, ~ ] = g2Moments( beta, N, dPidHhat, model, counter );

    % Stack moments in vector of size M X 1
    g = [ g1; g2 ];

    % Get observation-level moments of size N X M
    %   If needed to calculate covariance matrix
    [ ~, g1i ] = g1Moments( beta, y, X, Z, N );
    [ ~, g2i ] = g2Moments( beta, N, dPidHhat, model, counter );
    gi = [ g1i, g2i ];
end

function [ g1, g1i ] = g1Moments( beta, y, X, Z, N )
    % Moments based on instrument orthogonality conditions
    g1  = Z'*(y-X*beta)/N;                   % Aggregate
    g1i = Z .* repmat(y-X*beta,1,size(Z,2)); % Observation level
end

function [ g2, g2i ] = g2Moments( beta, N, dPidHhat, model, counter )
    % Moments based on counterfactual profit

    % Store current coefficient estimates and calculate residuals
    model.gmm.coef = beta;
    model          = model.decomposition;
    model          = model.residuals;

    % Update model parameters in counterfactual object
    % counter.model = obj; % Could update only parameters here
    counter.model.alpha  = model.alpha;
    counter.model.betaYE = model.betaYE; 
    counter.model.betaYH = model.betaYH;

    % Update residuals in counterfactual object, if desired, and
    %   pass through the updated residuals to productivity
    % counter.model.yx_deviations = model.yx_deviations;
    % counter.model.S             = model.S;
    % counter.model.omega_hatA    = model.omega_hatA;
    % counter.model.omega_hatC    = model.omega_hatC;
    % counter = counter.productivity;

    % Marginal benefit of relaxing the ration
    [ mb ] = counter.marginalBenefit;

    % Moment based on difference between model and estimate
    g2 = (1e3*mb - dPidHhat)/N; % Aggregate moment

    % Observation level moment
    [ ~, mbi ] = counter.marginalBenefit;
    g2i = 1e3*mbi - dPidHhat; % Farmer X crop moment
end

function [ fval ] = gmmObjectiveSG( beta, y, X, Z, N, Omega_hat, W, wpos )
    % Calculate GMM objective function value with extra moment
    gbeta = g1MomentsSG( beta, y, X, Z, N, W, wpos );
    fval  = gbeta'* inv(Omega_hat) * gbeta; 
end

function [ g1, g1i ] = g1MomentsSG( beta, y, X, Z, N, W, wpos )
    % Moments based on instrument orthogonality conditions
    %   Production function Stone-Geary in water
    
    % Calculate production residual
    X(:,wpos) = log(W-beta(end)); % Replace log(W) with log(W-W_bar)
    epsHat = y - X*beta(1:end-1); % Form residuals
    
    % Form moments
    g1  = Z'*epsHat/N;                                % Aggregate
    g1i = Z .* repmat(y-X*beta(1:end-1),1,size(Z,2)); % Observation level
end

function [ stop ] = outfun(x,optimValues,state)
   stop = false;
 
   switch state
       case 'init'
           hold on
       case 'iter'
           display(x');
       case 'done'
           hold off
       otherwise
   end
end
