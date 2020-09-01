/*******************************************************************************
Purpose: Baseline survey data analysis (farmer x crop profitability)

Author: Viraj Jorapur (modified by Yashaswi Mohanty)

Date: 04 June, 2018
*******************************************************************************/
*** This file analyses farmer x crop profitability for each farmer
* Opening commands:

// ========================= PREAMBLE ==========================================	
if c(mode) == "batch" {
	local PROJECT_ROOT = strrtrim("`0'")
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

// Getting the water variables first

// ================================MERGING WATER VARIABLES=======================
	
	capture erase baseline_data.dta
	
	tempfile baseline_data
	
// Use the csv file created in water_flow.R to get water variables

	import delimited "`PROJECT_ROOT'/data/geology/clean/water_flow.csv", clear
	
	keep f_id crop water_liter* elec_source* water_crop_* elec_crop_* error_cal_water error_cal_elec ///
	tot_water_* tot_elec_* pump_farmer_plot tot_hours liter_per_hour pump_farmer
	
	destring f_id crop water_liter* elec_source* water_crop_* elec_crop_* error_cal_water error_cal_elec ///
	tot_water_* tot_elec_* pump_farmer_plot tot_hours liter_per_hour, replace force

	sort f_id crop
	
	save `baseline_data'
	
// Use the cleaned version of the data
	
	use "`CLEAN_FARMER_SURVEY'/baseline_survey_farmer_crop_level.dta", clear 
	
	preserve
	
	
	// ================= GENERATE FIGURES ON WATER USE =========================
	
	replace f2_3_6_hours_per_day_1 = f2_3_6_hours_per_day_1 - 1
	drop if f2_3_6_hours_per_day_1 < 0
	tab f2_3_6_hours_per_day_1
	la var f2_3_6_hours_per_day_1 "Average Hours of Pumpset Use Rabi'17"
	hist f2_3_6_hours_per_day_1, xline(6, lwidth(0.7) lpattern(dash)) percent fcolor(midblue) lcolor(black) ///
	graphregion(color(white)) plotregion(color(white))  width(1) xtitle("Mean daily hours of use", size(large)) ///
	xlabel(0(4)24) ytitle("Percent", size(large))
	
	graph export "`FIGURES'/daily_electricity_usage.pdf", replace

	replace b2_1_1_hrs_avg_supp_rabi = b2_1_1_hrs_avg_supp_rabi - 1
	drop if b2_1_1_hrs_avg_supp_rabi < 0
	la var b2_1_1_hrs_avg_supp_rabi "Average Supply Hours Per Day Rabi'17"
	
	hist b2_1_1_hrs_avg_supp_rabi, xline(6, lwidth(0.7) lpattern(dash)) percent fcolor(midblue) ///
	lcolor(black) graphregion(color(white)) plotregion(color(white)) width(1) ///
	xlabel(0(4)24) xtitle("Mean daily hours of supply", size(large))  yscale(range(0(10)100)) yticks(0(20)100) ylabel(0(20)100)  ytitle("Percent", size(large))
	graph export "`FIGURES'/daily_electricity_supply.pdf", replace
	
	restore
	
	merge 1:1 f_id crop using `baseline_data'
	
	drop _merge

	la var water_liter1 "Water Drawn Source1 (liter)"
	la var water_liter2 "Water Drawn Source2 (liter)"
	la var water_liter3 "Water Drawn Source3 (liter)"
	la var water_liter4 "Water Drawn Source4 (liter)"
	la var water_liter5 "Water Drawn Source5 (liter)"
	la var water_liter6 "Water Drawn Source6 (liter)"
	la var water_liter7 "Water Drawn Source7 (liter)"
	la var water_liter8 "Water Drawn Source8 (liter)"
	la var water_liter9 "Water Drawn Source9 (liter)"

	la var water_crop_source1 "Water to Crop from Source1 (liter)"
	la var water_crop_source2 "Water to Crop from Source2 (liter)"
	la var water_crop_source3 "Water to Crop from Source3 (liter)"
	la var water_crop_source4 "Water to Crop from Source4 (liter)"
	la var water_crop_source5 "Water to Crop from Source5 (liter)"
	la var water_crop_source6 "Water to Crop from Source6 (liter)"
	la var water_crop_source7 "Water to Crop from Source7 (liter)"
	la var water_crop_source8 "Water to Crop from Source8 (liter)"
	la var water_crop_source9 "Water to Crop from Source9 (liter)"


	la var tot_water_liter "Total Water Drawn (liter)"
	la var tot_water_check "Check Total Sum of Water Across Crops"
	la var tot_water_crop "Total Water for Crop (liter)"
	la var tot_hours "Total Hours in Rabi'17"
	
	la var error_cal_water "Check Total Water Drawn and Sum of Water Across Crops"
	
	la var elec_source1 "Electricity Source1 (hp-hours)"
	la var elec_source2 "Electricity Source2 (hp-hours)"
	la var elec_source3 "Electricity Source3 (hp-hours)"
	la var elec_source4 "Electricity Source4 (hp-hours)"
	la var elec_source5 "Electricity Source5 (hp-hours)"
	la var elec_source6 "Electricity Source6 (hp-hours)"
	la var elec_source7 "Electricity Source7 (hp-hours)"
	la var elec_source8 "Electricity Source8 (hp-hours)"
	la var elec_source9 "Electricity Source9 (hp-hours)"

	la var elec_crop_source1 "Electricity to Crop from Source1 (hp-hours)"
	la var elec_crop_source2 "Electricity to Crop from Source2 (hp-hours)"
	la var elec_crop_source3 "Electricity to Crop from Source3 (hp-hours)"
	la var elec_crop_source4 "Electricity to Crop from Source4 (hp-hours)"
	la var elec_crop_source5 "Electricity to Crop from Source5 (hp-hours)"
	la var elec_crop_source6 "Electricity to Crop from Source6 (hp-hours)"
	la var elec_crop_source7 "Electricity to Crop from Source7 (hp-hours)"
	la var elec_crop_source8 "Electricity to Crop from Source8 (hp-hours)"
	la var elec_crop_source9 "Electricity to Crop from Source9 (hp-hours)"


	la var tot_elec_hp "Total Electricity Used (hp-hours)"
	la var tot_elec_check_hp "Check Total Sum of Electricity Across Crops"
	la var tot_elec_crop_hp "Total Electricity for Crop (hp-hours)"
	la var pump_farmer_plot "Pump Power (HP)"

	la var error_cal_elec "Check Total Electricity Used and Sum of Electricity Used Across Crops"
	la var liter_per_hour "Liters of Water Drawn per Hour"

//=============== Compute prices for each crop variety =========================

	tostring f_id, generate(f_id_str)
	gen SDO_num_str = substr(f_id_str,1,1)
	gen fdr_num_str = substr(f_id_str,1,3)
	destring fdr_num_str, generate(fdr1)
	drop fdr_num_str
	drop sdo_feeder_code
	rename fdr1 sdo_feeder_code
	destring SDO_num_str, generate(SDO_num)
	drop SDO_num_str
	drop f_id_str
	
	
* Calculating the prices prices by crops
	gen f5_4_price = f5_4_9_tot_value_sold/f5_4_8_tot_amt_sold
	bysort sdo_num f1_3_crops_plntd : egen median_price = median(f5_4_price)
	bysort f1_3_crops_plntd : egen med_median_price = median(median_price)
	replace median_price = med_median_price if f1_3_crops_plntd == 610
	replace median_price = med_median_price if f1_3_crops_plntd == 628
	replace median_price = med_median_price if f1_3_crops_plntd == 630
	replace median_price = med_median_price if f1_3_crops_plntd == 711
	replace median_price = med_median_price if f1_3_crops_plntd == 905
	replace median_price = med_median_price if f1_3_crops_plntd == -699
	replace median_price = med_median_price if f1_3_crops_plntd == 702
	replace median_price = med_median_price if f1_3_crops_plntd == 609
	replace median_price = med_median_price if f1_3_crops_plntd == 619
	replace median_price = med_median_price if f1_3_crops_plntd == 630
	replace median_price = med_median_price if f1_3_crops_plntd == 903
	replace median_price = med_median_price if f1_3_crops_plntd == -1199
	replace median_price = 1500 if f1_3_crops_plntd == 106
	replace median_price = 1500 if f1_3_crops_plntd == 105
	replace median_price = 650 if f1_3_crops_plntd == 633
	replace median_price = 2875 if f1_3_crops_plntd == 613
	replace median_price = 2875 if f1_3_crops_plntd == 615
	replace median_price = 1500 if f1_3_crops_plntd == -199
	replace median_price = 466.6667 if f1_3_crops_plntd == 643
	replace median_price = 500 if f1_3_crops_plntd == -999
	replace median_price = 4285.714 if f1_3_crops_plntd == 206
	replace median_price = . if f1_3_crops_plntd == 100
	
	la var median_price "Median Prices of each crop (per Quintal)" /*Issue with crop number 100*/
	
	drop med_median_price
	drop f5_4_price
	
// ===========================GENERATING CROP TYPES AND CROP DUMMIES ===========

	gen crop_type = "others"
	replace crop_type = "fielspea" if f1_3_crops_plntd == 208
	replace crop_type = "wheat" if f1_3_crops_plntd == 102
	replace crop_type = "mustard" if f1_3_crops_plntd == 308
	replace crop_type = "lentil" if f1_3_crops_plntd == 207
	replace crop_type = "bengalgram" if f1_3_crops_plntd == 210
	replace crop_type = "rajka" if f1_3_crops_plntd == 100
	replace crop_type = "coriander" if f1_3_crops_plntd == 611
	replace crop_type = "barley" if f1_3_crops_plntd == 103
	replace crop_type = "fenugreek" if f1_3_crops_plntd == 617
	replace crop_type = "garlic" if f1_3_crops_plntd == 711
	replace crop_type = "sugarcane" if f1_3_crops_plntd == 501
	replace crop_type = "orange" if f1_3_crops_plntd == 902
	
	la var crop_type "Crop Type"
	
// Generating crop type dummies

	gen wheat = 0
	replace wheat = 1 if crop_type == "wheat"
	la var wheat "Wheat"
	
	gen others = 0
	replace others = 1 if crop_type == "others"
	la var wheat "Others"
	
	gen fielspea = 0
	replace fielspea = 1 if crop_type == "fielspea"
	la var wheat "Fielspea"
	
	gen mustard = 0
	replace mustard = 1 if crop_type == "mustard"
	la var wheat "Mustard"
	
	gen lentil = 0
	replace lentil = 1 if crop_type == "lentil"
	la var wheat "Lentil"
	
	gen bengalgram = 0
	replace bengalgram = 1 if crop_type == "bengalgram"
	la var wheat "Bengalgram"
	
	gen rajka = 0
	replace rajka = 1 if crop_type == "rajka"
	la var wheat "Rajka"
	
	gen coriander = 0
	replace coriander = 1 if crop_type == "coriander"
	la var wheat "Coriander"
	
	gen barley = 0
	replace barley = 1 if crop_type == "barley"
	la var wheat "Barley"
	
	gen fenugreek = 0
	replace fenugreek = 1 if crop_type == "fenugreek"
	la var wheat "Fenugreek"
	
	gen garlic = 0
	replace garlic = 1 if crop_type == "garlic"
	la var wheat "Garlic"
	
	gen sugarcane = 0
	replace sugarcane = 1 if crop_type == "sugarcane"
	la var wheat "Sugarcane"
	
	gen orange = 0
	replace orange = 1 if crop_type == "orange"
	la var wheat "Orange"
	

//==== Replacing the amount of household irrigation labour to reflect true values ==========

	replace f5_3_5_hh_lab_days = 0.25 * f5_3_5_hh_lab_days
	
	
//=========== Calculating median wages by SDO x Activity =======================
	bysort sdo_num : egen median_wage_sow = median(f5_3_4_avg_wage_sow)
	la var median_wage_sow "Median wages for sowing by SDO"
	bysort sdo_num : egen median_wage_irr = median(f5_3_8_avg_wage_irr)
	la var median_wage_irr "Median wages for irrigation by SDO"
	bysort sdo_num : egen median_wage_hrvst = median(f5_3_12_avg_wage_hrvst)
	la var median_wage_hrvst "Median wages for harvesting by SDO"
	local WAGE_MGNREGS = 181
	display `WAGE_MGNREGS'
/*	
* Calculating the median wages
	bysort f1_3_crops_plntd : egen median_wage_sow = median(f5_3_4_avg_wage_sow)
	la var median_wage_sow "Median wages for sowing"
	bysort f1_3_crops_plntd : egen median_wage_irr = median(f5_3_8_avg_wage_irr)
	la var median_wage_irr "Median wages for irrigation"
	bysort f1_3_crops_plntd : egen median_wage_hrvst = median(f5_3_12_avg_wage_hrvst)
	la var median_wage_hrvst "Median wages for harvesting"
*/


//============== Calculating seed price and biofertiliser price ================
	bysort f1_3_crops_plntd : egen median_seed_price = median(f5_2_3_seed_price)
	la var median_seed_price "Median seed price"
	bysort f1_3_crops_plntd : egen median_bio_fert_price = median(f5_2_8_bio_fert_price)
	la var median_bio_fert_price "Median bio-fertilisers price"


//=====================Sorting by farmer ID and crop ===========================
	sort f_id crop
	
	
//============================= Imputing profits ===============================
	
//================ Calculating total land as per inventory =====================

	egen d1_tot_land = rowtotal(d1_2_pakka_sqft d1_3_kacha_sqft), missing
	winsor d1_tot_land, gen(d1_wnsr) p(0.01) highonly
	drop d1_tot_land
	rename d1_wnsr d1_tot_land
	winsor d1_tot_land, gen(d1_wnsr) p(0.01) lowonly
	drop d1_tot_land
	rename d1_wnsr d1_tot_land
	la var d1_tot_land "Total land reported in sq ft"
	
	gen d1_2_prop_pakka = d1_2_pakka_sqft/d1_tot_land
	la var d1_2_prop_pakka "Proportion of pakka land to total land (reported) in sq ft"
	gen d1_2_prop_kacha = d1_3_kacha_sqft/d1_tot_land
	la var d1_2_prop_kacha "Proportion of kacha land to total land (reported) in sq ft"
	//summ d1_tot_land d1_2_pakka_sqft d1_3_kacha_sqft , detail
	//univar d1_tot_land d1_2_pakka_sqft d1_3_kacha_sqft , dec(1)
	
	
//=============== Calculating total land from land parcels =====================
	
	forvalues i = 1/18 {
	gen d2_pakka_`i' = d2_1_tot_size_land_`i'_sqft if d2_2_parcel_type_`i' == "2" | d2_2_parcel_type_`i' == "1 2"
	replace d2_pakka_`i' = (0.90*d2_1_tot_size_land_`i'_sqft) if d2_2_parcel_type_`i' == "1 2"
	la var d2_pakka_`i' "Total pakka land in parcel `i' (in sq ft)"
	}
	egen d2_tot_pakka = rowtotal(d2_pakka_*), missing
	la var d2_tot_pakka "Total imputed pakka land owned in sq ft"
	
	forvalues i = 1/18 {
	gen d2_kacha_`i' = d2_1_tot_size_land_`i'_sqft if d2_2_parcel_type_`i' == "1" | d2_2_parcel_type_`i' == "1 2"
	replace d2_kacha_`i' = (0.10*d2_1_tot_size_land_`i'_sqft) if d2_2_parcel_type_`i' == "1 2"
	la var d2_kacha_`i' "Total kacha land in parcel `i' (in sq ft)"
	}
	egen d2_tot_kacha = rowtotal(d2_kacha_*), missing
	la var d2_tot_kacha "Total imputed kacha land owned in sq ft"
	egen d2_tot_land = rowtotal(d2_tot_pakka d2_tot_kacha), missing
	la var d2_tot_land "Total (imputed) land owned in sq ft"
	//summ d2_tot_land d2_tot_pakka d2_tot_kacha
	//univar d2_tot_land d2_tot_pakka d2_tot_kacha , dec(1)
	
	egen f2_3_tot_land_irr = rowtotal(f2_3_1_land_irrgtd_*_sqft), missing
	la var f2_3_tot_land_irr "Total land irrigated in Rabi'17"

	
