* Production function estimation
program define est_prod_func
	syntax varname[if] [in], endog(varlist) ///
	instr_1(varlist) instr_2(varlist) instr_3(varlist) controls(varlist) filename(string) figurename(string) ///
	title(string) ref(string) [ weight(varlist) ]
	
	if "`weight'" == "" {
		// Estimate OLS
		_reg_ols `varlist', regressors(`endog') controls(`controls') eststo("ols")
			
		// Estimate IV: Instrument set 1
		_ivreg `varlist', endog(`endog') ivset(`instr_1') controls(`controls') eststo("instr_1")
		
		// Estimate IV: Instrument set 2
		_ivreg `varlist', endog(`endog') ivset(`instr_2') controls(`controls') eststo("instr_2")
		
		// Estimate IV: Instrument set 3
		_ivreg `varlist', endog(`endog') ivset(`instr_3') controls(`controls') eststo("instr_3")
		
		// Estimate IV_PDS
		_lasso_iv `varlist', endog(`endog') ivset(`instr_3') controls(`controls') eststo("pds") pnotpen(`controls')
	}
	else {
		// Estimate OLS
		_reg_ols `varlist', regressors(`endog') controls(`controls') eststo("ols") weight(`weight')
			
		// Estimate IV: Instrument set 1
		_ivreg `varlist', endog(`endog') ivset(`instr_1') controls(`controls') eststo("instr_1") weight(`weight')
		
		// Estimate IV: Instrument set 2
		_ivreg `varlist', endog(`endog') ivset(`instr_2') controls(`controls') eststo("instr_2") weight(`weight')
		
		// Estimate IV: Instrument set 3
		_ivreg `varlist', endog(`endog') ivset(`instr_3') controls(`controls') eststo("instr_3") weight(`weight')
		
		// Estimate IV_PDS
		_lasso_iv `varlist', endog(`endog') ivset(`instr_3') controls(`controls') eststo("pds") pnotpen(`controls') weight(`weight')
	
	}
	
	//~~~~~~~ Construct residual plot ~~~~~~~
	// Raw data
	estimates restore instr_3
	predict log_revenue_hat
	gen resid = log_revenue - log_revenue_hat

	// Feeder FE
	reg resid I.sdo_feeder_code
	predict resid_hat
	gen resid_feeder = resid - resid_hat
	
	// Farmer FE
	drop resid_hat
	areg resid, absorb(f_id)
	predict resid_hat, xbd
	gen resid_farmer = resid - resid_hat
	drop resid_hat
	
	// Farmer-crop
	areg resid, absorb(farmer_crop)
	predict resid_hat, xbd
	gen resid_crop = resid - resid_hat
	drop resid_hat
	
	
	// Plot
	twoway kdensity resid, lp(solid) bwidth(0.3) kernel(gaussian) || kdensity resid_feeder, lp(shortdash) bwidth(0.3) kernel(gaussian) || ///
		   kdensity resid_farmer, lp("--...") bwidth(0.3) kernel(gaussian) || kdensity resid_crop, kernel(gaussian) legend(label(1 "Raw") label(2 "Feeder FE") label (3 "Farmer FE") label(4 "Farmer-Crop FE")) xlabel(-6(2)7) xtitle("log(TFP)")  ///
		graphregion(color(white)) bgcolor(white) lp(dash) bwidth(0.3) note("Kernel: gaussian" "Bandwidth: 0.3")
	graph export "`figurename'.pdf", replace
	
	// Plot 2
	twoway kdensity resid if abs(resid) < 2, lp(solid) bwidth(0.3) kernel(gaussian) || kdensity resid_feeder if abs(resid_feeder) < 2, lp(shortdash) bwidth(0.3) kernel(gaussian) || ///
		   kdensity resid_farmer if abs(resid_farmer) < 2, lp("--...") bwidth(0.3) kernel(gaussian) || kdensity resid_crop if abs(resid_crop) < 2, ///
		   legend(label(1 "Raw") label(2 "Feeder FE") label (3 "Farmer FE") label(4 "Farmer-Crop FE")) xlabel(-2(1)2) xtitle("log(TFP)")  ///
		   graphregion(color(white)) bgcolor(white) lp(dash) bwidth(0.3) note("Kernel: gaussian" "Bandwidth: 0.3") kernel(gaussian)
	
	graph export "`figurename'_truncated.pdf", replace
	drop log_revenue_hat resid*
	
	// Construct droplist
	qui des `controls', varlist
	local droplist `r(varlist)' _cons 
	
	// Output table
	esttab ols instr_1 instr_2 instr_3 pds using "`filename'.tex", ///
		title(`title'\label{tab:`ref'}) ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		stats(toposeq soil_indicator weather_indicator sdo_fe_indicator ld_fe_indicator DEPMEAN R_SQ Z Z_SELECTED N FARMER, fmt(a2) label("Toposequence" "Soil quality controls" "Weather controls" "Subdivisional effects" "Plot size effects" "Mean dep. var" "$\text{R}^2$" "Candidate instruments" "Instruments Selected" "N" "Farmers")) ///
		mtitles("OLS" "2SLS" "2SLS" "2SLS" "IV-PDS") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		addnotes("Standard errors clustered at the farmer level") ///
		drop(`droplist') 
end

	


