* Wrapper for lasso IV
program define _lasso_iv
	syntax varname, ///
	endog(varlist) ///
	controls(varlist) ivset(varlist) eststo(string) cluster(varlist) ///
	[ pnotpen(varlist) ] [ weight(varlist) ] [ method(string) ] [ conley ]
	
	if "`method'" == "" {
		local method "pds"
	}
	
	if "`cluster'" == "" {
		local cluster f_id
	}
	
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
	
	// If we are penalizing all controls
	if "`pnotpen'" == "" {
		if "`weight'" == "" {	
			ivlasso `varlist' (`controls') (`endog'=`ivset'), loptions(cluster(f_id)) ivoptions(cluster(`cluster')) post(`method')
		}
		else {
			ivlasso `varlist' (`controls') (`endog'=`ivset') [aweight=`weight'], loptions(cluster(f_id)) ivoptions(cluster(`cluster')) post(`method')
		}
	}
	else {
		if "`weight'" == "" {	
			ivlasso `varlist' (`controls') (`endog'=`ivset'), loptions(cluster(f_id)) ivoptions(cluster(`cluster')) post(`method') partial(`pnotpen')
		}
		else {
			ivlasso `varlist' (`controls') (`endog'=`ivset') [aweight=`weight'], loptions(cluster(f_id)) ivoptions(cluster(`cluster')) post(`method') partial(`pnotpen')
		}
	}
	
	// Clear previous estimates if conley
	if "`conley'" != "" {
		gen constant = 1
		local pnotpen: list pnotpen - controls
		conley_viraj `varlist' `controls' `pnotpen' constant, lat(g11_gpslatitude) lon(g11_gpslongitude) ///
		endog(`endog') ivset(`ivset') lcluster(f_id) ivcluster(`cluster') regtype("iv_pds") ///
		distcutoff(2)
		drop constant
	}
		
	// Count the number of high dimensional instruments supplied and selected
	local z: word count `e(zhighdim)'
	local z_selected: word count `e(zselected)'
	
	// Calculate dependent variable mean
	eststo `eststo'
	qui sum `varlist' 
	if "`weight'" != "" {
		qui sum `varlist' [aweight=`weight']
	}
	
	// Add thee above to stored estimates
	estadd scalar DEPMEAN = r(mean)
	estadd scalar Z = `z'
	estadd scalar Z_SELECTED = `z_selected'
	
	// Add number of farmers
	unique f_id if e(sample) == 1
	estadd scalar FARMER = r(unique)
	
	// Add spaces
	estadd local SPACE ""
	
	// Toposequence indicators
	if `topos' == 1 {
		estadd local toposeq "Yes": `eststo'
	}
	else {
		estadd local toposeq " ": `eststo'
	}
	
	// Soil control indicators
	if `soil_in' == 0 {
		estadd local soil_indicator " ": `eststo'
	}
	else {
		estadd local soil_indicator "Yes": `eststo'
	}
	
	// Weather control indicators
	if `weather_in' == 0 {
		estadd local weather_indicator " ":`eststo'
	}
	else {
		estadd local weather_indicator "Yes": `eststo'
	}
	
	// Fixed effects indicators
	if `sdo_fe' == 0 {
		estadd local sdo_fe_indicator " "
	}
	else {
		estadd local sdo_fe_indicator "Yes"
	}
	
	if `ld_fe' == 0 {
		estadd local ld_fe_indicator " "
	}
	else {
		estadd local ld_fe_indicator "Yes"
	}
		

end
