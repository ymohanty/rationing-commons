function optfig = changeFontSize(optfig,increase_vec)
% change font sizes temporarily
%
% INPUTS
%       optfig: struct of figure parameters
%       increase vec: 1x4 vector of fontsize increases for each parameter

optfig.fontsize = optfig.fontsize + increase_vec(1);
optfig.labfontsize = optfig.labfontsize + increase_vec(2);
optfig.axfontsize = optfig.axfontsize + increase_vec(3);
optfig.legfontsize = optfig.legfontsize + increase_vec(4);

optfig.textProp = {'fontsize'    , optfig.labfontsize, ...
            'FontName'    , optfig.fontname};
optfig.labProp  = {'fontsize'    , optfig.axfontsize, ...
            'FontName'    , optfig.fontname};
optfig.legProp  = {'fontsize'    , optfig.legfontsize, ...
            'FontName'    , optfig.fontname};

end