function [] = plotOptimalRation(benefits,counter,opp_cost, filename)
    
    %% Unpack structs
    d_pi_d_D = benefits.d_Pi_d_D * 1000 / 187;                   % reduced form profit coefficient (INR/hr)
    d_pi_d_D_SE = benefits.d_Pi_d_D_SE * 1000 / 187;             % reduced form profit std. error in levels (INR/hr)
    d_bar_over_h_bar = benefits.D_bar_over_H_bar * 187;          % mean depth by mean power use in levels 
        
    
    %% Prepare data
    
    % Marginal benefit
    marginal_benefit = d_pi_d_D * d_bar_over_h_bar;
    benefit_err = 1.96 * d_pi_d_D_SE * d_bar_over_h_bar;
    
    % Marginal private cost     
    [ ~, ~, dEdH, dWdH, dSdH_low,dEdHse, dWdHse, Cov_dWdH_dEdH ] = counter.marginalCost( opp_cost.low.lambda_w_ltr );
    [ ~, ~, ~, ~, dSdH_med, ~, ~ ] = counter.marginalCost( opp_cost.med.lambda_w_ltr );
    [ ~, ~, ~, ~, dSdH_high, ~, ~ ] = counter.marginalCost( opp_cost.high.lambda_w_ltr );
    
    % Transform from '000 ltrs to ltrs
    dWdH = dWdH * 1000;
    Cov_dWdH_dEdH = Cov_dWdH_dEdH * 1000;
        
    diff_cE_pE = (counter.policy.power_cost - counter.policy.power_price);
    marginal_private_cost = dEdH * diff_cE_pE;
    private_cost_err = 1.96 * dEdHse * diff_cE_pE;
    
    % Social cost of water
    marginal_social_cost_low = 1000 * dSdH_low;
    marginal_social_cost_med = 1000 * dSdH_med;
    marginal_social_cost_high =  1000 * dSdH_high;
    
    
    social_cost_err_low = 1.96 * stdErrMarginalCost(diff_cE_pE, Cov_dWdH_dEdH, dWdH, dWdHse, dEdHse, ...
        opp_cost.low.lambda_w_ltr, opp_cost.low.lambda_w_ltr_se );
    social_cost_err_med = 1.96 * stdErrMarginalCost(diff_cE_pE, Cov_dWdH_dEdH, dWdH, dWdHse, dEdHse, ...
        opp_cost.med.lambda_w_ltr, opp_cost.med.lambda_w_ltr_se );
    social_cost_err_high = 1.96 * stdErrMarginalCost(diff_cE_pE, Cov_dWdH_dEdH, dWdH, dWdHse, dEdHse, ...
        opp_cost.high.lambda_w_ltr, opp_cost.high.lambda_w_ltr_se );
    
    
    % Bar vectors
    data = [marginal_benefit marginal_private_cost marginal_private_cost marginal_private_cost marginal_private_cost; ...
         0 0 marginal_social_cost_low marginal_social_cost_med marginal_social_cost_high];
    err_data = [marginal_benefit marginal_private_cost marginal_private_cost + marginal_social_cost_low ...
         marginal_private_cost + marginal_social_cost_med marginal_private_cost + marginal_social_cost_high];
    err = [benefit_err private_cost_err social_cost_err_low social_cost_err_med social_cost_err_high];
    
    
    %% Plot
    
    % Generate bar graph with whiskers
    left_color = [0 0 0];
    right_color = [0 0 0];
    f0 = figure('Renderer', 'painters', 'Position', [10 10 1000 600],'defaultAxesColorOrder',[right_color; left_color]);
    set(f0,'defaultAxesTickLabelInterpreter','latex');  
    
    yyaxis left;
    b = bar([0.5 1 1.5 2 2.5],data','stacked','EdgeColor',[0 0 0],'FaceColor',[0.5 0.5 0.5],'BarWidth',0.6,'LineWidth',2);
    b(2).FaceColor = 'flat';
    b(2).CData = [1 1 1];
    xticks([0.5 1 1.5 2 2.5]);
    
    social_cost_low = sprintf('\\beta = %1.2f',opp_cost.low.beta);
    social_cost_med = sprintf('\\beta = %1.2f',opp_cost.med.beta);
    social_cost_high = sprintf('\\beta = %1.2f',opp_cost.high.beta);
    xtl = {{'Marginal'; 'benefit'},{'Private marginal'; 'cost'},{'Social cost'; social_cost_low},{'Social cost'; social_cost_med}, {'Social cost'; social_cost_high}};

    hold on

    er = errorbar([0.5 1 1.5 2 2.5],err_data,err,err,'LineWidth',2.5,'CapSize',10);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';  

    hold off
    
    % Formatting
    textProp = {'fontsize'    , 26, ...
            'FontName'    , 'Times New Roman'};
        
    set(gca, textProp{:}, ...
         'Box'         , 'off' ,...
         'LineWidth'   ,  2);
        
    % Axis 1: INR per ha-hour   
    ylabel("Costs and benefits ('000s INR/Ha-hour)",textProp{:});
    ylim([0,4000]);
    yticks(0:1000:4000);
    yticklabels({'0','1','2','3','4'});
    
    % Axis 2: % of Annual income
    ylim_right = ylim;
    ylim_right = round(ylim_right(2)*2.3*0.65*100/88200); % Proportion of annual income
    yyaxis right;
    ylabel('Percent of annual income (%)',textProp{:});
    ylim([0,ylim_right])
    yticks(0:1:ylim_right);
    
    xlim([0.25,2.75])
    set(gca,textProp{:})
    box off;
    
    % X-tick labels
    my_xticklabels(gca,[0.5 1 1.5 2 2.5],xtl,textProp{:});
    
    %Legend
    legend([b(1) b(2)],'Private benefit/cost',...
            'Social cost',...,
            'Location','southoutside',...
            'Orientation','vertical',...
            'FontName','Times New Roman',...
            'fontsize',24);
    legend boxoff;
    legend hide;
        
    % Crop whitespace 
    fig = gcf;
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    
    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4);
    ax.Position = [left bottom ax_width ax_height];
    
    % Write to disk
    fprintf(1,'Writing %s to file ...\n',filename);
    print(f0,'-dpdf','-painters','-noui','-r600', filename);
    
end