function [ deltaProfit ] = marginalBenefitOneHour( model, alphaW, ...
                                                   rationIncrease )
% marginalBenefitOneHour Calculate the marginal benefit of a one-hour
%   relaxation in the ration under the rationing regime
%
% INPUT:
%   model  - waterModel object
%   alphaW - elasticity of output with respect to water 
%
% OUTPUT:
%   deltaProfit - Average change in profit from a 1-hour relaxation of the
%                 ration
if nargin < 3
    rationIncrease = 1;
end

% Set elasticity of output with respect to water
model.alpha(end) = alphaW; 

% Calculate counterfactual increase in profits from one-hour relaxation of
%   the rationing regime
counters       = cell(2,1);
counter        = waterCounter( model );
counter.policy = waterPolicy('rationing');

counter.policy.ration = 6;
counters{1} = counter.solveFarmersProblem;

counter.policy.ration = 6 + rationIncrease;
counters{2} = counter.solveFarmersProblem;

deltaProfit = ((counters{2}.outcomes.profit-counters{1}.outcomes.profit)...
               ./counters{1}.outcomes.Land)/rationIncrease;

end

