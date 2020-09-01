function obj = findOptimalTransfers( obj, exAnteRegime )
%findOptimalTransfers Function to find transfers that minimize fraction of
%  farmers that lose from reform.
%
% INPUT:
%   obj    - Counterfactual object of policy regime post reform
%   exante - Counterfactual object of policy regime ex ante
%
% OUTPUT:
%   Transfer function on discretized space of farmer characteristics

% Simulations to keep 
Sfast = 0.25;

%% Create discretized space of farmer characteristics

% Variables on which to target
% Xvars = {'Land','pump','depth'};
Xvars = {'Land','pump'};
X     = table2array(obj.farmer(obj.farmer.s_id==1,Xvars));

% Percentiles of X distribution
tau       = [ 12.5:12.5:100 ];
quantiles = prctile(X,tau);

N = size(X,1);
Q = size(quantiles,1);
J = size(quantiles,2);
j = zeros(N,J+1);
for jdim = 1:J
    jGtQuant  = repmat(X(:,jdim),1,Q) > ...
                repmat(quantiles(:,jdim)',N,1);
    j(:,jdim) = sum(jGtQuant,2) + 1; 
end

% Unique group IDs and group counts
j(:,end) = 10*j(:,1) + j(:,2);
[ jcode, ~, jid ] = unique(j(:,end));

jids = jid(:,ones(1,obj.S*Sfast))';
jids = jids(:);

nj = accumarray(jid,ones(size(jid)),[],@sum);


%% Record change in profit across regimes

deltaProfit = obj.farmer.profit - exAnteRegime.farmer.profit;
deltaProfit = deltaProfit(obj.farmer.s_id <= obj.S*Sfast);
budget      = obj.budget * size(obj.fmplot,1) / size(obj.farmer,1);


%% Pose optimization problem to maximize farmers who gain

options = optimoptions(@fmincon,'Display','iter',...
                       'MaxFunEvals',1e5,...
                       'MaxIter',1000);

bw        = 0.250; % 0.250 INR '000s = INR 250 bandwidth
objective = @(T) -shareWinners( T, jids, deltaProfit, bw );
T0        = budget * ones(size(nj));

A  = nj';
B  = budget * sum(nj);
LB = zeros(size(nj));

[ T, S ] = fmincon(objective,T0,A,B,[],[],LB,[],[],options);
fprintf(1,'Fraction %3.2f of farmers better off\n',S);


%% Store output and graph targeting function

x1 = floor(jcode/10);
x2 = mod(jcode,10);
obj.transfers = table(x1,x2,T);
obj.transfers.Properties.VariableNames = [Xvars {'Transfer'}];

end

function S = shareWinners( T, jid, deltaProfit, bw )
    % Calculate share of winners given a transfer rule T    
    netProfit = deltaProfit + T(jid);
    S         = mean( normcdf(netProfit/bw) );
end
