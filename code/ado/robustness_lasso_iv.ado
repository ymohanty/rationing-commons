*! Unreleased/Untagged beta Yashaswi Mohanty 19aug2019
*! Stata 15.0 and later
* IV-PDS estimates and tables for robustness tables
program define robustness_lasso_iv 
	syntax varlist, ///
	controls(varlist) frac(varlist) rock(varlist) ///
	frac_rock(varlist) main(varlist) ///
	large(varlist) filename(string) cluster(varlist) [ pnotpen(varlist) ] [ title(string) ] [ method(string) ]
	
	if "`method'" ==  "" {
		local method "pds"
	}
	
	// Create table title
	if "`varlist'" == "yield"  {
		local title "Yield (bushels/ha) on farmer well depth"
	}
	else if "`varlist'" == "profit_cash_wins" {
		local title "Cash Profit (Rs/ha, reported) on farmer well depth"
	}
	else if "`varlist'" == "profit_cashwown_wins" {
		local title "Total Profit (Rs/ha) on farmer well depth" 
	}
	else if "`varlist'" == "revenue_perha"{
		local title "Total Value of Output (Rs/ha) on farmer well depth"
	}

	
	// Create title in footnote
	if "`varlist'" == "yield"  {
		local ftitle "yield (bushels/ha)"
	}
	else if "`varlist'" == "profit_cash_wins" {
		local ftitle "cash profit (Rs/ha)"
	}
	else if "`varlist'" == "profit_cashwown_wins" {
		local ftitle "total profit (Rs/ha)" 
	}
	else if "`varlist'" == "revenue_perha" {
		local ftitle "total value of output (Rs/ha)"
	}
	
	// Estimate smallest instrument set with 2SLS
	_ivreg `varlist', endog(farmer_well_depth) controls(`controls') ///
		ivset(`frac') eststo("frac") cluster(`cluster')
	
	
	if "`pnotpen'" == "" {
		
		// Varying the instrument set
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`rock') eststo("rock") cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`frac_rock') eststo("frac_rock") cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`main') eststo("main") cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`large') eststo("large") cluster(`cluster') method(`method')
			
		// Varying the controls 
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd*) ///
			ivset(`main') eststo("controls_1") cluster(`cluster') method(`method')
			
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd* _Ild*) ///
			ivset(`main') eststo("controls_2") cluster(`cluster') method(`method')
			
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd* _Ild* slope elevation) ///
			ivset(`main') eststo("controls_3") cluster(`cluster') method(`method')
			
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`main') eststo("controls_4") cluster(`cluster') method(`method')

	}
	else {
		
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`rock') eststo("rock") pnotpen(`pnotpen') cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`frac_rock') eststo("frac_rock") pnotpen(`pnotpen') cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`main') eststo("main") pnotpen(`pnotpen') cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls') ///
			ivset(`large') eststo("large") pnotpen(`pnotpen') cluster(`cluster') method(`method')
			
		// Varying the controls 
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd*) ///
			ivset(`main') eststo("controls_1") pnotpen(_Isd*) cluster(`cluster') method(`method')
			
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd* _Ild*) ///
			ivset(`main') eststo("controls_2") pnotpen(_Isd* _Ild*) cluster(`cluster') method(`method')
			
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd* _Ild* slope elevation) ///
			ivset(`main') eststo("controls_3") pnotpen(_Isd* _Ild* slope elevation) cluster(`cluster') method(`method')
			
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd* _Ild* slope elevation prop_sufficient_* ///
							prop_high_* prop_med_* prop_acidic prop_mildly_alkaline missing_soil_controls) ///
			ivset(`main') eststo("controls_4") pnotpen(_Isd* _Ild* slope elevation prop_sufficient_* ///
							prop_high_* prop_med_* prop_acidic prop_mildly_alkaline missing_soil_controls) cluster(`cluster') method(`method')
		
		_lasso_iv `varlist', endog(farmer_well_depth) controls(_Isd* _Ild* slope elevation prop_sufficient_* ///
							prop_high_* prop_med_* prop_acidic prop_mildly_alkaline missing_soil_controls temp_rabi_* ) ///
			ivset(`main') eststo("controls_5") pnotpen(_Isd* _Ild* slope elevation prop_sufficient_* ///
							prop_high_* prop_med_* prop_acidic prop_mildly_alkaline missing_soil_controls temp_rabi_*) cluster(`cluster') method(`method')

	
	}
	
	// Check if fixed effects are in controls
	qui des _Isd*, varlist
	local sdo `r(varlist)'
	qui des _Ild*, varlist
	local ld `r(varlist)'
	local sdo_fe : list sdo in controls // Look for SDO fixed effects
	local ld_fe : list ld in controls // Look for decile fixed effects
	
	
	// Construct droplist
	if `sdo_fe' == 1 & `ld_fe' == 1 {
		local droplist `sdo' `ld'
	}
	else if `sdo_fe' == 1 & `ld_fe' == 0 {
		local droplist `sdo'
	}
	else if `sdo_fe' == 0 & `ld_fe' == 1 {
		local droplist `ld'
	}
	else {
		local droplist ""
	}
	
	// Get standard deviation of well depth
	qui sum farmer_well_depth
	local std = r(sd)
	
	// Create sparse output table
	estout frac rock frac_rock main large using "`filename'_inner.tex" , ///
		cells(b(star fmt(a2)) se(par fmt(a2))) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.01) label style(tex) ///
		stats( SPACE DEPMEAN Z Z_SELECTED FARMER N, fmt(a2) label("  " "Mean dep. var" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
		replace mlabels(none) collabels(none) drop(`controls' _cons) transform( `std'*@ `std')
		
	// Create sparse output table for controls based robustness exercize
	estout controls_1 controls_2 controls_3 controls_4 controls_5 using "`filename'_controls_inner.tex" , ///
		cells(b(star fmt(a2)) se(par fmt(a2))) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.01) label style(tex) ///
		stats(sdo_fe_indicator ld_fe_indicator toposeq soil_indicator weather_indicator   SPACE DEPMEAN Z Z_SELECTED FARMER N, fmt(a2) label("Subdivisional effects" "Plot size effects" "Toposequence" "Soil quality controls" "Temperature"   "  " "Mean dep. var" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
		replace mlabels(none) collabels(none) drop(_Isd* _Ild* _cons elevation slope `controls' temp_rabi_* _cons) transform( `std'*@ `std')
		
	// Create output table for controls based robustness exercize
	esttab controls_1 controls_2 controls_3 controls_4 using "`filename'_controls.tex", ///
		title(`title') ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		mtitles("IV-PDS" "IV-PDS" "IV-PDS" "IV-PDS") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		addnotes("Date Run: `c(current_date)' " "Standard errors clustered at the farmer level") ///
		drop(`droplist')  transform( `std'*@ `std')
	
	// Create output
	esttab frac rock frac_rock main large  ///
		using "`filename'.tex", ///
		title(`title') ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		stats (SPACE DEPMEAN Z Z_SELECTED FARMER N , fmt(a2) label(" " "Mean dep. var"  "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops")) ///
		nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{IV-2SLS}&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}\\" ///
				"\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" ///
				"&\multicolumn{1}{c}{Fractures}&\multicolumn{1}{c}{Rock}&\multicolumn{1}{c}{Aquifers}&\multicolumn{1}{c}{Main}&\multicolumn{1}{c}{Large}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\midrule \\") ///
		prefoot(" ") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		postfoot("\bottomrule" ///
				 "\multicolumn{6}{p{\hsize}}{\footnotesize This table shows instrumental variable regressions of `ftitle' on farmer well depth.  The data is from the main agricultural household survey and the observations are at the farmer-by-crop level. All the model specifications control for the toposequence (elevation and slope), along with subdivisional and plot size effects, as defined in Table \ref{tab:ivProfitsDepth}. The set of candidate instruments changes by column; the definitions of different instrument sets used in the model specifications above can be found in Table \ref{tab:instruments}. Standard errors are clustered at the farmer level, at which well depth varies. The statistical significance of a coefficient at certain thresholds is indicated by  \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.} \\" ///
				 "\end{tabular*}" ///
				"\end{table}") ///
		drop(`droplist' _cons elevation slope `controls') transform( `std'*@ `std') ///
			 
	
	
	

end
