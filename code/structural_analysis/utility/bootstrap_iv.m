function [bootcoefs] = bootstrap_iv(data,yname,Xnames,Znames,endog,clustername,nboot)
%%
% This function returns coefficients from 2SLS regressions by sampling the data with replacement.
%
% INPUTS:
%   data: waterData object from which we can get a clean table of data rows
%   yname: The name of the outcome variable
%   Xnames: The endogenous and exogenous regressors
%   Ynames: The exogenous regressors and instruments
%   endog: names of the endogenous variables
%   clustername: name of variable for clustering std. errors/block
%   bootstrap
%   nboot: Number of bootsamples to use
% OUTPUT:
%   bootcoefs: matrix of coefficients from 2sls fit over bootsamples
%   indices: cell matrix of indices for each cluster x iteration
    
    % Get data from waterModel object.
    data = data.clean;
    
    % Get variables from data
    y = data{:,yname};
    X = data{:,Xnames};
    Z = data{:,Znames};
    clustervar = data{:,clustername};
    endogi = ismember(Xnames,endog);
    endogi = find(endogi);
    
    % Set seed for consistent randomization
    seed = RandStream('mlfg6331_64');
    
    % Empty vector of coefficients
    bootcoefs = zeros([size(X,2)+1],nboot);
    
    % Get unique clusters
    unique_clustervar = unique(clustervar);
    
    % Preserve randomization for production function estimation
    %indices = cell(nboot,length(unique_clustervar));
    
    for i=1:nboot
        
        % Generate cell to hold randomizations foe each cluster
        cluster_cell = cell(3,length(unique_clustervar));
        for j = 1:length(unique_clustervar)
            
            % Get blocks by clustering variable
            y_c = y(clustervar(:) == unique_clustervar(j));
            X_c = X(clustervar(:) == unique_clustervar(j),:);
            Z_c = Z(clustervar(:) == unique_clustervar(j),:);
            
            % Sampling with replacement
            sample_indices = randsample(seed,length(y_c),length(y_c),true);
            y_c = y_c(sample_indices);
            X_c = X_c(sample_indices,:);
            Z_c = Z_c(sample_indices,:);
            
            %indices{i,j} = sample_indices;
            cluster_cell(:,j) = {y_c X_c Z_c};
        end
        % Concatenate bootsampled matrices
        yboot = cat(1,cluster_cell{1,:});
        Xboot = cat(1,cluster_cell{2,:});
        Zboot = cat(1,cluster_cell{3,:});

        % Estimate by 2SLS
        est = iv2sls(yboot,Xboot,Zboot,'endog',endogi,'vartype','homo');
        bootcoefs(:,i) = est.coef;
    end    
end