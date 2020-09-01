*! Unreleased/Untagged beta Yashaswi Mohanty 19aug2019
*! Stata 15.0 and later
program define lasso_iv_first
	syntax varname, ///
	controls(varlist) filename(string) frac(varlist) rock(varlist) ///
	aquifers(varlist) main(varlist) large(varlist)
	
	// 2SLS -- Fractures
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`frac') ///
		eststo("fractures_estimates") method("2sls")
		
	// PDS -- Rocks
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`rock') ///
		eststo("rocks_estimates")
		
	// PDS -- Aquifers
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`aquifers') ///
		eststo("aquifers_estimates")
		
	// PDS -- Main
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`main') ///
		eststo("main_estimates")
		
	// PDS -- Large
	_lasso_iv_first `varlist', endog(farmer_well_depth) controls(`controls') ivset(`large') ///
		eststo("large_estimates")
		
	// Output sparse table (matrix only)
	estout fractures_estimates rocks_estimates aquifers_estimates main_estimates large_estimates using "`filename'_inner.tex" , ///
		label style(tex) ///
		stats(fractures_coeff rock_shares_coeff rock_types_coeff aquifer_types_coeff fractures_squared_coeff rock_shares_squared_coeff fractures_rock_shares_coeff frac_sq_rock_coeff frac_rock_sq_coeff all_squared_coeff SPACE RMSE F_STAT Z Z_SELECTED FARMERS N, fmt(a2) label("Fractures" "Rock shares" "Rock types" "Aquifer types" "$\text{Fractures}^2$" "$\text{Rock shares}^2$" "$\text{Fractures} \times \text{Rock shares}$" "$\text{Fractures}^2 \times \text{Rock shares}$" "$\text{Fractures} \times \text{Rock shares}^2$" "$\text{Fractures}^2 \times \text{Rock shares}^2$" " " "RMSE" "F" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops" )) ///
		replace mlabels(none) collabels(none) drop(slope elevation _Isd* _Ild* _cons farmer_well_depth)
	
	
end