//=========== Calculating difference in total land between inventory and land parcels ============
	gen d1_diff_tot_land = d1_tot_land - d2_tot_land
	la var d1_diff_tot_land "Difference in total land that is reported and imputed"
	summ d1_diff_tot_land

	
	
//==================== Getting land in Hectares ================================

	local SQ_TO_HA = 0.000009290304
	
	winsor f1_4_3_area_und_crp_sqft, gen(f1_4_3_area_und_crp_sqft_wnsr) p(0.005) high
	drop f1_4_3_area_und_crp_sqft
	rename f1_4_3_area_und_crp_sqft_wnsr f1_4_3_area_und_crp_sqft
	la var f1_4_3_area_und_crp_sqft "Area under the crop in sqft"
	
	gen area_und_crop_ha = f1_4_3_area_und_crp_sqft*`SQ_TO_HA'
	
	la var area_und_crop_ha "Area under crop in hectares"
	
	gen tot_area_ha = d1_tot_land*`SQ_TO_HA'
	
	la var tot_area_ha "Total area in hectares"
	
	bysort f_id : egen tot_cropped_area = sum(f1_4_3_area_und_crp_sqft)
	la var tot_cropped_area "Total Cropped Area in sq.ft."
	
	gen frac_cropped_area = f1_4_3_area_und_crp_sqft/tot_cropped_area
	la var frac_cropped_area "Fraction of area plotted for the crop"
	
	gen tot_cropped_area_ha = tot_cropped_area*`SQ_TO_HA'
	la var tot_cropped_area_ha "Cropped area for the crop in Hectares"
	
	gen f2_3_tot_land_irr_ha = f2_3_tot_land_irr*`SQ_TO_HA'
	la var f2_3_tot_land_irr_ha "Total land irrigated in Hectares"
	

	
//========================= Calculating Water for missing crop =================
	bysort SDO resp_num crop_type : egen median_water_crop = median(tot_water_crop)
	replace tot_water_crop = median_water_crop if resp_num == 1 & tot_water_crop == 0
	drop median_water_crop
	sort f_id crop
//===================== Generating Water Drawn per Hectare =====================

	gen tot_water_crop_ha = tot_water_crop/(area_und_crop_ha)	
	winsor tot_water_crop_ha, gen(wnsr) p(0.005) highonly
	drop tot_water_crop_ha
	rename wnsr tot_water_crop_ha	
	la var tot_water_crop_ha "Water used per crop per unit of land (l/Ha)"
	
	replace tot_water_crop = tot_water_crop_ha * area_und_crop_ha
	



/* Calculating the Summary stats on water use
	forvalues i=1/9 {
		gen f2_3_2_irrg_time_`i' = f2_3_1_land_irrgtd_`i'_sqft * f2_3_3_irrg_tme_pr_unit_lnd_`i'
		la var f2_3_2_irrg_time_`i' "Amount of hours for which irrigation source `i' was used in Rabi'17"
		gen f2_3_2_irrg_pr_day_`i' = f2_3_2_irrg_time_`i'/f2_3_4_dys_wtr_drwn_`i'
		la var f2_3_2_irrg_pr_day_`i' "Daily amount of hours for which irrigation source `i' was used in Rabi'17"
		gen time_water_drawn_`i' = 0
		replace time_water_drawn_`i' = 6 * f2_3_4_dys_wtr_drwn_`i' if f2_3_4_dys_wtr_drwn_`i' != 0 & f2_3_6_hours_per_day_`i' == 0
		replace time_water_drawn_`i' = f2_3_6_hours_per_day_`i' * f2_3_4_dys_wtr_drwn_`i' if f2_3_4_dys_wtr_drwn_`i' != 0 & f2_3_6_hours_per_day_`i' > 0
		la var time_water_drawn_`i' "Total hours water drawn from source `i'"
	}
*/
	
	//egen f2_3_tot_irr_time = rowtotal(f2_3_2_irrg_time_*), missing
	//la var f2_3_tot_irr_time "Total hours for which land was irrigated in Rabi'17"
	//egen f2_3_tot_day = rowtotal(f2_3_4_dys_wtr_drwn_*), missing
	//la var f2_3_tot_day "Total number of days for which water was drawn for irrigation in Rabi'17"
	//gen f2_3_irr_per_day = f2_3_tot_irr_time/f2_3_tot_day
	//la var f2_3_irr_per_day "Number of days land was irrigated in Rabi'17"
	
	//egen f2_3_tot_irr_tm_day = rowtotal(f2_3_2_irrg_pr_day_*), missing
	//la var f2_3_tot_irr_tm_day "Hours for which all parcels of land were irrigated per day in Rabi'17"
	
	//egen tot_hrs_water_drawn = rowtotal(time_water_drawn_*), missing
	//la var tot_hrs_water_drawn "Total hours water drawn Rabi'17"
	
	//winsor tot_hrs_water_drawn, gen(tot_hrs_water_drawn_wnsr) p(0.1) lowonly
	//winsor tot_hrs_water_drawn_wnsr, gen(tot_hrs_winsor) p(0.005) highonly
	//drop tot_hrs_water_drawn_wnsr
	//rename tot_hrs_winsor tot_hrs_water_drawn_wnsr
	
	//la var tot_hrs_water_drawn_wnsr "Total hours water drawn Rabi'17 (winsored)"
	
	//summ f2_3_tot_land_irr f2_3_tot_irr_time
	//summ f2_3_tot_land_irr f2_3_tot_irr_tm_day
/*	
	/* Since there were outliers in both total area irrigated and the time taken, capped the outliers at both ends at 1% */
	winsor f2_3_tot_irr_time , gen(f2_3_tot_irr_tm_wnsr) p(0.01)
	la var f2_3_tot_irr_tm_wnsr "Total hours for which land was irrigated in Rabi'17 (winsored)"
	winsor f2_3_tot_land_irr , gen(f2_3_tot_land_irr_wnsr) p(0.01)
	la var f2_3_tot_land_irr_wnsr "Total land irrigated in Rabi'17 (winsored)"
	winsor f2_3_tot_irr_tm_day , gen(f2_3_tot_irr_tm_day_wnsr) p(0.01)
	la var f2_3_tot_irr_tm_day_wnsr "Hours for which all parcels of land were irrigated per day in Rabi'17 (winsored)"
	winsor f2_3_irr_per_day , gen(f2_3_irr_per_day_wnsr) p(0.01)
	la var f2_3_irr_per_day_wnsr "Number of days land was irrigated in Rabi'17 (winsored)"
	summ f2_3_tot_land_irr_wnsr f2_3_tot_irr_tm_wnsr
	summ f2_3_tot_land_irr_wnsr f2_3_tot_irr_tm_day_wnsr
	univar f2_3_tot_land_irr_wnsr f2_3_tot_irr_tm_day_wnsr, dec(1)
*/


