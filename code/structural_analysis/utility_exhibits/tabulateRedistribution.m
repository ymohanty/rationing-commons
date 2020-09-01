function [ ] = tabulateRedistribution( counters, level, file_stub )
% Table of counterfactual surplus and inputs
%
%   counters : cell array of counterfactuals to tabulate
%              First counterfactual is rationing regime
%              Later counterfactuals are Pigouvian regimes with transfers:
%                 * None, flat, pump, land
%   file_stub : file to which to print the table


%% Prepare data 

% Extract counterfactuals for status quo and pigouvian regimes
C = length(counters);
outcomes = cell(size(counters));
for i = 1:C
    colHeads{i} = [ counters{i}.transferOn ];
    switch level
        case 'farmer'
            outcomes{i} = counters{i}.farmer;
        case 'fmplot'
            outcomes{i} = counters{i}.fmplot;
    end
end

% Put in transfers and net profit for rationing regime
N = size(outcomes{1},1);
outcomes{1}(:,'transfer')   = array2table(zeros(N,1));
outcomes{1}(:,'profit_net') = outcomes{1}(:,'profit');

% Variable names and statistics to calculate
rowHeads = {'Mean profit (INR 000s)', ...
            '~~~~$+$ Mean transfer (INR 000s)', ...
            'Mean net profit (INR 000s)', ...
            'Std dev net profit (INR 000s)',...
            'Share who gain',...
            '~~~~Mean ex ante profit',...
            '~~~~Mean change in net profit',...
            '~~~~Mean land (Ha)',...
            '~~~~Mean depth (feet)',...
            '~~~~Mean productivity (percentile)',...
            'Share who lose',...
            '~~~~Mean ex ante profit',...
            '~~~~Mean change in net profit',...
            '~~~~Mean land (Ha)',...
            '~~~~Mean depth (feet)',...
            '~~~~Mean productivity (percentile)'};

% Calculate quantiles of productivity 
tau_omega  = [ 1:1:100 ];
qt_omega   = prctile(outcomes{1}.omega_Eit,tau_omega);
omega_ptile = repmat(outcomes{1}.omega_Eit,1,length(qt_omega)) > ...
              repmat(qt_omega,length(outcomes{1}.omega_Eit),1);
omega_ptile = sum(omega_ptile,2) + 1;
          
% Create table contents
R = length(rowHeads);
dataTable = array2table( zeros(R,C) );
for i = 1:C
    
    dataTable{1,i} = mean(outcomes{i}.profit);
    dataTable{2,i} = mean(outcomes{i}.transfer);
    dataTable{3,i} = mean(outcomes{i}.profit_net);
    dataTable{4,i} = std(outcomes{i}.profit_net);
    
    deltaProfit = outcomes{i}.profit_net - ...
                  outcomes{1}.profit_net;
    gain = deltaProfit >= 0;    
    
    if i > 1
        
        dataTable{5,i}  = mean( gain );
        dataTable{6,i}  = mean( outcomes{1}.profit(gain) );
        dataTable{7,i}  = mean( deltaProfit(gain) );
        dataTable{8,i}  = mean( outcomes{1}.Land(gain) );
        dataTable{9,i}  = mean( outcomes{1}.depth(gain) );
        dataTable{10,i} = mean( omega_ptile(gain) );
        
        dataTable{11,i} = mean( ~gain );
        dataTable{12,i} = mean( outcomes{1}.profit(~gain) );
        dataTable{13,i} = mean( deltaProfit(~gain) );
        dataTable{14,i} = mean( outcomes{1}.Land(~gain) );
        dataTable{15,i} = mean( outcomes{1}.depth(~gain) );
        dataTable{16,i} = mean( omega_ptile(~gain) );
           
    else
        dataTable{5,i}  = NaN;
        dataTable{6,i}  = NaN;
        dataTable{7,i}  = NaN;
        dataTable{8,i}  = NaN;
        dataTable{9,i}  = NaN;
        dataTable{10,i} = NaN;
        
        dataTable{11,i} = NaN;
        dataTable{12,i} = NaN;
        dataTable{13,i} = NaN;
        dataTable{14,i} = NaN;
        dataTable{15,i} = NaN;
        dataTable{16,i} = NaN;
    end
end

colHeads{1} = 'None';            
colHeads = [ {'Transfers:'} proper(colHeads) ];


