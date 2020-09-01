* Wrappper for regress
program define _reg_ols
	syntax varname, ///
	regressors(varlist) cluster(varlist) [ controls(varlist) ] eststo(string) [ weight(varlist) ] [ conley ]
	
	// Check if fixed effects are in regressors
	qui des _Isd*, varlist
	local sdo `r(varlist)'
	qui des _Ild*, varlist
	local ld `r(varlist)'
	local sdo_fe : list sdo in controls // Look for SDO fixed effects
	local ld_fe : list ld in controls // Look for decile fixed effects
	
	// Check if toposequence variables are in regressors
	local t elevation
	local topos: list t in controls
	
	// Check if soil controls are in regressors
	unab soil: prop_high_* prop_med_* prop_sufficient_* prop_acidic prop_mildly_alkaline
	local soil_in: list soil in controls
	
	// Check if weather controls variables are in regressors
	cap confirm variable temp_rabi_hdd
	if _rc == 0 {
		unab weather: temp_rabi_hdd
		local weather_in: list weather in controls
	}
	else {
		local weather_in 0
	}
	
	
	// Run OLS regression
	if "`cluster'" == "" {
		if "`weight'" == "" {
			reg `varlist' `regressors' `controls', vce(cluster `cluster')
		}
		else {
			reg `varlist' `regressors' `controls' [ aweight=`weight' ], vce(cluster `cluster') 
		}
	}
	else {
		if "`weight'" == "" {
			reg `varlist' `regressors' `controls' 
		}
		else {
			reg `varlist' `regressors' `controls' [ aweight=`weight' ]
		}
	}
	
	if "`conley'" != "" {
		tempvar timevar
		gen constant = 1
		gen `timevar' = 1
		ols_spatial_HAC `varlist' `regressors' `controls' constant, lat(g11_gpslatitude) ///
			lon(g11_gpslongitude) t(`timevar') p(id) distcutoff(2)
		drop constant `timevar'
		estimates restore spatial
	}
	eststo `eststo'
	
	// Run OLS with std errors corrected for spatial correlation
	
	// Add dependent variable mean to
	if "`weight'" == "" {
		qui sum `varlist'
	}
	else {
		qui sum `varlist' [aweight = `weight']
	}
	estadd scalar DEPMEAN = r(mean)
	
	// Add farmer numbers
	unique f_id if e(sample) == 1
	estadd scalar FARMER = r(unique)
	
	// Add space
	estadd local SPACE ""
	
	// Toposequence indicators
	if `topos' == 1 {
		estadd local toposeq "Yes": `eststo'
	}
	else {
		estadd local toposeq " ": `eststo'
	}
	
	// Soil controls indicator
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
	
	// Add RMSE
	estadd scalar RMSE = e(rmse)
	
	// Add F_STAT
	test `regressors'
	estadd scalar F_STAT = r(F)
	
	// Add R^2
	estadd scalar R_SQ = e(r2)
	
	// Add adj. R^2
	estadd scalar R_SQ_a = e(r2_a)
end
	
	
