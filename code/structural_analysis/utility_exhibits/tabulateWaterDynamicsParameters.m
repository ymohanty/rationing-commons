function tabulateWaterDynamicsParameters(model,filename)
% This function tabulates the values of thee primitives and exogenous 
% variables used in the structural model
%
%   INPUTS:
%       model: waterDynamics object containing all parameters
%       filename: name
%

    %% Prepare data
    alpha_w = model.alpha_w;
    omega = model.omega/1000;
    p_E = model.policy.power_price;
    c_E = model.policy.power_cost;
    ration = model.policy.ration;

    %% Output

    % Open file
    filename = [filename '.tex'];
    fid = fopen(filename, 'w');
    
    % Frontmatter
    title = 'Parameters used in the dynamic model';
    label = '\label{tab:dynamicParameters}';
    
    fprintf(fid,'\\begin{table}[!ht]\n\t\\centering\n');
    fprintf(fid,'\t\\caption{%s %s} \n',title,label);
    fprintf(fid,'\t\\begin{tabular}{p{2 cm}p{2 cm}p{6 cm}}\n');
    
    fprintf(fid,'\t\t\\toprule\n');
    
    % Headers
    fprintf(fid,'\t\t Parameter & Value & Source \\\\\n');
    fprintf(fid,'\t\t\\midrule\n');
    
    % Panel A: Primitives
    fprintf(fid,'\t\t\\multicolumn{3}{c}{\\emph{Primitives}} \\\\\n \t\t\\addlinespace \n');
    fprintf(fid,'\t\t $\\alpha_W$ & %.2f & %s \\\\\n',alpha_w,'Main model');
    fprintf(fid,'\t\t $\\Omega$ & %.2f & %s \\\\\n', omega, 'Main model');
    
    % Panel B: Exogenous variables
    fprintf(fid,'\t\t\\addlinespace\n \t\t\\multicolumn{3}{c}{\\emph{Exogenous variables}} \\\\\n \t\t\\addlinespace \n');
    fprintf(fid,'\t\t $p_E$ & INR %.1f  & %s \\\\\n',p_E,'Rajasthan policy');
    fprintf(fid,'\t\t $c_E$ & INR %.1f  & %s \\\\\n', c_E, 'Rajasthan policy');
    fprintf(fid,'\t\t $\\overline{H}$ & %i hours & %s \\\\\n', ration, 'Rajasthan policy');
    
    fprintf(fid,'\t\t\\bottomrule\n');
     
    % Table notes
    fprintf(fid,['\t\t\\multicolumn{3}{p{0.65\\hsize}}{\\footnotesize This table reports the inputs to our model that are homogenous across all SDOs.'... 
                 'The \\emph{primitives} are unobserved structural parameters assumed to be policy invariant.'...
                 'These include $\\alpha_W$, which defines the concavity of the production function,'...
                 'and $\\Omega$ which is total factor productivity.'...
                 'The \\emph{exogenous variables} are unmodeled policy choices which include the nominal price of one kilowatt-hour of electricity,'...
                 'the marginal cost of producing one kilowatt-hour of electricity, and the power ration in hours per day.}\n']);
             
    % Endmatter
    fprintf(fid,'\t\\end{tabular}\n');
    fprintf(fid,'\\end{table}');
    
    % Output
    fclose(fid);
    fprintf(1,'Printed: %s\n',filename);
end
   
    
             
             
     
    
    
    
    