//====================== Calculating KWh per farmer ============================
/* First calculating the bill share for each farmer. If it is not shared equally, 
extracting from individual bill share and if shared equally, 
calculating by division */

	gen a1_22_4_share_bill = .
	la var a1_22_4_share_bill "Share of bill paid by the respondent"
	forvalues i = 1/20 { 
	replace a1_22_4_share_bill = a1_22_4_bill_share_`i' if a1_22_2_sharer_rel_`i' == 1
	}
	replace a1_22_4_share_bill = 100/a1_20_sharer_count if a1_29_elec_conn_div == 1

	
//=========== Calculating the total pump capacity for each farmer ==============
	forvalues i = 1/4 {
	replace b7_1_3_pmp_cpcty_`i'_hp = 7.5 if b7_1_3_pmp_cpcty_`i'_hp == 75
	replace b7_1_3_pmp_cpcty_`i'_hp = . if b7_1_3_pmp_cpcty_`i'_hp == 77
	}
	egen b7_1_tot_pmp_cap = rowtotal(b6_15_orig_capacity_*_hp), missing
	la var b7_1_tot_pmp_cap "Total pump capacity connected to sampled connection"
	gen b7_1_avg_pmp_cap = b7_1_tot_pmp_cap/b6_1_pmpset
	la var b7_1_avg_pmp_cap "Average pump capacity connected to sampled connection"
	sum b7_1_avg_pmp_cap, detail
	replace b7_1_avg_pmp_cap = r(p50) if b7_1_avg_pmp_cap == .

	
	
	
/* Calculating the flow rate for all the farmers

	gen net_pump_cap = avg_pump_capacity * 0.4
	winsor net_pump_cap, gen(net_wnsr) p(0.01)
	drop net_pump_cap
	rename net_wnsr net_pump_cap
	
	la var net_pump_cap "Actual pump capacity"
	
	egen avg_pump_diameter = mean(b7_3_9_exp_pipe_diamtr_1_ft)
	la var avg_pump_diameter "Average Pump Diameter (meter)"
	
*/

/* Calculating the per person kwh consumption
	gen a1_22_hp_cnsm = b2_1_1_hrs_avg_supp_rabi*b7_1_tot_pmp_cap*a1_22_4_share_bill
	/*For people who do not share the connection*/
	replace a1_22_hp_cnsm = b2_1_1_hrs_avg_supp_rabi*b7_1_tot_pmp_cap if a1_19_share_conn == 2 
	la var a1_22_hp_cnsm "Electricity consumption (in HPh) of farmer per day in Rabi'17"
	sum a1_22_hp_cnsm
	tab a1_22_hp_cnsm
	gen a1_22_kwh_cnsm_supp = a1_22_hp_cnsm*0.75
	la var a1_22_kwh_cnsm_supp  "Electricity consumption (in kWh) of farmer per day in Rabi'17"
	la var a1_22_kwh_cnsm_supp  
* Calculating per farmer per hectare consumption
	gen a1_22_hp_hectr = a1_22_hp_cnsm/(tot_area_ha)
	la var a1_22_hp_hectr "Electricity consumption (in HP) of farmer per day per hectare in Rabi'17"
	gen a1_22_kwh_hectr_supp = a1_22_kwh_cnsm_supp/(tot_area_ha)
	la var a1_22_kwh_hectr_supp "Electricity consumption (in kWh) of farmer per day per hectare in Rabi'17"
	summ a1_22_kwh_hectr_supp
	tab a1_22_kwh_hectr_supp
	* Since there are outliers in average kwh consumption per farmer, capped the outliers at 0.25% at both ends
	winsor a1_22_kwh_cnsm_supp , gen(a1_22_kwh_cnsm_supp_wnsr) p(0.0025)
	la var a1_22_kwh_cnsm_supp_wnsr "Electricity consumption (in kWh) of farmer per day in Rabi'17"
	winsor a1_22_kwh_hectr_supp , gen(a1_22_kwh_hectr_supp_wnsr) p(0.0025)
	la var a1_22_kwh_hectr_supp_wnsr "Electricity consumption (in kWh) of farmer per day per hectare in Rabi'17"
	winsor a1_22_hp_hectr, gen(a1_22_hp_hectr_wnsr) p(0.00025)
	la var a1_22_hp_hectr_wnsr "Electricity consumption (in HP) of farmer per day per hectare in Rabi'17"
	univar a1_22_kwh_hectr_supp_wnsr , dec(1)
*/
	

	
	
	
//============ Calculating consumption per pump for each farmer ================
	split f2_2_irri_sorce
	
	forvalues i = 1/8 {
		label variable f2_2_irri_sorce`i' "Split variable of irrigation source `i'"
	}
	
	
	
//========== Calculating the total kwh consumption in Rabi 2017 ================
	forvalues i = 1/5 {
	replace  b6_15_orig_capacity_`i'_hp = 7.5 if  b6_15_orig_capacity_`i'_hp == 75
	replace  b6_15_orig_capacity_`i'_hp = . if  b6_15_orig_capacity_`i'_hp == 77
	}
	
	
	
	
	
	
/*
	forvalues i = 1/5 {
	gen tot_kwh_cons_`i' = .
	la var tot_kwh_cons_`i' "Total consumption (in kWh) from pump `i' in Rabi'17"
	}
	//Not including pumps from connections other than those sampled since we do know if they have been metered or not
	forvalues i = 1/5 {
	replace tot_kwh_cons_`i' = b6_15_orig_capacity_`i'_hp*f2_3_6_hours_per_day_`i'*f2_3_4_dys_wtr_drwn_`i'*0.7457 if f2_2_irri_sorce`i' == "`i'"
	}
	egen tot_kwh_cons = rowtotal(tot_kwh_cons_*), missing
	replace tot_kwh_cons = tot_kwh_cons*a1_22_4_share_bill if a1_19_share_conn == 1
	la var tot_kwh_cons "Total energy consumption (in kWh) in Rabi'17"
	tab tot_kwh_cons
* Figuring out cost for missing ones
	replace tot_kwh_cons = . if tot_kwh_cons == 0
	egen tot_pump_capac = rowtotal(b6_15_orig_capacity_1_hp-b6_15_orig_capacity_5_hp), missing 
	la var tot_pump_capac "Total pump capacity (in HP) connected to sampled connection in Rabi'17"
	sort tot_pump_capac
	by tot_pump_capac: egen avg_kwh_cons = mean(tot_kwh_cons)
	la var avg_kwh_cons "Averge energy consumption (in kWh) in Rabi'17"
	replace tot_kwh_cons = avg_kwh_cons if tot_kwh_cons == .
	
* Generating reported consumption in HPh
	forvalues i = 1/5 {
	replace b6_15_orig_capacity_`i'_hp = 7.5 if b6_15_orig_capacity_`i'_hp == 75
	replace b6_15_orig_capacity_`i'_hp = . if b6_15_orig_capacity_`i'_hp == 77
	}
	forvalues i = 1/5 {
		gen reported_cons_hph_`i' =.
		la var reported_cons_hph_`i' "Reported consumption (in HPh) in Rabi'17"
	}
	
	forvalues i = 1/5 { 
		forvalues j = 1/8 { 
			replace reported_cons_hph_`i' = b6_15_orig_capacity_`i'_hp*f2_3_6_hours_per_day_`j'*f2_3_4_dys_wtr_drwn_`j' if f2_2_irri_sorce`j' == "`i'"
		}
	}

	
* For pumps on other connections - excluding informal and diesel pumps
	forvalues i = 1/7 {
		gen reported_cons_hph_3`i' =.
		la var reported_cons_hph_3`i' "Reported Consumption (in HPh) of non-sampled connec pump `i' in Rabi'17"
	}
	
	forvalues i = 1/7 {
		forvalues j = 1/8 {
			replace reported_cons_hph_3`i' = c2_2_pmp_nmplte_cap_`i'_hp*f2_3_6_hours_per_day_`j'*f2_3_4_dys_wtr_drwn_`j' if ///
			f2_2_irri_sorce`j' == "3`i'" & c2_1_pmp_cnctn_type_`i' == 1
		}
	}
	
* Calculating consumption per farmer
	egen a1_22_cons = rowtotal(reported_cons_hph_*), missing
	la var a1_22_cons "Total reported consumption (in HPh) from sampled & non-sampled connec in Rabi'17"
	gen a1_22_cons_kwh = a1_22_cons*0.7457 
	la var a1_22_cons_kwh "Total reported consumption (in kWh) from sampled & non-sampled connec in Rabi'17" 
	tab a1_22_cons_kwh
	
* Calculating Consumption Per Farmer Per Hectare
	gen a1_22_cons_kwh_hectr = a1_22_cons_kwh/(tot_area_ha)
	la var a1_22_cons_kwh_hectr "Reported consumption (in kWh) per hectare from sampled & non-sampled connec in Rabi'17"
	winsor a1_22_cons_kwh_hectr, gen(a1_22_cons_kwh_hectr_wnsr) p(0.00035)
	la var a1_22_cons_kwh_hectr_wnsr "Reported consumption (in kWh) per hectare from sampled & non-sampled connec in Rabi'17"

*/





//============ Calculating yield per crop (Quintals per hectare) ===============
	gen f5_4_yield = f5_4_1_tot_prod/(area_und_crop_ha)
	la var f5_4_yield "Yield (in Quintals per hectare)"
	winsor f5_4_yield, gen(f5_4_yield_wnsr2) p(0.0002) high
	drop f5_4_yield
	rename f5_4_yield_wnsr2 f5_4_yield
	la var f5_4_yield "Yield (in Quintals per hectare)"
	

* Group 1: 1490.061, Group 2: 3890.389, Group 3: 3228.968, Group 4: missing
* Group 5: 1359.681, Group 6: 3064.318, Group 7: 2304.87, Group 8: 136416.7
* Group 9: 878.6558, Group 10: 2057.143, Group 11: 4000
/*	
	gen avg_price1 = 1490.061
	gen avg_price2 = 3890.389
	gen avg_price3 = 3228.968
	gen avg_price4 = .
	gen avg_price5 = 1359.681
	gen avg_price6 = 3064.318
	gen avg_price7 = 2304.87
	gen avg_price8 = 136416.7
	gen avg_price9 = 878.6558
	gen avg_price10 = 2057.143
	gen avg_price11 = 4000
*/

	
/*	if f5_4_price == . {
		forvalues i = 1/11{
			replace f5_4_price = avg_price`i' if f1_3_crops_plntd == `i'01 | f1_3_crops_plntd == `i'02 | ///
					f1_3_crops_plntd == `i'03 | f1_3_crops_plntd == `i'04 | f1_3_crops_plntd == `i'05 | f1_3_crops_plntd == `i'06 | ///
					f1_3_crops_plntd == `i'07 | f1_3_crops_plntd == `i'08 | f1_3_crops_plntd == `i'09 | f1_3_crops_plntd == `i'10 | ///
					f1_3_crops_plntd == `i'11 | f1_3_crops_plntd == `i'12 | f1_3_crops_plntd == `i'13 | f1_3_crops_plntd == `i'14 | ///
					f1_3_crops_plntd == `i'15 | f1_3_crops_plntd == `i'16 | f1_3_crops_plntd == `i'17 | f1_3_crops_plntd == `i'18 | ///
					f1_3_crops_plntd == `i'19 | f1_3_crops_plntd == `i'20 | f1_3_crops_plntd == `i'21 | f1_3_crops_plntd == `i'22 | ///
					f1_3_crops_plntd == `i'23 | f1_3_crops_plntd == `i'24 | f1_3_crops_plntd == `i'25 | f1_3_crops_plntd == `i'26 | ///
					f1_3_crops_plntd == `i'27 | f1_3_crops_plntd == `i'28 | f1_3_crops_plntd == `i'29 | f1_3_crops_plntd == `i'30 | ///
					f1_3_crops_plntd == `i'31 | f1_3_crops_plntd == `i'32 | f1_3_crops_plntd == `i'33 | f1_3_crops_plntd == `i'34 | ///
					f1_3_crops_plntd == `i'35 | f1_3_crops_plntd == `i'36 | f1_3_crops_plntd == `i'37 | f1_3_crops_plntd == `i'38 | ///
					f1_3_crops_plntd == `i'39 | f1_3_crops_plntd == `i'40 | f1_3_crops_plntd == `i'41 | f1_3_crops_plntd == `i'42 | ///
					f1_3_crops_plntd == `i'43 | f1_3_crops_plntd == `i'44 | f1_3_crops_plntd == -`i'99  
		}
	}
*/
* Winsorising the area under crop
/*
	winsor f1_4_3_area_und_crp_sqft, gen(f1_4_3_area_und_crp_sqft_wnsr) p(0.005) high
	drop f1_4_3_area_und_crp_sqft
	rename f1_4_3_area_und_crp_sqft_wnsr f1_4_3_area_und_crp_sqft
	la var f1_4_3_area_und_crp_sqft "Area under the crop in sqft"
	
*/

	
	
