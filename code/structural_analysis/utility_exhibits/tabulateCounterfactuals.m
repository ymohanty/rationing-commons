function [ ] = tabulateCounterfactuals( counters, file )
% Table of counterfactual surplus and inputs
%
%   counters : cell array of counterfactuals to tabulate
%   file : file to which to print the table


%% Switch for whether table is fancy version for paper or not
paperVersion = strcmp(file,'tab_counterfactual_outcomes.tex');


%% Prepare data 

C = length(counters);
R = length(counters{1}.outcomes.Properties.VariableNames) - 1;
colHeads = {};
for i = 1:C
    if i == 1
        table = counters{i}.outcomes(:,1:R);
    else
        table = [ table; counters{i}.outcomes(:,1:R) ];
    end
    colHeads{i} = strrep(counters{i}.policy.regime,'_',' ');
end

% Calculate contribution of input usage to output and residual TFP
Endog = proper(counters{1}.endog);
M     = containers.Map( counters{1}.model.input, counters{1}.model.alpha );
alpha = cell2mat(values(M,counters{1}.endog));

table.YGainTotal  = zeros(C,1);
table.YGainInputs = zeros(C,1);
table.YGainResid  = zeros(C,1);
for i = 1:C
    
    % Total gain in output (pp)
    table{i,'YGainTotal'}  = 100*(table.Output(i)/table.Output(1)-1);
    
    % Gain in output due to proportional increase in inputs (pp)
    J = table{i,Endog} ./ table{1,Endog};
    YfacInputOnly = prod(bsxfun(@power, J, alpha));
    table{i,'YGainInputs'} = 100*(YfacInputOnly - 1);
    
    % Residual gain in output (pp)
    table{i,'YGainResid'} = table{i,'YGainTotal'} - table{i,'YGainInputs'};
end

