
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//					Marginal Analysis: Summary Statistics
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//======================= SUMMARY STATS FOR MAIN SAMPLE ========================

// Panel A: Farmer level characteristics
preserve


bys f_id: gen numcrops = _N
collapse (firstnm) numcrops (mean) pump_farmer (firstnm) farmer_well_depth, by(f_id)

la var numcrops "Crops grown (number)"
la var pump_farmer "Pump capacity (HP, total)"
la var farmer_well_depth "Well depth (feet)"

eststo clear
qui estpost sum numcrops pump_farmer farmer_well_depth, detail

estout using "`TABLES'/farmer_characteristics.tex", cells("mean(fmt(a2)) sd(fmt(a2)) p25(fmt(a2)) p50(fmt(a2)) p75(fmt(a2)) count(fmt(a2))") ///
		label style(tex) mlabels(none) collabels(none) replace

restore

// Panel B: Farmer crop output and profit
eststo clear
qui estpost sum yield output revenue_perha_t  profit_cash_t profit_total_t profit_total_nrega_wage_t, detail

estout using "`TABLES'/ag_output.tex", cells("mean(fmt(a2)) sd(fmt(a2)) p25(fmt(a2)) p50(fmt(a2)) p75(fmt(a2)) count(fmt(a2))") ///
		label style(tex) mlabels(none) collabels(none) replace
		
// Panel C: Farmer Crop input quantities
eststo clear
qui estpost sum land water labour, detail


estout using "`TABLES'/ag_input_quantity.tex", cells("mean(fmt(a2)) sd(fmt(a2)) p25(fmt(a2)) p50(fmt(a2)) p75(fmt(a2)) count(fmt(a2))") ///
		label style(tex) mlabels(none) collabels(none) replace
		
// Panel D: Farmer crop input expenditures
eststo clear
qui estpost sum capital labour_rupees elec_exp_sub_irr, detail

estout using "`TABLES'/ag_input_exp.tex", cells("mean(fmt(a2)) sd(fmt(a2)) p25(fmt(a2)) p50(fmt(a2)) p75(fmt(a2)) count(fmt(a2))") ///
		label style(tex) mlabels(none) collabels(none) replace
		

// All together	
eststo clear
qui estpost sum yield revenue profit_cash_wins profit_cashwown_wins profit_consumption_wins farmer_well_depth ///
	water labour land capital ///
	water_requirement prop_area_sprinkler water_hardy share_value_output_sold, detail
	
esttab using "`TABLES'/paper_summary_stats.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Summary Statistics\label{tab:sumstats}") ///
		booktabs noobs nonumbers label replace ///
		refcat(yield "\textbf{\emph{Outcome variables}}" water "\textbf{\emph{Production inputs}}" water_requirement "\textbf{\emph{Margins of adaptation}}", nolabel) ///
		noisily

eststo clear
estpost sum farmer_well_depth yield profit_cash_wins profit_cashwown_wins revenue, detail

esttab using "`TABLES'/profit_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: Cash Profits and Well Depth") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'")
	
	
// Pump capacity and depth
la var pump_farmer_plot "Plot pump capacity (HP)"
gen pump_by_depth = pump_farmer_plot/farmer_well_depth
la var pump_by_depth "Pump capacity per unit well depth (HP/feet)"
qui estpost sum farmer_well_depth pump_farmer_plot pump_by_depth, detail
esttab using "`TABLES'/depth_pump_capacity_reduced_form.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Depth and pump capacity (reduced form sample)") ///
		booktabs noobs nonumbers label replace 
	
//=============================== PAPER FACTS ==================================

// Average number of crops
qui unique f_id
gen avg_plot_num = r(N)/r(unique)

sum avg_plot_num


//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Proceed with cleaned data
// use baseline_profits_instruments

// TEMP
drop if missing(d1_tot_land, b7_3_3_avg_surce_dpth)
	
// Generating proportion of formal land (pakka land)
destring d2_tot_pakka d2_tot_land, replace force
gen d2_formal_land = 100*d2_tot_pakka/d2_tot_land
la var d2_formal_land "Formal land (percent)" 

// Destring profit and yield variables
	
// Generating land deciles
xtile land_decile = d1_tot_land, nq(10)
	
// Create dummies for SDO and land decile effects
xi, prefix(_Ild) noomit i.land_decile
drop _Ildland_de_1

// tab sdoy
// xi, prefix(_Isd) noomit i.sdoy
// drop _Isdsdoy_1

tab sdo
xi, prefix(_Isd) noomit i.sdo
drop _Isdsdo_1


