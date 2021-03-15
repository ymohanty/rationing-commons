 //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//					Marginal Analysis: Profit Regressions
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//                              MAIN SPECIFICATION
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if `MAIN' == 1 {

//========================== DEFINE INSTRUMENT SETS ============================

// Fracture-lineament instrument
local FRACTURE_IVSET dist2fault_km ltot_1km ltot_5km

// Rock type instruments
local ROCK_TYPE_IVSET rock_area_* rock_type_*

// Fracture-lineament + Rock type instruments (without interactions)
local FRACTURE_ROCK_TYPE_IVSET `FRACTURE_IVSET' `ROCK_TYPE_IVSET'


// Small instrument set (Rock type + fractures + 1st order interactions)
local SMALL_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 rock_area2_* /// 
		ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11 ///
		ltot1km_area11* ltot5km_area11* dist2fault_area11* aquifer_type* 
		
// Large instrument set (Small instrument set + 2nd order interactions)
local LARGE_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 ///
		ltot1km_ltot5km* ltot1km_dist* ltot5km_dist* ///
		ltot1km_area* ltot5km_area* dist2fault_area* ///
		aquifer_type*
		

//========================= DEFINE CONTROLS ====================================
		
local CONTROLS _Ild* _Isd* elevation slope `SOIL_CONTROLS' 

//========================== MAIN ESTIMATION ===================================

local clustervar sdo_feeder_code
la var farmer_well_depth "Well depth (1 sd = 187 feet)"

// Unique ID 
replace id = _n

//~~~~~~~~~~~~~~~~~~~~~ WEIGHTED BY D_I/H_I ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Total profits
main_lasso_iv profit_cashwown_wins, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_profit_cashwown_wins_weighted") weight(d_over_h)
	
//~~~~~~~~~~~~~~~~~~~~~~ OUTCOME VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Yield
main_lasso_iv yield, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_yield") 
	
// Cash profits
main_lasso_iv profit_cash_t, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_profit_cash_wins") 
	
// Total profits
main_lasso_iv profit_total_t, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_profit_cashwown_wins") 
	
// Revenue
main_lasso_iv revenue_perha_t, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_revenue_wins") 
	

//~~~~~~~~~~~~~~~~~~~ ADAPTATION VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Water requirement
main_lasso_iv water_requirement, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_water_req") 
	
// Proportion under sprinker irrigation
main_lasso_iv prop_area_sprinkler, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_sprinkler")
	
// Water hardiness
main_lasso_iv water_hardy, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_water_hardiness")
	
// Share of value sold
main_lasso_iv share_value_output_sold, controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///                                                                                           controls(`CONTROLS') small_ivset(`SMALL_IVSET') ///
	large_ivset(`LARGE_IVSET') cluster(`clustervar') filename("`TABLES'/main_share_val_out")

} // Main estimation

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//							ROBUSTNESS CHECKS
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if `ROBUSTNESS' == 1 {

local SECOND_STAGE = 1
local FIRST_STAGE = 1
local PREDICTED_DEPTH = 0

//========================== DEFINE INSTRUMENT SETS ============================

// Fracture-lineament instrument
local FRACTURE_IVSET dist2fault_km ltot_1km ltot_5km

// Rock type instruments
local ROCK_TYPE_IVSET rock_area_* rock_type_*

// Fracture-lineament + Rock type instruments (without interactions)
local FRACTURE_ROCK_TYPE_IVSET `FRACTURE_IVSET' `ROCK_TYPE_IVSET' aquifer_type*

// Main instrument set (Rock type + fractures + 1st order interactions + aquifers)
local MAIN `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 rock_area2_* /// 
		ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11 ///
		ltot1km_area11* ltot5km_area11* dist2fault_area11*		
		
// Large instrument set (Small instrument set + 2nd order interactions)
local LARGE_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 ///
		ltot1km_ltot5km* ltot1km_dist* ltot5km_dist* ///
		ltot1km_area* ltot5km_area* dist2fault_area* ///
	
		
//========================= DEFINE CONTROLS ====================================
		
local CONTROLS _Ild* _Isd* elevation slope `SOIL_CONTROLS' 

local clustervar sdo_feeder_code
la var farmer_well_depth "Well depth (1 sd = 187 feet)"


