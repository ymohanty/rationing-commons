//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//						Generate structural sample
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if `MATLABSAMPLE' == 1 {
  
// Generate farmer plot id
gen f_id_s = string(f_id)
gen crop_s = string(crop)
gen farmer_plot_id = f_id_s + crop_s

// Create crop type labels
gen crop_type = "Others"
replace crop_type = "Fielspea" if f1_3_crops_plntd == 208
replace crop_type = "Wheat" if f1_3_crops_plntd == 102
replace crop_type = "Mustard" if f1_3_crops_plntd == 308
replace crop_type = "Lentil" if f1_3_crops_plntd == 207
replace crop_type = "Bengalgram" if f1_3_crops_plntd == 210
replace crop_type = "Rajka" if f1_3_crops_plntd == 100
replace crop_type = "Coriander" if f1_3_crops_plntd == 611
replace crop_type = "Barley" if f1_3_crops_plntd == 103
replace crop_type = "Fenugreek" if f1_3_crops_plntd == 617
replace crop_type = "Garlic" if f1_3_crops_plntd == 711
replace crop_type = "Sugarcane" if f1_3_crops_plntd == 501
replace crop_type = "Orange" if f1_3_crops_plntd == 902

la var crop_type "Crop Type"

// Create dummy variables of each crop
gen wheat = cond(crop_type == "Wheat", 1, 0)
gen fielspea = cond(crop_type == "Fielspea", 1, 0)
gen mustard = cond(crop_type == "Mustard", 1, 0)
gen lentil = cond(crop_type == "Lentil", 1, 0)
gen rajka = cond(crop_type == "Rajka", 1, 0)
gen bengalgram = cond(crop_type == "Bengalgram", 1, 0)
gen coriander = cond(crop_type == "Coriander", 1, 0)
gen barley = cond(crop_type == "Barley", 1, 0)
gen fenugreek = cond(crop_type == "Fenugreek", 1, 0)
gen garlic = cond(crop_type == "Garlic", 1, 0)
gen sugarcane = cond(crop_type == "Sugarcane", 1, 0)
gen orange = cond(crop_type == "Orange", 1, 0)
gen other = cond(crop_type == "Other", 1, 0)

// Reformat to Nick's specifications in the spreadsheet
rename f_id farmer_id
rename crop plot_id
rename farmer_well_depth depth
rename water_requirement crop_water_req
drop revenue
rename revenue_t revenue
rename f5_4_2_prod_level_exptn prod_below_expect
rename f5_4_3_lost_pre_hrvst crop_lost_preharvest
rename f5_4_4_lost_post_hrvst crop_lost_postharvest
rename d1_5_parcels_land land_parcels
la var land_parcels "Number of land parcels"
rename a2_9_hh_male hh_adult_males
rename a2_11_1_youngest_age age_youngest_member
la var age_youngest_member "Age of youngest member"

rename a3_5_3_non_agr_prft non_agricultural_profit
la var non_agricultural_profit "Non agricultural profit (Rs.)"

rename a3_6_2_sal_emp_est_prft salaried_profit
la var salaried_profit "Salaried profit (Rs.)"

rename f5_3_4_avg_wage_sow land_prep_wage
la var land_prep_wage "Land preparation wages (Rs.)"

// Generate square of adult males
gen sq_hh_adult_males = hh_adult_males^2
la var sq_hh_adult_males "Squared num. adult males"

// Generate square of youngest age
gen sq_age_youngest_member = age_youngest_member^2
la var sq_age_youngest_member "Squared age youngest member"

// Generate dummy variables for parcel leveling
forval i = 1/15 {
	gen parcel_leveled_pre_sow`i' = f5_1_6_7_level_pcl`i'
	replace parcel_leveled_pre_sow`i' = 0 if parcel_leveled_pre_sow`i' == 2
}