//====================== SOIL CONTROLS SPECIFICATIONS ==========================

sum *_pH

sum *_N
sum *_P
sum	*_K

//~~~~~~~~~~~~~ pH based controls ~~~~~~~~~~~~~~~~'
// Fix missing suplur proportions
replace Tot_S = . if Tot_S == 0

// Generate missing indicator
gen missing_soil_controls = 1 if missing(AS_pH) | missing(Tot_S)
replace missing_soil_controls = 0 if missing(missing_soil_controls)
la var missing_soil_controls "Missing soil controls"

// Aggregate acidic (including neutral)
egen acidic_pH = rowtotal(AS_pH *Ac_pH SrAC_pH N_pH)
gen prop_acidic = acidic_pH/Tot_pH
la var prop_acidic "Prop. farmers with acidic soil"
gen prop_mildly_alkaline = MAl_pH/Tot_pH
la var prop_mildly_alkaline "Prop. farmers with mildly alkaline soil"
gen prop_strongly_alkaline = SlAl_pH/Tot_pH
la var prop_strongly_alkaline "Prop. farmers with strongly alkaline soil"

// Aggregate potassium
egen low_k= rowtotal(VL_K L_K)
gen prop_low_k = low_k/Tot_K
// la var prop_low_k "Prop. farmers with low potassium in soil"
la var prop_low_k "Prop. low potassium"
egen high_k = rowtotal(VH_K H_K)
gen prop_high_k = high_k/Tot_K
// la var prop_high_k "Prop. farmers with high potassium in soil"
la var prop_high_k "Prop. high potassium"
gen prop_med_k = M_K/Tot_K
la var prop_med_k "Prop. farmers with medium potassium in soil"

// Aggregate phosphorus
egen low_p = rowtotal(VL_P L_P)
gen prop_low_p = low_p/Tot_P
// la var prop_low_p "Prop. farmers with low phosphorus in soil"
la var prop_low_p "Prop. low phosphorus"
egen high_p = rowtotal(VH_P H_P)
gen prop_high_p = high_p/Tot_P
// la var prop_high_p "Prop. farmers with high phosphorus in soil"
la var prop_high_p "Prop. high phosphorus"
gen prop_med_p = M_P/Tot_K
la var prop_med_p "Prop. farmers with medium phosphorus in soil"

// Sufficient deficient
gen prop_sufficient_s = S_S/Tot_S
// la var prop_sufficient_s "Prop. farmers with sufficient sulphur in soil"
la var prop_sufficient_s "Prop. sufficient sulphur"
gen prop_sufficient_zn = S_Zn/Tot_Zn
// la var prop_sufficient_zn "Prop. farmers with sufficient zinc in soil"
la var prop_sufficient_zn "Prop. sufficient zinc"
gen prop_sufficient_fe = S_Fe/Tot_Fe
// la var prop_sufficient_fe "Prop. farmers with sufficient iron in soil"
la var prop_sufficient_fe "Prop. sufficient iron"
gen prop_sufficient_cu = S_Cu/Tot_Cu
// la var prop_sufficient_cu "Prop. farmers with sufficient copper in soil"
la var prop_sufficient_cu "Prop. sufficient copper"
gen prop_sufficient_mn = S_Mn/Tot_Mn
// la var prop_sufficient_mn "Prop. farmers with sufficient manganese in soil"
la var prop_sufficient_mn "Prop. sufficient manganese"


// Summary stats
eststo clear
qui estpost sum prop_acidic prop_mildly_alkaline prop_strongly_alkaline missing_soil , detail
esttab using "`TABLES'/controls_ph.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Summary Statistics: Acidity\label{tab:sumstats}") ///
		booktabs noobs nonumbers label replace 
		
eststo clear
qui estpost sum prop_*_k, detail
esttab using "`TABLES'/controls_k.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Summary Statistics: Potassium\label{tab:sumstats}") ///
		booktabs noobs nonumbers label replace 
		

eststo clear
qui estpost sum prop_*_p, detail
esttab using "`TABLES'/controls_p.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Summary Statistics: Phosphorus\label{tab:sumstats}") ///
		booktabs noobs nonumbers label replace 
		
eststo clear
qui estpost sum prop_sufficient_*, detail
esttab using "`TABLES'/controls_other.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Summary Statistics: Other nutrients\label{tab:sumstats}") ///
		booktabs noobs nonumbers label replace 

// Replace missing controls to zeros
unab suff: prop_sufficient_*
unab high: prop_high_*
unab med: prop_med_*

local vars `suff' `high' `med' prop_acidic prop_mildly_alkaline

