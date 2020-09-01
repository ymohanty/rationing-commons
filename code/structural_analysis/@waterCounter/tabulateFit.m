function [ ] = tabulateFit( obj, file )
% Table of counterfactual fit to production data
%
%   counter : counterfactual object
%   file    : file to which to print the table (1 for print to screen)
%   inLogs  : whether to print table in logarithms of inputs 

%% Prepare data 

% Data 
vars = {'Revenue','Land','Labor','Capital','Water'};
table = zeros(length(vars),4);

data           = table2array(obj.model.data.clean(:,vars));
table(:,1)     = mean(data,1)';
table(:,3)     = std(data,1)';

% Counterfactual simulations
vars = {'Output','Land','Labor','Capital','Water'};

nanFree        = ~any(isnan(table2array(obj.farmer(:,vars))),2);
cntr           = table2array(obj.farmer(nanFree,vars));
table(:,2)     = mean(cntr,1)';
table(:,4)     = std(cntr,1)';

% Put data in a format useful for tabulation
colHeads = {'Mean (Data)','Mean (Model)','SD (Data)','SD (Model)'};
dataTable = array2table(table);
dataTable.Properties.RowNames = vars;

% rowHeads = {'Profit (INR 000s)', ...
%             'Unpriced power cost (INR 000s)', ...
%             'Water cost (INR 000s)', ...
%             'Surplus (INR 000s)', ...
%             'Output (INR 000s)',...
%             'Land (Ha)',...
%             'Labor (person-days)',...
%             'Capital (INR 000s)',...
%             'Water (liter 000s)',...
%             'Power (kWh per season)',...
%             'Hours of use (per day)'};
rowHeads = {'Output (INR 000s)',...
            'Land (Ha)',...
            'Labor (person-days)',...
            'Capital (INR 000s)',...
            'Water (liter 000s)'};
        
colHeads = [ {''} colHeads ];


%% Prepare table formatting

% Title of table
regime = proper({obj.policy.regime});
title = sprintf('Counterfactual Fit of %s Regime',regime{1});

% Calculate size of parameter table
columns  = size(table,2);
rows     = length(rowHeads);
      
% Adjust format with latex separators
format = ['%15s',repmat('\t%4.2f',1,columns)];
format = regexprep(format,'\\t','&');

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
fprintf(fid,'\t\\caption{%s}\n',title);
fprintf(fid,'\\begin{tabular}{%s}\n',['l',repmat('r',1,columns)]);

% Title of table
fprintf(fid,'\t\t\\toprule\n');

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
        fprintf(fid,cformat{c},sprintf('(%1.0f)',c-1));
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
    
%     if r == 1
%         fprintf(fid,['\t\t \\addlinespace \n']);
%         fprintf(fid,['\\emph{Social surplus}',filler,'\\\\\n']);
%         
%     elseif r == 5
%         fprintf(fid,['\t\t \\addlinespace \n']);
%         fprintf(fid,['\\emph{Production}',filler,'\\\\\n']);
%         
%     elseif r == 10 
%         fprintf(fid,['\t\t \\addlinespace \n']);
%         fprintf(fid,['\\emph{Electricity use}',filler,'\\\\\n']);
%     end
    
    fprintf(fid,['\t\t',format,'\\\\\n'],rowHeads{r},dataTable{r,:});
    
%     fprintf(fid,['\t\t',seformat,'\\\\\n'],' ',table_data(r,2),...
%         table_data_winners(r,2));
end

%  Footer rows with statistics of interest
% foot3format = ['%15s\t\\multicolumn{2}{c}{%3.0f}'];
% foot3format = regexprep(foot3format,'\\t','&');
% fprintf(fid,['\t\t',foot3format,'\\\\\n'],'N',obj.N);

% End matter
fprintf(fid,'\t\t\\bottomrule\n');
fprintf(fid,['\\multicolumn{%1.0f}{p{%2.1f\\hsize}}{\\footnotesize ' ...
        'The table shows the fit of the model to a counterfactual ' ...
        'regime.'  ],...
        columns+1,0.8);
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

                
