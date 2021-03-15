* Main model estimation and table output
program define main_lasso_iv
	syntax varname [if] [in], ///
	controls(varlist)  cluster(varlist) ///
	small_ivset(varlist) large_ivset(varlist) filename(string) [ noplotfe ] [ nocrop ] [ title(string) ] ///
	[ weight(varlist) ] [ force_controls(varlist) ] [ feethundreds ] [ conley ]
	
	
	// Create table title
	if "`varlist'" == "yield"  {
		local title "Yield (bushels/Ha) on groundwater depth"
	}
	else if "`varlist'" == "profit_cash_wins" {
		local title "Profit (Rs/Ha, reported) on groundwater depth"
	}
	else if "`varlist'" == "profit_cashwown_wins" {
		local title "Profit (Rs/ha, cash reported plus own consumption) on groundwater depth" 
	}
	else if "`varlist'" == "revenue" {
		local title "Value of output  (Rs/ha) on groundwater depth"
	}
	else {
		local title "`title'"
	}
	
	// Scale farmer well depth to hundreds of feet to make coefficients larger
	if "`feethundreds'" != "" {
		replace farmer_well_depth = farmer_well_depth/100
		la var farmer_well_depth "Farmer well depth ('00 ft)"
		local title "`title' ('00 feet)"
	}
	
	if "`plotfe'" == "noplotfe" {
		qui des _Ild*, varlist
		local ild_fe `r(varlist)'
		local controls: list controls - ild_fe
	}
	if "`weight'" == "" {
		// Estimate OLS, no controls
		_reg_ols `varlist', regressors(farmer_well_depth) controls(`force_controls') ///
			eststo("ols_no_controls") cluster(`cluster') `conley' 
		
		// Estimate OLS, all controls and fixed effects
		_reg_ols `varlist', regressors(farmer_well_depth) controls(`controls' `force_controls') ///
			eststo("ols_controls") cluster(`cluster') `conley' 
			
		// Estimate IV-PDS (Small instrument set)
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls' `force_controls') ///
			ivset(`small_ivset') pnotpen(`controls' `force_controls') eststo("small") cluster(`cluster') `conley' 
			
		// Estimate IV-PDS (Large instrument set)
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls' `force_controls') ///
			ivset(`large_ivset') pnotpen(`controls' `force_controls') eststo("large") cluster(`cluster') `conley'
	}
	else {
		// Estimate OLS, no controls
		_reg_ols `varlist', regressors(farmer_well_depth) controls(`force_controls') ///
			eststo("ols_no_controls") weight(`weight') cluster(`cluster') `conley'
		
		// Estimate OLS, all controls and fixed effects
		_reg_ols `varlist', regressors(farmer_well_depth) controls(`controls' `force_controls') ///
			eststo("ols_controls") 	weight(`weight') cluster(`cluster') `conley'
			
		// Estimate IV-PDS (Small instrument set)
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls' `force_controls') ///
			ivset(`small_ivset') pnotpen(`controls' `force_controls') eststo("small") weight(`weight') cluster(`cluster') `conley'
			
		// Estimate IV-PDS (Large instrument set)
		_lasso_iv `varlist', endog(farmer_well_depth) controls(`controls' `force_controls') ///
			ivset(`large_ivset') pnotpen(`controls' `force_controls') eststo("large") weight(`weight') cluster(`cluster') `conley'
	}
	
	
	// Reverse rescaling operation
	if "`feethundreds'" != "" {
		replace farmer_well_depth = farmer_well_depth*100
		la var farmer_well_depth "Farmer well depth (ft)"
	}
	
	// Construct droplist
	qui des `force_controls' prop_high_* prop_med_* missing_soil_controls prop_sufficient_* prop_acidic prop_mildly_alkaline _Isd* _Ild*, varlist
	local droplist `r(varlist)' _cons elevation slope 
	
	if "`plotfe'" == "noplotfe" {
		local droplist: list droplist - ild_fe
	}
	
	
	di "`droplist'"
	
	if "`conley'" == "" {
		
		// Get std of well depth
		qui sum farmer_well_depth
		local std = r(sd)
		
		// Output sparse table (matrix only)
		estout ols_no_controls ols_controls small large using "`filename'_inner.tex" , ///
			cells(b(star fmt(a2)) se(par fmt(a2)) ) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.01) label style(tex) ///
			stats(toposeq soil_indicator sdo_fe_indicator ld_fe_indicator SPACE DEPMEAN Z Z_SELECTED FARMER N, fmt(a2) label("Toposequence" "Soil quality controls"  "Subdivisional effects" "Plot size effects" "  " "Mean dep. var" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
			replace mlabels(none) collabels(none) drop(`droplist') transform( `std'*@ `std')

		// Output tables
		esttab ols_no_controls ols_controls small large using "`filename'.tex", ///
			title(`title') ///
			b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
			stats(toposeq soil_indicator sdo_fe_indicator ld_fe_indicator DEPMEAN N FARMER Z Z_SELECTED, fmt(a2) label("Toposequence" "Soil quality controls" "Subdivisional effects" "Plot size effects" "Mean dep. var" "N" "Farmers" "Candidate Instruments" "Instruments Selected")) ///
			mtitles("OLS" "OLS" "IV-PDS (Main)" "IV-PDS (Large)") ///
			alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
			addnotes( "Standard errors clustered at the feeder level") ///
			drop(`droplist') //transform( `std'*@ `std')
	}		

	else {
		
		local consta _cons
		local droplist: list droplist - consta
		local consta constant
		local droplist: list droplist | consta
		
		// Get std of well depth
		qui sum farmer_well_depth
		local std = r(sd)
		
		// Output sparse table (matrix only)
		estout ols_no_controls ols_controls small large using "`filename'_inner_spatial.tex" , ///
			cells(b(star fmt(a2)) se(par fmt(a2)) V_2(par fmt(a2)) V_3(par fmt(a2))) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.01) label style(tex) ///
			stats(toposeq soil_indicator sdo_fe_indicator ld_fe_indicator SPACE DEPMEAN Z Z_SELECTED FARMER N, fmt(a2) label("Toposequence" "Soil quality controls"  "Subdivisional effects" "Plot size effects" "  " "Mean dep. var" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
			replace mlabels(none) collabels(none) drop(`droplist') transform( `std'*@ `std' )

		// Output tables
		esttab ols_no_controls ols_controls small large using "`filename'_spatial.tex", ///
			title(`title') ///
			cells(b(star fmt(a2)) se(par fmt(a2)) V_10(par fmt(a2)) V_20(par fmt(a2)))star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
			stats(toposeq soil_indicator sdo_fe_indicator ld_fe_indicator DEPMEAN N FARMER Z Z_SELECTED, fmt(a2) label("Toposequence" "Soil quality controls" "Subdivisional effects" "Plot size effects" "Mean dep. var" "N" "Farmers" "Candidate Instruments" "Instruments Selected")) ///
			mtitles("OLS" "OLS" "IV-PDS (Main)" "IV-PDS (Large)") ///
			alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
			addnotes( "Standard errors adjusted for spatial correlation with bandwidths at 5, 10 and 20 kms.") ///
			drop(`droplist') transform( `std'*@ `std' )
	}
		
		
		
	
end
