classdef waterData 
%
% waterData 
%
% Creates waterData in matlab from file of productive inputs
%
% INPUTS:
%    - Text file of production inputs
%
% OUTPUTS:
%    - waterData object
%
properties
    
    % Data files and raw input
    file_input;
    raw;         % Raw data as read
    keep;        % Observations with complete input records
    clean;       % Data with complete records only
    N;
    Nclean;
    Nfarmers;
    Require = {'Revenue','Land','Labor','Capital','Water'};
    require = {'revenue','land','labor','capital','water'};
    
    % Variables to clean
    ZX = {'hh_adult_males','sq_hh_adult_males'};
    ZL = {'size_largest_parcel_1','size_largest_parcel_2',...
          'size_largest_parcel_3','sq_size_largest_parcel_1',...
          'sq_size_largest_parcel_2','sq_size_largest_parcel_3'};
    ZW = {'rock_area_4','rock_area_6','rock_area_14',...
          'rock_area_15','rock_area_20','aquifer_type_4',...
          'rock_area2_10','ltot1km_area1130',...
          'ltot5km_area1115','dist2fault_area1114',...
          'dist2fault_area1146','water_sellers'};
    ZK = {'seed_price_across_farmer',...
          'seed_price_sq_across_farmer'};
    Zmiss;
    
    % Print options
    noisy = false;
end

properties (Dependent)
    Znames;
end