/* Calculating Water Drawn by each farmer during the season of Rabi'17
	replace b7_1_avg_pmp_cap = . if b7_1_avg_pmp_cap <=3 
	replace avg_source_depth = . if avg_source_depth == 0
	gen water_drawn = f2_3_tot_irr_tm_wnsr*b7_1_avg_pmp_cap/avg_source_depth
*/



//======= Calculating the imputed value of crops lost and stored ===============

	gen val_lost_preharv = .
	la var val_lost_preharv "Total value lost pre harvest in Rabi'17"
	gen val_lost_postharv = .
	la var val_lost_postharv "Total value lost post harvest in Rabi'17"
	gen val_paid_cred = .
	la var val_paid_cred "Total value of credit paid in Rabi'17"
	gen val_dom_cons = .
	la var val_dom_cons "Total value kept for domestic use (in INR) in Rabi'17"
	gen val_store = .
	la var val_store "Total value stored for future selling in Rabi'17"
	
	
	replace f5_4_3_lost_pre_hrvst = 0 if f5_4_3_lost_pre_hrvst == .
	replace val_lost_preharv = f5_4_3_lost_pre_hrvst * median_price
	winsor val_lost_preharv, gen(wnsr) p(0.005) high
	drop val_lost_preharv
	rename wnsr val_lost_preharv
	la var val_lost_preharv "Value of the crop lost pre-harvest"
	gen val_lost_preharv_per_hectare = val_lost_preharv/(area_und_crop_ha)
	la var val_lost_preharv_per_hectare "Value of the crop lost pre-harvest per hectare"
	
	replace f5_4_4_lost_post_hrvst = 0 if f5_4_4_lost_post_hrvst == .
	replace val_lost_postharv = f5_4_4_lost_post_hrvst * median_price
	winsor val_lost_postharv, gen(wnsr) p(0.005) high
	drop val_lost_postharv
	rename wnsr val_lost_postharv
	la var val_lost_postharv "Value of the crop lost post-harvest"
	gen val_lost_postharv_per_hectare = val_lost_postharv/(area_und_crop_ha)
	la var val_lost_postharv_per_hectare "Value of the crop lost post-harvet per hectare"
	
	replace f5_4_6_amt_reimbrs_cred = 0 if f5_4_6_amt_reimbrs_cred == .
	replace val_paid_cred = f5_4_6_amt_reimbrs_cred * median_price
	winsor val_paid_cred, gen(wnsr) p(0.005) high
	drop val_paid_cred
	rename wnsr val_paid_cred
	la var val_paid_cred "Value of the crop paid as credit"
	gen val_paid_cred_per_hectare = val_paid_cred/(area_und_crop_ha)
	la var val_paid_cred_per_hectare "Value of the crop paid as credit per hectare"
	
	replace f5_4_7_domestic_use = 0 if f5_4_7_domestic_use == .
	replace val_dom_cons = f5_4_7_domestic_use * median_price
	winsor val_dom_cons, gen(wnsr) p(0.005) high
	drop val_dom_cons
	rename wnsr val_dom_cons
	la var val_dom_cons "Value of the crop stored for domestic consumption"
	gen val_dom_cons_per_hectare = val_dom_cons/(area_und_crop_ha)
	la var val_dom_cons_per_hectare "Value of the crop stored for domestic consumption per hectare"
	
	replace f5_4_19_selling = 0 if f5_4_19_selling == .
	replace val_store = f5_4_19_selling * median_price
	winsor val_store, gen(wnsr) p(0.005) high
	drop val_store
	rename wnsr val_store
	la var val_store "Value of the crop stored for future selling"
	gen val_store_per_hectare = val_store/(area_und_crop_ha)
	la var val_store_per_hectare "Value of the crop stored for future selling per hectare"
	
	replace f5_4_9_tot_value_sold = 0 if f5_4_9_tot_value_sold == .
	winsor f5_4_9_tot_value_sold, gen(f5_4_9_tot_value_sold_wnsr) p(0.005) high
	drop f5_4_9_tot_value_sold
	rename f5_4_9_tot_value_sold_wnsr f5_4_9_tot_value_sold
	la var f5_4_9_tot_value_sold "Value of the crop sold"
	gen f5_4_9_tot_value_sold_hectare = f5_4_9_tot_value_sold/(area_und_crop_ha)
	la var f5_4_9_tot_value_sold_hectare "Value of the crop sold per hectare"
	
	egen impu_value = rowtotal(f5_4_9_tot_value_sold val_store val_dom_cons val_paid_cred), missing
	winsor impu_value, gen(impu_value_wnsr) p(0.005) 
	drop impu_value
	rename impu_value_wnsr impu_value
	la var impu_value "Imputed value of crops produced (in INR) in Rabi'17"
	replace impu_value = . if f1_3_crops_plntd == 100
	replace impu_value = . if f1_3_crops_plntd == -499
	replace impu_value = . if f1_3_crops_plntd == 702
	gen impu_value_per_hectare = impu_value/(area_und_crop_ha)
	la var impu_value_per_hectare "Imputed value of crops produced (in INR) in Rabi'17 per hectare"
	
/* Calculating summary stats on water price for buyers
	forvalues i = 1/9 {
	gen e2_time_irr_`i' = e2_7_7_time_irrigate_tkn_wtr_`i'*e2_7_9_hours_wtr_tkn_`i'
	la var e2_time_irr_`i' "Total hours of irrigation for crop `i' in Rabi'17"
	gen e2_impu_pr_hr_`i' = e2_7_4_wtr_trnsfr_tot_amt_`i'/e2_time_irr_`i'
	la var e2_impu_pr_hr_`i' "Total imputed amt of water transferred for crop `i' per hour in Rabi'17"
	gen e2_pr_per_hr_`i' = e2_7_3_wtr_trnsfr_price_`i' 
	la var e2_pr_per_hr_`i' "Price of water transferred per hour for crop `i' in Rabi'17"
	replace e2_pr_per_hr_`i' = e2_7_3_wtr_trnsfr_price_`i'/b2_1_1_hrs_avg_supp_rabi if e2_7_1_wtr_rec_units_`i' == 2
	replace e2_pr_per_hr_`i' = e2_impu_pr_hr_`i' if e2_7_1_wtr_rec_units_`i' == 1
	replace e2_pr_per_hr_`i' = e2_7_4_wtr_trnsfr_tot_amt_`i'/e2_time_irr_`i' if e2_7_1_wtr_rec_units_`i' == 7
	replace e2_pr_per_hr_`i' = e2_7_3_wtr_trnsfr_price_`i'/b2_1_1_hrs_avg_supp_rabi if e2_7_1_wtr_rec_units_`i' == 5
	replace e2_pr_per_hr_`i' = . if e2_7_1_wtr_rec_units_`i' == 8 | e2_7_1_wtr_rec_units_`i' == -102 | e2_7_1_wtr_rec_units_`i' == 6
	}
	egen e2_pr_per_hr = rowmean(e2_pr_per_hr_*)
	la var e2_pr_per_hr "Price of water transferred per hour in Rabi'17"
	winsor e2_pr_per_hr, gen(e2_pr_per_hr_wnsr) p(0.025) high
	la var e2_pr_per_hr_wnsr "Price of water transferred per hour in Rabi'17"
	univar e2_pr_per_hr , dec(1)
*/

* Calculating Input Costs
/*
* Recovering prices from the separate codes that I have in the prices folder

* Prices for crop 1
	gen avg_seed1 = 83.8198
	gen avg_bio1 = 2087.489
	gen avg_wage_sow1 = 216.7866
	gen avg_wage_irr1 = 243.107
	gen avg_wage_harvest1 = 302.7865
	
* Prices for crop 2
	gen avg_seed2 = 104.6232
	gen avg_bio2 = 3011.905
	gen avg_wage_sow2 = 204.902
	gen avg_wage_irr2 = 205.9859
	gen avg_wage_harvest2 = 230.3592
	
* Prices for crop 3
	gen avg_seed3 = 444.5748
	gen avg_bio3 = 1520.87
	gen avg_wage_sow3 = 265.8878
	gen avg_wage_irr3 = 311.7769
	gen avg_wage_harvest3 = 330.9702
	
* Prices for crop 4
	gen avg_seed4 = 580
	gen avg_bio4 = .
	gen avg_wage_sow4 = .
	gen avg_wage_irr4 = .
	gen avg_wage_harvest4 = .
	
* Prices for crop 5
	gen avg_seed5 = 136.3224
	gen avg_bio5 = 3750
	gen avg_wage_sow5 = 221.4286
	gen avg_wage_irr5 = 225
	gen avg_wage_harvest5 = 226.5957
	
* Prices for crop 6
	gen avg_seed6 = 180.8165
	gen avg_bio6 = 1668.273
	gen avg_wage_sow6 = 198.8227
	gen avg_wage_irr6 = 173.3441
	gen avg_wage_harvest6 = 201.6575
	
* Prices for crop 7
	gen avg_seed7 = 191.8362
	gen avg_bio7 = 2837.5
	gen avg_wage_sow7 = 193.2836
	gen avg_wage_irr7 = 153.75
	gen avg_wage_harvest7 = 198.6487
	
* Prices for crop 8
	gen avg_seed8 = 733.3333
	gen avg_bio8 = .
	gen avg_wage_sow8 = 200
	gen avg_wage_irr8 = 200
	gen avg_wage_harvest8 = 200
	
* Prices for crop 9
	gen avg_seed9 = 71.69892
	gen avg_bio9 = 2093.75
	gen avg_wage_sow9 = 203.2727
	gen avg_wage_irr9 = 163.8889
	gen avg_wage_harvest9 = 217.1053
	
* Prices for crop 10
	gen avg_seed10 = 184
	gen avg_bio10 = .
	gen avg_wage_sow10 = 200
	gen avg_wage_irr10 = .
	gen avg_wage_harvest10 = 200
	
* Prices for crop 11
	gen avg_seed11 = 266.5
	gen avg_bio11 = 1500
	gen avg_wage_sow11 = 225
	gen avg_wage_irr11 = 250
	gen avg_wage_harvest11 = 200
*/