foreach var of local vars {
	replace `var' = 0 if missing_soil_controls == 1
}
			
// Generate soil control local		
local SOIL_CONTROLS prop_sufficient_* prop_high_* prop_med_* prop_acidic prop_mildly_alkaline missing_soil_controls
unab SOIL_CONTROLS_UNAB: `SOIL_CONTROLS'

// Correlating predicted groundwater depth with the soil controls


//~~~~~~~~~~~~ Validity of soil controls ~~~~~~~~~~~~~
eststo clear
reg profit_cashwown_wins `SOIL_CONTROLS'
eststo total_profit
estadd scalar R2 `e(r2_a)': total_profit
estadd scalar F_STAT `e(F)': total_profit
test `SOIL_CONTROLS_UNAB'
estadd scalar P `r(p)': total_profit

reg profit_cash_wins `SOIL_CONTROLS'
eststo cash_profit
estadd scalar R2 `e(r2_a)': cash_profit
estadd scalar F_STAT `e(F)': cash_profit
test `SOIL_CONTROLS_UNAB'
estadd scalar P `r(p)': cash_profit

reg yield `SOIL_CONTROLS' 
eststo yield
estadd scalar R2 `e(r2_a)': yield
estadd scalar F_STAT `e(F)': yield
test `SOIL_CONTROLS_UNAB'
estadd scalar P `r(p)': yield

reg revenue_perha `SOIL_CONTROLS'
eststo revenue
estadd scalar R2 `e(r2_a)': revenue
estadd scalar F_STAT `e(F)': revenue
test `SOIL_CONTROLS_UNAB'
estadd scalar P `r(p)': revenue

esttab total_profit cash_profit yield revenue using "`TABLES'/reg_profits_soil_controls.tex", ///
		title("Profits on soil quality controls") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		stats(R2 F_STAT P N, fmt("a2" "a2" "%12.2f" "a2") label("$\text{Adj. } R^2$" "F" "p-value" "Obs.")) nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}\\" ///
				"\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" ///
				"&\multicolumn{1}{c}{Total Profit}&\multicolumn{1}{c}{Cash Profit}&\multicolumn{1}{c}{Yield}&\multicolumn{1}{c}{Revenue}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\midrule \\") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		addnotes("Date Run: `c(current_date)' " "Standard errors clustered at the farmer level") ///
		drop(`droplist') 
		

		
		
//====================== Weather controls specifications =======================

//~~~~~~~~~~~~ validity of weather controls ~~~~~~~~~~~~~
local WEATHER_CONTROLS temp_rabi_*
la var temp_rabi_hdd "Heating degree-days"
la var temp_rabi_cdd "Cooling degree-days"
unab weather_controls_unab: `WEATHER_CONTROLS'

eststo clear
reg profit_cashwown_wins `WEATHER_CONTROLS'
eststo total_profit
estadd scalar R2 `e(r2_a)': total_profit
estadd scalar F_STAT `e(F)': total_profit
test `weather_controls_unab'
estadd scalar P `r(p)': total_profit

reg profit_cash_wins `WEATHER_CONTROLS'
eststo cash_profit
estadd scalar R2 `e(r2_a)': cash_profit
estadd scalar F_STAT `e(F)': cash_profit
test `weather_controls_unab'
estadd scalar P `r(p)': cash_profit

reg yield `WEATHER_CONTROLS' 
eststo yield
estadd scalar R2 `e(r2_a)': yield
estadd scalar F_STAT `e(F)': yield
test `weather_controls_unab'
estadd scalar P `r(p)': yield

reg revenue_perha `WEATHER_CONTROLS'
eststo revenue
estadd scalar R2 `e(r2_a)': revenue
estadd scalar F_STAT `e(F)': revenue
test `weather_controls_unab'
estadd scalar P `r(p)': revenue

esttab total_profit cash_profit yield revenue using "`TABLES'/reg_profits_weather_controls.tex", ///
		title("Profits on weather controls") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		stats(R2 F_STAT P N, fmt("a2" "a2" "%12.2f" "a2") label("$\text{Adj. } R^2$" "F" "p-value" "Obs.")) nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}\\" ///
				"\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" ///
				"&\multicolumn{1}{c}{Total Profit}&\multicolumn{1}{c}{Cash Profit}&\multicolumn{1}{c}{Yield}&\multicolumn{1}{c}{Revenue}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\midrule \\") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		addnotes("date run: `c(current_date)' " "standard errors clustered at the farmer level") ///
		drop(`droplist') 
		
// ~~~~~~~~~~~~~~~ weather controls + sdo fe ~~~~~~~~~~~~~~~~~~	
eststo clear
reg profit_cashwown_wins `WEATHER_CONTROLS' _Isd*
eststo total_profit
estadd scalar R2 `e(r2_a)': total_profit
estadd scalar F_STAT `e(F)': total_profit
test `weather_controls_unab'
estadd scalar P `r(p)': total_profit

reg profit_cash_wins `WEATHER_CONTROLS' _Isd*
eststo cash_profit
estadd scalar R2 `e(r2_a)': cash_profit
estadd scalar F_STAT `e(F)': cash_profit
test `weather_controls_unab'
estadd scalar P `r(p)': cash_profit

reg yield `WEATHER_CONTROLS' _Isd*
eststo yield
estadd scalar R2 `e(r2_a)': yield
estadd scalar F_STAT `e(F)': yield
test `weather_controls_unab'
estadd scalar P `r(p)': yield

reg revenue_perha `WEATHER_CONTROLS' _Isd*
eststo revenue
estadd scalar R2 `e(r2_a)': revenue
estadd scalar F_STAT `e(F)': revenue
test `weather_controls_unab'
estadd scalar P `r(p)': revenue

esttab total_profit cash_profit yield revenue using "`TABLES'/reg_profits_weather_controls_sdo.tex", ///
		title("Profits on weather controls with SDO fixed effects") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		stats(R2 F_STAT P N, fmt("a2" "a2" "%12.2f" "a2") label("$\text{Adj. } R^2$" "F" "p-value" "Obs.")) nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}\\" ///
				"\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" ///
				"&\multicolumn{1}{c}{Total Profit}&\multicolumn{1}{c}{Cash Profit}&\multicolumn{1}{c}{Yield}&\multicolumn{1}{c}{Revenue}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\midrule \\") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		addnotes("date run: `c(current_date)' " "standard errors clustered at the farmer level") ///
		indicate(Subdivisional effects = _Isd*)

 
