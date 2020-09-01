classdef waterPlanner
    %waterPlanner Solve the planner's problem for optimal water policy
    %   A water planner object specifies the planner's problem and solves
    %   it, with the objective of maximizing farmer surplus. Surplus under
    %   each candidate policy is calculated using a waterCounter object
    %   that runs counterfactuals.
    
    properties
        
        counter; % Water planner object
        
        regime;      % What dimension to optimize over
        opt_policy;  % Optimal policy (price or ration)
        opt_price;   % Optimal price of power (Rs/kWh)
        opt_ration;  % Optimal ration of power (Hours per day)
        opt_surplus; % Surplus achieved by optimal policy   
    end
    
    properties (Dependent)
        instrument0; % Default level of policy instrument
    end
    
    methods
        
        function obj = waterPlanner( waterCounter )
            % Initialize waterCounter object
            
            % Store counterfactual object 
            obj.counter               = waterCounter;
            obj.counter.aggregateOnly = true;
            
            % Record the policy lever used in the counterfactual
            obj.regime = obj.counter.policy.regime;
        end
        
        function instrument0 = get.instrument0( obj )
            % Initialize instrument (price/ration) based on regime
            switch obj.regime
                case 'pigouvian'
                    instrument0 = obj.counter.policy.power_price;
                case 'rationing'
                    instrument0 = obj.counter.policy.ration;
            end
        end
    
        function obj = solvePlannersProblem( obj )
            % Maximize surplus
            
            % Cobb-Douglas production yields smooth planner's problem
            if ~obj.counter.model.translogTerms
                options = optimoptions(@fminunc,'Display','iter',...
                                       'MaxIter',200,...
                                       'Algorithm','quasi-newton');

                objective   = @( x ) - obj.plannersObjective( x );
                [ obj.opt_policy, obj.opt_surplus ] = ...
                    fminunc( objective, obj.instrument0, options );

            % Translog production solves for input demands numerically,
            %   yielding a planner's objective that is slightly nonsmooth 
            %   (at the scale of (1e-6) or below
            else
                options = psoptimset('Display','iter',...
                                     'TolMesh',1e-4,'TolX',1e-4,...
                                     'MaxIter',1000);
                LB = 0;
                UB = 24;

                objective   = @( x ) - obj.plannersObjective( x );
                [ obj.opt_policy, obj.opt_surplus ] = ...
                    patternsearch( objective, obj.instrument0, [], [], ...
                            [], [], LB, UB, [], options );                
            end
                
            % Store and print result
            fprintf(1,'\nRegime is %s\n', obj.regime);
            switch obj.regime
                case 'pigouvian'
                    obj.opt_price = obj.opt_policy;
                    fprintf(1,'\tInitial price: %3.2f Rs per kWh\n',obj.instrument0);
                    fprintf(1,'\tOptimal price: %3.2f Rs per kWh\n',obj.opt_price); 
      
                case 'rationing'
                    obj.opt_ration = obj.opt_policy;
                    fprintf(1,'\tInitial ration: %3.2f hours per day\n',obj.instrument0);
                    fprintf(1,'\tOptimal ration: %3.2f hours per day\n',obj.opt_ration); 
            end
            
        end

        function S = plannersObjective( obj, instrument )
            % Planner's objective function
            
            % Update policy to new instrument (price/ration)
            switch obj.regime
                case 'pigouvian'
                    obj.counter.policy.power_price = instrument;
                    
                case 'rationing'
                    obj.counter.policy.ration = instrument;
            end
            
            % Calculate surplus under the updated policy
            counterfactual = obj.counter.solveFarmersProblem;
            S = counterfactual.outcomes.surplus;
        end
        
        [ ] = plotPlannersObjective( obj, pointsToPlot );
        
    end
    
end