* Calculating parcel specific multiplier
/*
	forvalues i = 1/15{
		gen irrigation_crop_parcel`i' = .
		replace irrigation_crop_parcel`i' = (f5_1_6_8_irr_cnt_presow_pcl`i' + ///
		f5_1_6_2_irr_cnt_crp_pcl`i') //* f5_1_6_3_irr_frq_pcl`i'
		
		la var irrigation_crop_parcel`i' "Irrigation time for this crop on this parcel"
	}
*/
*/

	
//==== Input costs from seeds, biofertilisers, chemical fertilisers, pesticides, and labour =========


	egen seed_total_amt = rowtotal(f5_2_1_home_prod_seed f5_2_2_purchase_seed), missing
	la var seed_total_amt "Total amount of seeds used (homemade and purchased)"
	gen seed_total_cost = .
	la var seed_total_cost "Total costs spent on seeds"
	
	egen bio_fert_amt = rowtotal(f5_2_6_bio_fertilizer f5_2_7_bio_fer_purch), missing
	la var bio_fert_amt "Total amount of bio-fertilisers used (homemade and purchased)"
	gen bio_fert_cost = .
	la var bio_fert_cost "Total costs spent on bio-fertilisers"
	
	gen hhl_amt_sow = f5_3_1_hh_lab_sow * f5_3_1_hh_lab_days
	la var hhl_amt_sow "Total amount of house hold labour used for sowing"
	gen hhl_cost_sow = .
	la var hhl_cost_sow "Total cost of house hold labour used for sowing"
	gen hhl_cost_sow_mgnregs = .
	la var hhl_cost_sow_mgnregs "Total cost of hh labour used for sowing MGNREGS"
	
	gen hhl_amt_irr = f5_3_5_hh_lab_irr * f5_3_5_hh_lab_days
	la var hhl_amt_irr "Total amount of house hold labour used for irrigation"
	gen hhl_cost_irr = .
	la var hhl_cost_irr "Total cost of house hold labour used for irrigation"
	gen hhl_cost_irr_mgnregs = .
	la var hhl_cost_irr_mgnregs "Total cost of hh labour used for irrigation MGNREGS"
	gen hhl_amt_irr_adhoc = f5_3_5_hh_lab_irr * f5_3_5_hh_lab_days
	la var hhl_amt_irr_adhoc "Total amount of house hold labour used for irrigation (2 hours per day)"
	gen hhl_cost_irr_adhoc = .
	la var hhl_cost_irr_adhoc "Total cost of house hold labour used for irrigation (2 hours per day)" 
	
	gen hhl_amt_harvest = f5_3_9_hh_lab_hrvst * f5_3_9_hh_lab_days
	la var hhl_amt_harvest "Total amount of house hold labour used for harvesting"
	gen hhl_cost_harvest = .
	la var hhl_cost_harvest "Total cost of house hold labour used for harvesting"
	gen hhl_cost_harvest_mgnregs = .
	la var hhl_cost_harvest_mgnregs "Total cost of hh labour used for harvesting MGNREGS"
	
	gen wgl_amt_sow = f5_3_3_wage_lab_sow * f5_3_3_wage_lab_days
	la var wgl_amt_sow "Total amount of wage labour used for sowing"
	gen wgl_cost_sow = .
	la var wgl_cost_sow "Total cost of wage labour used for sowing"
	
	gen wgl_amt_irr = f5_3_7_wage_lab_irr * f5_3_7_wage_lab_days
	la var wgl_amt_irr "Total amount of wage labour used for irrigation"
	gen wgl_cost_irr = .
	la var wgl_cost_irr "Total cost of wage labour used for irrigation"
	
	gen wgl_amt_harvest = f5_3_11_wage_lab_hrvst * f5_3_11_wage_lab_days
	la var wgl_amt_harvest "Total amount of wage labour used for harvesting"
	gen wgl_cost_harvest = .
	la var wgl_cost_harvest "Total cost of wage labour used for harvesting"
	
	winsor f5_2_12_chem_fert_ttl_cst, gen(chem_fert_cost) p(0.005) high
	la var chem_fert_cost "Total costs on chemical fertilisers"
	gen chem_fert_cost_per_hectare = chem_fert_cost/(area_und_crop_ha)
	la var chem_fert_cost_per_hectare "Total costs on chemical fertilisers per hectare"
	
	winsor f5_2_16_pestcd_tot_cost, gen(pest_cost) p(0.005) high
	la var pest_cost "Total Costs on pesticides"
	gen pest_cost_per_hectare = pest_cost/(area_und_crop_ha)
	la var pest_cost_per_hectare "Total Costs on pesticides per hectare"
	
