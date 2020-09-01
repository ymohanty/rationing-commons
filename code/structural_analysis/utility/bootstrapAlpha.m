function alphaSE = bootstrapAlpha(data_obj,nboot)
% This function generates a bootstrapped std. error for the output
% elasticity of water which matches the reduced form effect of relaxing the
% ration.
%
% INPUTS:
%   data_obj: main waterData object.
%   nboot: The size of bootstrap sample. 
% OUTPUTS:
%   alphaSE: Std. dev of the bootstrap distribution
%

    %% Setup
    
    % Get the data table
    data = data_obj.clean;
    
    % Get the cluster variable/randomization block
    clustervar = data_obj.clean{:,'sdo_feeder_code'};
    unique_clustervar = unique(clustervar);
    
    % Empty vector of estimates
    alphaWcalibrated = zeros(nboot,1);
    
    % Set seed for consistent randomization
    seed = RandStream('mlfg6331_64');
    
    
    %% Estimation
    for i = 1:nboot
        
        % Generate cell to hold randomizations for each cluster
        cluster_cell = cell(1,length(unique_clustervar));
        for j = 1:length(unique_clustervar)
            data_c = data(clustervar == unique_clustervar(j),:);
            k = size(data_c,1);
            indices = randsample(seed,k,k,true);
            data_c = data_c(indices,:);
            cluster_cell{j} = data_c;
        end
        
        % Concantenate matrices
        data_boot = cat(1,cluster_cell{:});
        
        % Set up waterModel with bootstrapped sample
        data_obj.clean = data_boot;
        model = waterModel(data_obj);
        model.noisy          = false;  
        model.calibrateAlpha = true;
        model.estimationMethod = 'iv';
        model.ivSet = 'logInvDepthPDS';
        
        % Estimate production model
        model = model.estimateIV;
        model = model.decomposition;
        model = model.residuals;

        % Estimate reduced form model
        model = model.estimateProfitIV;
        rf_mb = model.rf_mb;
        
        % Set up counterfactual object
        counter = waterCounter( model );
        counter.policy = waterPolicy('rationing');
        alphaWcalibrated(i) = calibrateAlpha(counter,rf_mb);
       
    end
    
    % Return std. dev of the vector of calibrated estimates
    alphaSE = std(alphaWcalibrated);
end
    
    