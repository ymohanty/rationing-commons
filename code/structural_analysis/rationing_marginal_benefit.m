%% ========================================================================
%                 Model-implied marginal benefit of ration increase
%%=========================================================================

%% Compare marginal benefit calculated from finite difference 
%    to true marginal benefit

% Finite difference

% 1.00 hour
rationIncrease = 1.00;
mb_fd = marginalBenefitOneHour( model, model.alpha(end), rationIncrease );
fprintf(1,'Marginal benefit (%3.2f hour difference): %4.2f INR per hour\n',...
        rationIncrease,mb_fd*1e3);

% 0.10 hour
rationIncrease = 0.10;
mb_fd = marginalBenefitOneHour( model, model.alpha(end), rationIncrease );
fprintf(1,'Marginal benefit (%3.2f hour difference): %4.2f INR per hour\n',...
        rationIncrease,mb_fd*1e3);

% True marginal benefit (only water endogenous)
counter        = waterCounter( model );
counter.endog  = {'water'};
counter.policy = waterPolicy('rationing');

mb_tr = counter.marginalBenefit;
fprintf(1,'Marginal benefit (at the margin): %4.2f INR per hour\n',...
    mb_tr*1e3);
    
% True marginal benefit (water, capital endogenous)
counter        = waterCounter( model );
counter.policy = waterPolicy('rationing');

mb_tr = counter.marginalBenefit;
fprintf(1,'Marginal benefit (at the margin): %4.2f INR per hour\n',...
    mb_tr*1e3);


%% Calculate marginal cost of an expansion

[ mc, mci ] = counter.marginalCost; 
fprintf(1,'Marginal cost (at the margin): %4.2f INR per hour\n',mc*1e3);

% ============================== END ======================================
