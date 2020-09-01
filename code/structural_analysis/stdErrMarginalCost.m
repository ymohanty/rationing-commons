function se = stdErrMarginalCost(c, Cov_dWdH_dEdH, dWdH, dWdHse, dEdHse,  lambda_w, lambda_w_se)
   
    % Componets of variance
    var_PC = c^2 * dEdHse^2;
    covariance_term = c * Cov_dWdH_dEdH * lambda_w;
    var_dWdH_lambda = dWdH^2 * lambda_w_se^2 + lambda_w^2 * dWdHse^2 + lambda_w_se^2 * dWdHse^2;
    
    % Standard error of total marginal cost
    se = sqrt(var_PC + var_dWdH_lambda + covariance_term);
    
end