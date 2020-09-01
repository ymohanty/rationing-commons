//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*

NAME: select_variables.do

PURPOSE: This file takes the baseline data and selects and creates those variables that
are important for our analysis.

AUTHOR: Viraj Jorapur 

*/
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//=============================== PREAMBLE =====================================

// SET UP ROOT DIRECTORY
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


//============================ FARMER-CROP DATA ==============================='
// Load the dataset
use "`CLEAN_FARMER_SURVEY'/baseline_survey_farmer_crop_with_imputed_variables.dta", clear

// Turn if tractor owned or rented into a dummy variable for owned.
bys f_id: gen own_tractor = f6_1_2_farm_mach_ownrshp_1 if _n == 1 
replace own_tractor = 0 if own_tractor == 2

// Turn if harvester owned or rented into dummy variable for owned
bys f_id: gen own_harvester = f6_1_2_farm_mach_ownrshp_2 if _n == 1
replace own_harvester = 0 if own_harvester == 2

// Turn if thresher owned or rented into dummy variable for owned
bys f_id: gen own_thresher = f6_1_2_farm_mach_ownrshp_3 if _n == 1
replace own_thresher = 0 if own_thresher == 2

drop f5_1_6_5_irr_tech_pcl_*_*

// Rename machinery expense variables
gen tractor_rental_cost = f6_1_3_farm_mach_expnse_1 if own_tractor == 1 
gen harvester_rental_cost = f6_1_3_farm_mach_expnse_2 if own_harvester == 1
gen thresher_rental_cost = f6_1_3_farm_mach_expnse_3 if own_thresher == 1

// Calculate mean machinery expense rate
rangestat (mean) tractor_rental_rate=tractor_rental_cost harvester_rental_rate=harvester_rental_cost ///
	thresher_rental_rate=thresher_rental_cost, interval(sdo_feeder_code 0 0) excl
	
// Generate median feeder fertilizer prices (exclude current)
gen fert_chem = f5_2_12_chem_fert_ttl_cst/f5_2_11_chem_fert_purch
rangestat (mean) fertilizer_price_bio=f5_2_8_bio_fert_price ///
	fertilizer_price_chem=fert_chem, interval(sdo_feeder_code 0 0) excl
gen fertilizer_price_chem_sq=fertilizer_price_chem^2
	
// Generate mean fertilizer prices within farmer prices (excluding current crop)
rangestat (mean) fertilizer_price_bio_crop=f5_2_8_bio_fert_price ///
	fertilizer_price_chem_crop=fert_chem, interval(f_id 0 0) excl
	
// Winsorize outliers
winsor fertilizer_price_chem_crop, gen(fertilizer_price_chem_crop_wins) p(0.001) highonly
replace fertilizer_price_chem_crop = fertilizer_price_chem_crop_wins
drop fertilizer_price_chem_crop_wins

// Generate squared variable for fertilizer prices within farmer
gen fertilizer_price_chem_crop_sq=fertilizer_price_chem_crop^2

// Recast migration variable
replace a2_11_9 = 0 if a2_11_9 == 2
la var a2_11_9_yngst_migrated "Youngest family member migrated"
rename a2_11_9 youngest_migrated

// Mean feeder price within farmer excluding current crop
la var fertilizer_price_bio "Mean price of biological fertilizer in feeder"
la var fertilizer_price_chem "Mean price of chemical fertilizer in feeder"
la var fertilizer_price_chem_crop "Mean chem fert price for farmer"
la var fertilizer_price_bio_crop "Mean bio fert price for farmer"
la var fertilizer_price_chem_sq "Mean price chem fert squared in feeder"
la var fertilizer_price_chem_crop_sq "Mean price chem fert squared for farmer"
	
// Generate number of tractors nearby (exclude current)
rangestat (sum) tractors_owned_nearby=own_tractor, interval(sdo_feeder_code 0 0) excl
la var tractors_owned_nearby "No. of tractor owning farmers in feeder"
bys f_id: replace tractors_owned_nearby = tractors_owned_nearby[1]

// Generate number of harvester owning farmers nearby (excluding current)
rangestat (sum) harvesters_owned_nearby=own_harvester, interval(sdo_feeder_code 0 0) excl
la var harvesters_owned_nearby "No. of harvester owning farmers in feeder"
bys f_id: replace harvesters_owned_nearby = harvesters_owned_nearby[1]

