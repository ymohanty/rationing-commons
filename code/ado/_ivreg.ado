* Wrapper for ivregress
program define _ivreg
	syntax varname, ///
	endog(varlist) cluster(varlist) ///
	[ controls(varlist) ] ivset(varlist) eststo(string) [ weight(varlist) ]
	
	// Check if fixed effects are in controls
	qui des _Isd*, varlist
	local sdo `r(varlist)'
	qui des _Ild*, varlist
	local ld `r(varlist)'
	local sdo_fe : list sdo in controls // Look for SDO fixed effects
	local ld_fe : list ld in controls // Look for decile fixed effects
	
	// Check if toposequence variables are in regressors
	local t elevation
	local topos: list t in controls
	
	// Check if soil control variables are in regressors
	cap confirm variable prop_high_k
	if _rc == 0 {
		unab soil: prop_high_* prop_med_* prop_sufficient_* prop_acidic prop_mildly_alkaline
		local soil_in: list soil in controls
	}
	else {
		local soil_in 0
	}
	
	// Check if weather controls variables are in regressors
	cap confirm variable temp_rabi_hdd
	if _rc == 0 {
		unab weather: temp_rabi_*
		local weather_in: list weather in controls
	}
	else {
		local weather_in 0
	}
	
	// Count instruments
	local z: word count `ivset'
	
	// Run IV regression
	if "`weight'" == "" {
		ivregress 2sls `varlist' `controls' (`endog'=`ivset'), vce(cluster `cluster')
	}
	else {
		ivregress 2sls `varlist' `controls' (`endog'=`ivset') [aweight=`weight'], vce(cluster `cluster')
	}
	eststo `eststo'
	estadd scalar R_SQ = e(r2_a)
	estadd scalar Z = `z'
	
	// Add dependent variable mean to stored estimates
	if "`weight'" == "" {
		qui sum `varlist'
	}
	else {
		qui sum `varlist' [aweight=`weight']
	}
	estadd scalar DEPMEAN = r(mean)
	
	// Add spaces
	estadd local SPACE ""
	
	// Add farmer numbers
	unique f_id if e(sample) == 1
	estadd scalar FARMER = r(unique)
	
	// Toposequence indicators
	if `topos' == 1 {
		estadd local toposeq "Yes": `eststo'
	}
	else {
		estadd local toposeq " ": `eststo'
	}
	
	// Weather control indicators
	if `weather_in' == 0 {
		estadd local weather_indicator " ":`eststo'
	}
	else {
		estadd local weather_indicator "Yes": `eststo'
	}
	
	// Soil control indicators
	if `soil_in' == 0 {
		estadd local soil_indicator " ": `eststo'
	}
	else {
		estadd local soil_indicator "Yes": `eststo'
	}
	
	// Fixed effects indicators
	if `sdo_fe' == 0 {
		estadd local sdo_fe_indicator " " : `eststo'
	}
	else {
		estadd local sdo_fe_indicator "Yes" : `eststo'
	}	

	if `ld_fe' == 0 {
		estadd local ld_fe_indicator " " : `eststo'
	}
	else {
		estadd local ld_fe_indicator "Yes" : `eststo'
	}
end
		
