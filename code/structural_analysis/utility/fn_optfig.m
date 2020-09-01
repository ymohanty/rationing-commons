function [fontsize,fontname,dimension,lw,folder,color,style,marker,markersize,axfontsize,axlabelfontsize,legfontsize] = fn_optfig(optfig)
% This function unpacks the structure optfig

fontsize        = optfig.fontsize;
fontname        = optfig.fontname;
dimension       = optfig.dimension;
lw              = optfig.lw;
folder          = optfig.folder;
color           = optfig.color;
style           = optfig.style;
marker          = optfig.marker;
markersize      = optfig.markersize;
axfontsize      = optfig.axfontsize;
axlabelfontsize = optfig.axlabelfontsize;
legfontsize     = optfig.legfontsize;

end