// Generate dummy variables for whether crop is under irrigated/over irrigated
forval i = 1/15 {
	gen under_irrigated_parcel`i' = cond(f5_1_6_4_irr_adqcy_pcl`i' == 3, 1, 0)
	replace under_irrigated_parcel`i' = . if missing(f5_1_6_4_irr_adqcy_pcl`i')
}

// Convert to sqft 
gen land_owned_pakka = 1/107639*d1_2_pakka_sqft
la var land_owned_pakka "Land owned (pakka) (Ha)"

gen land_owned_kacha = 1/107639*d1_3_kacha_sqft
la var land_owned_kacha "Land owned (kacha) (Ha)"

gen tot_land_owned = 1/107639*d1_tot_land


// Gen high yield variety dummy
gen crop_hyv = 0
replace crop_hyv = 1 if f1_4_2_crop_variety == 1 
la var crop_hyv "High-yielding variety grown"

// Generate area irrigated for each crop
gen crop_area_irrigated = 0
forval i = 1/15 {
	forval j = 1/11 {
		replace crop_area_irrigated = crop_area_irrigated + f5_1_6_1_irr_area_pcl`i'_`j'_sqft if plot_id == `j' & !missing(f5_1_6_1_irr_area_pcl`i'_`j'_sqft)
	}
}

// Convert to hectares from sqft
replace crop_area_irrigated = 1/107639*crop_area_irrigated
la var crop_area_irrigated "Land area irrigated for crop (ha)"

// ~~~~~~~~~~~ Create order statistic variables on the parcel size for each crop ~~~~~~~~~~~~

// Split the crop-parcel map variable into dummy variables which indicate if a crop is grown on the 'i'th parcel
forval i = 1/15 {
	gen crop_in_parcel_`i' = regexm(f5_1_5_parcel_crop,"`i' ") | regexm(f5_1_5_parcel_crop, " `i'") | regexm(f5_1_5_parcel_crop, "3`i'") | f5_1_5_parcel_crop == "`i'" 
}

// Set parcel sizes to 0 if that parcel is not used for this crop
forval i = 1/15 {
	gen parcel_`i'_size = crop_in_parcel_`i'*d2_1_tot_size_land_`i'_sqft
	replace parcel_`i'_size = 1/107639*parcel_`i'_size
	replace parcel_`i'_size = 0 if missing(parcel_`i'_size)
}

// Find the 'i'th largest parcel size from i = 1 to n where n is the max number of parcels in the dataset. We first 
// reshape the data to long for the parcel size variables and then we sort the parcel size variables and then
// reshape back to wide.

// Generate variable names so that the stub comes first.
forval i = 1/15 {
	gen size_largest_parcel_`i' = parcel_`i'_size 
}


// Reshape to long with respect to the parcel size variable
reshape long size_largest_parcel_, i(farmer_plot_id) j(order)

// Sort the new generated variable by size in descending order
gsort farmer_plot_id -size_largest_parcel_

// Generate new counter to append to our stub
by farmer_plot_id: gen new_order = _n

// Drop old counter
drop order

// Reshape back to wide
reshape wide size_largest_parcel_, i(farmer_plot_id) j(new_order)

// Label new variable
forval i = 1/15 {
	la var size_largest_parcel_`i' "Size of the `i'th largest parcel"
}

// Generate squared terms
forval i = 1/15 {
	gen sq_size_largest_parcel_`i' = size_largest_parcel_`i'^2
	la var sq_size_largest_parcel_`i' "Squared size of the `i'th largest parcel"
}

// Drop temporary variables
drop parcel_*_size

// ~~~~~~~~~~ Create variable which captures the proportion of land cropped within village ~~~~~~~~~~


// Create crop area in parcel as a crop level variable in hectares
forval j = 1/15 {
	egen crop_area_in_parcel_`j' = rowtotal(f5_1_6_9_area_crp_pcl`j'_*_sqft), missing
	replace crop_area_in_parcel_`j' = 1/107639*crop_area_in_parcel_`j' 
}


// Generate total crop area in parcel [WARNING: THIS DOES NOT EQUAL TOTAL LAND USED LIKE IT SHOULD]
egen total_crop_area_in_parcels = rowtotal(crop_area_in_parcel_*), missing 


// Generate total crop area within village 
forval j = 1/15 {
	gen parcel_`j'_within_village = d2_5_parcel_within_vill_`j'
	replace parcel_`j'_within_village = 0 if d2_5_parcel_within_vill_`j' == 2
	gen village_parcel_area_`j' = parcel_`j'_within_village*crop_area_in_parcel_`j'
}

egen total_crop_area_within_village = rowtotal(village_parcel_area_*), missing

// Generate share of total crop area which is within village boundaries.
gen share_of_area_in_village = total_crop_area_within_village/total_crop_area_in_parcels
la var share_of_area_in_village "Share of crop area in village"

// ~~~~~~~~~~~~ Create variables that capture the amount of walking time to parcel ~~~~~~~~~~

//  Get the walking time for parcels on which the crop is grown
forval j = 1/15 {
	gen walking_time_crop_parcel`j' = crop_in_parcel_`j'*d2_7_time_frm_home_`j'
}

// Reshape to long 
reshape long crop_area_in_parcel_ walking_time_crop_parcel, i(farmer_plot_id) j(parcel)



// Create crop area weighted mean of walking time to crop
egen weighted_walking_time_to_crop = wtmean(walking_time_crop_parcel), weight(crop_area_in_parcel) by(farmer_plot_id)

// Reshape back to wide
reshape wide crop_area_in_parcel_ walking_time_crop_parcel, i(farmer_plot_id) j(parcel) 

// Drop temporary variables
drop walking_time_crop_parcel*

// Label variable
la var weighted_walking_time_to_crop "Weighted walk time to crop (minutes)" 

//~~~~~~~~~~~~~~~~~ Map source level variables to parcel level ~~~~~~~~~~~~~~~~~~~~~~~~~~~
tempfile croplevel
save `croplevel'

keep farmer_plot_id b7_3_15_prspctv_sell_wtr_* f2_3_7_parcel_irrigate_* b7_3_10_dist_chnnel_usd_* crop_in_parcel_*

// Reshape to farmer-crop-source level
reshape long b7_3_15_prspctv_sell_wtr_ f2_3_7_parcel_irrigate_ b7_3_10_dist_chnnel_usd_, i(farmer_plot_id) j(source)

// Create parcel dummies for source used on parcel
forval i=1/15 {
	gen source_irrigates_parcel`i' = regexm(f2_3_7_parcel_irrigate_,"`i' ") | regexm(f2_3_7_parcel_irrigate_, " `i'") | regexm(f2_3_7_parcel_irrigate_, "3`i'") | f2_3_7_parcel_irrigate_ == "`i'" 
}