* Calculating the imputed costs using the prices calculated
	replace seed_total_cost = seed_total_amt * median_seed_price
	replace bio_fert_cost = bio_fert_amt * median_bio_fert_price
	replace hhl_cost_sow = hhl_amt_sow * median_wage_sow
	replace hhl_cost_sow_mgnregs = hhl_amt_sow * `WAGE_MGNREGS'
	replace hhl_cost_irr = hhl_amt_irr * median_wage_irr
	replace hhl_cost_irr_mgnregs = hhl_amt_irr * `WAGE_MGNREGS'
	replace hhl_cost_irr_adhoc = hhl_amt_irr_adhoc * median_wage_irr
	replace hhl_cost_harvest = hhl_amt_harvest * median_wage_hrvst
	replace hhl_cost_harvest_mgnregs = hhl_amt_harvest * `WAGE_MGNREGS'
	replace wgl_cost_sow = wgl_amt_sow * median_wage_sow
	replace wgl_cost_irr = wgl_amt_irr * median_wage_irr
	replace wgl_cost_harvest = wgl_amt_harvest * median_wage_hrvst
	
	winsor seed_total_cost, gen(seed_total_cost_wnsr) p(0.005) high
	drop seed_total_cost
	rename seed_total_cost_wnsr seed_total_cost
	la var seed_total_cost "Total costs spent on seeds"
	replace seed_total_cost = 0 if seed_total_cost == .
	gen seed_total_cost_per_hectare = seed_total_cost/(area_und_crop_ha)
	la var seed_total_cost_per_hectare "Total costs spent on seeds per hectare"
	
	winsor bio_fert_cost, gen(bio_fert_cost_wnsr) p(0.005) high
	drop bio_fert_cost
	rename bio_fert_cost_wnsr bio_fert_cost
	la var bio_fert_cost "Total costs spent on bio-fertilisers"
	replace bio_fert_cost = 0 if bio_fert_cost == .
	gen bio_fert_cost_per_hectare = bio_fert_cost/(area_und_crop_ha)
	la var bio_fert_cost_per_hectare "Total costs spent on bio-fertilisers per hectare"
	
	winsor hhl_cost_sow, gen(hhl_cost_sow_wnsr) p(0.005) high
	drop hhl_cost_sow
	rename hhl_cost_sow_wnsr hhl_cost_sow
	la var hhl_cost_sow "Total cost of house hold labour used for sowing"
	replace hhl_cost_sow = 0 if hhl_cost_sow == .
	gen hhl_cost_sow_per_hectare = hhl_cost_sow/(area_und_crop_ha)
	la var hhl_cost_sow_per_hectare "Total cost of house hold labour used for sowing per hectare"
	
	winsor hhl_cost_sow_mgnregs, gen(hhl_cost_sow_wnsr) p(0.005) high
	drop hhl_cost_sow_mgnregs
	rename hhl_cost_sow_wnsr hhl_cost_sow_mgnregs
	la var hhl_cost_sow_mgnregs "Total cost of hh labour used for sowing MGNREGS"
	replace hhl_cost_sow_mgnregs = 0 if hhl_cost_sow_mgnregs == .
	gen hhl_cost_sow_mgnregs_per_hectare = hhl_cost_sow_mgnregs/(area_und_crop_ha)
	la var hhl_cost_sow_mgnregs_per_hectare "Total cost of hh labour used for sowing per hectare MGNREGS"
	
	winsor hhl_cost_irr, gen(hhl_cost_irr_wnsr) p(0.005) high
	drop hhl_cost_irr
	rename hhl_cost_irr_wnsr hhl_cost_irr
	la var hhl_cost_irr "Total cost of house hold labour used for irrigation"
	replace hhl_cost_irr = 0 if hhl_cost_irr == .
	gen hhl_cost_irr_per_hectare = hhl_cost_irr/(area_und_crop_ha)
	la var hhl_cost_irr_per_hectare "Total cost of house hold labour used for irrigation per hectare"
	
	winsor hhl_cost_irr_mgnregs, gen(hhl_cost_irr_wnsr) p(0.005) high
	drop hhl_cost_irr_mgnregs
	rename hhl_cost_irr_wnsr hhl_cost_irr_mgnregs
	la var hhl_cost_irr_mgnregs "Total cost of hh labour used for irrigation MGNREGS"
	replace hhl_cost_irr_mgnregs = 0 if hhl_cost_irr_mgnregs == .
	gen hhl_cost_irr_mgnregs_per_hectare = hhl_cost_irr_mgnregs/(area_und_crop_ha)
	la var hhl_cost_irr_mgnregs_per_hectare "Total cost of hh labour used for irrigation per hectare MGNREGS"
	
	winsor hhl_cost_irr_adhoc, gen(hhl_cost_irr_adhoc_wnsr) p(0.005) high
	drop hhl_cost_irr_adhoc
	rename hhl_cost_irr_adhoc_wnsr hhl_cost_irr_adhoc
	la var hhl_cost_irr_adhoc "Total cost of house hold labour used for irrigation (2 hours per day)" 
	replace hhl_cost_irr_adhoc = 0 if hhl_cost_irr_adhoc == .
	gen hhl_cost_irr_adhoc_per_hectare = hhl_cost_irr_adhoc/(area_und_crop_ha)
	la var hhl_cost_irr_adhoc_per_hectare "Total cost of house hold labour used for irrigation per hectare (2 hours per day)" 
	
	
	winsor hhl_cost_harvest, gen(hhl_cost_harvest_wnsr) p(0.005) high
	drop hhl_cost_harvest
	rename hhl_cost_harvest_wnsr hhl_cost_harvest
	la var hhl_cost_harvest "Total cost of house hold labour used for harvesting"
	replace hhl_cost_harvest = 0 if hhl_cost_harvest == .
	gen hhl_cost_harvest_per_hectare = hhl_cost_harvest/(area_und_crop_ha)
	la var hhl_cost_harvest_per_hectare "Total cost of house hold labour used for harvesting per hectare"
	
	winsor hhl_cost_harvest_mgnregs, gen(hhl_cost_harvest_wnsr) p(0.005) high
	drop hhl_cost_harvest_mgnregs
	rename hhl_cost_harvest_wnsr hhl_cost_harvest_mgnregs
	la var hhl_cost_harvest_mgnregs "Total cost of hh labour used for harvesting MGNREGS"
	replace hhl_cost_harvest_mgnregs = 0 if hhl_cost_harvest_mgnregs == .
	gen hhl_cost_hvt_mgnregs_per_hectare = hhl_cost_harvest_mgnregs/(area_und_crop_ha)
	la var hhl_cost_hvt_mgnregs_per_hectare "Total cost of hh labour used for harvesting per hectare MGNREGS"
	
	winsor wgl_cost_sow, gen(wgl_cost_sow_wnsr) p(0.005) high
	drop wgl_cost_sow
	rename wgl_cost_sow_wnsr wgl_cost_sow
	la var wgl_cost_sow "Total cost of wage labour used for sowing"
	replace wgl_cost_sow = 0 if wgl_cost_sow == .
	gen wgl_cost_sow_per_hectare = wgl_cost_sow/(area_und_crop_ha)
	la var wgl_cost_sow_per_hectare "Total cost of wage hold labour used for sowing per hectare"
	
	winsor wgl_cost_irr, gen(wgl_cost_irr_wnsr) p(0.005) high
	drop wgl_cost_irr
	rename wgl_cost_irr_wnsr wgl_cost_irr
	la var wgl_cost_irr "Total cost of wage labour used for irrigation"
	replace wgl_cost_irr = 0 if wgl_cost_irr == .
	gen wgl_cost_irr_per_hectare = wgl_cost_irr/(area_und_crop_ha)
	la var wgl_cost_irr_per_hectare "Total cost of wage labour used for irrigation per hectare"
	
	
	winsor wgl_cost_harvest, gen(wgl_cost_harvest_wnsr) p(0.005) high
	drop wgl_cost_harvest
	rename wgl_cost_harvest_wnsr wgl_cost_harvest
	la var wgl_cost_harvest "Total cost of wage labour used for harvesting"
	replace wgl_cost_harvest = 0 if wgl_cost_harvest == .
	gen wgl_cost_harvest_per_hectare = wgl_cost_harvest/(area_und_crop_ha)
	la var wgl_cost_harvest_per_hectare "Total cost of wage labour used for harvesting per hectare"
	
// Generating fertiliser subsidy based on the reference from the paper (Assume 3889 Rs/Ha)
	gen fert_subsidy = d1_tot_land * 0.000009290304 * 3889
	winsor fert_subsidy, gen(fert_subsidy_wnsr) p(0.005) high
	drop fert_subsidy
	rename fert_subsidy_wnsr fert_subsidy
	la var fert_subsidy "Total Fertiliser Subsidy"
	
	gen icrop = 1
	bysort f_id : egen number_crops = total(icrop)
	drop icrop
	la var number_crops "Number of crops per farmer"
	gen fert_subsidy_crop = fert_subsidy/number_crops
	la var fert_subsidy_crop "Fertiliser subsidy per crop"
	
// Seed subsidy (Assuming 50%)
	gen seed_subsidy = seed_total_cost * 2
	la var seed_subsidy "Seed Subsidy"
		
* Machinary costs
	egen f6_1_1_hrs_use_1 = rowtotal(f6_1_1_hrs_use_crp1_1-f6_1_1_hrs_use_crp11_1)
	egen f6_1_1_hrs_use_2 = rowtotal(f6_1_1_hrs_use_crp1_2-f6_1_1_hrs_use_crp11_2)
	egen f6_1_1_hrs_use_3 = rowtotal(f6_1_1_hrs_use_crp1_3-f6_1_1_hrs_use_crp11_3)
	
	bysort f_id: egen total_tractor_use = sum(f6_1_1_hrs_use_crp_trctr), missing
	bysort f_id: egen total_harvester_use = sum(f6_1_1_hrs_use_crp_hvstr), missing
	bysort f_id: egen total_thresher_use = sum(f6_1_1_hrs_use_crp_trshr), missing
	
	gen total_exp_tractor = (f6_1_1_hrs_use_crp_trctr/total_tractor_use)*f6_1_3_farm_mach_expnse_1
	gen total_exp_harvester = (f6_1_1_hrs_use_crp_hvstr/total_harvester_use)*f6_1_3_farm_mach_expnse_2
	gen total_exp_thresher = (f6_1_1_hrs_use_crp_trshr/total_thresher_use)*f6_1_3_farm_mach_expnse_3
	winsor total_exp_thresher, gen(tot_exp_thresher_wnsr) p(0.005) high
	winsor total_exp_harvester, gen(tot_exp_harvester_wnsr) p(0.005) high
	winsor total_exp_tractor, gen(tot_exp_tractor_wnsr) p(0.005) high
	drop total_exp_tractor
	drop total_exp_harvester
	drop total_exp_thresher
	rename tot_exp_thresher_wnsr total_exp_thresher
	la var total_exp_thresher "Total expenditure on thresher by crop"
	replace total_exp_thresher = 0 if total_exp_thresher == .
	
	rename tot_exp_harvester_wnsr total_exp_harvester
	la var total_exp_harvester "Total expenditure on harvester by crop"
	replace total_exp_harvester = 0 if total_exp_harvester == .
	
	rename tot_exp_tractor_wnsr total_exp_tractor
	la var total_exp_tractor "Total expenditure on tractor by crop"
	replace total_exp_tractor = 0 if total_exp_tractor == .
	
	gen total_exp_thresher_per_hectare = total_exp_thresher/(area_und_crop_ha)
	la var total_exp_thresher_per_hectare "Total expenditure on thresher by crop per hectare"
	
	gen total_exp_harvester_per_hectare = total_exp_harvester/(area_und_crop_ha)
	la var total_exp_harvester_per_hectare "Total expenditure on harvester by crop per hectare"
	
	gen total_exp_tractor_per_hectare = total_exp_tractor/(area_und_crop_ha)
	la var total_exp_tractor_per_hectare "Total expenditure on tractor by crop per hectare"
	
	egen mach_exp = rowtotal(total_exp_thresher total_exp_harvester total_exp_tractor), missing
	winsor mach_exp, gen(wnsr) p(0.005) high
	drop mach_exp
	rename wnsr mach_exp
	la var mach_exp "Total expenditure on machinary by crop"
	gen mach_exp_per_hectare = mach_exp/(area_und_crop_ha)
	la var mach_exp_per_hectare "Total expenditure on machinary by crop per hectare"
	
//=========================== Electricity costs ================================

/*
* First I need to calculate how many hours are spent on each crop, and then multiply it 
* by the number of times it is irrigated
	gen irr_multiplier = .
	* I here use only those observations where the estimate was the number of hours
	* of irrigation, that is response number 3.
	replace irr_multiplier = f5_1_4_avg_irr if f5_1_2_est_wtr_amt == 3
	* For the rest, I make use of the fact that SDO and crop type would approximately
	* use the same amount of hours.
	bysort sdo_num f1_3_crops_plntd : egen median_irr_multiplier = median(irr_multiplier)
	replace median_irr_multiplier = irr_multiplier if irr_multiplier != .
	sort f_id
	egen tot_pre_harv_irr = rowtotal(f5_1_6_8_irr_cnt_presow_pcl1 - f5_1_6_8_irr_cnt_presow_pcl15), missing
	egen tot_post_harv_irr = rowtotal(f5_1_6_2_irr_cnt_crp_pcl1 - f5_1_6_2_irr_cnt_crp_pcl15), missing
	replace tot_pre_harv_irr = 0 if tot_pre_harv_irr == .
	replace tot_post_harv_irr = 0 if tot_post_harv_irr == .
	egen tot_irr_time = rowtotal(tot_pre_harv_irr tot_post_harv_irr), missing
	gen tot_irr_hr = median_irr_multiplier * tot_irr_time
*/

	gen elec_exp_subsidy = tot_elec_crop_hp * 0.7457 * 0.9
	
//========================== Calculating costs for missing crops ===============
	bysort SDO resp_num crop_type : egen median_eleccrop = median(elec_exp_subsidy)
	replace elec_exp_subsidy = median_eleccrop if resp_num == 1 & elec_exp_subsidy == 0
	drop median_eleccrop
	
	sort f_id crop
	
	gen elec_exp_sub_irr = 42 * 6 * b7_1_avg_pmp_cap * 0.7457 * 0.9
	winsor elec_exp_subsidy, gen(elec_exp_wnsr) p(0.005) high
	drop elec_exp_subsidy
	rename elec_exp_wnsr elec_exp_subsidy
	la var elec_exp_subsidy "Total electricity expenditure by crop (subsidised)"
	gen elec_exp_no_subsidy = elec_exp_subsidy * 4.85/0.9
	la var elec_exp_no_subsidy "Total electricity expenditure by crop (non subsidised)"
	winsor elec_exp_sub_irr, gen(wnsr) p(0.005) high
	drop elec_exp_sub_irr
	rename wnsr elec_exp_sub_irr 
	la var elec_exp_sub_irr "Total electricity expenditure by crop (subsidised)"
	
	gen elec_exp_subsidy_per_hectare = elec_exp_subsidy/(area_und_crop_ha)
	la var elec_exp_subsidy_per_hectare "Total electricity expenditure by crop per hectare (subsidised)"
	gen elec_exp_no_subsidy_per_hectare = elec_exp_no_subsidy/(area_und_crop_ha)
	la var elec_exp_no_subsidy_per_hectare "Total electricity expenditure by crop per hectare (non subsidised)"
	
	//bysort f_id : egen tot_irr_hr_farmer = sum(tot_irr_hr)
	//la var tot_irr_hr_farmer "Total irrigation time in hours by farmer"
	
	//gen frac_irr_hr = tot_irr_hr/tot_irr_hr_farmer
	//la var frac_irr_hr "Fraction of total hours of irrigation"

	
	
//============== Generating total electricity costs ============================
	
	bysort f_id : egen tot_elec_exp_subsidy = sum(elec_exp_subsidy)
	la var tot_elec_exp_subsidy "Total electricity expenditure by farmer (subsidised)"
	
	bysort f_id : egen tot_elec_exp_no_subsidy = sum(elec_exp_no_subsidy)
	la var tot_elec_exp_no_subsidy "Total electricity expenditure by farmer (non subsidised)"
	
	
//====================== Calculating total costs ===============================

	winsor f5_4_10_trnsprt_cost, gen(f5_4_10_trnsprt_cost_wnsr) p(0.005) high
	drop f5_4_10_trnsprt_cost
	rename f5_4_10_trnsprt_cost_wnsr f5_4_10_trnsprt_cost
	la var f5_4_10_trnsprt_cost "Transport costs by crop"
	gen f5_4_10_trnsprt_cost_per_hectare = f5_4_10_trnsprt_cost/(area_und_crop_ha)
	la var f5_4_10_trnsprt_cost_per_hectare "Transport costs by crop per hectare"
	
	egen impu_cost = rowtotal(seed_total_cost bio_fert_cost chem_fert_cost hhl_cost_sow hhl_cost_irr hhl_cost_harvest ///
		 wgl_cost_sow wgl_cost_irr wgl_cost_harvest pest_cost elec_exp_subsidy mach_exp f5_4_10_trnsprt_cost), missing
	gen impu_cost_zero_labor = impu_cost - hhl_cost_sow - hhl_cost_irr - hhl_cost_harvest
	gen impu_cost_nreg_labor = impu_cost_zero_labor + hhl_cost_sow_mgnregs + ///
	hhl_cost_irr_mgnregs + hhl_cost_harvest_mgnregs
	winsor impu_cost, gen(wnsr) p(0.005) high
	drop impu_cost
	rename wnsr impu_cost
	winsor impu_cost_zero_labor, gen(wnsr) p(0.005) high
	drop impu_cost_zero_labor
	rename wnsr impu_cost_zero_labor
	winsor impu_cost_nreg_labor, gen(wnsr) p(0.005) high
	drop impu_cost_nreg_labor
	rename wnsr impu_cost_nreg_labor
	
	egen impu_cost_adhoc = rowtotal(seed_total_cost bio_fert_cost chem_fert_cost hhl_cost_sow hhl_cost_irr_adhoc hhl_cost_harvest ///
		 wgl_cost_sow wgl_cost_irr wgl_cost_harvest pest_cost elec_exp_subsidy mach_exp f5_4_10_trnsprt_cost), missing
	winsor impu_cost_adhoc, gen(wnsr) p(0.005) high
	drop impu_cost_adhoc
	rename wnsr impu_cost_adhoc
	
	
	
//========= Had to convert the imputed costs of crop 100, -499, and 702 to missing value =========

	replace impu_cost = . if f1_3_crops_plntd == 100
	replace impu_cost = . if f1_3_crops_plntd == -499
	replace impu_cost = . if f1_3_crops_plntd == 702
	la var impu_cost "Total imputed cost by crop"
	
	replace impu_cost_adhoc = . if f1_3_crops_plntd == 100
	replace impu_cost_adhoc = . if f1_3_crops_plntd == -499
	replace impu_cost_adhoc = . if f1_3_crops_plntd == 702
	la var impu_cost "Total imputed cost by crop"
	
	gen impu_cost_per_hectare = impu_cost/(area_und_crop_ha)
	la var impu_cost_per_hectare "Total imputed cost by crop per hectare"
	
	replace impu_cost_zero_labor = . if f1_3_crops_plntd == 100
	replace impu_cost_zero_labor = . if f1_3_crops_plntd == -499
	replace impu_cost_zero_labor = . if f1_3_crops_plntd == 702
	la var impu_cost_zero_labor "Total imputed cost by crop zero labor"
	
	gen impu_cost_per_hectare_zero_labor = impu_cost_zero_labor/(area_und_crop_ha)
	la var impu_cost_per_hectare_zero_labor "Total imputed cost by crop per hectare zero labor"
	
	replace impu_cost_nreg_labor = . if f1_3_crops_plntd == 100
	replace impu_cost_nreg_labor = . if f1_3_crops_plntd == -499
	replace impu_cost_nreg_labor = . if f1_3_crops_plntd == 702
	la var impu_cost_nreg_labor "Total imputed cost by crop MGNREGS labor"
	
	gen impu_cost_per_hectare_nreg_labor = impu_cost_nreg_labor/(area_und_crop_ha)
	la var impu_cost_per_hectare_nreg_labor "Total imputed cost by crop per hectare MGNREGS labor"
	
	gen impu_cost_per_hectare_adhoc = impu_cost_adhoc/(area_und_crop_ha)
	la var impu_cost_per_hectare_adhoc "Total imputed cost by crop per hectare"
	
	
//===================== Total imputed profits ==================================
	gen impu_profit = impu_value - impu_cost
	la var impu_profit "Total imputed profit by crop"
	
	gen impu_profit_zero_labor = impu_value - impu_cost_zero_labor
	la var impu_profit_zero_labor "Total imputed profit by crop zero labor"
	
	gen impu_profit_nreg_labor = impu_value - impu_cost_nreg_labor
	la var impu_profit_nreg_labor "Total imputed profit by crop MGNREGS labor"
	
	gen impu_profit_adhoc = impu_value - impu_cost_adhoc
	la var impu_profit_adhoc "Total imputed profit by crop"
	
	gen impu_profit_per_hectare = impu_value_per_hectare - impu_cost_per_hectare
	la var impu_profit_per_hectare "Total imputed profit by crop per hectare"
	
	gen impu_profit_per_hectare_zero_lab = impu_value_per_hectare - impu_cost_per_hectare_zero_labor
	la var impu_profit_per_hectare_zero_lab "Total imputed profit by crop per hectare zero labor"
	
	gen impu_profit_per_hectare_nreg_lab = impu_value_per_hectare - impu_cost_per_hectare_nreg_labor
	la var impu_profit_per_hectare_nreg_lab "Total imputed profit by crop per hectare MGNREGS labor"
	
	gen impu_profit_per_hectare_adhoc = impu_value_per_hectare - impu_cost_per_hectare_adhoc
	la var impu_profit_per_hectare "Total imputed profit by crop per hectare"
	
	
//=================== Reported profits and losses ==============================
	gen neg_rep_loss = -1 * f5_4_15_tot_loss
	winsor neg_rep_loss, gen(wnsr) p(0.005) high
	drop neg_rep_loss
	rename wnsr neg_rep_loss
	winsor f5_4_12_tot_profit, gen(wnsr) p(0.005) high
	drop f5_4_12_tot_profit
	rename wnsr f5_4_12_tot_profit
	egen rep_net_profit = rowtotal(f5_4_12_tot_profit neg_rep_loss), missing
	winsor rep_net_profit, gen(wnsr) p(0.005) high
	drop rep_net_profit
	rename wnsr rep_net_profit
	la var rep_net_profit "Reported Net Profits"
	
	gen rep_net_profit_per_hectare = rep_net_profit/(area_und_crop_ha)
	la var rep_net_profit_per_hectare "Reported Net Profits by crop per hectare"
	
	
* Generating shares of costs in the total cost
	gen share_seed_cost = seed_total_cost/impu_cost
	gen share_bio_fert_cost = bio_fert_cost/impu_cost
	gen share_hhl_sow_cost = hhl_cost_sow/impu_cost
	gen share_hhl_irr_cost = hhl_cost_irr/impu_cost
	gen share_hhl_harvest_cost = hhl_cost_harvest/impu_cost
	gen share_wgl_sow_cost = wgl_cost_sow/impu_cost
	gen share_wgl_irr_cost = wgl_cost_irr/impu_cost
	gen share_wgl_harvest_cost = wgl_cost_harvest/impu_cost
	gen share_elec_exp_subsidy = elec_exp_subsidy/impu_cost
	gen share_transport_cost = f5_4_10_trnsprt_cost/impu_cost
	gen share_mach_exp = mach_exp/impu_cost
	la var share_seed_cost "Share of seeds to total costs"
	la var share_bio_fert_cost "Share of bio-fertilisers to total costs"
	la var share_hhl_sow_cost "Share of household labour for sowing to total costs"
	la var share_hhl_irr_cost "Share of household labour for irrigation to total costs"
	la var share_hhl_harvest_cost "Share of household labour for harvesting to total costs"
	la var share_wgl_sow_cost "Share of wage labour for sowing to total costs"
	la var share_wgl_irr_cost "Share of wage labour for irrigation to total costs"
	la var share_wgl_harvest_cost "Share of wage labour for harvesting to total costs"
	la var share_elec_exp "Share of electricity expenditure to total costs"
	la var share_transport_cost "Share of transport costs to total costs"
	la var share_mach_exp "Share of costs spent on machinary"
	
* Generating feeder level water depth
// 		forvalues i=1/4 {
// 		gen b7_3_3_surce_curr_dpth`i'_ft = .
// 		replace b7_3_3_surce_curr_dpth`i'_ft = b7_3_3_surce_dpth_`i'_ft if b7_3_8_curr_dpth_surce_`i'_ft ==.
// 		replace b7_3_3_surce_curr_dpth`i'_ft = b7_3_8_curr_dpth_surce_`i'_ft if b7_3_8_curr_dpth_surce_`i'_ft !=.
// 		}
// 		egen avg_source_depth = rowmean(b7_3_3_surce_curr_dpth*_ft)
// 		la var avg_source_depth "Average reported well depth for farmer (ft)"
		