// Generate number of threshsers owning farmers nearby (excluding current)
rangestat (sum) threshers_owned_nearby=own_thresher, interval(sdo_feeder_code 0 0) excl
la var threshers_owned_nearby "No. of thresher owning farmers in feeder"
bys f_id: replace threshers_owned_nearby = threshers_owned_nearby[1]

// Generate mean seed price within farmer
rangestat (mean) seed_price_within_farmer=f5_2_3_seed_price, interval(f_id 0 0) excl
la var seed_price_within_farmer "Seed price (Rs/kg) within farmer"
gen seed_price_sq_within_farmer = seed_price_within_farmer^2
la var seed_price_sq_within_farmer "Seed price squared within farmer"

// Generate mean seed price across farmer
egen sdo_crop_id = group(sdo_feeder_code crop_type)

rangestat (mean) seed_price_across_farmer=f5_2_3_seed_price, interval(sdo_crop_id 0 0) excl
la var seed_price_across_farmer "Seed price (Rs/kg) across farmer"
gen seed_price_sq_across_farmer = seed_price_across_farmer^2
la var seed_price_sq_across_farmer "Seed price squared across farmer"

// Generate mean seed price for wheat, mustard and others
rangestat wheat_seed_price_feeder=f5_2_3_seed_price if wheat == 1, interval(sdo_feeder_code 0 0) excl
rangestat mustard_seed_price_feeder=f5_2_3_seed_price if mustard == 1, interval(sdo_feeder_code 0 0) excl
rangestat other_seed_price_feeder=f5_2_3_seed_price if mustard == 0 & wheat == 0, interval(sdo_feeder_code 0 0) excl

bys f_id (wheat_seed_price_feeder): replace wheat_seed_price_feeder = wheat_seed_price_feeder[1]
bys f_id (mustard_seed_price_feeder): replace mustard_seed_price_feeder = mustard_seed_price_feeder[1]
bys f_id (other_seed_price_feeder): replace other_seed_price_feeder = other_seed_price_feeder[1]

la var wheat_seed_price_feeder "Wheat price in feeder"
la var mustard_seed_price_feeder "Mustard price in feeder"
la var other_seed_price_feeder "Other price in feeder"
	
keep f_id crop f5_4_1_tot_prod impu_value impu_profit impu_profit_per_hectare /// 
	 impu_profit_zero_labor impu_profit_per_hectare_zero_lab ///
	 impu_profit_nreg_labor impu_profit_per_hectare_nreg_lab ///
     d2_tot_pakka d2_tot_land f1_4_3_area_und_crp_sqft f5_4_1_tot_op_perha b2_1_1_hrs_avg ///
	 f5_4_12_net_profit_perha_wins f5_4_12_net_profit_perha_w_own avg_source_depth ///
	 sdo_feeder_code d1_2_pakka_sqft sdo_price d1_3_kacha_sqft SDO missing_* resp_num ///
	 tot_water_crop capital_cost tot_days f1_3_wat_intst f5_4_9_tot_value_sold water_hardy prop_area_sprinkler ///
	 f1_4_2_crop_variety labour_rupees elec_exp_sub_irr elec_exp_subsidy_per_hectare ///
	 a2_9_hh_male f5_4_val_not_sold ///
	 d1_5_parcels_land ///
	 b7_1_2_pmp_* f5_1_5_parcel_crop own_* e2_7_3_wtr_trnsfr_price_* ///
	 f1_3_wat_intst f5_1_6_1_* f5_4_2_prod_level_exptn f5_4_3_lost_pre_hrvst f5_4_4_lost_post_hrvst ///
	 d2_1_tot_size_* f5_1_6_9_* d2_5_parcel_within_vill_* d2_7_time_* f1_3_crops_plntd f5_1_6_7_* f5_1_6_4_* bought_water_price_per_ha* ///
	 log_water_price* katha* bigha* sqft* sqm* acre* hectare* dismil* sqyard* block_water_supply* ///
	 f5_1_6_5_irr_tech_pcl_drip* f5_1_6_5_irr_tech_pcl_fld* f5_1_6_5_irr_tech_pcl_frw* f5_1_6_5_irr_tech_pcl_spr* f5_1_6_5_irr_tech_pcl_brst* ///
	 a2_11_1_youngest_age ///
	 a3_5_3_non_agr_prft a3_6_2_* f5_3_4_avg_wage_sow ///
	 d2_1_tot_size_land_* tot_irr_labour d2_12_* f2_3_7_parcel_irrigate_1-f2_3_7_parcel_irrigate_4 b7_3_15_prspctv_sell_wtr_* b7_3_10_dist_chnnel_usd_* ///
	 thresher_rental_rate tractor_rental_rate harvester_rental_rate ///
	 fertilizer_price_* tractors_owned_nearby threshers_owned_nearby harvesters_owned_nearby seed_price_* *_seed_price_feeder ///
	 improved_* material_costs youngest_migrated augmented_labour a2_2* a2_4* a2_5* median_wage_* land_rent_* wage_weighted
	 	 
