/*******************************************************************************
Purpose: Generate data for input into dynamic model.

Author: Viraj Jorapur (modified by Yashaswi Mohanty)

Date: 20 December, 2019
*******************************************************************************/

// ========================= PREAMBLE ==========================================	
if c(mode) == "batch" {
	local PROJECT_ROOT =strrtrim("`0'")	
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


// Use the cleaned version of the data
	
use "`CLEAN_FARMER_SURVEY'/baseline_survey_farmer_crop_with_imputed_variables.dta", clear
drop SDO_num

	
// Only keeping the relevant variables for analysis

	forval x=1/4{
		egen year_dug`x' = ends(b7_3_2_surce_dug_yr_`x'), tail p(,) 
		destring(year_dug`x'), replace
		rename b7_3_3_surce_dpth_`x'_ft depth`x'
	}
	
	keep if resp_num == 1
	collapse (firstnm) sdo_feeder_code SDO depth* avg_source_depth year_dug* tot_water_liter b7_1_2_pmp_nmplte_cap_*_hp f2_3_4_* f2_3_6*, by(f_id)
	
	save "`WORKING_DATA'/baseline_dynamics_raw.dta", replace
	
	gen replacement_level = 0
	replace replacement_level = 1.74 if SDO == "Bansur"
	replace replacement_level = 0.99 if SDO == "Dug"
	replace replacement_level = 0.95 if SDO == "Hindoli"
	replace replacement_level = 2.3 if SDO == "Kotputli"
	replace replacement_level = 1.74 if SDO == "Mundawar"
	replace replacement_level = 0.95 if SDO == "Nainwa"
	replace replacement_level = tot_water_liter/replacement_level
	

	reshape long depth year_dug, i(f_id) j(number)
	drop if depth == .
	
	// Create figure of depth of wells dug by year by SDO
	preserve
	
	keep if year_dug >= 1990 & year_dug < 2017
	
	local plottype rline
	winsor depth, p(0.02) highonly gen(depth_wins)
	
	lpoly depth_wins year_dug, graphregion(color(white)) bgcolor(white) ysc(reverse) lineopts(lcolor(black) lpattern(dash) lwidth(0.5)) jitter(5) ///
		msymbol(circle_hollow) msize(0.8) mcolor(midblue) title("") bwidth(1) xtitle("Year") ytitle("Well depth (feet)") note("")
	graph export "`FIGURES'/fig_wells_dug_by_year.pdf", replace
	
	graph twoway (lpolyci depth year_dug if SDO == "Bansur", ciplot(`plottype') clcolor(red)) (lpolyci depth year_dug if SDO == "Dug",ciplot(`plottype') clcolor(blue)) ///
				(lpolyci depth year_dug if SDO == "Hindoli", ciplot(`plottype') clcolor(orange)) (lpolyci depth year_dug if SDO == "Kotputli", ciplot(`plottype') clcolor(green)) ///
				(lpolyci depth year_dug if SDO == "Mundawar", ciplot(`plottype') clcolor(brown)) (lpolyci depth year_dug if SDO == "Nainwa", ciplot(`plottype') clcolor(black)), ysc(reverse) ytitle("Well depth (feet)") xtitle("Year") graphregion(color(white)) bgcolor(white) ///
				legend(order(2 "Bansur" 4 "Dug" 6  "Hindoli" 8 "Kotputli" 10 "Mundawar" 12 "Nainwa"))
	graph export "`FIGURES'/wells_dug_by_year_by_sdo.pdf", replace
	
	
	
	// Generate depth matrix for estimating the law of motion
	keep f_id year_dug depth
	sort f_id year_dug depth
	order f_id year_dug depth
	export delimited "`WORKING_DATA'/depth_data.txt", replace
	
	restore
	
	
	sum sdo_feeder_code
	
	encode SDO, gen(SDO_code)
	reg depth c.year_dug##i.SDO_code
	
	
	// ~~~~~~~~~~~~~~~~~~ Calculating the gamma_W and gamma_R: SDO by SDO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	preserve 
	
	// Create two groups of years to estimate the parameters of the water low of motion
	gen year_group = 0 if year_dug > 2000  & year_dug < 2010
	replace year_group = 1 if year_dug >= 2010
	
	gen year_0 = year_dug if year_group == 0
	gen year_1 = year_dug if year_group == 1 
	
	unab pumps: b7_1_2_pmp_nmplte_cap_*_hp
	egen mean_pump_capacity_farmer = rowmean(`pumps')
	
	bysort sdo_feeder_code: egen P = mean(mean_pump_capacity_farmer)
	bysort sdo_feeder_code: egen Wt = mean(tot_water_liter)
	bysort sdo_feeder_code: egen Rt = mean(replacement_level)
	bysort sdo_feeder_code year_group: egen Dt = mean(depth)
	
	
	gen Dt1 = .
	replace Dt1 = Dt if year_group == 1
	replace Dt = . if year_group == 1
	
	la var Dt1 "\$ D_{t+1} \$"
	la var Dt  "\$ D_t \$"
	
	// Export time series by SDO for MATLAB parameter estimation exercise
	tempfile estimation by_sdo
	save `estimation', replace
	collapse Dt Dt1, by(SDO)
	drop SDO
	save `by_sdo', replace
	use `estimation', clear
	collapse Dt Dt1
	append using `by_sdo'
	// export delimited "`WORKING_DATA'/depth_matrix.txt", novarnames replace
	use `estimation', clear
	
	
	sort f_id sdo_feeder_code

	collapse (mean) Dt1 Dt Rt Wt P f2_3_6_hours_per_day_1 year_0 year_1 (firstnm) SDO SDO_code, by(sdo_feeder_code)
	
	gen delta_D = Dt1 - Dt
	replace delta_D = delta_D/(year_1 - year_0)
	la var delta_D "\$\Delta D_t\$"
	
	gen time_diff = year_1 - year_0
	tabstat time_diff, by(SDO)
	
	gen water_regen = Wt - Rt
	la var water_regen "\$ W_t - R_t \$"
	
	la var Rt "\$ R \$"
	la var Wt "\$ W_t \$"
	
	drop if missing(delta_D)
	
	local sdo Bansur Dug Hindoli Kotputli Mundawar Nainwa
	
	// Define value labels for each SDO code
	label define sdo_code_label 1 "Bansur" 2 "Dug" 3 "Hindoli" 4 "Kotputli" 5 "Mundawar" 6 "Nainwa"
	label values SDO_code sdo_code_label
	
	// Tabulate the depths by SDO
	estpost tabstat Dt1 Dt, by(SDO) statistics(mean)
	eststo sum_stats
	esttab sum_stats using "`TABLES'/tab_depth_by_sdo.tex", ///
		title("Average depths by SDO\label{tab:DepthBySDO"}) ///
		cells("Dt(label(\$ D_t \$) fmt(a2)) Dt1(label(\$ D_{t+1} \$) fmt(a2))") label nonumbers replace ///
		booktabs noobs ///
		subs("\_" "_" "\$" "$") /// 
		postfoot("\bottomrule" ///
				 "\multicolumn{3}{p{0.3\hsize}}{\footnotesize This table reports the average depths (in feet) of wells dug by sampled farmers in each of the six subdivisional offices in two different periods. \$ D\_{t}$ denotes the average depth of wells dug between 2000 and 2010. \$ D\_{t+1}$ denotes the average depth of wells dug between 2010 and 2017. The average time difference between wells dug in these two periods is 7.5 years.}" ///
				 "\end{tabular}" ///
				 "\end{table}")
	
	
	//~~~~~~~~~~~~~~ Estimating the law of motion ~~~~~~~~~~~~~~
	
	// Estimating the law of motion without an explicit replacement term
	reg delta_D Wt
	eststo spec_1
	
	reg delta_D water_regen, nocons
	eststo spec_2
	gen gamma = _b[water_regen]
	
	reg delta_D water_regen 
	eststo spec_3
	
	reg delta_D c.water_regen##i.SDO_code
	eststo spec_4
	
	reg delta_D Wt Rt, nocons
	eststo spec_5
	
	esttab spec_2 spec_3 spec_1  spec_5 using "`TABLES'/gamma_parameter_estimates_sdo.tex", ///
		title("Estimating the parameters of the groundwater law of motion") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		label nogaps nomtitles ///
		addnotes("Date run: `c(current_date)'") ///
		subs("\_" "_" "\$" "$") ///
		cons noomit ///
		postfoot("\bottomrule" ///
				"\multicolumn{5}{p{0.7\hsize}}{\footnotesize This table reports coefficients from estimating the groundwater law of motion of the dynamic model. The dependent variable is the difference in average well depth of wells dug between 2000-2010 and wells dug after 2010. The specification of the law of motion varies by column: the baseline model reported in column (1) estimates Eq \eqref{eq:LawMotion} for our entire sample. In column (2), we include an additive constant term with the specification in column (1). In column (3), we absorb the effect of the recharge rate into a constant term rather than using values provided by the CGWB. Finally, in column (4), we estimate separate coefficients for both extraction and recharge."} ///
				"\end{tabular}" ///
				"\end{table}") ///
		//drop(1.SDO_code)
	
	// Store the value of gamma as a MATLAB input
	keep gamma
	duplicates drop
	export delimited using "`WORKING_DATA'/gamma.txt", novarnames replace
		
	restore
	
	// ~~~~~~~~~~~~~~~ Estimate \tilde{rho} ~~~~~~~~~~~~~~~~~
	// Generate the mean of pump capacity for a given farmer
	unab pumps: b7_1_2_pmp_nmplte_cap_*_hp
	egen mean_pump_capacity_farmer = rowmean(`pumps')
	replace mean_pump_capacity_farmer = mean_pump_capacity_farmer/1.341
	
	// Turn depth to meters
	
	// Collapse data to farmer level
	collapse (mean) mean_pump_capacity_farmer depth (firstnm) SDO tot_water_liter ///
		replacement_level, by(f_id)
		
	// Generate rho_tilde
	gen rho_tilde = tot_water_liter*depth/(42*6*mean_pump_capacity_farmer)
	
	// Collapse data to SDO level
	preserve 
	
	// Store SDO exogenous variables as MATLAB input
	collapse (mean) depth mean_pump_capacity tot_water_liter rho_tilde, by(SDO)
	gen rho_tilde_bar = tot_water_liter*depth/(42*6*mean_pump_capacity_farmer)
	drop SDO
	export delimited using "`WORKING_DATA'/sdo_initial_conditions.txt", replace
	restore
	
	// Heterogenous initial conditions
	preserve 
	collapse (mean) depth mean_pump_capacity, by(f_id)
	keep f_id depth mean_pump_capacity
	order f_id depth mean_pump_capacity
	export delimited depth mean_pump_capacity using "`WORKING_DATA'/het_init_conditions.txt", replace
	restore
	
	// Store sample-wide exogenous variables as MATLAB input 
	collapse (mean) depth mean_pump_capacity 
	// gen rho_tilde_bar = tot_water_liter*depth/(42*6*mean_pump_capacity_farmer)
	export delimited using "`WORKING_DATA'/mean_init_conditions.txt", replace
	
	
	
	
	

	




	
	
	
	
