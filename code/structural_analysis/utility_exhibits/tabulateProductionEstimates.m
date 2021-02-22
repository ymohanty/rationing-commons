function [ ] = tabulateProductionEstimates( estimates, file )
% Print table of coefficient estimates for production function
%   estimates : cell array with parameter estimates

%% Prepare data 
columns = length(estimates);
rows    = length(estimates{1}.alpha);

theta = zeros(rows,columns);
se    = zeros(rows,columns);
p     = zeros(rows,columns);

inputs = {'water','land','labor','capital'};
colHeads = cell(columns,1);
endog    = cell(columns,1);

% Indicators for controls
topos = cell(columns,1);
soil  = cell(columns,1);
sdofe = cell(columns,1);

% Summary stats
mean_dep_var = cell(columns,1); % Mean dep. var
farmers      = cell(columns,1); % # Farmers
farmer_crops = cell(columns,1); % Obs.

for c = 1:columns
    
    if strcmp(estimates{c}.estimationMethod,'ols')
        coefNames    = estimates{c}.ols.xnames;
        coefficients = estimates{c}.ols.coef;   
        stdErrors    = estimates{c}.ols.stderr;
        pValues      = estimates{c}.ols.pValue;
        colHeads{c}  = 'OLS';
        
        farmer_crops{c} = estimates{c}.ols.N;
        endog{c} = ' ';
        
    elseif strcmp(estimates{c}.estimationMethod,'iv')
        coefNames    = estimates{c}.iv.xnames;
        coefficients = estimates{c}.iv.coef;  
        stdErrors    = estimates{c}.iv.stderr;
        pValues      = estimates{c}.iv.pValue;
        colHeads{c}  = '2SLS';
        
        farmer_crops{c} = estimates{c}.iv.N;
        if estimates{c}.waterEndogOnly
            endog{c} = 'Water';
        else
            endog{c} = 'All';
        end
    end
    
    % Add dagger to endogenous variable decription
    % to signify calibration.
%     if estimates{c}.calibrateAlpha
%         endog{c} = sprintf('$\\text{%s}^{\\dagger}$',endog{c});
%     end
    
    % Update indicators for controls with data
    if any(ismember(coefNames,{'elevation'}))
        topos{c} =  '\emph{Yes}';
    else
        topos{c} = '';
    end
    
    if any(ismember(coefNames,{'x_Isdsdo_2'}))
        sdofe{c} =  '\emph{Yes}';
    else
        sdofe{c} = '';
    end
    
    if any(ismember(coefNames,{'prop_acidic'}))
        soil{c} =  '\emph{Yes}';
    else
        soil{c} = '';
    end
    
    % Update summary statistics
    mean_dep_var{c} = mean(estimates{c}.y);
    farmers{c} = length(unique(table2array(estimates{c}.data.clean(:,'farmer_id'))));
    
    alphaIndex = [ find(ismember(coefNames,inputs)) ];
    alphaNames = coefNames(alphaIndex);
            
    theta(:,c) = coefficients(alphaIndex);
    se(:,c)    = stdErrors(alphaIndex); 
    p(:,c)     = pValues(alphaIndex);
    
    if isfield(estimates{c}.iv,'stderr_rts')
        pe_rts = sum(theta(:,c));
        fprintf('The point estimate for the returns to scale for production inputs is %1.2f with standard error of %2.2f\n', ...
            pe_rts,estimates{c}.iv.stderr_rts);
    end
    
%     if c == columns
%        theta(:,c) = estimates{c}.alpha;
%        se(end,c)  = estimates{c}.bootstrapWaterSE;
%        p(end,c) = 2*(1-tcdf(abs(estimates{c}.alpha(end)/se(end,c)),estimates{c}.iv.resdf));
%     end
end


%% Format and print table
theta = num2cell(theta);
se    = num2cell(se);
p = num2cell(p);
for i = 1:numel(theta)
    if p{i} < 0.01 
        theta{i} = sprintf('%3.2f%s',theta{i},'\sym{***}');
    elseif p{i} < 0.05 && p{i} >= 0.01
        theta{i} = sprintf('%3.2f%s',theta{i},'\sym{**}');
    elseif p{i} < 0.1 && p{i} >= 0.05
        theta{i} = sprintf('%3.2f%s',theta{i},'\sym{*}');
    else
        theta{i} = sprintf('%3.2f%s',theta{i},'');
    end
    
    if isnan(se{i})
        theta{i} = '';
        se{i}    = '';
    end
end

      
% Adjust ordering of data and standard errors (and format names for table).
roworder = [ 4 1 2 3 ];
coefNames = regexprep(coefNames(roworder),'(^|\.)\s*.','${upper($0)}');
coefNames = regexprep(coefNames, '(.*)','log($0)');
theta    = theta(roworder,:);
se       = se(roworder,:);
        
% Adjust format with latex separators
format = ['%15s',repmat('\t%3.2f',1,columns)];
format = regexprep(format,'\\t','&');

coefFormat = ['%15s',repmat('\t%s',1,columns)];
coefFormat = regexprep(coefFormat,'\\t','&');

summaryFormat = ['%15s',repmat('\t%i',1,columns)];
summaryFormat = regexprep(summaryFormat,'\\t','&');

seformat = ['%15s',repmat('\t(%4.3f)',1,columns)];
seformat = regexprep(seformat,'\\t','&');

seformat2 = ['%15s','\t(%4.3f)\t%.4f'];
seformat2 = regexprep(seformat2,'\\t','&');

% Title of table
title = 'Production Function Estimates';
label = '\label{tab:prodFunc}';

%% Print table to file
fid = fopen( file, 'w' );