% Transpose data array to create data for table
dataArray = table2array(table);
dataTable = array2table(dataArray');
dataTable.Properties.RowNames = table.Properties.VariableNames;

order = {'profit','power_cost','water_cost',...
         'surplus','Land','Labor',...
         'Capital','Water','Power','Hours',...
         'Output','YGainTotal','YGainInputs','YGainResid','CovOmegaW'};
dataTable = dataTable(order,:);

% Variable names and statistics to calculate
rowHeads = {'Profit (INR 000s)', ...
            '~~~~$-$ Unpriced power cost (INR 000s)', ...
            '~~~~$-$ Water cost (INR 000s)', ...
            'Surplus (INR 000s)', ...
            'Land (Ha)',...
            'Labor (person-days)',...
            'Capital (INR 000s)',...
            'Water (liter 000s)',...
            '~~~~Power (kWh per season)',...
            '~~~~Hours of use (per day)',...
            'Output (INR 000s)',...
            '~~~~Gain in output from status quo (pp)',...
            '~~~~Gain in output due to input use (pp)',...
            '~~~~Gain in output due to productivity (pp)',...
            '$\Cov(\Omega_{Eit},W_{it}^{\alpha_W})$'};
        
colHeads = [ {''} proper(colHeads) ];

if paperVersion
    colHeads{2} = 'Status quo';
    colHeads{3} = 'Optimal';
    colHeads{4} = 'Private cost';
end

%% Prepare table formatting

% Title of table
title = 'Counterfactual Production and Social Surplus';
label = '\label{tab:cfOutcomes}';

% Calculate size of parameter table
columns  = C;
rows     = length(rowHeads);
      
% Adjust format with latex separators
format = ['%15s',repmat('\t%4.2f',1,columns)];
format = regexprep(format,'\\t','&');

formatShort = ['%15s\t',repmat('\t%4.1f',1,columns-1)];
formatShort = regexprep(formatShort,'\\t','&');

% seformat = ['%15s',repmat('\t(%.2f)',1,columns)];
% seformat = regexprep(seformat,'\\t','&');


%% Print table to file
if ~isempty( file )
    fid = fopen( file, 'w' );
else
    fid = 1;
end
    
% Front matter
fprintf(fid,'\\begin{table}[!ht]\n\t\\centering\n\t');
fprintf(fid,'\t\\caption{%s%s}\n',title,label);
fprintf(fid,'\\begin{tabular}{%s}\n',['l',repmat('r',1,columns)]);
fprintf(fid,'\t\t\\toprule\n');

% Meta headings
if paperVersion
    fprintf(fid,['& \\multicolumn{2}{c}{Rationing} & \\multicolumn{2}{c}{Pricing} \\\\\n']);
    fprintf(fid,['\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}']);
end

% Column headings
cformat = regexp(regexprep(format,'\.\df','s'),'&','split')';
for c = 1:columns+1
    fprintf(fid,cformat{c},colHeads{c});
    if c <= columns
        fprintf(fid,'&');
    else
        fprintf(fid,'\\\\\n');
    end
end

% Column numbers
for c = 1:columns+1
    if c > 1
        fprintf(fid,cformat{c},sprintf('\\multicolumn{1}{c}{(%1.0f)}',c-1));
    end
    if c <= columns
        fprintf(fid,'&');
    else
        fprintf(fid,'\\\\\n');
    end
end
fprintf(fid,'\t\t\\midrule\n');

filler = [' ',repmat('\t ',1,columns)];
filler = regexprep(filler,'\\t','&');

% Data rows with row headings
for r = 1:rows
    
    if r == 1
        fprintf(fid,['\t\t \\addlinespace \n']);
        fprintf(fid,['\\multicolumn{%1.0f}{c}{'...
            '\\emph{A. Profits and social surplus}}\\\\\n'],columns+1);
        fprintf(fid,['\t\t \\addlinespace \n']);
    
    elseif r == 4
        fprintf(fid,['\\cmidrule(lr){1-1}']);

    elseif r == 5
        fprintf(fid,['\t\t \\addlinespace \n']);
        fprintf(fid,['\\multicolumn{%1.0f}{c}{'...
            '\\emph{B. Input use}}\\\\\n'],columns+1);
        fprintf(fid,['\t\t \\addlinespace \n']);    
    
    elseif r == 11 
        fprintf(fid,['\t\t \\addlinespace \n']);
        fprintf(fid,['\\multicolumn{%1.0f}{c}{'...
            '\\emph{C. Output and productivity}}\\\\\n'],columns+1);
        fprintf(fid,['\t\t \\addlinespace \n']);
    end
    
    if ~ismember(r,[12 13 14])
        fprintf(fid,['\t\t',format,'\\\\\n'],rowHeads{r},dataTable{r,:});
    else
        fprintf(fid,['\t\t',formatShort,'\\\\\n'],rowHeads{r},dataTable{r,2:end});
    end 
        
%     fprintf(fid,['\t\t',seformat,'\\\\\n'],' ',table_data(r,2),...
%         table_data_winners(r,2));
end

%  Footer rows with statistics of interest
% foot3format = ['%15s\t\\multicolumn{2}{c}{%3.0f}'];
% foot3format = regexprep(foot3format,'\\t','&');
% fprintf(fid,['\t\t',foot3format,'\\\\\n'],'N',obj.N);

% End matter
fprintf(fid,'\t\t\\bottomrule\n');
fprintf(fid,['\\multicolumn{%1.0f}{p{%2.2f\\hsize}}{\\footnotesize ' ...
        'The table shows the outcomes of counterfactual policy regimes ' ...
        'with respect to farmer profit, external costs and social ' ...
        'surplus. The columns show different policy regimes: the ' ...
        'status quo rationing regime, with a ration of 6 hours and a ' ...
        'price of INR 0.90 per kWh, a private cost regime, where power ' ...
        'is priced at its private marginal cost of INR 6.2 per kWh, and a Pigouvian ' ...
        'regime where power is priced at marginal social cost. ' ...
        'The rows show ' ...
        'the outcome variables in each regime. All outcome variables, '...
        'except where noted, are mean values at the farmer-by-crop level, ' ...
        'where the average farmer plants 2.3 crops. Panel C shows output ' ...
        'and the change in output, in percentage points, relative to the ' ...
        'status quo value under rationing. Row 3 gives the change ' ...
        'in output that would have been achieved from a proportional ' ...
        'change in input use for all farmers, equal to the aggregate ' ...
        'proportional change in input use in each scenario relative ' ...
        'to column 1. Row 4 then gives the residual change in output ' ...
        'due to increases in aggregate productivity from the input ' ...
        'reallocation. Finally, row 5 ' ...
        'reports the covariance between $\\Omega_{Eit}$ and the ' ...
        'contribution of water input to production.'],...
        columns+1,0.85);
fprintf(fid,'} \\\\\n');
fprintf(fid,'\t\\end{tabular}\n');
fprintf(fid,'\\end{table}\n');

fclose(fid);
fprintf(1,'Printed: %s\n',file);

end               

function outcell = proper( cell )
    % Make string entries in a cell array proper case
    properString = @(s) regexprep(lower(s),'(\<[a-z])','${upper($1)}');
    outcell = cellfun(properString,cell,'UniformOutput', false); 
end

                
