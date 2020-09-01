function [] = plotRegimesRations(optfig)
%% Plot clustered bar chart describing the ration and price used in different regimes
  
    %% Status quo + Pigouvian animation
    
    % Status quo
    rations = [6 0; 0 0;];
    prices = [0.9 0; 0 0;];
    
    axislabs = {'Hours per day',0:6:24,[0 24],'Price (INR/KwH)',0:2:12, [0 12]};
    
    stackData= permute(cat(3,rations,prices),[1 3 2]);
    groupLabels = {'Status Quo', ''};
    plot_bar_stacks(stackData,groupLabels,optfig,axislabs,'regime','fig_policy_animation_1')
    
    % Status quo + pigouvian
    rations = [6 0; 24 0;];
    price_above_mc = 11.7-6.2;
    prices = [0.9 0; 6.2 price_above_mc;];
    
    stackData= permute(cat(3,rations,prices),[1 3 2]);
    groupLabels = {'Status Quo', 'Pigouvian'};
    plot_bar_stacks(stackData,groupLabels,optfig,axislabs,'regime','fig_policy_animation_2')
    
    %% Counterfactual equity
    
    percent_gain = [0.15 0; 0.79 0; 0.66 0;];
    mean_loss_if_loss = [16.05 0; 12.02 0; 11.2 0;];
    
    axislabs = {'Prop. of farmers who gain', 0:0.25:1, [0 1],'Mean loss if loss', 0:5:20, [0 20]};
    
    stackData = permute(cat(3,percent_gain,mean_loss_if_loss),[1 3 2]);
    groupLabels = {'None','Flat','Land'};
    
    plot_bar_stacks(stackData,groupLabels,optfig,axislabs,'equity','fig_distributional_effects');
    
    %% Welfare in Pigouvian regime vs Indian government transfer
    
    % Figure environment
    f0 = figure('Renderer', 'painters', 'Position', [10 10 1100 400]);
    
    % Data
    efficiency_gain = [6 24];
    
    % Horizontal bar
    b = barh(efficiency_gain,'FaceColor',[0.098 0.098 0.439],'EdgeColor',[0 0 0]);
    set(gca,'xtick',[]);
    
    % Bar labels
    ytl = {{'Flagship'; 'Government of India';'transfer to farmers'},{'Pigouvian'; 'budget-neutral' ; 'transfer'}};
    set(gca,'Xcolor','none');
    set(gca,'YTickLabelMode','manual');
    my_yticklabels(gca,[1 2], ytl,'FontSize',24);  
    set(gca,'FontName',optfig.fontname,'fontsize',18)
    
    box off;
    
    % Bar value labels
    vlabs = ["INR 6,000" "INR 24,000"];
    text([efficiency_gain+0.3],b.XData,vlabs,'VerticalAlignment','middle','FontSize',24);
    
    % Trim figure
    ylim([0 3]);
    
    % Write to disk
    fig = gcf;
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    print(f0,'-dpdf','-painters','-noui','-r600', [optfig.folder, 'fig_efficiency_gain', '.pdf']);
    


end