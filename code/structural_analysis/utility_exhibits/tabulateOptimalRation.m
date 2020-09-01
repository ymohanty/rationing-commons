function tabulateOptimalRation( benefits, counter, waterDynamicsObj, filename )
% This table tabulates the marginal benefits and costs of relaxing the
% ration by one hr. Note that this does not generate the tabular hull
% which is stored statically.

    %% Prepare data
    
    % Opp cost of water
    lambda_w = waterDynamicsObj.lambda_w_ltr;
    
    % Marginal benefit
    dPidD    = benefits.d_Pi_d_D;
    DbarHbar = benefits.D_bar_over_H_bar;
    marginal_benefit = dPidD * DbarHbar;
    
    % Marginal cost from counterfactual object
    [ ~, ~, dEdH, dWdH, dSdH, ~, ~, ~ ] = counter.marginalCost( lambda_w );
    
    diff_cE_pE = (counter.policy.power_cost - counter.policy.power_price);
    marginal_private_cost = dEdH * diff_cE_pE;
    marginal_social_cost  = marginal_private_cost/1e3 + dSdH;
    
    %% Create table
    
    % Open file
    filename_panelA = [filename '_panelA.tex'];
    fidA = fopen(filename_panelA, 'w');
    
    filename_panelB = [filename '_panelB.tex'];
    fidB = fopen(filename_panelB, 'w');
    
    filename_panelC = [filename '_panelC.tex'];
    fidC = fopen(filename_panelC, 'w');
    
    % Panel A: Private cost
    fprintf(fidA,['$ -d \\Pi / d D $ &  %4.3f & %s &', ...
        '$dE / d\\overline{H} $ & %5.0f & %s \\\\\n'],...
        dPidD,'INR 000s per Ha-sd',dEdH,'kWh per Ha-hr');
    fprintf(fidA,['$\\times \\overline{D}/\\overline{H} $ & %1.2f & %s &', ...
        '$\\times (c_E - p_E)$ & %1.2f & %s \\\\\n'],...
            DbarHbar,'sd / hr',diff_cE_pE,'INR per kWh');
    fprintf(fidA,'\\cline{2-2} \\cline{5-5} \n');
    fprintf(fidA,['$d \\Pi / d \\overline{H}$ & %4.3f & %s ',...
        '& $dPC / d\\overline{H}$ & %4.3f & %s \\\\\n'],...
        marginal_benefit,'INR 000s per Ha-hr',...
        marginal_private_cost/1000,'INR 000s per Ha-hr');
  
    fprintf(fidA,'\\addlinespace \n \\addlinespace \n');  
    fclose(fidA);
    
    % Panel B: Opportunity cost of water
    fprintf(fidB,' &  &  & $dW / d\\overline{H} $ & %1.2f & %s \\\\\n',...
            dWdH/1e3,'liter 000s per Ha-hr');
    fprintf(fidB,' &  &  & $\\times\\lambda_w$ & %4.3f & %s \\\\\n',...
            lambda_w*1e3,'INR per liter 000s');
    fprintf(fidB,'\\cline{5-5} \n');
    fprintf(fidB,' &  &  & $dOC / d\\overline{H}$ & %4.3f & %s \\\\\n',...
            dSdH,'INR 000s per Ha-hr');
    
    fprintf(fidB,'\\addlinespace \n');
    fclose(fidB);
    
    % Panel C: Social cost of power
    fprintf(fidC,' &  &  & Private & %4.3f & %s \\\\\n',...
            marginal_private_cost/1000,'INR 000s per Ha-hr');
    fprintf(fidC,' &  &  & +Opportunity & %4.3f & %s \\\\\n',...
            dSdH,'INR 000s per Ha-hr');
    fprintf(fidC,'\\cline{5-5} \n');
    fprintf(fidC,' &  &  & Social & %4.3f & %s \\\\\n',...
            marginal_social_cost,'INR 000s per Ha-hr');
    
    fprintf(fidC,'\\addlinespace \n');
    fclose(fidC);
    
    % Output
    fprintf(1,'Printed: %s\n',filename_panelA);
    fprintf(1,'Printed: %s\n',filename_panelB);
    fprintf(1,'Printed: %s\n',filename_panelC);

end