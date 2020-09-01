function tabulateOppCostParameters(estimates,file,ext)
%%   Print table of opportunity cost estimtaes 
%
%   INPUTS:
%       estimates: cell matrix of waterDynamics objects
%       file: filename with path of tex output
%       ext: the type of opportunity cost to be used (INR/KwH,INR/Ltr)

    %% Prepare data
    
    % Get dimensions
    data_rows = size(estimates,1);
    data_columns = size(estimates,2);
    
    % Add relevant data to matrices
    point_estimates = zeros(data_rows,data_columns);
    standard_errors = zeros(data_rows,data_columns);
    alpha_values = zeros(1,data_columns);
    
    for i = 1:data_rows
        for j = 1:data_columns
            if strcmp(ext,'kwh')
                point_estimates(i,j) = estimates{i,j}.lambda_w_kwh;
                standard_errors(i,j) = estimates{i,j}.lambda_w_kwh_se;
            else
                point_estimates(i,j) = estimates{i,j}.lambda_w_ltr*1000;
                standard_errors(i,j) = estimates{i,j}.lambda_w_ltr_se*1000;
            end
            alpha_values(j) = estimates{1,j}.alpha_w;
        end
    end
    
    % Numerical formats
    if strcmp(ext,'kwh')
        coefFormat = ['\\multirow{2}{1 cm}{%1.2f}',repmat('\t%.2f',1,data_columns)];
        seFormat = repmat('\t(%1.2f)',1,data_columns);
    else
        coefFormat = ['\\multirow{2}{1 cm}{%1.2f}',repmat('\t%.2f',1,data_columns)];
        seFormat = repmat('\t(%1.2f)',1,data_columns);
    end
    
    alphaFormat = ['%s',repmat('\t%1.2f',1,data_columns)];
    
    % Insert align operator '&' into formats
    coefFormat = regexprep(coefFormat,'\\t','&');
    seFormat = regexprep(seFormat, '\\t','&');
    alphaFormat = regexprep(alphaFormat,'\\t','&');
    
    % Open file
    filename = [file, '_', ext,'.tex'];
    fid = fopen(filename, 'w');
    
    %% Frontmatter
    title = 'Estimates of $\lambda_W$ for alternate parameter values';
    label = ['\label{tab:oppCostParam',ext,'}'];
    
    fprintf(fid,'\\begin{table}[!ht]\n\t\\centering\n\t');
    fprintf(fid,'\t\\caption{%s %s} \n',title,label);
    fprintf(fid,'\t\\begin{tabular}');
    
    % Open tabular environment
    for col = 1:data_columns
        if col == 1
            fprintf(fid,'{p{1 cm}');
        end
        fprintf(fid,'p{2 cm}');
        if col == data_columns
            fprintf(fid,'}\n');
        end   
    end
    
    % Toprule
    fprintf(fid,'\t\t\\toprule\n');
    
    % Alpha values header
    fprintf(fid,['\t\t',alphaFormat,'\\\\\n'],'$\beta\backslash\alpha_W$',alpha_values(:));
    
    % Midrule
    fprintf(fid,'\t\t\\midrule\n\t\t\\addlinespace\n');
    
    %% Body
    for row = 1:data_rows
        
        % Print Panel label
%         fprintf(fid,'\t\t\\multicolumn{%i}{c}{\\textit{Panel %s: $\\beta$ = %1.2f}}\\\\\n',[data_columns+1],char(row+'A'-1),estimates{row,1}.beta);
%         fprintf(fid,'\t\t\\addlinespace\n');
        
        % Print point estimates 
        fprintf(fid,['\t\t',coefFormat,'\\\\\n'],estimates{row,1}.beta,point_estimates(row,:));
        
        % Print standard errors
        fprintf(fid,['\t\t',seFormat,'\\\\\n'],standard_errors(row,:));
        
        % Table notes
        if row == data_rows
            fprintf(fid,'\t\t\\bottomrule\n');
            fprintf(fid,['\t\t\\multicolumn{%i}{p{%1.2f\\hsize}}{\\footnotesize This ' ...
                'table reports the opportunity cost of water for different values ' ...
                'of the output elasticity of water $\\alpha_W $ and the discount ' ...
                'rate $\\beta $. The units of $\\lambda_W$ are INR per %s. ' ...
                'Bootstrapped standard errors in parentheses account for ' ...
                'estimation error in the groundwater law of motion.}\n']...
                    ,[data_columns+1],0.9,ext);
        else
            fprintf(fid,'\t\t\\addlinespace\n\t\t\\addlinespace\n');
        end
        
    end
    
    %% Endmatter
    fprintf(fid,'\t\\end{tabular}\n');
    fprintf(fid,'\\end{table}');
    
    %% Output
    fclose(fid);
    fprintf(1,'Printed: %s\n',filename);
   
end