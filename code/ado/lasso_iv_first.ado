*! Unreleased/Untagged beta Yashaswi Mohanty 19aug2019
*! Stata 15.0 and later
program define lasso_iv_first
	syntax varname, ///
	controls(varlist) filename(string) frac(varlist) rock(varlist) ///
	aquifers(varlist) main(varlist) large(varlist) cluster(varlist) [slides]
		
	// 2SLS -- Fractures
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`frac') ///
		eststo("fractures_estimates") method("2sls") cluster(`cluster')
		
	// PDS -- Rocks
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`rock') ///
		eststo("rocks_estimates") cluster(`cluster')
		
	// PDS -- Aquifers
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`aquifers') ///
		eststo("aquifers_estimates") cluster(`cluster')
		
	// PDS -- Main
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`main') ///
		eststo("main_estimates") cluster(`cluster')
		
	// PDS -- Large
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`large') ///
		eststo("large_estimates") cluster(`cluster')
	
	// Construct droplists
	estimates restore fractures_estimates
	local frac_coeff `e(NAMES_SELECTED)'
	
	estimates restore rocks_estimates
	local rocks_coeff `e(NAMES_SELECTED)'
	
	estimates restore aquifers_estimates
	local aquifers_coeff `e(NAMES_SELECTED)'
	
	estimates restore main_estimates
	local main_coeff `e(NAMES_SELECTED)'
	
	estimates restore large_estimates
	local large_coeff `e(NAMES_SELECTED)'
	
	qui des _Isd* _Ild* prop_sufficient_* prop_high_* prop_med_* prop_acidic prop_mildly_alkaline missing_soil_controls, varlist
	
	if "`slides'" == "" {
		local droplist `frac_coeff' `aquifers_coeff' `rocks_coeff' `main_coeff' `large_coeff' slope elevation `r(varlist)' _cons
		
		// Output sparse table (matrix only)
		estout fractures_estimates rocks_estimates aquifers_estimates main_estimates large_estimates using "`filename'_inner.tex" , ///
			label style(tex) ///
			stats(fractures_coeff rock_shares_coeff rock_types_coeff aquifer_types_coeff fractures_squared_coeff rock_shares_squared_coeff fractures_rock_shares_coeff frac_sq_rock_coeff frac_rock_sq_coeff all_squared_coeff SPACE RMSE F_STAT Z Z_SELECTED FARMERS N, fmt(a2) label("Fractures" "Rock shares" "Rock types" "Aquifer types" "$\text{Fractures}^2$" "$\text{Rock shares}^2$" "$\text{Fractures} \times \text{Rock shares}$" "$\text{Fractures}^2 \times \text{Rock shares}$" "$\text{Fractures} \times \text{Rock shares}^2$" "$\text{Fractures}^2 \times \text{Rock shares}^2$" " " "RMSE" "F" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
			replace mlabels(none) collabels(none) drop(`droplist')
	}
	else {
		// Remove fractures coefficients from other coefficient sets
		local aquifers_coeff: list aquifer_coeff - frac_coeff
		local rocks_coeff: list rocks_coeff - frac_coeff
		local main_coeff: list main_coeff - frac_coeff
		local large_coeff: list large_coeff - frac_coeff

		// Construct droplist without dropping fractures estimates
		local droplist `aquifers_coeff' `rocks_coeff' `main_coeff' `large_coeff' slope elevation `r(varlist)' _cons
		
		// Output sparse table (matrix only)
		estout fractures_estimates rocks_estimates aquifers_estimates main_estimates large_estimates using "`filename'_`slides'_inner.tex" , ///
			cells(b(star fmt(a2)) se(par fmt(a2))) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.01) ///
			label style(tex) ///
			stats( rock_shares_coeff rock_types_coeff aquifer_types_coeff foi_coeff soi_coeff SPACE RMSE F_STAT Z Z_SELECTED FARMERS N, fmt(a2) label("Rock shares" "Rock types" "Aquifer types" "First-order interactions" "Second-order interactions" " " "RMSE" "F" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
			replace mlabels(none) collabels(none) drop(`droplist')
	}
	
	
end
