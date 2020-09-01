classdef waterPolicy
    % waterPolicy Definition of a water policy regime
    properties
        
        regime  = 'pigouvian'; % rationing, private_cost, pigouvian, block_pricing
        varies  = 'uniform';   % uniform, hetero
        rebate  = 'none';      % none, flat, land, pump
  
        power_cost = 6.2; % Rs / kWh variable cost of supply
        power_price;      % Rs / kWh
        ration;           % Hours per day
        
        price_steps  = [];
        ration_steps = [];
        
    end
    
    properties (Dependent)
        water_cost;
        T;          % Transfer in Rs
    end
    
    methods
        
        function obj = waterPolicy( regime )
            % Initialize waterPolicy object
            
            % Initialize regime, if passed
            if exist('regime','var')
                obj.regime = regime;
            end
            
            % Initialize power price based on policy regime
            %   The power price can also be set directly as a property of
            %   the policy.
            obj.power_price = obj.default_power_price;
            
            % Initialize ration
            obj.ration = obj.default_ration;
            
            % Initialize block pricing
            if strcmp(regime,'block_pricing')
                obj.price_steps  = [ 0.90 obj.power_price ];
                obj.ration_steps = [ 6 24 ];
            end
            
        end
       
        function price = default_power_price( obj )
            % Get price of electricity
            switch obj.regime
                case 'rationing'
                    
                    switch obj.varies
                        case 'uniform'
                            price = 0.9;
                        case 'hetero'
                            price = [];     
                    end
                    
                case 'private_cost'
                    
                    switch obj.varies
                        case 'uniform'
                            price = obj.power_cost;
                        case 'hetero'
                            price = [];     
                    end
                    
                case 'pigouvian'
                    
                    switch obj.varies
                        case 'uniform'
                            price = obj.power_cost*1.5;
                        case 'hetero'
                            price = [];     
                    end    
                    
                case 'block_pricing'
                    
                    price = obj.power_cost*1.5;
                    
                otherwise
                    disp('Unknown regime');
            end
        end
        
        function water_cost = get.water_cost( obj )
            % Get price of water
            %   Based on preliminary runs of dynamic model, which yield
            %   estimates of the opportunity cost of water around Rs 0.003
            %   per liter.
%             water_cost = 0.00171; % Pigouvian price 9.15
            water_cost = 0.00335;  % Pigiouvian price 12.21
%             water_cost = 0.00457; % Pigouvian price 14.59
%             water_cost = 0.003;
%             water_cost = 0.0078;
        end
         
        function ration = default_ration( obj )
            % Get ration
            switch obj.regime
                case 'rationing'
                    
                    switch obj.varies
                        case 'uniform'
                            ration = 6;
                        case 'hetero'
                            ration = [];     
                    end
                    
                case {'private_cost','pigouvian','block_pricing'}
                                        
                    switch obj.varies
                        case 'uniform'
                            ration = 24;
                        case 'hetero'
                            ration = 24;     
                    end
                    
                otherwise
                    disp('Unknown regime');
            end
        end
        
    end
     
end