methods
    
    function obj = waterData( file_input )
        % Initialize a waterData object
        
        % Input data from text file 
        obj.file_input = file_input;
        obj.raw        = readtable( obj.file_input, 'Delimiter', '\t' );
        obj.N          = size(obj.raw,1);
        
        % Identifers 
        obj.raw.feeder_id  = floor(obj.raw.farmer_id/100);
        
        % Encode new variables needed for production function estimation
        
        % Production above / below expectations
        obj.raw.prod_above_expect = (obj.raw.prod_below_expect==1);
        obj.raw.prod_below_expect = (obj.raw.prod_below_expect==3);
        
        % Generate logged values of input and output variables
        obj.raw.Revenue = obj.raw.revenue;
        obj.raw.Land    = obj.raw.land;
        obj.raw.Labor   = obj.raw.labor;
        obj.raw.Capital = obj.raw.capital;
        obj.raw.Water   = obj.raw.water;
        
        delete = {'revenue','land','labor','capital','water'};
        obj.raw( :, delete ) = [];
        
        obj.raw.revenue = log(obj.raw.Revenue);
        obj.raw.land    = log(obj.raw.Land);
        obj.raw.labor   = log(obj.raw.Labor);
        obj.raw.capital = log(obj.raw.Capital); 
        obj.raw.water    = log(obj.raw.Water);
        
        obj.raw.laborAndCapital = obj.raw.labor + obj.raw.capital;
                
        % Clean input variables
        obj.raw.land_owned_pakka2 = obj.raw.land_owned_pakka.^2;
        obj.raw.hh_adult_males = min(obj.raw.hh_adult_males,6);
        obj.raw.sq_hh_adult_males = obj.raw.hh_adult_males.^2;
        
        obj.raw.seed_price_across_farmer    = obj.raw.seed_price_across_farmer/1000;  
        obj.raw.seed_price_sq_across_farmer = obj.raw.seed_price_across_farmer.^2;
        
        % Minimum depth
        %   A floor on depth sets a floor on water prices
        obj.raw.depth = max(obj.raw.depth,30);
        
        % Convert pump capacity to kW
        %   The variable pump_farmer_plot contains the share of pump
        %   capacity devoted to each plot. The farmer's pump capacity is
        %   thus allocated across crops.
        obj.raw.pump_capacity = obj.raw.pump_farmer_plot * 0.7457;
        no_capacity              = (obj.raw.pump_capacity == 0) | ...
                                   isnan(obj.raw.pump_capacity);
        pump_overall_mean        = mean(obj.raw.pump_capacity(~no_capacity));
        obj.raw.pump_capacity(no_capacity) = ...
            pump_overall_mean*ones(sum(no_capacity),1);
        
        % Flags for crop type or other conditions to drop
        orchardCrop = strcmp(obj.raw.crop_type,'Orange');
       
        % Subset observations based on completeness of inputs
        obj.keep       = ~any(ismissing(obj.raw(:,obj.require)),2) & ...
                         ~any(table2array(obj.raw(:,obj.Require)) <= 0,2) & ...
                         ~orchardCrop;
        obj.clean      = obj.raw(obj.keep,:);
        obj.Nclean     = size(obj.clean,1);
        
        
        % Dummy out any exogenous variables that are needed as either 
        %   controls or instruments but are missing in the data
        [ obj.clean, obj.Zmiss ] = ...
            dummyOutMissing( obj.clean, obj.Znames );
        if obj.noisy        
            obj.print;
        end
    end
    
    function Znames = get.Znames( obj )
       % Get instrument names
       Znames = [ obj.ZX obj.ZL obj.ZW obj.ZK ];
    end
    
    function print( obj )
       % Print summary of input variables
       fprintf(1,'Dataset with %5.0f cleaned farmer X crop records\n',...
               obj.Nclean);
           
       missingVars = sum(ismissing(obj.raw(:,obj.require)),1);
       fprintf(1','\nRaw data had the following missing inputs:\n');
       for i = 1:length(obj.require)
           fprintf(1,'%30s : \t%4.0f\n',obj.require{i},missingVars(i));
       end
       
       missingVars = sum(ismissing(obj.raw(:,obj.Znames)),1);
       fprintf(1','\nRaw data had the following missing instruments:\n');
       for i = 1:length(obj.Znames)
           fprintf(1,'%30s : \t%4.0f\n',obj.Znames{i},missingVars(i));
       end
    end
    
    function correlations( obj )
        % Plot correlation matrix between revenue and inputs
        fprintf(1,'\nCorrelation of revenue and inputs\n');
        display(corr(table2array(obj.clean(:,obj.require))));
    end
    
end

end % End class definition

function [ D, newMissingDums ] = dummyOutMissing( D, names )
    % Dummy out missing values of variables in a data table
    %   Replace all missing values with zero, and add a dummy variable
    %   equal to one if the variable was initially missing
    
    % Flag variables missing any observations
    missing        = any(isnan(table2array(D(:,names))),1);
    varsMissingAny = names(missing);
    
    % Quit if nothing to replace
    if isempty(varsMissingAny)
        newMissingDums = {};
        return
    end
    
    % Set missing values to zero
    varsMissingMat = D{:,varsMissingAny};
    missingObs     = isnan(varsMissingMat);
    varsMissingMat(missingObs) = 0;
    D{:,varsMissingAny} = varsMissingMat;
    
    % Create names of new variables
    uniqueDummies    = rank(double(missingObs));
    newMissingDums   = cell(1,uniqueDummies);
    missingObsUnique = zeros(size(missingObs,1),uniqueDummies);
    j                = 1;
    for i = 1:length(varsMissingAny)
        
        % Whether column is collinear with those added before
        if i == 1
            fullRank = 1;
        else
            fullRank = rank([missingObsUnique(:,1:j-1) missingObs(:,i)]) == ...
                       size([missingObsUnique(:,1:j-1) missingObs(:,i)],2);
        end
        
        % If dummy is not collinear, add it to matrix of dummies
        if fullRank
            missingObsUnique(:,j) = missingObs(:,i);
            newMissingDums{j} = [ 'missing_' varsMissingAny{i} ];
            j = j + 1;
        else
            continue;
        end
        
    end
    
    % Append new dummy variables to data table
    missingDummy = array2table(missingObsUnique,'VariableNames',...
                               newMissingDums);
    D = [ D missingDummy ];
end