// // ~~~~~~~~~~~~~~~ Correlation of soil controls with predicted depth ~~~~~~~~~~~~~
// ivlasso yield (farmer_well_depth=`MAIN'), first cluster(f_id) post(pds) 
// estimates restore _ivlasso_farmer_well_depth
// predict depth_hat
// la var depth_hat "Predicted depth"
// corrtex depth_hat prop_sufficient_* prop_high_* prop_acidic , file("`TABLES'/corr_soil_controls_predicted_depth.tex") replace landscape
// graph matrix depth_hat prop_sufficient_* prop_high_* prop_acidic
// graph export "`FIGURES'/fig_corr_soil_controls_predicted_depth.pdf", replace

		
//========================== MAIN ESTIMATION ===================================

if `SECOND_STAGE' == 1 {

// Yield
robustness_lasso_iv yield, controls(`CONTROLS') frac(`FRACTURE_IVSET') rock(`ROCK_TYPE_IVSET') frac_rock(`FRACTURE_ROCK_TYPE_IVSET') ///
	main(`MAIN') large(`LARGE_IVSET') ///
	filename("`TABLES'/iv_reg_yield_nopen_all") pnotpen(_Isd* _Ild* elevation slope `SOIL_CONTROLS') cluster(`clustervar')
	
// Value of output
robustness_lasso_iv revenue_perha_t, controls(`CONTROLS') frac(`FRACTURE_IVSET') rock(`ROCK_TYPE_IVSET') frac_rock(`FRACTURE_ROCK_TYPE_IVSET') ///
	main(`MAIN') large(`LARGE_IVSET') ///
	filename("`TABLES'/iv_reg_revenue_nopen_all") pnotpen(_Isd* _Ild* elevation slope `SOIL_CONTROLS') cluster(`clustervar')
	
// Cash profits
robustness_lasso_iv profit_cash_t, controls(`CONTROLS') frac(`FRACTURE_IVSET') rock(`ROCK_TYPE_IVSET') frac_rock(`FRACTURE_ROCK_TYPE_IVSET') ///
	main(`MAIN') large(`LARGE_IVSET') ///
	filename("`TABLES'/iv_reg_profit_cash_wins_nopen_all") pnotpen(_Isd* _Ild* elevation slope `SOIL_CONTROLS') cluster(`clustervar')

// Total profits
robustness_lasso_iv profit_total_t, controls(`CONTROLS') frac(`FRACTURE_IVSET') rock(`ROCK_TYPE_IVSET') frac_rock(`FRACTURE_ROCK_TYPE_IVSET') ///
	main(`MAIN') large(`LARGE_IVSET') ///
	filename("`TABLES'/iv_reg_profit_cashwown_wins_nopen_all") pnotpen(_Isd* _Ild* elevation slope `SOIL_CONTROLS') cluster(`clustervar')
	
	
// ~~~~~~~~~~~~~~~~~~~~~~ Farmer level clustering ~~~~~~~~~~~~~~~~~~~~~~~~~~
// Total profits 
robustness_lasso_iv profit_total_t, controls(`CONTROLS') frac(`FRACTURE_IVSET') rock(`ROCK_TYPE_IVSET') frac_rock(`FRACTURE_ROCK_TYPE_IVSET') ///
	main(`MAIN') large(`LARGE_IVSET') ///
	filename("`TABLES'/iv_reg_profit_cashwown_wins_cluster_farmer") pnotpen(_Isd* _Ild* elevation slope `SOIL_CONTROLS') cluster(f_id)  title("Profit regressions with std. errors clustered at the feeder level") 
	
}
//method("plasso")


//===================== FIRST STAGE ============================================

if `FIRST_STAGE' == 1 {

label var dist2fault_km "Distance to fault (km)"
label var ltot_1km "Fracture length (1 km radius)"
label var ltot_5km "Fracture length (5 km radius)"

lasso_iv_first profit_cashwown_wins, controls(`CONTROLS') filename("`TABLES'/tab_ivpds_first_stage") ///
					  frac(`FRACTURE_IVSET') rock(`ROCK_TYPE_IVSET') aquifers(`FRACTURE_ROCK_TYPE_IVSET') ///
					  main(`MAIN') large(`LARGE_IVSET') cluster(sdo_feeder_code) 


					  } 
					  
					  
					  
// ============= REGRESS OBSERVABLE PRODUCTIVITY ON PREDICTED DEPTH ============

if `PREDICTED_DEPTH' == 1 {

// Save current data in a temporary file
tempfile master_data
sort f_id crop
save `master_data', replace

// Load TFP data from main structural model
import delimited using "`WORKING_DATA'/tfp_by_farmer_crop.csv", clear
sort f_id crop
merge 1:1 f_id crop using `master_data'



// ~~~~~~~~~~~~~~~~~~~~~~~~ Instrument sets & Controls ~~~~~~~~~~~~~~~~~~~~~~~~~
// Fracture-lineament instrument
local FRACTURE_IVSET dist2fault_km ltot_1km ltot_5km

// Rock type instruments
local ROCK_TYPE_IVSET rock_area_* rock_type_*

// Fracture-lineament + Rock type instruments (without interactions)
local FRACTURE_ROCK_TYPE_IVSET `FRACTURE_IVSET' `ROCK_TYPE_IVSET' aquifer_type*

// Main instrument set (Rock type + fractures + 1st order interactions + aquifers)
local MAIN `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 rock_area2_* /// 
		ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11 ///
		ltot1km_area11* ltot5km_area11* dist2fault_area11*		
		
// Large instrument set (Small instrument set + 2nd order interactions)
local LARGE_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 ///
		ltot1km_ltot5km* ltot1km_dist* ltot5km_dist* ///
		ltot1km_area* ltot5km_area* dist2fault_area* ///

local CONTROLS _Ild* _Isd* elevation slope `SOIL_CONTROLS'

// ~~~~~~~~~~~~~~~~~~~~~~~~~~ Estimation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// First stage
ivlasso yield (`CONTROLS') (farmer_well_depth=`MAIN'), ///
	first cluster(f_id) pnotpen(`CONTROLS') post(pds) idstats 
estimates restore _ivlasso_farmer_well_depth

// Generate predicted depth
predict depth_hat


// Labels
la var depth_hat "Predicted depth (feet)"
la var elevation "Elevation"
la var slope "Slope"
la var prop_acidic "Prop. acidic"
la var tfp "TFP"
gen tot_land_owned = 1/107639*d1_tot_land
la var tot_land_owned "Land owned (ha)" 

estpost sum depth_hat elevation slope prop_acidic tot_land_owned tfp, detail
esttab using "`TABLES'/summary_observable_productivity.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
		title("Summary Statistics: Observable determinants of productivity") ///
		booktabs noobs nonumbers label replace 

// Regress elevation on predicted depth
reg elevation depth_hat _Isd*, cluster(sdo_feeder_code)
eststo elevation
qui sum depth_hat
estadd scalar DEPMEAN = r(mean)
unique f_id if e(sample) == 1
estadd scalar FARMER = r(unique)

// Regress slope on predicted depth
reg slope depth_hat _Isd*, cluster(sdo_feeder_code)
eststo slope
qui sum depth_hat
estadd scalar DEPMEAN = r(mean)
unique f_id if e(sample) == 1
estadd scalar FARMER = r(unique)

// Regress acidity on predicted depth
reg prop_acidic depth_hat _Isd*, cluster(sdo_feeder_code)
eststo acidity
qui sum depth_hat
estadd scalar DEPMEAN = r(mean)
unique f_id if e(sample) == 1
estadd scalar FARMER = r(unique)

// Regress plot size on predicted depth
reg tot_land_owned depth_hat _Isd*, cluster(sdo_feeder_code)
eststo land
qui sum depth_hat
estadd scalar DEPMEAN = r(mean)
unique f_id if e(sample) == 1
estadd scalar FARMER = r(unique)

// Regress tfp on predicted deepth
reg tfp depth_hat _Isd*, cluster(sdo_feeder_code)
eststo tfp
qui sum depth_hat
estadd scalar DEPMEAN = r(mean)
unique f_id if e(sample) == 1
estadd scalar FARMER = r(unique)


// Output regression table
esttab elevation slope acidity land tfp using "`TABLES'/observables_on_predicted_depth.tex", ///
	title("Regressions of predicted depth on observable components of productivity") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	indicate("Subdivisional effects = _Isd*") ///
	stats( DEPMEAN N FARMER , fmt(a2) label( "Mean dep. var" "N" "Farmers" )) ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes("Standard errors clustered at the feeder level") 


drop tot_land_owned



}

} // Robustness


