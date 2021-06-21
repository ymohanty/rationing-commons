%% ========================================================================
%                           Setup workspace
%%=========================================================================

% Directories for code and data
if exist('project_root','var') == 0
    if ismac
        project_root = sprintf('/Users/%s/projects/replication_rationing_commons',getenv('USER'));
    elseif ispc
        project_root = sprintf('C:/Users/%s/Dropbox/replication_rationing_commons',getenv('USERNAME'));
    else
        error('Other Unix platforms are currently unsupported!');
    end
end

code     = [project_root,'/code/structural_analysis/'];
data     = [project_root,'/data/work/'];
addpath(genpath(code));

% Directories for output
figures  = [project_root,'/exhibits/figures'];
tables   = [project_root,'/exhibits/tables'];
% paper    = [project_root,'/documents/paper/exhibits'];

% Figure data
optfig.fontsize        = 22;
optfig.fontname        = 'Times New Roman';
optfig.dimension       = [0 0 8 6];
optfig.lw              = 3.5;
optfig.folder          = figures;
optfig.color           = num2cell(parula(7),2);
% optfig.color         = num2cell(jet(7),2);
optfig.style           = {'-','--',':','-','--','-','.-'};
optfig.marker          = {'none','o','x','s','+'};
optfig.markersize      = 12;
optfig.labfontsize     = 20;
optfig.axfontsize      = 20;
optfig.axlabelfontsize = 25;
optfig.legfontsize     = 22;
optfig.axisweight      = 2;

optfig.textProp = {'fontsize'    , optfig.labfontsize, ...
            'FontName'    , optfig.fontname};
optfig.labProp  = {'fontsize'    , optfig.axfontsize, ...
            'FontName'    , optfig.fontname};
optfig.legProp  = {'fontsize'    , optfig.legfontsize, ...
            'FontName'    , optfig.fontname};


%% ========================================================================
%                                 END
%%=========================================================================