// Generate whether pipe is used to bring water from that source to parcel
gen pipe = cond(b7_3_10_dist_chnnel_usd_ == 4, 1, 0)

// Reshape to farmer-crop-source-parcel level
gen source_str = string(source)
gen farmer_plot_source_id = farmer_plot_id + source_str

reshape long crop_in_parcel_ source_irrigates_parcel, i(farmer_plot_source_id) j(parcel)

// Generate water buyers for each crop
//  * Here we assign the total number of water buyers at the source level to the crop level iff the source
//  irrigates the parcels the crop is grown on.
gen water_buyers = crop_in_parcel*source_irrigates_parcel*b7_3_15_prspctv_sell_wtr

// Assign piped water to parcel
replace pipe = pipe*crop_in_parcel*source_irrigates_parcel

collapse (mean) water_buyers pipe, by(farmer_plot_id)
replace pipe = 1 if pipe > 0
la var pipe "Pipe/hose/tube used to deliver water"
la var water_buyers "Num. water buyers"

// Histogram of water buyers
hist water_buyers, graphregion(color(white)) plotregion(color(white)) color(blue)
graph export "`FIGURES'/hist_water_buyers.pdf", replace

merge 1:1 farmer_plot_id using `croplevel'
drop _merge

// ~~~~~~~~~~~~~~~ Map parcel level variables to crop level ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tempfile irrigation
save `irrigation'