// 		bysort sdo_feeder_code : egen fdr_avg_dpth = mean(avg_source_depth) 
// 		la var fdr_avg_dpth "Average depth of water by feeder code"
// 		sort f_id
		
		
//================ Creating sprinker irrigation statistics =====================

gen area_under_irrigated = 0
gen area_sprinkler = 0
gen area_irrigated = 0
	
forvalues i = 1/15 {
	replace area_sprinkler = area_sprinkler + f5_1_6_1_irriga_area_pcl`i'_sqft ///
	if f5_1_6_5_irr_tech_pcl_spr`i' != . & f5_1_6_1_irriga_area_pcl`i'_sqft != .
	replace area_under_irrigated = area_under_irrigated + f5_1_6_1_irriga_area_pcl`i'_sqft ///
	if f5_1_6_4_irr_adqcy_pcl`i' == 3 & f5_1_6_1_irriga_area_pcl`i'_sqft != .
	replace area_irrigated = area_irrigated + f5_1_6_1_irriga_area_pcl`i'_sqft ///
	if f5_1_6_1_irriga_area_pcl`i'_sqft != .
}
	
la var area_sprinkler "Area of the crop under sprinkler irrigation"
la var area_under_irrigated "Area of the crop under irrigated"
la var area_irrigated "Area of the crop irrigated"
	
sort f_id
by f_id: egen tot_area_sprinkler = sum(area_sprinkler)
by f_id: egen tot_area_under_irrigated = sum(area_under_irrigated)
by f_id: egen tot_area_irrigated = sum(area_irrigated)
	
la var tot_area_sprinkler "Total area under sprinkler irrigation"
la var tot_area_under_irrigated "Total area under irrigated by farmer"
la var tot_area_irrigated "Total area irrigated by farmer"
	
gen prop_area_sprinkler = 100*tot_area_sprinkler/tot_area_irrigated
gen prop_area_under_irrigated = 100*tot_area_under_irrigated/tot_area_irrigated
	
la var prop_area_sprinkler "Proportion of area under sprinkler irrigation"
la var prop_area_under_irrigated "Proportion of area under irrigated"
		
		
		
