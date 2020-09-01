 
/*******************************************************************************

	Rationing the Commons -- Marginal Analysis
	
			* Data preparation
	
			* Summary statistics of outcome variables, regressors, and controls
			
			* Profit regressions
				* Main (OLS/IVPDS)
				* Robustness  (OLS/IVPDS)
				* First Stage
				
			* Generate sample for structural analysis
				

*******************************************************************************/


// Setup
if c(mode) == "batch" {
	local PROJECT_ROOT = strrtrim("`0'")	
}
else {
	if c(os) == "Windows" {
		cd "C:/Users/`c(username)'/Dropbox"
		local PROJECT_ROOT "C:/Users/`c(username)'/Dropbox/replication_rationing_commons"
	}
	else {
		cd "/Users/`c(username)'/Dropbox"
		local PROJECT_ROOT "/Users/`c(username)'/Dropbox/replication_rationing_commons"
	}
}
 
include "`PROJECT_ROOT'/code/load_project_globals.do"	


// Exhibits to run
local REG_FIRST   0
local MAIN        1
local ROBUSTNESS  1

// Output production function data to matlab
local MATLABSAMPLE 1

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 								Data Preparation
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "`marginal_analysis'/rationing_data_preparation.do"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 								Summary Statistics
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "`marginal_analysis'/rationing_summary_statistics.do"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 								Profit Regressions
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "`marginal_analysis'/rationing_profit_regressions.do"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 								Structural Sample
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "`marginal_analysis'/rationing_structural_sample.do"