drop f5_1_6_5_irr_tech_pcl_drip f5_1_6_5_irr_tech_pcl_fld f5_1_6_5_irr_tech_pcl_frw f5_1_6_5_irr_tech_pcl_spr f5_1_6_5_irr_tech_pcl_brst


reshape long f5_1_6_5_irr_tech_pcl_drip f5_1_6_5_irr_tech_pcl_fld parcel_leveled_pre_sow under_irrigated_parcel ///
	f5_1_6_5_irr_tech_pcl_frw f5_1_6_5_irr_tech_pcl_spr f5_1_6_5_irr_tech_pcl_brst crop_in_parcel_ d2_12_prspctv_wtr_sellrs_, i(farmer_plot_id) j(parcel)

keep if crop_in_parcel == 1

collapse (sum) drip=f5_1_6_5_irr_tech_pcl_drip sprinkler=f5_1_6_5_irr_tech_pcl_spr flood=f5_1_6_5_irr_tech_pcl_fld ///
	border_strip=f5_1_6_5_irr_tech_pcl_brst plot_leveled=parcel_leveled_pre_sow (mean) water_sellers=d2_12_prspctv_wtr_sellrs_  under_irrigated_parcel ///
		(firstnm) crop_type, by(farmer_plot_id)	
	
la var crop_type "Crop type"
la var drip "Drip irrigation"
la var flood "Flood irrigation"
la var sprinkler "Sprinkler irrigation"
la var border_strip "Border strip irrigation"
la var water_sellers "Num. water sellers"

replace drip = 1 if drip > 0
replace flood = 1 if flood > 0
replace sprinkler = 1 if sprinkler > 0
replace border_strip = 1 if border_strip > 0
replace plot_leveled = 1 if plot_leveled > 0
replace under_irrigated_parcel = cond(under_irrigated_parcel > 0.5, 1, 0)

// Histgram of the number of water sellers for each crop
hist water_sellers, graphregion(color(white)) plotregion(color(white)) color(blue)
graph export "`FIGURES'/hist_water_sellers.pdf", replace

merge 1:1 farmer_plot_id using `irrigation'
drop _merge


// ~~~~~~~~~~~~~~~~~ Create cross-tabulation of non-Rajka crops with negative profits and zero output ~~~~~~~~~
preserve

keep if rajka == 0

gen non_positive_profits = cond(profit_cashwown_wins <= 0, 1, 0)
la var non_positive_profits "Profits"
la define profit_status 1 "Non-positive" 0 "Positive"
la values non_positive_profits profit_status

gen zero_output = cond(output == 0, 1, 0)
la var zero_output "Output"
la define output_status 1 "Zero" 0 "Positive"
la values zero_output output_status

tabout non_positive_profits zero_output using "`TABLES'/tabulate_zero_output_positive_profit.tex", replace ///
c(freq) style(tex) format(0c 1) font(bold) twidth(9) 	

restore


// ~~~~~~~~~~~~~~~~~~~~ Impute values for missing inputs ~~~~~~~~~~~~~~~~~~~~~~~~
// Cross tabulating positive output with missing inputs
gen positive_output = cond(output > 0, 1, 0)
gen missing_capital = cond(missing(labour), 1, 0)
gen missing_water = cond(missing(water),1,0)
la var positive_output "Output > 0"
la var missing_capital "Missing capital"
la var missing_water "Missing water"
la def yesno 1 "Yes" 0 "No"
label values positive_output yesno
label values missing_capital yesno
label values missing_water yesno


