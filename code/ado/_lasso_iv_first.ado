program define _lasso_iv_first 
	syntax varname, ///
	endog(varlist) controls(varlist) ivset(varlist) eststo(string) cluster(varlist) ///
	[ method(string) ] [ pnotpen(varlist) ]
	
	
	//================== Construct instrument type varlists ======================	
	// Rock types
	qui des rock_type_*, varlist
	local rock_types `r(varlist)'
	
	// Rock shares
	qui des rock_area_*, varlist
	local rock_shares `r(varlist)'
	
	// Fractures
	local fractures ltot_1km ltot_5km dist2fault_km
	
	// Aquifers
	qui des aquifer_type_*, varlist
	local aquifer_types `r(varlist)'
	
	// Fractures squared
	qui des dist2fault_km2 ltot_1km2 ltot_5km2 ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11, varlist
	local fractures_squared `r(varlist)'
	
	// Rock shares squared
	qui des rock_area2_*, varlist
	local rock_shares_squared `r(varlist)'
	
	// Fractures * rock share
	qui des ltot1km_area11* ltot5km_area11* dist2fault_area11*, varlist
	local fractures_rock_shares, `r(varlist)'
	
	// Fractures^2 * rock share
	qui des ltot1km_area21* ltot5km_area21* dist2fault_area21*, varlist
	local frac_sq_rock, `r(varlist)'
	
	// Rock shares^2 * fractures
	qui des ltot1km_area12* ltot5km_area12* dist2fault_area12*, varlist
	local frac_rock_sq `r(varlist)'
	
	// Fractures^2 * Rock shares^2
	qui des ltot1km_area22* ltot5km_area22* dist2fault_area22*, varlist
	local all_squared `r(varlist)'
	
	//===========================  ESTIMATION ===================================
	if "`method'" == "2sls" {
		// Run first stage
		regress `endog' `ivset' `controls', vce(cluster f_id)
		eststo `eststo'
		
		// Add F-STAT
		estadd scalar F_STAT `e(F)': `eststo'
		
		// Run IV-2SLS regression
		ivregress 2sls `varlist' `controls' (`endog'=`ivset'), vce(cluster f_id) first
		eststo `eststo'_second
		
		// Add # of farmers
		unique f_id if e(sample) == 1
		estadd scalar FARMERS `r(unique)': `eststo'
		
		// Add RMSE
		reg `endog' `ivset' `controls'
		estadd scalar RMSE `e(rmse)': `eststo'
		
		// For coefficient locals
		local instr_selected "`ivset'"
		
		// Add instruments selected
		estadd local NAMES_SELECTED `instr_selected':`eststo'
		
	}
	else {
		// Run IV-PDS regression
		ivlasso `varlist' (`controls') (`endog'=`ivset'), first loptions(cluster(f_id) supscore) ivoptions(cluster(`cluster')) post(pds) partial(`controls' `pnotpen') idstats 
		eststo `eststo'_second
		
		// Count the number of high dimensional instruments supplied and selected
		local z: word count `e(zhighdim)'
		local z_selected: word count `e(zselected)'
		
		// Store the names of selected instruments
		local instr_selected = "`e(zselected)'"
		
		// Restore first stage estimates
		estimates restore _ivlasso_`endog'
		eststo `eststo'
			
		// Add instruments selected and contained
		estadd scalar Z = `z'
		estadd scalar Z_SELECTED = `z_selected'
		
		// Farmers
		estimates restore `eststo'_second
		unique f_id if e(sample) == 1
		estadd scalar FARMERS `r(unique)': `eststo'
		
		// RMSE
		estimates restore _ivlasso_`endog'
		predict hat
		rmse `endog' hat
		estadd scalar RMSE real(r(hat)): `eststo'
		drop hat
			
		// F-STAT
		estimates restore `eststo'_second
		estadd scalar F_STAT `e(weakid)': `eststo'
		
		// Add instruments selected
		estadd local NAMES_SELECTED `instr_selected':`eststo'

	}
	
	//=================== ADD SCALARS =================================
	
	//~~~~~~~~~~~~~~~~~~ Add coefficient locals ~~~~~~~~~~~~~~~~~~~~
	
	// Fractures
	local fractures_in: list fractures & instr_selected
	if "`fractures_in'" == "" {
		estadd local fractures_coeff " ": `eststo'
	}
	else {
		estadd local fractures_coeff "Yes": `eststo'
	}
	
	// Rock shares
	local rock_shares_in: list rock_shares & instr_selected
	if "`rock_shares_in'" == "" {
		estadd local rock_shares_coeff " ": `eststo'
	}
	else {
		estadd local rock_shares_coeff "Yes": `eststo'
	}
	
	// Rock types
	local rock_types_in: list rock_types & instr_selected
	if "`rock_shares_in'" == "" {
		estadd local rock_types_coeff " ": `eststo' 
	}
	else {
		estadd local rock_types_coeff "Yes": `eststo' 
	}
	
	
	// Aquifer types
	local aquifer_types_in: list aquifer_types & instr_selected
	if "`aquifer_types_in'" == "" {
		estadd local aquifer_types_coeff " ": `eststo'
	}
	else {
		estadd local aquifer_types_coeff "Yes": `eststo'
	}
	
	// Fractures^2
	local fractures_squared_in: list fractures_squared & instr_selected
	if "`fractures_squared_in'" == "" {
		estadd local fractures_squared_coeff " ": `eststo'
	}
	else {
		estadd local fractures_squared_coeff "Yes": `eststo'
	}

	// Rock shares^2
	local rock_shares_squared_in: list rock_shares_squared & instr_selected
	if "`rock_shares_squared_in'" == "" {
		estadd local rock_shares_squared_coeff " ": `eststo'
	}
	else {
		estadd local rock_shares_squared_coeff "Yes": `eststo'
	}
	
	// Fractures*rock shares
	local fractures_rock_shares_in: list fractures_rock_shares & instr_selected
	if "`fractures_rock_shares_in'" == "" {
		estadd local fractures_rock_shares_coeff " ": `eststo'
	}
	else {
		estadd local fractures_rock_shares_coeff "Yes": `eststo'
	}
	
	// Fractures^2 * Rock shares
	local frac_sq_rock_in: list frac_sq_rock & instr_selected
	if "`frac_sq_rock_in'" == "" {
		estadd local frac_sq_rock_coeff " ": `eststo'
	}
	else {
		estadd local frac_sq_rock_coeff "Yes": `eststo'
	}
	
	// Fractures * Rock shares^2
	local frac_rock_sq_in: list frac_rock_sq & instr_selected
	if "`frac_rock_sq_in'" == "" {
		estadd local frac_rock_sq_coeff " ": `eststo'
	}
	else {
		estadd local frac_rock_sq_coeff "Yes": `eststo'
	}
	
	// Fractures^2 * Rock shares^2
	local all_squared_in: list all_squared & instr_selected
	if "`all_squared_in'" == "" {
		estadd local all_squared_coeff " ": `eststo'
	}
	else {
		estadd local all_squared_coeff "Yes": `eststo'
	}
	
	//~~~~~~~~~~ General coefficient locals ~~~~~~~~~
	// First order interactions
	local foi `"`fractures_squared' `rock_shares_squared' `fractures_rock_shares' "'
	local foi_in: list foi & instr_selected
	if "`foi_in'" == "" {
		estadd local foi_coeff " ": `eststo'
	}
	else {
		estadd local foi_coeff "Yes": `eststo'
	}
	
	// Second order interactions
	local soi `"`frac_sq_rock' `frac_rock_sq' `all_squared' "'
	local soi_in: list soi & instr_selected
	if "`soi_in'" == "" {
		estadd local soi_coeff " ": `eststo'
	}
	else {
		estadd local soi_coeff "Yes": `eststo'
	}
	
	//~~~~~~~~~~~~ Other Stats ~~~~~~~~~~~~~~~~~~~~~
	
	// Add mean of dep variable
	qui sum `endog'
	estadd scalar DEPMEAN r(mean): `eststo'
	
	// Check if fixed effects are in regressors
	qui des _Isd*, varlist
	local sdo `r(varlist)'
	qui des _Ild*, varlist
	local ld `r(varlist)'
	local sdo_fe : list sdo in regressors // Look for SDO fixed effects
	local ld_fe : list ld in regressors // Look for decile fixed effects
	
	// Check if soil controls are in regressors
	qui des prop_*, varlist
	local soil `r(varlist)'
	local soil_in: list soil in regressors
	
	// Check if toposequence variables are in regressors
	local t elevation
	local topos: list t in regressors
	
	// Toposequence indicators
	if `topos' == 1 {
		estadd local toposeq "Yes": `eststo'
	}
	else {
		estadd local toposeq "No": `eststo'
	}
	
	// Fixed effects indicators
	if `sdo_fe' == 0 {
		estadd local sdo_fe_indicator "No" : `eststo'
	}
	else {
		estadd local sdo_fe_indicator "Yes" : `eststo'
	}	

	if `ld_fe' == 0 {
		estadd local ld_fe_indicator "No" : `eststo'
	}
	else {
		estadd local ld_fe_indicator "Yes" : `eststo'
	}
	
	// Soil indicators
	if `soil_in' == 0 {
		estadd local soil_indicator "No": `eststo'
	}
	else {
		estadd local soil_indicator "Yes": `eststo'
	}
	
	
end
	
	
	