% Front matter
fprintf(fid,'\\begin{table}[!ht]\n\t\\centering\n\t');
fprintf(fid,'\t\\caption{%s} %s\n',title,label);
fprintf(fid,'\t\\def\\sym#1{\\ifmmode^{#1}\\else\\(^{#1}\\)\\fi}\n');
fprintf(fid,'\t\\begin{tabular}{%s}\n',['l',repmat('r',1,columns)]);

% Toprule
fprintf(fid,'\t\t\\toprule\n');

% Dependent variable header
fprintf(fid, ['\\multicolumn{1}{l}{\\emph{Dependent variable}} &\\multicolumn{%i}{c}{log(Value of output)} \\\\\n' ...
              '\\cmidrule(lr){2-%i}\n'], c, c+1);

% Column headings
for c = 1:columns+1
    if c > 1
        fprintf(fid,'\\multicolumn{1}{c}{%s}',colHeads{c-1});
    end
    if c <= columns
        fprintf(fid,'&');
    else
        fprintf(fid,'\\\\\n');
    end
end

% Midrule
for c = 2:columns+1
    fprintf(fid, '\\cmidrule(lr){%i-%i}',c,c);
    if c == columns+1
        fprintf(fid,'\n');
    end
end

% Endogenous variables
for c = 1:columns+1
    if c == 1
        fprintf(fid,'\\multicolumn{1}{l}{\\emph{Endogenous inputs:}}');
    else
        fprintf(fid,'\\multicolumn{1}{c}{%s}',endog{c-1});
    end
    if c <= columns
        fprintf(fid,'&');
    else
        fprintf(fid,'\\\\\n');
    end
end

% Column numbers
for c = 1:columns+1
    if c > 1
        fprintf(fid,'\\multicolumn{1}{c}{(%1.0f)}',c-1);
    end
    if c <= columns
        fprintf(fid,'&');
    else
        fprintf(fid,'\\\\\n');
    end
end
fprintf(fid,'\t\t\\midrule\n');

% Data rows with row headings
for r = 1:rows
    fprintf(fid,['\t\t',coefFormat,'\\\\\n'],coefNames{r},theta{r,:});
    if r <= rows
        fprintf(fid,['\t\t',seformat,'\\\\\n'],' ',se{r,:});        
    else
        fprintf(fid,[seformat2,'\\\\\n'],' ',se{r,:});
    end
    fprintf(fid,['\t\t \\addlinespace \n']);
end


% Indicators for control variables
fprintf(fid,['\t\t \\addlinespace \n']);
fprintf(fid,['\t\t', coefFormat,'\\\\\n'],'Toposequence',topos{:});
fprintf(fid,['\t\t', coefFormat,'\\\\\n'],'Soil quality',soil{:});
fprintf(fid,['\t\t', coefFormat,'\\\\\n'],'Subdivisional effects',sdofe{:});

% Summary statistics
fprintf(fid,['\t\t \\addlinespace \n']);
fprintf(fid,['\t\t \\addlinespace \n']);
fprintf(fid,['\t\t', format,'\\\\\n'],'Mean dep. var',mean_dep_var{:});
fprintf(fid,['\t\t', summaryFormat,'\\\\\n'],'Farmers',farmers{:});
fprintf(fid,['\t\t', summaryFormat,'\\\\\n'],'Farmer-crops',farmer_crops{:});

% End matter
fprintf(fid,'\t\t\\bottomrule\n');
fprintf(fid,['\t\\multicolumn{%1.0f}{p{%2.2f\\hsize}}{\\footnotesize ' ...
    'The table reports estimates of the production function. ' ...
    'The dependent variable is the log of the total value of ' ...
    'agricultural output. The independent variables are the logs of ' ...
    'productive inputs, water, land, labor and capital, as well as ' ...
    'exogenous control variables. All specifications include as ' ...
    'controls subdivision fixed effects, as described in the notes ' ...
    'of Table \\ref{tab:ivProfitsDepth}, toposequence variables for ' ...
    'elevation and slope, and soil quality measured at the village ' ...
    'level (acidity/alkalinity of the soil along with variables ' ...
    'measuring the level of eight minerals). The columns vary in the ' ...
    'method of estimation and what variables are treated as ' ...
    'endogenous. Column 1 shows OLS estimates. Column 2 shows ' ...
    'instrumental variables estimates treating only water as endogenous ' ...
    'and using as instruments only geological factors. Column 3 shows ' ...
    'instrumental variables estimates treating all four inputs as ' ...
    'endogenous. The first stage results for the column 3 specification ' ...
    'are reported in Appendix~\\ref{sec:appendixRobustness}, ' ...
    'Table~\\ref{tab:firstStageProdFunc}. Column 4 takes the column 3 ' ...
    'estimates and calibrates the elasticity of output with respect to ' ...
    'water to match the marginal benefit of relaxing the ration by one ' ...
    'hour, as reported in Table~\\ref{tab:optimalRation}, column 1, ' ...
    'panel A. Columns 1 to 3 report analytic standard errors clustered ' ...
    'at the level of the feeder, the primary sampling unit. Column 4 ' ...
    'reports cluster-bootstrapped standard errors, also clustered at ' ...
    'the feeder level, to account for uncertainty in the estimated ' ...
    'marginal benefit of relaxing the ration. Statistical significance ' ...
    'is indicated by \\sym{*} $ p < 0.10$, \\sym{**} $ p < 0.05$, ' ...
    '\\sym{***} $ p < 0.01$.}\\\\\n'],...
        columns+1, 0.55 + 0.2*(columns > 4));
fprintf(fid,'\t\\end{tabular}\n');
fprintf(fid,'\\end{table}\n');

fclose(fid);
fprintf(1,'Printed: %s\n',file);

end               
                