gen b7_3_3_avg_surce_dpth_resp_ft = avg_source_depth
gen farmer_well_depth = avg_source_depth

drop avg_source_depth

// Rename and label variables
rename a2_2* village
rename a2_4* block
rename a2_5* district


// Generate total land and share area cropped
gen d1_tot_land = d1_2_pakka_sqft + d1_3_kacha_sqft

											 
// TO VIRAJ: What is going on here? This converts square feet into hectares
gen area_und_crop_ha = 0.000009290304*f1_4_3_area_und_crp_sqft
	

// Replace 0s with missing for net profits per hectare (winsorized)
replace f5_4_12_net_profit_perha_wins = 0 if (f5_4_12_net_profit_perha_wins == 0)


// Save crop-level data
save "`CLEAN_FARMER_SURVEY'/baseline_survey_selected_variables_crop_level.dta", replace


//~~~~~~~~~~~~~~~~~ Hacks to get controls into farmer level data ~~~~~~~~~~~~
// Generating land deciles
xtile land_decile = d1_tot_land, nq(10)
	
// Create dummies for SDO and land decile effects
xi, prefix(_Ild) noomit i.land_decile
drop _Ildland_de_1


xi, prefix(_Isd) noomit i.SDO
drop _IsdSDO_1


// Aggregate to farmer level
collapse (sum) water=tot_water_crop output=f5_4_1_tot_prod land=f1_4_3_area_und_crp_sqft impu_value impu_profit impu_profit_per_hectare ///
								(mean) d2_tot_land d2_tot_pakka b7_3_3_avg_surce_dpth_resp_ft ///
								(firstnm) village block district d1_tot_land sdo_price SDO farmer_well_depth missing_* resp_num d1_5_parcels_land ///
								f5_1_5_parcel_crop _Isd* _Ild* e2_7_3_wtr_trnsfr_price_* f1_3_wat_intst f5_1_6_1_* f5_1_6_7_* f5_1_6_4_* bought_water_price_per_ha* ///
								log_water_price* katha* bigha* sqft* sqm* acre* hectare* dismil* sqyard* block_water_supply*  ///
								f5_1_6_5_irr_tech_pcl_drip* f5_1_6_5_irr_tech_pcl_fld* f5_1_6_5_irr_tech_pcl_frw* f5_1_6_5_irr_tech_pcl_spr* f5_1_6_5_irr_tech_pcl_brst* a2_11_1_youngest_age ///
								d2_1_tot_size_land_* tot_irr_labour, ///
								by(f_id)

// Generate new variables
gen share_area_cropped = land/d1_tot_land
// Land from sqft to ha
replace land = land*0.000009290304
replace d1_tot_land = d1_tot_land*0.000009290304

// Drop redundant variables
drop f5_1_6_5_irr_tech_pcl_drip f5_1_6_5_irr_tech_pcl_fld f5_1_6_5_irr_tech_pcl_frw f5_1_6_5_irr_tech_pcl_spr f5_1_6_5_irr_tech_pcl_brst

// Label variables
la var tot_irr_labour "Irrigation labour (worker-days)"
la var share_area_cropped "Share of land area cultivated"
la var farmer_well_depth "Farmer well depth (feet)"
la var land "Land cultivated (ha)"
la var d1_tot_land "Land owned (ha)"

// Winsorize
winsor farmer_well_depth, gen(farmer_well_depth_wins) p(0.01) highonly

// Land from sqft to ha
replace land = land*0.000009290304

// Generate yield
gen yield = output/land

// Save the aggregated dataset
save "`CLEAN_FARMER_SURVEY'/baseline_survey_selected_variables.dta", replace								
























