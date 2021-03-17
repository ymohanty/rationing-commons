/*******************************************************************************
Purpose: Get the predicted variables from the main specification to graph the 
		 maps

Author: Viraj Jorapur

Date: 05 September, 2019
*******************************************************************************/

// This file analyses and gets important regression results by
// farmer x crop profitability for each farmer
* Opening commands:

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


/* Getting the data and doing the basic manipulations needed to get the 
first stage predictions
*/

cd "`WORKING_DATA'"

tempfile prepped_data

// import delimited baseline_profits_instruments.csv, delimiters(",") asfloat
use marginal_analysis_sample_crop_level, clear
drop _merge
merge m:1 f_id using "`RAW_FARMER_SURVEY'/pii_farmer_locations.dta", force

//describe
label data "Farmer profits merged with geological instruments"

destring impu_profit f5_4_1_tot_op_perha f5_4_12_net_profit_perha_wins ///
  f5_4_12_net_profit_perha_w_own elevation slope, replace force

lab var f5_4_1_tot_op_perha            "Yield (bushels/Ha)"
lab var f5_4_12_net_profit_perha_wins  "Cash profit (Rs/Ha)"
lab var f5_4_12_net_profit_perha_w_own "Profit (Rs/Ha, with own consumption)"
lab var farmer_well_depth               "Well depth (feet)"
lab var sdo_price 						"Median price for crop in SDO (Rs)"

// Rename key variables
rename f5_4_1_tot_op_perha             yield
rename f5_4_12_net_profit_perha_wins   profit_cash_wins
rename f5_4_12_net_profit_perha_w_own  profit_cashwown

// Replace profit with imputed profits if cash profit not reported and value of 
// own consumption is reported.
replace profit_cashwown = impu_profit_per_hectare if missing(profit_cash_wins)

// Winsorize variables
tempvar newwins
winsor profit_cashwown, generate(profit_cashwown_wins) p(0.01) highonly
winsor yield, generate(yield_wins) p(0.01) highonly
replace yield = yield_wins
winsor profit_cash_wins, generate(`newwins') p(0.01) highonly 
replace profit_cash_wins = `newwins'
lab var profit_cashwown_wins "Profit (Rs/Ha, with own consumption)"

// Generate revenue
gen revenue = sdo_price*yield
la var revenue "Revenue (Rs/Ha)"

save `prepped_data'

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Proceed with cleaned data
// use baseline_profits_instruments
use `prepped_data'

// TEMP
drop if missing(g11_gpslongitude, d1_tot_land, b7_3_3_avg_surce_dpth)
	
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


/* This section creates all the controls and the instruments */

// Fracture-lineament instrument
local FRACTURE_IVSET dist2fault_km ltot_1km ltot_5km

// Rock type instruments
local ROCK_TYPE_IVSET rock_area_* rock_type_*

// Fracture-lineament + Rock type instruments (without interactions)
local FRACTURE_ROCK_TYPE_IVSET `FRACTURE_IVSET' `ROCK_TYPE_IVSET'

// Main (paper model)
local MAIN `FRACTURE_ROCK_TYPE_IVSET' aquifer_type*

// Small instrument set (Rock type + fractures + 1st order interactions)
local SMALL_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 rock_area2_* /// 
		ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11 ///
		ltot1km_area11* ltot5km_area11* dist2fault_area11* aquifer_type*
		
// Large instrument set (Small instrument set + 2nd order interactions)
local LARGE_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 ///
		ltot1km_ltot5km* ltot1km_dist* ltot5km_dist* ///
		ltot1km_area* ltot5km_area* dist2fault_area* aquifer_type* ///
	
		
//========================= DEFINE CONTROLS ====================================
		
local CONTROLS _Ild* _Isd* elevation slope

// Getting the predicted well depths

ivlasso yield (`CONTROLS') (farmer_well_depth = `SMALL_IVSET'), first cluster(f_id) idstats pnotpen(`CONTROLS')
		estimates restore _ivlasso_farmer_well_depth
		eststo frac_lassoiv 
		predict depth_hat
		
// Storing the results of the predictions in our folder

// Only keeping the relevant variables that we need to get the prediction maps

keep f_id SDO farmer_well_depth depth_hat


export delimited "`CLEAN_GEOLOGICAL_DATA'/prediction.csv", replace