%% Prepare table formatting

% Title of table
title = 'Distributional Effects of Pigouvian Reform';
label = '\label{tab:cfDistribution}';

% Calculate size of parameter table
columns  = C;
rows     = length(rowHeads);
      
% Adjust format with latex separators
format = ['%15s',repmat('\t%4.2f',1,columns)];
format = regexprep(format,'\\t','&');

% seformat = ['%15s',repmat('\t(%.2f)',1,columns)];
% seformat = regexprep(seformat,'\\t','&');


%% Print table to file
file = [ file_stub '_' level '.tex' ];
if ~isempty( file )
    fid = fopen( file, 'w' );
else
    fid = 1;
end
    
% Front matter
fprintf(fid,'\\begin{table}[!ht]\n\t\\centering\n\t');
fprintf(fid,'\t\\caption{%s%s}\n',title,label);
fprintf(fid,'\\begin{tabular}{%s}\n',['l',repmat('r',1,columns)]);

% Title of table
fprintf(fid,'\t\t\\toprule\n');

% Meta headings
fprintf(fid,['& Rationing & \\multicolumn{4}{c}{Pigouvian} \\\\\n']);
fprintf(fid,['\\cmidrule(lr){2-2} \\cmidrule(lr){3-6}']);

% Column headings
cformat = regexp(regexprep(format,'\.\df','s'),'&','split')';
for c = 1:columns+1
    fprintf(fid,cformat{c},sprintf('\\multicolumn{1}{c}{%s}',colHeads{c}));
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
        fprintf(fid,['\\multicolumn{6}{c}{\\emph{A. Inequality under different transfer schemes}}\\\\\n']);
        fprintf(fid,['\t\t \\addlinespace \n']);
        
    elseif r == 3
        fprintf(fid,['\\cmidrule(lr){1-1}']);
        
    elseif r == 4
        fprintf(fid,['\t\t \\addlinespace \n']);
        
    elseif r == 5
        fprintf(fid,['\t\t \\addlinespace \n']);
        fprintf(fid,['\\multicolumn{6}{c}{\\emph{B. Change from rationing regime due to reform}}\\\\\n']);
        fprintf(fid,['\t\t \\addlinespace \n']);
    end
    
    if r == 6
        fprintf(fid,['\t\t \\multicolumn{6}{l}{\\emph{Conditional on gain in profit:}}\\\\\n']);
    end
        
    if r == 11
        fprintf(fid,['\t\t \\addlinespace \n']);
    end
    
    if r == 12
        fprintf(fid,['\t\t \\multicolumn{6}{l}{\\emph{Conditional on loss in profit:}}\\\\\n']);
    end
    
    rowString = sprintf(['\t\t',format,'\\\\\n'],rowHeads{r},dataTable{r,:});
    rowString = strrep(rowString,'NaN',' ');
    fprintf(fid,'%s',rowString);
end

%  Footer rows with statistics of interest
% foot3format = ['%15s\t\\multicolumn{2}{c}{%3.0f}'];
% foot3format = regexprep(foot3format,'\\t','&');
% fprintf(fid,['\t\t',foot3format,'\\\\\n'],'N',obj.N);

% End matter
fprintf(fid,'\t\t\\bottomrule\n');
fprintf(fid,['\\multicolumn{%1.0f}{p{%3.2f\\hsize}}{\\footnotesize ' ...
        'The table shows the distributional impacts of Pigouvian reform ' ...
        'on farmer profits. The columns show results for different ' ...
        'policy regimes: column 1 is the status quo rationing regime ', ...
        'and columns 2 through 4 show regimes with Pigouvian pricing. ' ...
        'The Pigouvian regimes differ in the transfers made to farmers ' ...
        'and how those transfers are conditioned. In column 2 onwards, ' ...
        'the transfer policies are: no transfers, flat (uniform) transfers, ' ...
        'transfers pro rata based on pump capacity, and transfers pro rata ' ...
        'based on land size. The rows in Panel A show summary statistics ' ...
        'on the level of profits under different regimes. The rows in Panel ' ...
        'B show summary statistics on the changes in profits between the ' ...
        'status quo rationing regime (column 1) and the respective ' ...
        'Pigouvian regimes (columns 2 through 5)'],...
        columns+1,0.80);
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


                