// ================================ OPTIMAL RATION  =============================

// Calculate  mean depth and mean hours of use
egen mean_well_depth = mean(farmer_well_depth)
egen mean_hours_elec = mean(electric_supply)

// Constant ratio
gen d_bar_over_h_bar = mean_well_depth/mean_hours_elec

// Mean (D/H)
gen d_over_h = farmer_well_depth/electric_supply
bys sdo_feeder_code: egen sdo_mean_d_over_h = mean(d_over_h)
egen d_over_h_bar = mean(d_over_h)
replace d_over_h = sdo_mean_d_over_h if missing(d_over_h)

// Compare \bar{D}/\bar{H} to \bar(D/H}
eststo clear
qui estpost sum d_bar_over_h_bar d_over_h_bar
la var d_bar_over_h_bar "$\bar{D}/\bar{H}$"
la var d_over_h_bar "$\overline{D/H}$"
esttab using "`TABLES'/ratio_depth_hours.tex", cells("mean(label(Value) fmt(a2))") ///
		title("The two ratios") ///
		booktabs noobs nonumbers label replace 



// Mean pump capacity
tempvar mean1 mean2 mean3 mean4

egen `mean1' = mean(b7_1_2_pmp_nmplte_cap_1_hp)
count if !missing(b7_1_2_pmp_nmplte_cap_1_hp)
scalar c1 = r(N)

egen `mean2' = mean(b7_1_2_pmp_nmplte_cap_2_hp)
count if !missing(b7_1_2_pmp_nmplte_cap_2_hp)
scalar c2 = r(N)

egen `mean3' = mean(b7_1_2_pmp_nmplte_cap_3_hp)
count if !missing(b7_1_2_pmp_nmplte_cap_3_hp)
scalar c3 = r(N)

egen `mean4' = mean(b7_1_2_pmp_nmplte_cap_4_hp)
count if !missing(b7_1_2_pmp_nmplte_cap_4_hp)
scalar c4 = r(N)

gen mean_pump_capacity = (c1*`mean1'+c2*`mean2'+c3*`mean3'+c4*`mean4')/(c1+c2+c3+c4)
egen mean_farmer_pump_capacity = rowmean(b7_1_2_pmp_nmplte_cap_*_hp)
egen agg_farmer_pump_capacity = rowtotal(b7_1_2_pmp_nmplte_cap_*_hp) 


sum mean_farmer_pump_capacity mean_pump_capacity agg_farmer_pump_capacity pump_farmer pump_farmer_plot

drop `mean1' `mean2' `mean3' `mean4' `newwins'

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//									END
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