//==== Creating dummies for water hardy crops, and water intensive crops =======
	gen water_hardy = 0
	gen water_moderate = 0
	gen water_intensive = 0
	la var water_hardy "Water hardiness"
	la var water_intensive "Water intensiveness"
	la var water_moderate "Water moderateness"
	
	replace water_hardy = 1 if f1_3_crops_plntd == 308 | ///
			f1_3_crops_plntd == 617 | f1_3_crops_plntd == 306 | ///
			f1_3_crops_plntd == 107 | f1_3_crops_plntd == 105 | ///
			f1_3_crops_plntd == 624 | f1_3_crops_plntd == 638 | /// 
			f1_3_crops_plntd == 207 | f1_3_crops_plntd == 315
	replace water_moderate = 1 if f1_3_crops_plntd == 608 | ///
			f1_3_crops_plntd == 302 | f1_3_crops_plntd == 104 | ///
			f1_3_crops_plntd == 303 | f1_3_crops_plntd == 707 | ///
			f1_3_crops_plntd == 609 | f1_3_crops_plntd == 102 | /// 
			f1_3_crops_plntd == 628 | f1_3_crops_plntd == 607 | ///
			f1_3_crops_plntd == 208 | f1_3_crops_plntd == 210 | /// 
			f1_3_crops_plntd == 619 | f1_3_crops_plntd == 711 | ///
			f1_3_crops_plntd == 313 | f1_3_crops_plntd == 611 | ///
			f1_3_crops_plntd == -399 | f1_3_crops_plntd == 103
	replace water_intensive = 1 if f1_3_crops_plntd == 501 | ///
			f1_3_crops_plntd == 101 | f1_3_crops_plntd == 643 | ///
			f1_3_crops_plntd == 902 | f1_3_crops_plntd == 903 | ///
			f1_3_crops_plntd == 100 | f1_3_crops_plntd == 715 | /// 
			f1_3_crops_plntd == 605 | f1_3_crops_plntd == 623 | ///
			f1_3_crops_plntd == 630 | f1_3_crops_plntd == 640 | ///
			f1_3_crops_plntd`i' == 604
	label define hardy 0 "Not water hardy" 1 "Water hardy"
	label define moderate 0 "Not water moderate" 1 "Water moderate"
	label define intensive 0 "Not water intensive" 1 "Water intensive"
	label values water_hardy hardy
	label values water_moderate moderate
	label values water_intensive intensive
	
	
	
//================= Generating Water Intensity measures ========================

	gen f1_3_wat_intst = .
	replace f1_3_wat_intst = 2200 if f1_3_crops_plntd == 501
	replace f1_3_wat_intst = 1050 if f1_3_crops_plntd == 902
	replace f1_3_wat_intst = 1000 if f1_3_crops_plntd == 100 
	replace f1_3_wat_intst = 840 if f1_3_crops_plntd == 604 
	replace f1_3_wat_intst = 750 if f1_3_crops_plntd == 715 
	replace f1_3_wat_intst = 650 if f1_3_crops_plntd == 605
	replace f1_3_wat_intst = 600 if f1_3_crops_plntd == 623 
	replace f1_3_wat_intst = 600 if f1_3_crops_plntd == 630 
	replace f1_3_wat_intst = 600 if f1_3_crops_plntd == 640 
	replace f1_3_wat_intst = 585 if f1_3_crops_plntd == 608 
	replace f1_3_wat_intst = 550 if f1_3_crops_plntd == 611 
	replace f1_3_wat_intst = 490 if f1_3_crops_plntd == 609 
	replace f1_3_wat_intst = 450 if f1_3_crops_plntd == 102 
	replace f1_3_wat_intst = 450 if f1_3_crops_plntd == 628 
	replace f1_3_wat_intst = 430 if f1_3_crops_plntd == 607 
	replace f1_3_wat_intst = 425 if f1_3_crops_plntd == 208 
	replace f1_3_wat_intst = 425 if f1_3_crops_plntd == 210 
	replace f1_3_wat_intst = 425 if f1_3_crops_plntd == 619 
	replace f1_3_wat_intst = 425 if f1_3_crops_plntd == 711 
	replace f1_3_wat_intst = 400 if f1_3_crops_plntd == 313 
	replace f1_3_wat_intst = 400 if f1_3_crops_plntd == -399 
	replace f1_3_wat_intst = 350 if f1_3_crops_plntd == 308 
	replace f1_3_wat_intst = 325 if f1_3_crops_plntd == 617 
	replace f1_3_wat_intst = 300 if f1_3_crops_plntd == 624 
	replace f1_3_wat_intst = 290 if f1_3_crops_plntd == 638 
	replace f1_3_wat_intst = 275 if f1_3_crops_plntd == 207 

	la var f1_3_wat_intst "Water requirement (mm)"
	
	gen water_requiremnt_lperha = f1_3_wat_intst * 10000
	la var water_requiremnt_lperha "Water requirement (l/Ha)"
	
//========== Generating amount paid per unit time ==============================

	forvalues x=1/9 {
		gen waterprice_per_hour`x' = e2_7_3_wtr_trnsfr_price_`x'/e2_7_9_hours_wtr_tkn_`x'
		
		la var waterprice_per_hour`x' "Water price per hour"
		
		gen waterprice_per_liter`x' = waterprice_per_hour`x'/liter_per_hour
		
		la var waterprice_per_liter`x' "Water price per liter"
	}
	
	
//========== Creating all the input variables for each farmers =================

gen capital_cost = pest_cost + chem_fert_cost + bio_fert_cost + seed_total_cost ///
+ total_exp_thresher + total_exp_tractor + total_exp_harvester

la var capital_cost "Capital Cost (Rs.)"
la var pest_cost "Pesticide Costs (Rs.)"
la var chem_fert_cost "Chem. Fert. Costs (Rs.)"
la var bio_fert_cost "Bio. Fert. Costs (Rs.)"
la var seed_total_cost "Seed Costs (Rs.)"
la var total_exp_thresher "Thresher Costs (Rs.)"
la var total_exp_tractor "Tractor Costs (Rs.)"
la var total_exp_harvester "Harvester Costs (Rs.)"

/*replace f5_3_5_hh_lab_days = 0.25*f5_3_5_hh_lab_days
gen tot_hh_days = f5_3_1_hh_lab_days + f5_3_5_hh_lab_days + f5_3_9_hh_lab_days
la var tot_hh_days "Household Labour (days)"
la var f5_3_1_hh_lab_days "Sowing (days)"
la var f5_3_5_hh_lab_days "Irrigation (days)"
la var f5_3_9_hh_lab_days "Harvesting (days)"


gen tot_wg_days = f5_3_3_wage_lab_days + f5_3_7_wage_lab_days + f5_3_11_wage_lab_days
la var tot_wg_days "Wage Labour (days)"
la var f5_3_3_wage_lab_days "Sowing (days)"
la var f5_3_7_wage_lab_days "Irrigation (days)"
la var f5_3_11_wage_lab_days "Harvesting (days)"

gen tot_days = tot_hh_days + tot_wg_days
la var tot_days "Total Labour (days)"
*/

winsor hhl_amt_sow, gen(hhl_wnsr) p(0.01) highonly
drop hhl_amt_sow
rename hhl_wnsr hhl_amt_sow

winsor hhl_amt_irr, gen(hhl_wnsr) p(0.01) highonly
drop hhl_amt_irr
rename hhl_wnsr hhl_amt_irr

winsor hhl_amt_harvest, gen(hhl_wnsr) p(0.01) highonly
drop hhl_amt_harvest
rename hhl_wnsr hhl_amt_harvest


egen tot_hh_days = rowtotal(hhl_amt_sow hhl_amt_irr hhl_amt_harvest), missing
la var tot_hh_days "Household Labour (workerxdays)"
la var hhl_amt_sow "Sowing (workerxdays)"
la var hhl_amt_irr "Irrigation (workerxdays)"
la var hhl_amt_harvest "Harvesting (workerxdays)"


winsor wgl_amt_sow, gen(hhl_wnsr) p(0.01) highonly
drop wgl_amt_sow
rename hhl_wnsr wgl_amt_sow

winsor wgl_amt_irr, gen(hhl_wnsr) p(0.01) highonly
drop wgl_amt_irr
rename hhl_wnsr wgl_amt_irr

winsor wgl_amt_harvest, gen(hhl_wnsr) p(0.01) highonly
drop wgl_amt_harvest
rename hhl_wnsr wgl_amt_harvest


egen tot_wg_days = rowtotal(wgl_amt_sow  wgl_amt_irr  wgl_amt_harvest), missing
la var tot_wg_days "Wage Labour (workerxdays)"
la var wgl_amt_sow "Sowing (workerxdays)"
la var wgl_amt_irr "Irrigation (workerxdays)"
la var wgl_amt_harvest "Harvesting (workerxdays)"

// Generate composite wage by SDO
gen wage_weighted = (wgl_amt_sow*median_wage_sow + wgl_amt_irr*median_wage_irr + wgl_amt_harvest*median_wage_hrvst)/(wgl_amt_sow + wgl_amt_irr + wgl_amt_harvest)
replace wage_weighted = 0 if wgl_amt_sow ==0 & wgl_amt_irr == 0 & wgl_amt_harvest == 0  

egen tot_days = rowtotal(tot_hh_days tot_wg_days), missing
la var tot_days "Total Labour (workerxdays)"

egen labour_rupees = rowtotal(hhl_cost_sow hhl_cost_irr hhl_cost_harvest wgl_cost_sow wgl_cost_irr wgl_cost_harvest)
replace labour_rupees = labour_rupees/1000
la var labour_rupees "Labour ('000 INR)"

gen tot_irr_labour = wgl_amt_irr + hhl_amt_irr
la var tot_irr_labour "Total amount of labour used for irrigation"


//============================== Generating improved land and labour costs ==========================

egen improved_labour = rowtotal(hhl_cost_sow hhl_cost_irr hhl_cost_harvest wgl_cost_sow ///
 wgl_cost_irr wgl_cost_harvest total_exp_thresher total_exp_tractor total_exp_harvester)
la var improved_labour "Improved Labour"

gen augmented_labour = labour_rupees + capital_cost
la var augmented_labour "Labour (augmented)"

local BHIGA_TO_SQFT = 27225

egen mean_land_rentout = rowmean(e2_5_4_lnd_leas_rate_*)
replace mean_land_rentout = mean_land_rentout/`BHIGA_TO_SQFT'

egen mean_land_rentin = rowmean(e2_9_3_rate_lnd_leas_in_*)
replace mean_land_rentin = mean_land_rentin/`BHIGA_TO_SQFT'

egen mean_land_rent = rowmean(mean_land_rentout mean_land_rentin)
la var mean_land_rent "Land rent per square feet"

bysort SDO: egen land_rent_SDO = mean(mean_land_rent)
la var land_rent_SDO "Land rent per square feet in SDO"

sort f_id crop
gen land_costs1 = f1_4_3_area_und_crp_sqft * land_rent_SDO
egen improved_land = rowtotal(land_costs1 pest_cost chem_fert_cost bio_fert_cost seed_total_cost)
la var land_costs1 "Land Costs (average rents)"
la var improved_land "Improved Land (average rents)"

bysort SDO: egen land_rent_SDO1 = median(mean_land_rent)
la var land_rent_SDO1 "Land rent per square feet in SDO"

sort f_id crop
gen land_costs2 = f1_4_3_area_und_crp_sqft * land_rent_SDO1
egen improved_land1 = rowtotal(land_costs2 pest_cost chem_fert_cost bio_fert_cost seed_total_cost)
la var land_costs2 "Land Costs (median rents)"
la var improved_land1 "Improved Land (median rents)"

egen material_costs = rowtotal(pest_cost chem_fert_cost bio_fert_cost seed_total_cost)
la var material_costs "Material Costs (in Rupees)"



//*****************************************************************************************************
//									RATION BINDS ON ALL DIMENSIONS
//*****************************************************************************************************

//================================= Sanctioned Load vs Actual Load =====================================

// Construct and label variables
egen sanctioned_load = rowtotal(a5_4_6_sanct_load_conn*), missing 
la var sanctioned_load "Sanctioned load (HP)"
egen actual_load = rowtotal(b7_1_3_pmp_cpcty_*_hp), missing
la var actual_load "Actual load (HP)"

gen load_ratio = actual_load/sanctioned_load
la var load_ratio "Ratio Actual/Sanctioned load"


// Histogram of load ratio
preserve
replace load_ratio = load_ratio - 0.25
keep if load_ratio >= 0
hist load_ratio, graphregion(color(white)) plotregion(color(white)) fcolor(midblue) lcolor(black) xline(1, lwidth(0.5) lpattern(dash)) width(0.25) xlabel(0(1)4)
graph export "`FIGURES'/hist_load_ratio.pdf", replace
restore
		

// Plot figure with sanctioned load (x-axis) and actual load (y-axis) with 45-degree line
bys actual_load sanctioned_load: gen marker_size = _N
tw (scatter actual_load sanctioned_load [w=marker_size], graphregion(color(white)) bgcolor(white) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")) (line sanctioned_load sanctioned_load) if sanctioned_load < 20

graph export "`FIGURES'/fig_sanctioned_actual_load.pdf", replace

//================================= Farmer pump capacity vs land size =============================
preserve

la var pump_farmer "Farmer pump capacity (HP)"

// Land owned in hectares
gen tot_land_owned = 1/107639*d1_tot_land
la var tot_land_owned "Land owned (ha)"

lpoly pump_farmer tot_land_owned, graphregion(color(white)) bgcolor(white) bwidth(0.5) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_land_pump_capacity.pdf", replace

restore

// ============================ Historgram of wait time for connection =============================
preserve

if c(mode) == "batch" {
	local PROJECT_ROOT = strrtrim("`0'")
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
use "`CLEAN_WAITING_DATA'/waiting_times_all.dta", clear
la var months "Waiting time (years) between application and connection being permitted"
hist months, graphregion(color(white)) plotregion(color(white)) fcolor(midblue) lcolor(black) ///
 xlabel(0 "0" 12 "1" 24 "2" 36 "3" 48 "4" 60 "5" 72 "6" 84 "7" 96 "8" 108 "9" 120 "10") xline(84, lwidth(0.5) lpattern(dash)) width(4) start(0)
graph export "`FIGURES'/hist_waiting_times.pdf", replace

restore

sort f_id crop
save "`CLEAN_FARMER_SURVEY'/baseline_survey_farmer_crop_with_imputed_variables.dta", replace