tabout positive_output missing_capital using "`TABLES'/tabulate_missing_capital_positive_output.tex", replace ///
c(freq) style(tex) format (0c 1) font(bold) twidth(15)

tabout positive_output missing_water using "`TABLES'/tabulate_missing_water_positive_output.tex", replace ///
c(freq) style(tex) format (0c 1) font(bold) twidth(15)

eststo clear
estpost sum labour land water capital, detail
esttab using "`TABLES'/input_summary_stats_pre_impute.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Input summary statistics (before imputation) \label{tab:PreImputeInputSumStats}") ///
		booktabs noobs nonumbers label replace 

bys sdo_feeder_code crop_type: egen med_capital =  median(capital/land)
replace med_capital = med_capital*land
replace capital = med_capital if missing(capital)

bys sdo_feeder_code crop_type: egen med_water = median(water/land)
replace med_water = med_water*land
replace water = med_water if missing(water)

eststo clear
estpost sum labour land water capital, detail
esttab using "`TABLES'/input_summary_stats_post_impute.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Input summary statistics (after imputation) \label{tab:PostImputeInputSumStats}") ///
		booktabs noobs nonumbers label replace 
		

		
//============================ Instrument and input missing values ======================================

// Drop if outputs and inputs missing
keep if revenue != .
keep if revenue > 0

keep if water != .
keep if water > 0

keep if labour != .
keep if labour > 0

keep if land != .
keep if land > 0

keep if capital != .
keep if capital > 0


// Generate log(revenue)
gen log_revenue = log(revenue)
la var log_revenue "log(Revenue)"

// Generate log(Water)
gen log_water = log(water)
la var log_water "log(Water)"

// Generate log labour
gen log_labour = log(labour)
la var log_labour "log(Labor)"

// Generate log land
gen log_land = log(land)
la var log_land "log(Land)"

// Generate log capital
gen log_capital = log(capital)
la var log_capital "log(Capital)"

// Generate log improved land
gen log_improved_land = log(improved_land)
la var log_improved_land "log(Improved land)"

// Generate log improved labour
gen log_improved_labour = log(improved_labour)
la var log_improved_labour "log(Improved labour)"

// Generate log materials cost
gen log_material_costs = log(material_costs)
la var log_material_costs "log(Material costs)" 

// Generate log augmented labour
gen log_augmented_labour = log(augmented_labour)
la var log_augmented_labour "log(Labour (augmented))"

// Drop if logged values missing
drop if log_revenue == .
drop if log_water == .
drop if log_labour == .
drop if log_land == .
drop if log_capital == .

// Dummy out missing variables
gen missing_topos = 1 if missing(elevation)
replace missing_topos = 0 if missing(missing_topos)
replace elevation = 0 if missing(elevation)
replace slope = 0 if missing(slope)

gen missing_seed_price_across_farmer = 1 if missing(seed_price_across_farmer)
replace missing_seed_price_across_farmer = 0 if missing_seed_price_across_farmer != 1
replace seed_price_across_farmer = 0 if missing(seed_price_across_farmer)
replace seed_price_sq_across_farmer = 0 if missing(seed_price_sq_across_farmer)

//***************** 4-input model ***********************

// Get water instruments
// Fracture-lineament instrument
local FRACTURE_IVSET dist2fault_km ltot_1km ltot_5km

// Rock type instruments
local ROCK_TYPE_IVSET rock_area_* rock_type_*

// Fracture-lineament + Rock type instruments (without interactions)
local AQUIFERS `FRACTURE_IVSET' `ROCK_TYPE_IVSET' aquifer_type*

