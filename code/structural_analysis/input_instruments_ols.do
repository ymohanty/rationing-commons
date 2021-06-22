

/*******************************************************************************

	Rationing the Commons -- First stage estimates of the production function	


********************************************************************************/

//============================= PREAMBLE =======================================
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
		// local PROJECT_ROOT "/Users/`c(username)'/Google Drive (josh.mohanty@gmail.com)/replication_rationing_commons"
		local PROJECT_ROOT "/Users/`c(username)'/Dropbox/replication_rationing_commons"
	}
}
 
include "`PROJECT_ROOT'/code/load_project_globals.do"	

use "`WORKING_DATA'/production_inputs_outputs.dta"


// Choose exhibits to run
local WATER = 0
local LABOUR = 0
local LAND = 0
local CAPITAL = 0

********************************************************************************
// ============================ PROGRAM DEFINITIONS ============================

program define superset_regression
	syntax [varlist(default=none)], kind(string) instr(varlist) ///
	water_instr(varlist) controls(varlist) suffix(string) ///
	figures(string) tables(string) cluster(varlist)
	
	if "`kind'" == "improved" {
		_reg_ols log_improved_land, regressors(`instr' `water_instr') controls(`controls') eststo("improved_land") cluster(`cluster')
		predict improved_land_hat
		la var improved_land_hat "Predicted log improved land "
	
		_reg_ols log_improved_labour, regressors(`instr' `water_instr') controls(`controls') eststo("improved_labour") cluster(`cluster')
		predict improved_labour_hat
		la var improved_labour_hat "Predicted log improved labour"
		
		_reg_ols log_water, regressors(`instr' `water_instr') controls(`controls') eststo("water") cluster(`cluster')
		predict water_hat
		la var water_hat "Predicted log water"
		
		//graph matrix improved_land_hat improved_labour_hat water_hat
		//graph export "`figures'/improved_corr_matrix_`suffix'.pdf", replace
		
		//corrtex improved_labour_hat improved_land_hat water_hat, file("`tables'/improved_predicted_input_correlation_table_`suffix'.tex") replace
		
		esttab improved_labour improved_land water using "`tables'/improved_tab_superset_instruments_`suffix'.tex", ///
			title("First stage regressions of improved log inputs on instrument superset") ///
			b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
			stats(toposeq sdo_fe_indicator ld_fe_indicator DEPMEAN r2_a RMSE F_STAT FARMERS N, fmt(a2) label("Toposequence" "Subdivisional effects" "Plot size effects" "Mean dep. var" "$\text{R}^2$" "RMSE" "F" "Farmers" "Farmer-crops")) ///
			mtitles("Improved labour" "Improved land" "Water") ///
			alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
			addnotes( "Standard errors clustered at the farmer level" "Dependent variable in logs") ///
			drop(_cons slope elevation _Isd*) ///
			indicate("High-dim. water instruments = `water_instr'")
			
		esttab improved_labour improved_land water using "`tables'/improved_tab_superset_instruments_incl_highdim_`suffix'.tex", ///
			title("First stage regressions of improved log inputs on instrument superset") ///
			b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
			stats(toposeq sdo_fe_indicator ld_fe_indicator DEPMEAN r2_a RMSE F_STAT FARMERS N, fmt(a2) label("Toposequence" "Subdivisional effects" "Plot size effects" "Mean dep. var" "$\text{R}^2$" "RMSE" "F" "Farmers" "Farmer-crops")) ///
			mtitles("Improved labour" "Improved land" "Water") ///
			alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
			addnotes("Standard errors clustered at the farmer level" "Dependent variable in logs") ///
			drop(_cons slope elevation _Isd* ) 
	}
	else {
		_reg_ols log_capital, regressors(`instr' `water_instr') controls(`controls') eststo("capital") cluster(`cluster')
		predict capital_hat
		la var capital_hat "Predicted log capital"
		
		_reg_ols log_labour, regressors(`instr' `water_instr') controls(`controls') eststo("labour") cluster(`cluster')
		predict labour_hat
		la var labour_hat "Predicted log labour"
		
		_reg_ols log_land, regressors(`instr' `water_instr') controls(`controls') eststo("land") cluster(`cluster')
		predict land_hat
		la var land_hat "Predicted log land"
		
		_reg_ols log_water, regressors(`instr' `water_instr') controls(`controls') eststo("water") cluster(`cluster')
		predict water_hat
		la var water_hat "Predicted log water"
		
		//graph matrix capital_hat labour_hat land_hat water_hat
		//graph export "`figures'/corr_matrix_`suffix'.pdf", replace
		
		//corrtex capital_hat labour_hat land_hat water_hat, file("`tables'/input_correlation_table_`suffix'.tex") replace
		
		// Paper table
		esttab water labour land capital using "`tables'/prod_func_first_stage_paper.tex", ///
			title("First stage estimates from production function estimation\label{tab:firstStageProdFunc}") ///
			b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
			nolines nomtitles nonumbers ///
			posthead("\toprule" ///
				"&\multicolumn{1}{c}{log(Water)}&\multicolumn{1}{c}{log(Labor)}&\multicolumn{1}{c}{log(Land)}&\multicolumn{1}{c}{log(Capital)}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\midrule \\") ///
			alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
			indicate("Geological variables = `water_instr'" ) ///	 
			stats(SPACE DEPMEAN R_SQ F_STAT FARMER N, fmt(a2) label(" " "Mean dep. var" "$ R^2 $" "F-statistic" "Farmers" "Farmer-crops")) ///
			postfoot("\bottomrule" ///
				 "\multicolumn{5}{p{\hsize}}{\footnotesize This table reports coefficients of the first stage equation for each input in the the instrumental variables estimates of the production function regression." ///
				 "Each column has as the dependent variable the logarithm of farmer-crop inputs and the independent variables the superset of all instruments." ///
				 "There are four sets of instruments. (i) The size of the farmer's three largest parcels owned and size squared." ///
				 "(ii) The number of adult males in the household and the number of adult males squared." /// 
				 "(iii) The mean price of seeds in the farmer's feeder and the mean price squared, where each variable leaves out the farmer's own prices paid." /// 
				 "(iv) Geological variables that influence groundwater depth." /// 
				 "All specifications include controls for toposequence (slope and elevation), subdivisional fixed effects and village-level soil quality indicators." ///
				 "Standard errors are clustered at the feeder, the primary sampling unit." ///
				 "Statistical significance at certain thresholds is indicated by  \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.}" /// 
				 "\end{tabular*}" ///
				"\end{table}") ///
			drop( _cons `controls')
			
		// Slides table
		esttab water labour land capital using "`tables'/prod_func_first_stage_slides.tex", ///
			title("First stage of production function estimation\label{tab:firstStageProdFunc}") ///
			b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
			nolines nomtitles nonumbers ///
			posthead("\toprule" ///
				"&\multicolumn{1}{c}{log(Water)}&\multicolumn{1}{c}{log(Labor)}&\multicolumn{1}{c}{log(Land)}&\multicolumn{1}{c}{log(Capital)}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\midrule \\") ///
			alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
			indicate("Geo. variables = `water_instr'")  /// 
			stats(SPACE F_STAT FARMER N, fmt(a2) label(" " "F" "Farmers" "Farmer-crops")) ///
			postfoot("\bottomrule" ///
				 "\multicolumn{5}{p{\hsize}}{\footnotesize  \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.} \\" ///
				 "\end{tabular*}" ///
				"\end{table}") ///
			drop(size_largest_parcel_2 size_largest_parcel_3 sq_size_largest_parcel_2 sq_size_largest_parcel_3 _cons `controls')
		
	}
	
	drop *_hat
end

//============================= PREP DATA ======================================

// ~~~~~~~~~~~~~ Summary stats ~~~~~~~~~~~~~~~~~
eststo clear
estpost sum log_*, detail
*** NOT FOR PUBLICATION **** 
esttab using "`TABLES'/log_input_instruments_summary_statistics", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
	title("Summary Statistics: Log inputs") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs

//~~~~~~~~~~~~ Define Candidate Instrument Sets ~~~~~~~~~~~~~~

// Fracture-lineament instrument
local FRACTURE_IVSET dist2fault_km ltot_1km ltot_5km

// Rock type instruments
local ROCK_TYPE_IVSET rock_area_* rock_type_*

// Fracture-lineament + Rock type instruments (without interactions)
local AQUIFERS `FRACTURE_IVSET' `ROCK_TYPE_IVSET' aquifer_type*

// Main instrument set (Rock type + fractures + 1st order interactions + aquifers)
local MAIN `AQUIFERS' dist2fault_km2 ltot_1km2 ltot_5km2 rock_area2_* /// 
		ltot1km_ltot5km11 ltot1km_dist11 ltot5km_dist11 ///
		ltot1km_area11* ltot5km_area11* dist2fault_area11*
		
// Large instrument set (Small instrument set + 2nd order interactions)
local LARGE_IVSET `FRACTURE_ROCK_TYPE_IVSET' dist2fault_km2 ltot_1km2 ltot_5km2 ///
		ltot1km_ltot5km* ltot1km_dist* ltot5km_dist* ///
		ltot1km_area* ltot5km_area* dist2fault_area* ///

// Controls
local CONTROLS _Isd* elevation slope crop_lost_preharvest crop_lost_postharvest

la var crop_lost_preharvest "Crop lost preharvest (quintals)"
la var crop_lost_postharvest "Crop lost postharvest (quintals)"



if `WATER' == 1 {
//============================ WATER ===========================================
//~~~~~~~~~~~~~~~~~~~ Estimation ~~~~~~~~~~~~~~~~~~~~

// **** TEMP: REPLACE WITH WRAPPER FUNCTION IF USED FOR PUBLICATION ****
// Estimate first stage: Fractures 
_reg_ols log_water, regressors(`FRACTURE_IVSET') controls(`CONTROLS') eststo("frac")

// Estimate first stage: Main selected instrument set
ivlasso output (`CONTROLS') (log_water=`MAIN' water_sellers), first cluster(f_id) post(pds) pnotpen(`CONTROLS' water_sellers)
local instr_selected `e(zselected)'
_reg_ols log_water, regressors(`instr_selected') controls(`CONTROLS') eststo("selected_2sls")

// Estimate Lasso: Main instrument set
_lasso_iv_first output, endog(log_water) controls(`CONTROLS') ivset(`MAIN' water_sellers ) eststo("main") pnotpen(water_sellers)

// Estimate lasso with plot decile controls
_lasso_iv_first output, endog(log_water) controls(`CONTROLS' _Ild*) ivset(`MAIN' water_sellers) eststo("lde") pnotpen(water_sellers)

// Drop controls from coefficient list
qui des _Isd* _Ild*, varlist
local droplist `r(varlist)' slope elevation _cons

// Output
esttab frac selected_2sls main lde using "`TABLES'/tab_water_instruments.tex", ///
	title("First stage regressions of log water drawn on candidate instruments") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(DEPMEAN r2_a RMSE F_STAT Z Z_SELECTED FARMERS N, fmt(a2) label("Mean dep. var" "$\text{R}^2$" "RMSE" "F" "Candidate instruments" "Instruments selected" "Farmers" "Farmer-crops")) ///
	mtitles("OLS" "OLS" "PDS" "PDS") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes("Standard errors clustered at the farmer level" "Dependent variable in logs") ///
	indicate("Subdivisional effects = _Isd*" ///
			 "Toposequence = elevation slope" ///
			 "Plot decile effects = _Ild*")
	
}

if `LABOUR' == 1 {
//========================== LABOUR ============================================

//~~~~~~~~~~~~~~ Define candidate instrument sets ~~~~~~~~
// Controls
local CONTROLS _Isd* slope elevation

// Demographics
local NUM_ADULT_MALES hh_adult_males age_youngest_member sq_hh_adult_males youngest_migrated

// Share of area in village
local SHARE_VILLAGE share_of_area_in_village

// Walk time to village
local WALK_TIME weighted_walking_time_to_crop

// All
local ALL `NUM_ADULT_MALES' `SHARE_VILLAGE' `WALK_TIME'

//~~~~~~~~~~~~~~ Summary statistics ~~~~~~~~~~~~~~~~~~~
// Relabel adult males number
la var hh_adult_males "Num. adult males"

eststo clear
estpost sum log_labour hh_adult_males youngest_migrated share_of_area_in_village weighted_walking_time_to_crop, detail

*** NOT FOR PUBLICATION **** 
esttab using "`TABLES'/labour_instruments_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: Candidate instruments for labour") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs 


//~~~~~~~~~~~~~~~~ Estimation ~~~~~~~~~~~~~~~
 
**** TEMP: REPLACE WITH WRAPPER FUNCTION IF USED FOR PUBLICATION ****

// Estimate adult males only
_reg_ols log_labour, regressors(`NUM_ADULT_MALES') controls(`CONTROLS') eststo("adult_males")

_reg_ols log_labour, regressors(`SHARE_VILLAGE') controls(`CONTROLS') eststo("share_village")

_reg_ols log_labour, regressors(`WALK_TIME') controls(`CONTROLS') eststo("walk_time")

_reg_ols log_labour, regressors(`ALL') controls(`CONTROLS') eststo("all")


// Drop controls from coefficient list
qui des _Isd* , varlist
local droplist `r(varlist)' slope elevation _cons

// Output
esttab adult_males share_village walk_time all using "`TABLES'/tab_labour_instruments.tex", ///
	title("First stage regressions of log labour on candidate instruments") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(DEPMEAN r2_a RMSE F_STAT FARMERS N, fmt(a2) label("Mean dep. var" "$\text{R}^2$" "RMSE" "F" "Farmers" "Farmer-crops")) ///
	mtitles("OLS" "OLS" "OLS" "OLS") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes("Standard errors clustered at the farmer level" "Dependent variable in logs") ///
	indicate("Subdivisional effects = _Isd*" /// 
			 "Toposequence = slope") ///
	drop(elevation _cons)


}

if `LAND' == 1 {
//========================= LAND =================================================

//~~~~~~~~~~~~~~~~~ Define candidates instrument sets ~~~~~~~~~~~~



// Controls
local CONTROLS _Isd* slope elevation

// Pakka land
local PAKKA_LAND land_owned_pakka

// Kaccha land
local KACHA_LAND land_owned_kacha

// Number of land parcels
local LAND_PARCELS land_parcels

// Size of land parcels
local SIZE_LAND_PARCELS size_largest_parcel_1-size_largest_parcel_3 sq_size_largest_parcel_1-sq_size_largest_parcel_3

// All
local ALL `PAKKA_LAND' `KACHA_LAND' `LAND_PARCELS' `SIZE_LAND_PARCELS' 

//~~~~~~~~~~~~~~~ Summary statistics ~~~~~~~~~~~~~~~~~

eststo clear
estpost sum log_land land_owned_* land_parcels, detail

*** NOT FOR PUBLICATION **** 
esttab using "`TABLES'/land_instruments_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: Candidate instruments for land") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs 

//~~~~~~~~~~~~~ Estimation ~~~~~~~~~~~~~~~~~~~~~~~~~~~

**** TEMP: REPLACE WITH WRAPPER FUNCTION IF USED FOR PUBLICATION ****
// Estimate pakka only
_reg_ols log_land, regressors(`PAKKA_LAND') controls(`CONTROLS') eststo("pakka_land")

// Estimate kacha only
_reg_ols log_land, regressors(`KACHA_LAND') controls(`CONTROLS') eststo("kacha_land")

// Estimate land parcels only
_reg_ols log_land, regressors(`LAND_PARCELS') controls(`CONTROLS') eststo("parcels")

// Estimates size of land parcels
_reg_ols log_land, regressors(`SIZE_LAND_PARCELS') controls(`CONTROLS') eststo("size_parcels")

// Estimate together
_reg_ols log_land, regressors(`ALL') controls(`CONTROLS') eststo("all")

// Drop controls from coefficient list
qui des _Isd* , varlist
local droplist `r(varlist)' slope elevation _cons

// Output
esttab pakka_land kacha_land parcels size_parcels all using "`TABLES'/tab_land_instruments.tex", ///
	title("First stage regressions of log land on candidate instruments") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(DEPMEAN r2_a RMSE F_STAT FARMERS N, fmt(a2) label("Mean dep. var" "$ \text{R}^2$" "RMSE" "F" "Farmers" "Farmer-crops")) ///
	mtitles("OLS" "OLS" "OLS" "OLS" "OLS") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes( "Standard errors clustered at the farmer level" "Dependent variable in logs") ///
	indicate("Subdivisional effects = _Isd*" /// 
			 "Toposequence = slope elevation") ///
	drop(elevation _cons)
	
}	 

if `CAPITAL' == 1 {
//=========================== CAPITAL ===========================================

	 
// Controls
local CONTROLS _Isd* slope elevation

// Seed prices across farmers
local SEED_ACROSS_FARMER seed_price_across_farmer seed_price_sq_across_farmer *_seed_price_feeder

// Chemical fertilizer price across farmer
local CHEM_FERT_ACROSS_FARMER fertilizer_price_chem fertilizer_price_chem_sq

// Seed prices
local SEED_PRICES seed_price_* *_seed_price_feeder

// Chem fert prices
local CHEM_FERT fertilizer_price_ch*

// Small
local SMALL `SEED_ACROSS_FARMER' `CHEM_FERT_ACROSS_FARMER'

// Large
local LARGE `SEED_PRICES' `CHEM_FERT'

// ~~~~~~~~~~~~~ Summary stats ~~~~~~~~~~~~~~~~~
eststo clear
estpost sum `SEED_PRICES' `CHEM_FERT', detail
*** NOT FOR PUBLICATION **** 
esttab using "`TABLES'/capital_instruments_summary_statistics_v2", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
	title("Summary Statistics: Candidate instruments for capital") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs 

	
//~~~~~~~~~~~~~ Estimation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Seed prices across farmers
_reg_ols log_capital, regressors(`SEED_ACROSS_FARMER') controls(`CONTROLS') eststo("seed_across_farmer")

// Chemical fertilizer price across farmer
_reg_ols log_capital, regressors(`CHEM_FERT_ACROSS_FARMER') controls(`CONTROLS') eststo("chem_fert_across_farmer")

// Seed_prices
_reg_ols log_capital, regressors(`SEED_PRICES') controls(`CONTROLS') eststo("seed_prices")

// Other business cash  
_reg_ols log_capital, regressors(`CHEM_FERT') controls(`CONTROLS') eststo("chem_fert")

// Small
_reg_ols log_capital, regressors(`SMALL') controls(`CONTROLS') eststo("small")

// Large
_reg_ols log_capital, regressors(`LARGE') controls(`CONTROLS') eststo("large")

// Sparse subset
//_lasso_iv_first output, endog(log_capital) controls(`CONTROLS') ivset(`ALL' ) eststo("all_lasso") 
rlasso log_capital `CONTROLS' `LARGE', partial(`CONTROLS')

// Output
esttab seed_across_farmer chem_fert_across_farmer seed_prices chem_fert small large using "`TABLES'/tab_capital_instruments_v2.tex", ///
	title("First stage regressions of log capital on candidate instruments") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(DEPMEAN r2_a RMSE F_STAT FARMERS N, fmt(a2) label("Mean dep. var" "$\text{R}^2$" "RMSE" "F" "Farmers" "Farmer-crops")) ///
	mtitles("OLS" "OLS" "OLS" "OLS" "OLS" "OLS") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes( "Standard errors clustered at the farmer level" "Dependent variable in logs") ///
	indicate("Subdivisional effects = _Isd*" )

}  

// =========================== SUPERSET REGRESSIONS =================================


/*******************************************************************************
*************** 		MAIN FIRST STAGE TABLE 		****************************
********************************************************************************/

// Dummy out missing values
gen missing_water_sellers = 1 if missing(water_sellers)
replace missing_water_sellers = 0 if missing_water_sellers != 1
replace water_sellers = 0 if missing(water_sellers)

gen missing_toposequence = 1 if missing(elevation)
replace missing_toposequence = 0 if missing_toposequence != 1
replace slope = 0 if missing(slope)
replace elevation = 0 if missing(elevation)

gen missing_seed_prices = 1 if missing(seed_price_across_farmer)
replace missing_seed_prices = 0 if missing_seed_prices != 1
replace seed_price_across_farmer = 0 if missing(seed_price_across_farmer)
replace seed_price_sq_across_farmer = 0 if missing(seed_price_sq_across_farmer)

// Gather the necessary variables into locals
local ENDOG log_land log_labour log_capital log_water

local INSTR size_largest_parcel_1 size_largest_parcel_2 size_largest_parcel_3 ///
    sq_size_largest_parcel_1 sq_size_largest_parcel_2 sq_size_largest_parcel_3 ///
    hh_adult_males sq_hh_adult_males seed_price_across_farmer seed_price_sq_across_farmer 
// missing_seed_prices 

local WATER_INSTR rock_area_14 rock_area_15 aquifer_type_4 dist2fault_area116 water_sellers ///
missing_water_sellers

local CONTROLS _Isdsdo_2 _Isdsdo_3 _Isdsdo_4 _Isdsdo_5 _Isdsdo_6 elevation ///
  slope crop_lost_preharvest crop_lost_postharvest ///
  missing_soil_controls prop_acidic prop_mildly_alkaline prop_high_k ///
  prop_med_k prop_high_p prop_med_p prop_sufficient_zn prop_sufficient_fe ///
  prop_sufficient_cu prop_sufficient_mn
// missing_toposequence 

// Label instruments for publications
la var size_largest_parcel_1 "Size of the largest parcel (Ha)"
la var size_largest_parcel_2 "Size of the 2nd largest parcel (Ha)"
la var size_largest_parcel_3 "Size of the 3rd largest parcel (Ha)"

la var sq_size_largest_parcel_1 "Size of the largest parcel squared ($\text{Ha}^2$)"
la var sq_size_largest_parcel_2 "Size of the 2nd largest parcel squared ($\text{Ha}^2$)"
la var sq_size_largest_parcel_3 "Size of the 3rd largest parcel squared ($\text{Ha}^2$)"

la var hh_adult_males "Adult males"
la var sq_hh_adult_males "Adult males squared"


replace seed_price_across_farmer = seed_price_across_farmer/100
la var seed_price_across_farmer "Seed price ('00 INR/kg)"

replace seed_price_sq_across_farmer = seed_price_sq_across_farmer/10000
la var seed_price_sq_across_farmer "Seed price squared ('0,000 $\text{INR}^2$/$\text{kg}^2$)"

// Summary statistics: instruments other than geological

preserve 

la var size_largest_parcel_1 "~~~Size of the largest parcel (Ha)"
la var size_largest_parcel_2 "~~~Size of the 2nd largest parcel (Ha)"
la var size_largest_parcel_3 "~~~Size of the 3rd largest parcel (Ha)"
la var hh_adult_males "~~~Adult males"
la var seed_price_across_farmer "~~~Seed price ('00 INR/kg)"

eststo clear
qui estpost sum size_largest_parcel_1 size_largest_parcel_2 size_largest_parcel_3 hh_adult_males seed_price_across_farmer, detail

esttab using "`TABLES'/tab_summary_nongeological_instruments.tex", cells("mean(label(Mean) fmt(a2)) sd(label(Std. dev) fmt(a2)) p25(label(25th) fmt(a2)) p50(label(Median) fmt(a2)) p75(label(75th) fmt(a2)) count(label(Farmer-crops))") ///
	title("Summary statistics for non-geological instruments") unstack nogaps label replace ///
	refcat(size_largest_parcel_1 "\emph{Land instruments}" hh_adult_males "\emph{Labor instruments}" seed_price_across_farmer "\emph{Capital instruments}", nolabel) ///
	varwidth(36) booktabs width(1.0\hsize) noobs nonumbers ///
	posthead("&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\midrule") ///		
	postfoot("\bottomrule" ///
				 "\multicolumn{7}{p{\hsize}}{\footnotesize This table provides summary statistics on the instruments used to generate exogenous variation in productive inputs for production function estimation." ///
				 "All observations are at the farmer-crop level." /// 
				 "The first block of summarize land instruments, which consist of the size of the three largest plots of land owned by a farmer." ///
				 "The second block summarizes the main instrument for labor, which is the number of adult males in the household." ///
				 "Finally, the last block summarizes seed prices which affect capital inputs exogenously, assuming the farmet has limited market power." ///
				 "Seed prices for each farmer-crop observation is calculated as the median price of all seed inputs in the feeder in which the farmer is located." ///
				 "Geological instruments are excluded from this summary since they are numerous and heterogenous, and their units are not always easy to interpret.}" /// 
				 "\end{tabular*}" ///
				"\end{table}") 
	
restore


superset_regression, kind("standard") instr(`INSTR') water_instr(`WATER_INSTR') ///
	controls(`CONTROLS') suffix("full_matlab") figures(`FIGURES') tables(`TABLES') cluster(sdo_feeder_code)
	

// ========================= "TESTING" EXCLUSION =================================

local SOIL_CONTROLS missing_soil_controls prop_acidic prop_mildly_alkaline ///
  prop_high_k prop_med_k prop_high_p prop_med_p prop_sufficient_zn ///
  prop_sufficient_fe prop_sufficient_cu prop_sufficient_mn

local TOPOSEQUENCE slope elevation
// missing_toposequence

// Profits and depth
_reg_ols profit_cashwown_wins, regressors(depth dist2fault_km ltot_1km ltot_5km) controls(`SOIL_CONTROLS' `TOPOSEQUENCE') eststo(profit_instruments) cluster(sdo_feeder_code)

// Input regressions on instruments
_reg_ols land, regressors(depth dist2fault_km ltot_1km ltot_5km) controls(`SOIL_CONTROLS' `TOPOSEQUENCE') eststo(land_instruments) cluster(sdo_feeder_code)

_reg_ols labour, regressors(depth dist2fault_km ltot_1km ltot_5km) controls(`SOIL_CONTROLS' `TOPOSEQUENCE') eststo(labour_instruments) cluster(sdo_feeder_code)

_reg_ols capital, regressors(depth dist2fault_km ltot_1km ltot_5km) controls(`SOIL_CONTROLS' `TOPOSEQUENCE') eststo(capital_instruments) cluster(sdo_feeder_code)

// Output
esttab profit_instruments land_instruments labour_instruments capital_instruments using "`TABLES'/slides_profit_inputs_on_instruments.tex", ///
	title("Total profits and production inputs on farmer well depth and instruments \label{tab:exclusion}") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	nolines nomtitles nonumbers ///
	posthead("\toprule" ///
			"&\multicolumn{1}{c}{Profit}&\multicolumn{1}{c}{Land}&\multicolumn{1}{c}{Labor}&\multicolumn{1}{c}{Capital}\\" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
			"\midrule \\") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	indicate("Soil controls = `SOIL_CONTROLS'" ///
			 "Toposequence = `TOPOSEQUENCE'")	///									
	stats(SPACE F_STAT FARMER N, fmt(a2) label(" " "$ F $-statistic" "Farmers" "Farmer-crops")) ///
	postfoot("\bottomrule" ///
				 "\multicolumn{5}{p{\hsize}}{\footnotesize  \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.} \\" ///
				 "\end{tabular*}" ///
				"\end{table}") ///
			

