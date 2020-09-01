function plotDepthTime(time,D_t, optfig, sdo)
%% Plot the time path of groundwater depth
% 
% INPUTS:
%   time: vector of time
%   D_t: Vector of groundwater depth (feet)
%   optfig: Struct of figure paramaters
%   sdo: Name of the SDO
%  
% 
% OUTPUTS:
%   Figure of depth
%       
%
    if optfig.plotfig == 1
        [fontsize,fontname,dimension,lw,folder,color,style,marker,~,axfontsize,axlabelfontsize,legfontsize] = fn_optfig(optfig);
        
        f0 = figure('Units','inches','Position',dimension);
        
        %real_depth_size = size(real_depth,2)-1;
        
        plot(time,D_t, 'Color','red','LineStyle',style{1},'Marker',marker{1},'LineWidth',lw); hold on
        %plot(0:real_depth_size,real_depth, 'Color', color{4}, 'LineStyle',style{1},'Marker',marker{1},'LineWidth',lw);
    
        set(gca,'FontName',fontname,'FontSize',axfontsize, 'Ydir', 'reverse')
        
        xlabel('$t$','interpreter', 'latex', 'FontName', fontname, 'FontSize', axlabelfontsize);
        ylabel('$D_t$','interpreter', 'latex', 'FontName', fontname, 'FontSize', axlabelfontsize);
        
        %legend({'Bansur','Dug','Hindoli','Kotputli','Mundawar','Nainwa'},'Location','best','interpreter','latex','FontSize',legfontsize)

        
        %legend boxoff;
        xlim = size(time);
        xlim = xlim(2)-1;
        grid; %box off; axis([0 xlim 0 1500])  
        %axis tight;
        
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        fig_pos = fig.PaperPosition;
        fig.PaperSize = [fig_pos(3) fig_pos(4)];
    
        name = strcat('fig_depth_time_path_',convertStringsToChars(sdo));
        print(f0,'-dpdf','-painters','-noui','-r600',[folder, name, '.pdf'])
     
        if optfig.close == 1; close(who('f')); end
        
    end
end