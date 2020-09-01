function diff = marginalBenefitMinusCost(benefits,model,counter,beta)
% The difference between marginal benefit and social cost of relaxing as a
% function of the discount rate
    
    % Marginal benefit
    marginal_benefit = benefits.d_Pi_d_D*benefits.D_bar_over_H_bar*1e3;
    
    % Estimate opportunity cost
    model.beta = beta;
    model.noisyEstimates = false;
    model = model.oppCostWater;
    lambda_w = model.lambda_w_ltr;
    
    % Marginal cost
    [ ~, ~, dEdH, ~, dSdH, ~, ~ ] = counter.marginalCost( lambda_w );
    
    diff_cE_pE = (counter.policy.power_cost - counter.policy.power_price);
    marginal_private_cost = dEdH * diff_cE_pE;
    marginal_social_cost  = marginal_private_cost + dSdH*1e3;
    
    
    % Difference
    diff = marginal_benefit - marginal_social_cost;
end