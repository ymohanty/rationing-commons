function plotPowerTime(time,H_t,optfig, sdo)
%% Plot the time path of electricity consumption choices of the farmer
% 
% INPUTS:
%   time: vector of time
%   H_t: Vector of electricity consumptions (kWh)
%   optfig: Struct of figure paramaters
%   sdo: Name of the SDO
% 
% OUTPUTS:
%       
%
    if optfig.plotfig == 1
        [fontsize,fontname,dimension,lw,folder,color,style,marker,~,axfontsize,axlabelfontsize,legfontsize] = fn_optfig(optfig);
        
        f0 = figure('Units','inches','Position',dimension);
        
        plot(time,H_t, 'Color','black','LineStyle',style{1},'Marker',marker{1},'LineWidth',lw); 
        
        set(gca,'FontName',fontname,'FontSize',axfontsize)
        
        xlabel('$t$','interpreter', 'latex', 'FontName', fontname, 'FontSize', axlabelfontsize);
        ylabel('$H_t^{\star}$','interpreter', 'latex', 'FontName', fontname, 'FontSize', axlabelfontsize);
        
        %legend({'Bansur','Dug','Hindoli','Kotputli','Mundawar','Nainwa'},'Location','best','interpreter','latex','FontSize',legfontsize)

        
        %legend boxoff;
        xlim = size(time);
        xlim = xlim(2)-1;
        grid; box off; axis([0 xlim 0 7]) ;
        
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        fig_pos = fig.PaperPosition;
        fig.PaperSize = [fig_pos(3) fig_pos(4)];
    
        name = strcat('fig_electricity_time_path_',convertStringsToChars(sdo))
        print(f0,'-dpdf','-painters','-noui','-r600',[folder, name,'.pdf'])
     
        if optfig.close == 1; close(who('f')); end
        
    end
end