// Main
local MAIN `AQUIFERS' dist2fault_km2 ltot_1km2 ltot_5km2 rock_area2_* /// 
		ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11 ///
		ltot1km_area11* ltot5km_area11* dist2fault_area11*
		
local CONTROLS _Isd* elevation slope

// Land
local LAND_INSTR size_largest_parcel_1-size_largest_parcel_3 sq_size_largest_parcel_1-sq_size_largest_parcel_3

// Land no squared parcels
local LAND_INSTR_2 size_largest_parcel_1-size_largest_parcel_3

// Labour
local LABOUR_INSTR hh_adult_males sq_hh_adult_males 
la var hh_adult_males "Num. adult males"

// Water
ivlasso output (`CONTROLS') (log_water=`MAIN'), first cluster(f_id) post(pds) pnotpen(`CONTROLS')
local WATER_INSTR `e(zselected)' water_sellers

// Capital
local CAPITAL_INSTR seed_price_across_farmer seed_price_sq_across_farmer 

// Combined
local INSTR `LAND_INSTR' `LABOUR_INSTR' `WATER_INSTR' `CAPITAL_INSTR'

local INSTR_2 `LAND_INSTR_2' `LABOUR_INSTR' `WATER_INSTR' `CAPITAL_INSTR'

la var crop_lost_preharvest "Crop lost preharvest (quintals)"
la var crop_lost_postharvest "Crop lost postharvest (quintals)"

// Summarize
drop log_water_price*
drop if rajka == 1 | orange == 1
eststo clear
estpost sum `INSTR' elevation slope crop_lost* log_*, detail
esttab using "`TABLES'/summary_production_function_components.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmers))") ///
	title("Summary Statistics: Components of the production function") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs 
	


//============================ Sub sample for MATLAB structural model ===================================

preserve

// Rename in noun_adj convention
rename improved_land land_improved
rename augmented_labour labor_augmented
rename improved_labour labor_improved
rename labour_rupees labor_rupees
rename labour labor



// Get reduced form profit estimates

// Select and order variables appropriately
keep farmer_id sdo_feeder_code labor_rupees plot_id farmer_plot_id ///
  land water labor capital output yield revenue crop_water_req crop_hyv ///
  rock_area_1 rock_area_4 rock_area_6 rock_area_9 rock_area_14 rock_area_15 ///
  rock_area_20 rock_area2_4 rock_area2_10 ///
  ltot5km_area1115 ltot1km_area1130 ltot5km_area119 profit_total_t ///
  dist2fault_area116 dist2fault_area1114 dist2fault_area112 ///
  dist2fault_area1120 dist2fault_area1146 aquifer_type_4 `WATER_INSTR' ///
  tot_land_owned land_owned_pakka land_owned_kacha land_parcels ///
  hh_adult_males sq_hh_adult_males median_wage_* land_rent_SDO1 ///
  fertilizer_price_* prod_below_expect ///
  crop_lost_preharvest crop_lost_postharvest crop_type ///
  wheat fielspea mustard lentil bengalgram coriander fenugreek barley ///
  garlic sugarcane orange other ///
  size_largest_parcel_* sq_size_largest_parcel_* ///
  elevation slope missing_topos tractors_owned_nearby harvesters_owned_nearby ///
  threshers_owned_nearby depth drip flood sprinkler border_strip ///
  plot_leveled water_sellers water_buyers pipe ///
  _Ild* _Isd* seed_price_* *_rental_rate *_seed_price_feeder ///
  material_costs labor_augmented `SOIL_CONTROLS' mean_pump_capacity ///
  mean_farmer_pump_capacity pump_farmer pump_farmer_plot wage_weighted ///
  tot_hours profit_cash_t profit_total_t missing_seed_*

order farmer_id plot_id farmer_plot_id yield revenue profit_total_t ///
  land water labor capital crop_water_req crop_hyv ///
  rock_area* aquifer* ltot* dist2fault*

export delimited using "`WORKING_DATA'/production_inputs_outputs.txt", delimiter(tab) replace

restore

save "`WORKING_DATA'/production_inputs_outputs.dta", replace

} /* MATLABSAMPLE */


//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//                                      END
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

