
/**********************************************************************

	Rationing the Commons -- Farmer adaptation to water scarcity
	
		*
	
	


***********************************************************************/

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

use "`CLEAN_FARMER_SURVEY'/baseline_survey_farmer_crop_with_imputed_variables.dta"

// Choose which exhibits to run
local IV_REGRESSIONS = 1
local SUMMARIES = 0


if `SUMMARIES' == 1 {
//======================= SUMMARY STATISTICS ===================================

// Create an output table 	
eststo clear
estpost tab crop_type 

esttab using "`TABLES'/crop_types_tabulation.tex", ///
cells("b(label(Frequency)) pct(label(Percent))") label unstack nogaps ///
title("Tabulations of crop types") nomtitle ///
varwidth(36) nonumber booktabs width(1.0\hsize) replace ///
addnotes("Date Run: `c(current_date)'")

// Winsorize well depth
winsor avg_source_depth, gen(avg_source_depth_wins) p(0.02) highonly
replace avg_source_depth = avg_source_depth_wins

//~~~~~~~~~~ STAGE 1: CROP CHOICE DUMMIES ~~~~~~~~~~~~~

eststo clear
estpost sum water_*

esttab using "`TABLES'/shares_water_intensive.tex", ///
	cells("count(label(Obs)) mean(label(Share))") label  nogaps nonumber replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'") ///
	title("Share of water intensive crops") 

/*
* These box plots are not particularly useful, mostly because water depth is defined
* at the farmer level whereas whether a crop is hardy or not is defined at the crop level.
* This means that if farmers tend to grow many types of crops but change the SHARE due to scarcity
* then it will not show up as a significant difference in the plots
*/
// Box plot well depth wrt water hardiness	
set graphics off
graph box avg_source_depth, over(water_hardy) graphregion(color(white)) bgcolor(white) 
graph export "`FIGURES'/hardiness_depth_box_plot.pdf", replace 

// Box plot well depth wrt water intensity
graph box avg_source_depth, over(water_intensive) graphregion(color(white)) bgcolor(white)
graph export "`FIGURES'/intensity_depth_box_plot.pdf", replace

// Box plot well dpeth wrt water moderation
graph box avg_source_depth, over(water_moderate) graphregion(color(white)) bgcolor(white)
graph export "`FIGURES'/moderate_depth_box_plot.pdf", replace


*** Area under water-() crops (Figure A) ***

// Generate area under water hardiness as a crop level variable
gen area_under_hardy = f1_4_3_area_und_crp_sqft if water_hardy == 1
gen area_under_intensive =  f1_4_3_area_und_crp_sqft if water_intensive == 1
gen area_under_moderate = f1_4_3_area_und_crp_sqft if water_moderate == 1

// Aggregate to farmer level
preserve
collapse (sum) total_crop_area=f1_4_3_area_und_crp_sqft area_* (firstnm) avg_source_depth, by(f_id)

// Create shares of crop under water hardy area
gen share_water_hardy = area_under_hardy/total_crop_area
gen share_water_intensive = area_under_intensive/total_crop_area
gen share_water_moderate = area_under_moderate/total_crop_area

la var share_water_hardy "Share under water hardy"
la var share_water_intensive "Share under water intensive"
la var share_water_moderate "Share under water moderate"
la var avg_source_depth "Water depth (ft)"

// Scatter share of area cropped under water () crops against water depth
lpoly share_water_hardy avg_source_depth, graphregion(color(white)) bgcolor(white) bwidth(100) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_hardy_depth.pdf", replace

lpoly share_water_intensive avg_source_depth, graphregion(color(white)) bgcolor(white) bwidth(100) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_intensive_depth.pdf", replace

lpoly share_water_moderate avg_source_depth, graphregion(color(white)) bgcolor(white) bwidth(100) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_moderate_depth.pdf", replace

// Find correlation between share of area under water () crops and water depth
reg share_water_hardy avg_source_depth
eststo reg_hardy
estadd scalar RMSE= e(rmse) 

reg share_water_intensive avg_source_depth
eststo reg_intensive
estadd scalar RMSE= e(rmse)

reg share_water_moderate avg_source_depth
eststo reg_moderate
estadd scalar RMSE= e(rmse)

// Output
esttab reg_hardy reg_moderate reg_intensive using "`TABLES'/reg_hardy_depth.tex", ///
	title("Share of area under crop type (water) on water depth (OLS)") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(F RMSE N, fmt(a2)) ///
	alignment(D{.}{.}{-1}) label width(0.7\hsize) nogaps ///
		varwidth(1) ///
		addnotes("Date Run: `c(current_date)'")
		
restore


*** Mean (weighted by area) water requirement (Figure B) ****

preserve

// Aggregate to farmer level
collapse (firstnm) avg_source_depth (mean) f1_3_wat_intst [aw=f1_4_3_area_und_crp_sqft], by(f_id)

// Label variables
la var avg_source_depth "Water depth (ft)"
la var f1_3_wat_intst "Water requirement (mm)"

// Scatter mean water requirement against depth
lpoly f1_3_wat_intst avg_source_depth, graphregion(color(white)) bgcolor(white) bwidth(100) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_water_req_depth.pdf", replace

restore


preserve
collapse prop_area_under_irrigated prop_area_sprinkler avg_source_depth, by(f_id)
bysort avg_source_depth : egen avg_prop_under_irr = mean(prop_area_under_irrigated)

lpoly prop_area_under_irrigated avg_source_depth, ///
lcolor(red) msymbol(circle_hollow) msize(0.3) mcolor(midblue) ///
graphregion(color(white)) plotregion(color(white)) bgcolor(white) ///
ytitle(Share of area under irrigated (percent)) xtitle("Water depth (ft)") ///
xlabel(0(100)800) title("") bwidth(100) lwidth(vvthick) note("")

graph export "`FIGURES'/scatter_irrigated_depth.pdf", replace

twoway (lfit avg_prop_under_irr avg_source_depth, lcolor(black)) ///
(lpoly avg_prop_under_irr avg_source_depth, lcolor(red) graphregion(color(white)) ///
plotregion(color(white)) bgcolor(white) ytitle(Share of area under irrigated (percent)) ///
xtitle(Avg. water depth in feeder(feet)) xlabel(0(100)800) title("") bwidth(100) note("")) ///
(scatter avg_prop_under_irr avg_source_depth, msymbol(circle_hollow) msize(0.3) mcolor(midblue)) ///
,legend(label(1 "Regression Line") label(2 "Polynomial Fit") label(3 "Share of area under irrigated"))

graph export "`FIGURES'/scatter_irrigated_depth_lpoly.pdf", replace

bysort avg_source_depth : egen avg_prop_area_sprinkler = mean(prop_area_sprinkler)

lpoly prop_area_sprinkler avg_source_depth, ///
lcolor(red) msymbol(circle_hollow) msize(0.3) mcolor(midblue) ///
graphregion(color(white)) plotregion(color(white)) bgcolor(white) ///
ytitle(Share of area with sprinkler irrigation (percent)) xtitle("Water depth (ft)") ///
xlabel(0(100)800) title("") bwidth(100) lwidth(vvthick) note("")

graph export "`FIGURES'/scatter_share_sprinkler_irrigated.pdf", replace

twoway (lfit avg_prop_area_sprinkler avg_source_depth, lcolor(black)) ///
(lpoly avg_prop_area_sprinkler avg_source_depth, lcolor(red) graphregion(color(white)) ///
plotregion(color(white)) bgcolor(white) ytitle(Share of area with sprinkler irrigation (percent)) ///
xtitle(Avg. water depth in feeder(feet)) xlabel(0(100)800) title("") bwidth(100) note("")) ///
(scatter avg_prop_area_sprinkler avg_source_depth, msymbol(circle_hollow) msize(0.3) mcolor(midblue)) ///
,legend(label(1 "Regression Line") label(2 "Polynomial Fit") label(3 "Share of area with sprinkler irrigation"))

graph export "Polynomial plus Regression area sprinkler irrigation (farmer).pdf", replace

la var avg_source_depth "Mean well depth (feet)"
la var avg_prop_under_irr "Under Irrigated (\%)"
la var avg_prop_area_sprinkler "Sprinkler Used (\%)"

eststo clear
reg avg_prop_under_irr avg_source_depth
eststo M1
estadd scalar RMSE= e(rmse)

reg avg_prop_area_sprinkler avg_source_depth
eststo M2
estadd scalar RMSE= e(rmse)

esttab M1 M2 using "`TABLES'/reg_area_irrigation_depth.tex", ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin booktabs ///
	title("Share of area irrigated on water depth (OLS)") replace ///
	stats(F RMSE N, fmt(a2)) ///
	alignment(D{.}{.}{-1}) label width(0.7\hsize) nogaps ///
		varwidth(1) ///
		addnotes("Date Run: `c(current_date)'")
	

restore
		
//~~~~~~~~~~~ STAGE 2: LABOUR CHOICES ~~~~~~~~~~~~~

preserve

// Collapse to farmer level (!)
collapse (sum) *_hh_lab_* *_wage_lab_* ///
		 (mean) *_avg_wage_* ///
		 (firstnm) avg_source_depth, by(f_id)
		 
la var avg_source_depth "Water depth (ft)"
//~~~~~~ Labour used for sowing	~~~~~~~

// Household labour	 
gen hh_lab_sow = f5_3_1_hh_lab_sow*f5_3_1_hh_lab_days
la var hh_lab_sow "HH Labour - Sowing (Wxd)"
winsor hh_lab_sow, p(0.02) highonly gen(hh_lab_sow_wins)
replace hh_lab_sow = hh_lab_sow_wins

// Wage labour
gen wage_lab_sow = f5_3_3_wage_lab_sow*f5_3_3_wage_lab_days
la var wage_lab_sow "Wage Labour - Sowing (Wxd)"
winsor wage_lab_sow, p(0.02) highonly gen(wage_lab_sow_wins)
replace wage_lab_sow = hh_lab_sow_wins

// Average wage per worker per day
la var f5_3_4_avg_wage_sow "Avg wage sowing (Rs/(Wxd))"


//~~~~~~ Labour used for irrigation ~~~~~~~

// Household labour
gen hh_lab_irr = f5_3_5_hh_lab_irr*f5_3_5_hh_lab_days
la var hh_lab_irr "HH Labour - Irrigation (Wxd)"
winsor hh_lab_irr, p(0.02) highonly gen(hh_lab_irr_wins)
replace hh_lab_irr = hh_lab_irr_wins*0.25

// Wage labour
gen wage_lab_irr = f5_3_7_wage_lab_irr*f5_3_7_wage_lab_days
la var wage_lab_irr "Wage Labour - Irrigation (Wxd)"
winsor wage_lab_irr, p(0.02) highonly gen(wage_lab_irr_wins)
replace wage_lab_irr = wage_lab_irr_wins

// Average wages per worker per day
la var f5_3_8_avg_wage_irr "Avg wage irrigation (Rs/(Wxd))"

// ~~~~~~~~ Labour used for harvesting ~~~~~~~

// Household labour
gen hh_lab_hrvst = f5_3_9_hh_lab_hrvst*f5_3_9_hh_lab_days
la var hh_lab_hrvst "HH Labour - Harvest (Wxd)"
winsor hh_lab_hrvst, p(0.02) highonly gen(hh_lab_hrvst_wins)
replace hh_lab_hrvst = hh_lab_hrvst_wins

// Wage labour
gen wage_lab_hrvst = f5_3_11_wage_lab_hrvst*f5_3_11_wage_lab_days
la var wage_lab_hrvst "Wage Labour - Harvest (Wxd)"
winsor wage_lab_hrvst, p(0.02) highonly gen(wage_lab_hrvst_wins)
replace wage_lab_hrvst = wage_lab_hrvst_wins

// Average wages per worker per day
la var f5_3_12_avg_wage_hrvst "Avg wage harvest (Rs/(Wxd))"

// ~~~~~~~ Total Labour ~~~~~~~~
// Irrigation labour
egen irr_worker_days = rowtotal(hh_lab_irr wage_lab_irr)
la var irr_worker_days "Labour -- Irrigation (Wxd)"

// Household labour
egen hh_workers_per_day = rowtotal(hh_lab_sow hh_lab_irr hh_lab_hrvst)
la var hh_workers_per_day "HH Labour (Wxd)"

// Wage labour
egen wage_workers_per_day = rowtotal(wage_lab_sow wage_lab_irr wage_lab_hrvst)
la var wage_workers_per_day "Wage Labour (Wxd)"

// Wage and HH labour
egen worker_days = rowtotal(wage_workers_per_day hh_workers_per_day) 
la var worker_days "Labour (Wxd)"

// Share of irrigation labour in total labour
gen share_labour_irr = irr_worker_days/worker_days
la var share_labour_irr "Share of irrigation labour"


// Summary table: All workers
eststo clear
estpost sum worker_days hh_workers_per_day wage_workers_per_day, detail

esttab using "`TABLES'/total_labour_per_day.tex", ///
	cells("mean sd p25 p50 p75 count") ///
	label unstack nogaps noobs ///
	title("Summary statistics: Worker-days") ///
	nomtitle ///
	varwidth(36) nonumber booktabs width(1.0\hsize) replace ///
	addnotes("Date Run: `c(current_date)'")	

// Summary table: sowing	
eststo clear
estpost sum hh_lab_sow wage_lab_sow f5_3_4_avg_wage_sow, detail

esttab using "`TABLES'/sowing_labour_per_day.tex", ///
	cells("mean sd p25 p50 p75 count") ///
	label unstack nogaps noobs ///
	title("Summary statistics: Worker-days (sowing)") ///
	nomtitle ///
	varwidth(36) nonumber booktabs width(1.0\hsize) replace ///
	addnotes("Date Run: `c(current_date)'")	

// Summary table: irrigation
eststo clear
estpost sum hh_lab_irr wage_lab_irr f5_3_8_avg_wage_irr, detail

esttab using "`TABLES'/irrigation_labour_per_day.tex", ///
	cells("mean sd p25 p50 p75 count") ///
	label unstack nogaps noobs ///
	title("Summary statistics: Worker-days (irrigation)") ///
	nomtitle ///
	varwidth(36) nonumber booktabs width(1.0\hsize) replace ///
	addnotes("Date Run: `c(current_date)'")	
	
// Summary table: harvesting
eststo clear
estpost sum hh_lab_hrvst wage_lab_hrvst f5_3_12_avg_wage_hrvst, detail

esttab using "`TABLES'/harvesting_labour_per_day.tex", ///
	cells("mean sd p25 p50 p75 count") ///
	label unstack nogaps noobs ///
	title("Summary statistics: Worker-days (harvesting)") ///
	nomtitle ///
	varwidth(36) nonumber booktabs width(1.0\hsize) replace ///
	addnotes("Date Run: `c(current_date)'")	
	
// Scatter total household labour per day vs water depth	
lpoly hh_workers_per_day avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_total_hh_wpd_depth.pdf", replace

// Scatter total wage labour per day vs water depth
lpoly wage_workers_per_day avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_total_wage_wpd_depth.pdf", replace

// Scatter sowing household labour per day vs water depth
lpoly hh_lab_sow avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_sowing_hh_wpd_depth.pdf", replace

// Scatter sowing wage labour per day vs water depth
lpoly wage_lab_sow avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_sowing_wage_wpd_depth.pdf", replace

// Scatter irrigation household labour per day vs water depth
lpoly hh_lab_irr avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_irrigation_hh_wpd_depth.pdf", replace

// Scatter irrigation wage labour per day vs water depth
lpoly wage_lab_irr avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red)	///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_irrigation_wage_wpd_depth.pdf", replace

// Scatter harvesting household labour per day vs water depth
lpoly hh_lab_hrvst avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_harvesting_hh_wpd_depth.pdf", replace

// Scatter harvesting wage labour per day vs water depth
lpoly wage_lab_hrvst avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_harvesting_wage_wpd_depth.pdf", replace

// Scatter share of irrigation labour in total labour
lpoly share_labour_irr avg_source_depth, bwidth(100) graphregion(color(white)) bgcolor(white) lcolor(red) ///
	msymbol(circle_hollow) msize(0.3) mcolor(midblue) title("")
graph export "`FIGURES'/scatter_share_irr_depth.pdf", replace


// Find correlation between water depth and different labour inputs (make functions later)

* Total Labour
eststo clear

reg hh_workers_per_day avg_source_depth
eststo hh_workers
estadd scalar RMSE = e(rmse)

reg wage_workers_per_day avg_source_depth
eststo wage_workers
estadd scalar RMSE = e(rmse)

esttab hh_workers wage_workers using "`TABLES'/reg_workers_depth.tex", ///
	title("Houshold and wage labour (worker-days) on water depth (OLS)") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(F RMSE N, fmt(a2)) ///
	alignment(D{.}{.}{-1}) label width(0.7\hsize) nogaps ///
		varwidth(1) ///
		addnotes("Date Run: `c(current_date)'")
		
		
* Sowing
eststo clear

reg hh_lab_sow avg_source_depth
eststo hh_workers_sow
estadd scalar RMSE = e(rmse)

reg wage_lab_sow avg_source_depth
eststo wage_workers_sow
estadd scalar RMSE = e(rmse)

reg f5_3_4_avg_wage_sow avg_source_depth
eststo wage_sow
estadd scalar RMSE = e(rmse)

esttab hh_workers_sow wage_workers_sow wage_sow using "`TABLES'/reg_sowing_depth.tex", ///
	title("Houshold and wage labour -- sowing (worker-days) on water depth (OLS)") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(F RMSE N, fmt(a2)) ///
	alignment(D{.}{.}{-1}) label width(0.7\hsize) nogaps ///
		varwidth(1) ///
		addnotes("Date Run: `c(current_date)'")
		
		
* Irrigation
eststo clear

reg hh_lab_irr avg_source_depth
eststo hh_workers_irr
estadd scalar RMSE = e(rmse)

reg wage_lab_irr avg_source_depth
eststo wage_workers_irr
estadd scalar RMSE = e(rmse)

reg f5_3_8_avg_wage_irr avg_source_depth
eststo wage_irr
estadd scalar RMSE = e(rmse)

esttab hh_workers_irr wage_workers_irr wage_irr using "`TABLES'/reg_irrigation_depth.tex", ///
	title("Houshold and wage labour -- irrigation (workers-days) on water depth (OLS)") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(F RMSE N, fmt(a2)) ///
	alignment(D{.}{.}{-1}) label width(0.7\hsize) nogaps ///
		varwidth(1) ///
		addnotes("Date Run: `c(current_date)'")
		
* Harvesting
eststo clear

reg hh_lab_hrvst avg_source_depth
eststo hh_workers_hrvst
estadd scalar RMSE = e(rmse)

reg wage_lab_hrvst avg_source_depth
eststo wage_workers_hrvst
estadd scalar RMSE = e(rmse)

reg f5_3_12_avg_wage_hrvst avg_source_depth
eststo wage_hrvst
estadd scalar RMSE = e(rmse)

esttab hh_workers_hrvst wage_workers_hrvst wage_hrvst using "`TABLES'/reg_harvesting_depth.tex", ///
	title("Houshold and wage labour -- harvesting (workers-dayss) on water depth (OLS)") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(F RMSE N, fmt(a2)) ///
	alignment(D{.}{.}{-1}) label width(0.7\hsize) nogaps ///
		varwidth(1) ///
		addnotes("Date Run: `c(current_date)'")


restore

}


if `IV_REGRESSIONS' == 1 {


local WATER_PRICE = 0
local LAND = 0
local CAPITAL = 0
local WATER_HARDY = 0
local LAND_SHARE = 0
local WATER_REQUIREMENT = 0
local AREA_IRRIGATED = 0
local SPRINKLER_IRRIGATION = 0
local SHARE_OUTPUT_SOLD = 0
local UNDER_IRRIGATED_PARCEL = 0
local IRRIGATION_METHOD = 1
local LAND_PREP = 0
/*******************************************************************************
********************** IV ADAPTATION REGRESSIONS *******************************
********************************************************************************/

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
local LARGE_IVSET `AQUIFERS' dist2fault_km2 ltot_1km2 ltot_5km2 ///
		ltot1km_ltot5km* ltot1km_dist* ltot5km_dist* ///
		ltot1km_area* ltot5km_area* dist2fault_area* 

// Controls
local CONTROLS _Ild* _Isd* elevation slope

if `WATER_PRICE' == 1 {
//======================== WATER PRICE [RAW] ===========================================

// Load farmer data
use "`WORKING_DATA'/marginal_analysis_sample.dta", clear

// // Reshape to water buyer level
// reshape long bought_water_price_per_ha, i(f_id) j(seller)

// la var bought_water_price_per_ha "Water bought price (Rs/ha-irrigated)"

// // Summary statistics
// eststo clear
// estpost sum bought_water_price_per_ha, detail
// esttab using "`TABLES'/water_price_summary_statistics", cells("mean sd p25 p50 p75 count") ///
// 	title("Summary Statistics: Water price (bought)") unstack nogaps nonumber label replace ///
// 	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'") 
	
	
// // Histogram
// histogram bought_water_price_per_ha
// graph export "`FIGURES'/hist_bought_water_price.pdf", replace
	
// // Relabel indep var
// la var farmer_well_depth "Well depth (ft)"

// // Destring elevation, slope
// destring elevation slope, replace force

// // Estimate 
// main_lasso_iv bought_water_price_per_ha, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
// 	filename("`TABLES'/iv_water_price_water_depth") title("Water price (Rs/ha) on farmer well depth")
	
// // Estimate without plotfe
// main_lasso_iv bought_water_price_per_ha, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
// 	filename("`TABLES'/iv_water_price_water_depth_noplotfe") title("Water price (Rs/ha) on farmer well depth (no plot size effects)") noplotfe
	
// Reshape to water price level
reshape long log_water_price katha bigha sqft sqm acre hectare dismil sqyard block_water_supply, i(f_id) j(price)

la var log_water_price "Water price (log Rs)"

// Drop collinear variables
_rmcoll  katha bigha sqft sqm acre hectare dismil sqyard block_water_supply
local dummies "`r(varlist)'"
di `dummies'

// Summary Statistics
eststo clear
estpost sum log_water_price katha bigha sqft sqm acre hectare dismil sqyard block_water_supply
esttab using "`TABLES'/water_price_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: Water price (bought and sold))") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'") 
	
// Destring elevation, slope
destring elevation slope, replace force

// Relabel indep var
la var farmer_well_depth "Well depth (ft)"
gen farmer_well_depth_dft "Wel depth ('00 ft)"

// Estimate
main_lasso_iv log_water_price , force_controls(katha bigha block_water_supply) ///
	controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') filename("`TABLES'/iv_log_water_price_water_depth") ///
	title("Log water price on farmer well depth")
	
// restore	
//===================== WATER PRICE [LEASES] =======================================
}

//===================== LAND =======================================================
use "`WORKING_DATA'/production_inputs_outputs.dta", clear
rename depth farmer_well_depth

if `LAND' == 1 {

main_lasso_iv land, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_land_water_depth") title("Land (ha) on water farmer well depth") noplotfe

}

if `CAPITAL' == 1 {
//===================== CAPITAL ===================================================
main_lasso_iv capital, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_capital_water_depth") title("Capital ('000 INR) on water farmer well depth") 

main_lasso_iv capital, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_capital_water_depth_noplotfe") title("Capital ('000 INR) on farmer well depth (no plot size effects)") noplotfe

}

if `WATER_HARDY' == 1 {
//===================== WATER HARDINESS ===========================================
main_lasso_iv water_hardy, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_water_hardy_water_depth") title("Water hardiness on farmer well depth (weighted by crop area)")  weight(land) feethundreds

main_lasso_iv water_hardy, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_water_hardy_water_depth_noplotfe") title("Water hardiness on farmer well depth (weighted by crop area) (no plot size effects)") noplotfe  weight(land) feethundreds
	
}
if `LAND_SHARE' == 1 {
//====================== SHARE OF LAND CROPPED ====================================
gen share_of_land_cropped = land/tot_land_owned
la var share_of_land_cropped "Share of the land owned used for crop"

main_lasso_iv share_of_land_cropped, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_land_share_water_depth") title("Share of land cropped on farmer well depth (no plot size effects)") noplotfe

}

if `WATER_REQUIREMENT' == 1 {
//========================= WATER REQUIREMENT ==========================================


//~~~~~~~~~~~~ Estimation ~~~~~~~~~~~~
eststo clear
estpost sum f1_3_wat_intst wheat mustard rajka crop_hyv, detail
esttab using "`TABLES'/crop_and_water_req_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: High yielding varieties") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'")

// LPM of whether wheat is grown
main_lasso_iv wheat, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') weight(land) filename("`TABLES'/iv_wheat_water_depth") ///
	title("Crop area weighted LPM of wheat grown on farmer well depth") noplotfe

// LPM of whether mustard is grown
main_lasso_iv mustard, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') weight(land) filename("`TABLES'/iv_mustard_water_depth") ///
	title("Crop area weighted LPM of mustard grown on farmer well depth") noplotfe
	
// LPM of whether a high yielding variety is grown
main_lasso_iv crop_hyv, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') weight(land) filename("`TABLES'/iv_hyv_water_depth") ///
	title("Crop area weighted LPM of whether a high-yielding variety crop is grown on farmer well depth")
}

if `AREA_IRRIGATED' == 1 {
//========================= AREA IRRIGATED =============================================
main_lasso_iv crop_area_irrigated, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_crop_area_irr_water_depth") title("Crop land area irrigated (ha) on farmer well depth") 


main_lasso_iv crop_area_irrigated, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_crop_area_irr_water_depth_noplotfe") title("Crop land area irrigated (ha) on farmer well depth (no plot size effects)") noplotfe

}

if `SPRINKLER_IRRIGATION' == 1 {
//========================= SPRINKLER IRRIGATION =======================================
main_lasso_iv prop_area_sprinkler, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_sprinkler_irrigation_water_depth") title("Proportion of area under sprinkler irrigation on farmer well depth")
	
main_lasso_iv prop_area_sprinkler, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_sprinkler_irrigation_water_depth_noplotfe") title("Proportion of area under sprinkler irrigation on farmer well depth (no plot size effects)") noplotfe
	
}

if `SHARE_OUTPUT_SOLD' == 1 {
//========================= SHARE OF VALUE SOLD =========================================
main_lasso_iv share_value_output_sold, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_share_value_output_sold_water_depth") title("Share of the value of output that was sold on farmer well depth")
	
main_lasso_iv share_value_output_sold, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_share_value_output_sold_water_depth_noplotfe") title("Share of the value of output that was sold on farmer well depth (no plot size effects)") noplotfe

}

if `LAND_PREP' == 1 {
// ====================== LAND PREPARATION WAGES =========================================
// Summary statistics
eststo clear
estpost sum land_prep_wage, detail
esttab using "`TABLES'/land_prep_wages_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: Land preparation wages") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'")

// Estimation
main_lasso_iv land_prep_wage, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_land_prep_wage_water_depth") title("Land preparation wages on farmer well depth") 


}
if `UNDER_IRRIGATED_PARCEL' == 1 {
//========================= UNDER-IRRIGATED PARCEL ========================================
preserve

// Reshape to farmer x crop x parcel level
reshape long parcel_leveled_pre_sow under_irrigated_parcel, i(farmer_plot_id) j(parcel)

// Label variables
la var parcel_leveled_pre_sow "Parcel leveled before sowing" 
la var under_irrigated_parcel "Parcel under-irrigated"

// Summary statistics
eststo clear
estpost sum parcel_leveled_pre_sow under_irrigated_parcel, detail
esttab using "`TABLES'/parcel_irr_level_summary_statistics", cells("mean sd p25 p50 p75 count") ///
	title("Summary Statistics: Parcel irrigation and leveling") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'")
	
// ~~~~~~~~~~ ESTIMATION ~~~~~~~~~~~~~~
// Parcel leveling
main_lasso_iv parcel_leveled_pre_sow, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_parcel_leveled_water_depth") title("LPM of parcel leveling on farmer well depth") noplotfe
	
// Under-irrigated parcel
main_lasso_iv under_irrigated_parcel, controls(`CONTROLS') small_ivset(`MAIN') large_ivset(`LARGE_IVSET') ///
	filename("`TABLES'/iv_under_irrigated_parcel_water_depth") title("LPM of whether a parcel is under-irrigated on farmer well depth") noplotfe

restore
}


if `IRRIGATION_METHOD' == 1 {
//========================= TYPE OF IRRIGATION METHOD =====================================
// ~~~~~~~~~~~~ CROSS-TABULATION: IRRIGATION METHOD & CROP TYPE ~~~~~~~~~~~~~~~~
label drop yesno
label define yesno 1 "Used" 0 "Not used"
label values drip yesno 
label values flood yesno
label values sprinkler yesno
label values border_strip yesno
 

// ~~~~~~~~~~~~~ DATA - PREP ~~~~~~~~~~~~~
// Load farmer level data
use "`WORKING_DATA'/marginal_analysis_sample.dta", clear

// Label farmer well depth
la var farmer_well_depth "Farmer well depth (ft)"

// Drop extra parcel sizes (we only have 15 wide variables for each parcel level variable but the total number of parcels is 18!)
drop d2_1_tot_size_land_16_sqft-d2_1_tot_size_land_18_sqft

// Rename parcel size variables to have stubs first numbers last
forval i = 1/15 {
	rename d2_1_tot_size_land_`i'_sqft parcel_size`i'
}

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

// Reshape to farmer x parcel level
reshape long f5_1_6_5_irr_tech_pcl_drip f5_1_6_5_irr_tech_pcl_fld parcel_leveled_pre_sow under_irrigated_parcel ///
	f5_1_6_5_irr_tech_pcl_frw f5_1_6_5_irr_tech_pcl_spr f5_1_6_5_irr_tech_pcl_brst parcel_size, i(f_id) j(parcel)
	
la var parcel_leveled_pre_sow "Parcel leveled"
la var under_irrigated_parcel "Parcel under-irrigated"

// Winsorize parcel size
winsor parcel_size, gen(parcel_size_wins) p(0.02) highonly
replace parcel_size = parcel_size_wins
la var parcel_size "Parcel size (ha)"

// Convert parcel size to ha
replace parcel_size = parcel_size*1/107639
	
	
// Destring elevation, slope
destring elevation slope, replace force
	
// Replace with 0s if missing
replace f5_1_6_5_irr_tech_pcl_drip = 0 if missing(f5_1_6_5_irr_tech_pcl_drip) & !missing(parcel_size) 
replace f5_1_6_5_irr_tech_pcl_frw = 0 if missing(f5_1_6_5_irr_tech_pcl_frw) & !missing(parcel_size)
replace f5_1_6_5_irr_tech_pcl_fld = 0 if missing(f5_1_6_5_irr_tech_pcl_fld) & !missing(parcel_size)
replace f5_1_6_5_irr_tech_pcl_brst = 0 if missing(f5_1_6_5_irr_tech_pcl_brst) & !missing(parcel_size)
replace f5_1_6_5_irr_tech_pcl_spr = 0 if missing(f5_1_6_5_irr_tech_pcl_spr) & !missing(parcel_size)

// Joint flood and furrow variable
gen furrow_flood = cond(f5_1_6_5_irr_tech_pcl_fld == 1 | f5_1_6_5_irr_tech_pcl_frw == 1, 1, 0)
replace furrow_flood = . if furrow_flood == 0 & missing(f5_1_6_5_irr_tech_pcl_fld) & missing(f5_1_6_5_irr_tech_pcl_frw)
la var furrow_flood "Furrow/flood irrigation used"

// Label variables
la var f5_1_6_5_irr_tech_pcl_drip "Parcel drip irrgiated"
la var f5_1_6_5_irr_tech_pcl_frw "Parcel furrow irrigated"
la var f5_1_6_5_irr_tech_pcl_fld "Parcel flood irrigated"
la var f5_1_6_5_irr_tech_pcl_brst "Parcel border strip irrigated"
la var f5_1_6_5_irr_tech_pcl_spr "Parcel sprinker irrigated"

//~~~~~~ Boxplots ~~~~~~
label define leveling 0 "Not leveled" 1 "Leveled"
label values parcel_leveled_pre_sow leveling

label define sprinkler 0 "Not Sprinkler Irrigated" 1 "Sprinkler Irrigated"
label values f5_1_6_5_irr_tech_pcl_spr sprinkler

graph box parcel_size, over(f5_1_6_5_irr_tech_pcl_spr) graphregion(color(white)) bgcolor(white) asyvars horizontal
graph export "`FIGURES'/box_sprinkler_irrigation_parcel_size.pdf", replace

graph box parcel_size, over(parcel_leveled_pre_sow) graphregion(color(white)) bgcolor(white) asyvars horizontal
graph export "`FIGURES'/box_parcel_leveled_parcel_size.pdf", replace

graph box tot_irr_labour, over(f5_1_6_5_irr_tech_pcl_spr) graphregion(color(white)) bgcolor(white) asyvars horizontal
graph export "`FIGURES'/box_sprinkler_irrigation_irrigation_labour.pdf", replace

// Summary statistics (lower bounds)
eststo clear
estpost sum f5_1_6_5*, detail
esttab using "`TABLES'/irrigation_tech_summary_statistics", cells("mean(fmt(a2)) sd(fmt(a2)) p25 p50 p75 count") ///
	title("Summary statistics of irrigation technology used") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'") 
	
eststo clear
estpost sum f5_1_6_5* [aweight=parcel_size], detail
esttab using "`TABLES'/irrigation_tech_summary_statistics_area_weighted", cells("mean(fmt(a2)) sd(fmt(a2)) p25 p50 p75 count") ///
	title("Parcel area-weighted summary statistics of irrigation technology used") unstack nogaps nonumber label replace ///
	varwidth(36) booktabs width(1.0\hsize) noobs addnotes("Date Run: `c(current_date)'") 
	
// ~~~~~~~~~~~~~ ESTIMATION ~~~~~~~~~~~~~~~~
// Generate farmer well depth in 100s of feet	
replace farmer_well_depth = farmer_well_depth
la var farmer_well_depth "Well depth (1 sd = 187 feet)"

// Sparse matrix of adaptation summary statistics
eststo clear
estpost sum parcel_leveled_pre_sow f5_1_6_5_irr_tech_pcl_spr furrow_flood under_irrigated_parcel, detail
estout using "`TABLES'/ag_adaptation_parcel_level.tex", cells("mean(fmt(a2)) sd(fmt(a2)) p25(fmt(a2)) p50(fmt(a2)) p75(fmt(a2)) count(fmt(a2))") ///
                label style(tex) mlabels(none) collabels(none) replace

//~~~~ Get Main IV-PDS Estimates ~~~~~~~~
// Not plot size effects
gen sdo_feeder_code = floor(f_id/100) 

local CONTROLS _Isd* elevation slope
local clustervar sdo_feeder_code

// Drip
_lasso_iv f5_1_6_5_irr_tech_pcl_drip, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("drip") weight(parcel_size) cluster(`clustervar')

// Furrow
_lasso_iv f5_1_6_5_irr_tech_pcl_frw, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("furrow") weight(parcel_size) cluster(`clustervar')

// Flood
_lasso_iv f5_1_6_5_irr_tech_pcl_fld, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("flood") weight(parcel_size) cluster(`clustervar')

// Border strip
_lasso_iv f5_1_6_5_irr_tech_pcl_brst, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("border_strip") weight(parcel_size) cluster(`clustervar')

// Sprinkler 
_lasso_iv f5_1_6_5_irr_tech_pcl_spr, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("sprinkler") weight(parcel_size) cluster(`clustervar')

// Flood or furrow
_lasso_iv furrow_flood, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("furrow_flood") weight(parcel_size) cluster(`clustervar')

// Parcel leveling
_lasso_iv parcel_leveled_pre_sow, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("leveling") weight(parcel_size) cluster(`clustervar')

// Under-irrigated
_lasso_iv under_irrigated_parcel, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("under_irrigated") weight(parcel_size) cluster(`clustervar')


use "`WORKING_DATA'/production_inputs_outputs.dta", clear
rename depth farmer_well_depth
replace farmer_well_depth = farmer_well_depth
la var farmer_well_depth "Well depth (1 sd = 187 feet)"

la var crop_hyv "High-yielding variety"
// HYV
_lasso_iv crop_hyv, endog(farmer_well_depth) controls(`CONTROLS') ivset(`MAIN') pnotpen(`CONTROLS') eststo("hyv") weight(land) cluster(`clustervar')

// All irrigation methods
esttab drip furrow flood border_strip sprinkler using "`TABLES'/iv_main_irrigation_methods_water_depth.tex", ///
	title("Area weighted IV-PDS Regression of different methods of irrigation on farmer well depth") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(toposeq sdo_fe_indicator ld_fe_indicator DEPMEAN N FARMER Z Z_SELECTED, fmt(a2) label("Toposequence" "Subdivisional effects" "Plot size effects" "Mean dep. var" "N" "Farmers" "Candidate Instruments" "Instruments Selected")) ///
	mtitles("Drip" "Furrow" "Flood" "Border Strip" "Sprinkler") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes("Date Run: `c(current_date)' " "Standard errors clustered at the farmer level") ///
	drop(`CONTROLS' _cons elevation slope) 
		
	
// Principal adaptation table	
esttab leveling sprinkler furrow_flood under_irrigated hyv using "`TABLES'/iv_principal_adaptation_water_depth.tex", ///
	title("Area weighted IV-PDS Regression of different margins of adaptation on farmer well depth") ///
	b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
	stats(toposeq sdo_fe_indicator ld_fe_indicator DEPMEAN N FARMER Z Z_SELECTED, fmt(a2) label("Toposequence" "Subdivisional effects" "Plot size effects" "Mean dep. var" "N" "Farmers" "Candidate Instruments" "Instruments Selected")) ///
	mtitles("Parcel Leveling" "Sprinkler Irrigation" "Furrow/Flood Irrigation" "Under-Irrigated" "High-yielding varieties") ///
	alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
	addnotes("Date Run: `c(current_date)' " "Standard errors clustered at the farmer level") ///
	drop(`CONTROLS' _cons elevation slope) 
	

// Principal adaptation matrix	
estout leveling sprinkler furrow_flood under_irrigated hyv using "`TABLES'/iv_principal_adaptation_water_depth_inner.tex", ///
	cells(b(star fmt(a2)) se(par fmt(a2))) starlevels(\sym{*} 0.1 \sym{**} 0.05 \sym{***} 0.01) label style(tex) ///
	stats(toposeq sdo_fe_indicator ld_fe_indicator SPACE DEPMEAN Z Z_SELECTED FARMER N, fmt(a2) label("Toposequence" "Subdivisional effects" "Plot size effects" "  " "Mean dep. var" "Candidate Instruments" "Instruments Selected" "Unique Farmers" "N" )) ///
	replace mlabels(none) collabels(none) drop(`CONTROLS' _cons elevation slope)
	
// Get std of well depth
qui sum farmer_well_depth
local std = r(sd)

di `std'	
	
// Principal adaptation table for publication
esttab hyv leveling sprinkler furrow_flood under_irrigated    ///
		using "`TABLES'/tab_ivpds_adaptation.tex", ///
		title("Instrumental variable estimates of farmer adaptation to water scarcity\label{tab:ivAdaptation}") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		stats (SPACE DEPMEAN Z Z_SELECTED FARMER N , fmt(a2) label(" " "Mean dep. var"  "Candidate Instruments" "Instruments Selected" "Unique Farmers" "Farmer-Crops")) ///
		nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}&\multicolumn{1}{c}{IV-PDS}\\" ///
				"\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" ///
				"&\multicolumn{1}{c}{\shortstack{High-yielding \\ variety}}&\multicolumn{1}{c}{\shortstack{Parcel\\leveled}}&\multicolumn{1}{c}{\shortstack{Sprinkler \\ irrigated}}&\multicolumn{1}{c}{\shortstack{Furrow/Flood \\ irrigated}}&\multicolumn{1}{c}{\shortstack{Under \\ irrigated}}\\" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\midrule \\") ///
		prefoot(" ") ///
		alignment(D{.}{.}{-1}) label width(1\hsize) nogaps ///
		postfoot("\bottomrule" ///
				 "\multicolumn{6}{p{\hsize}}{\footnotesize This table shows instrumental variable regressions of potential margins of adaptation to water scarcity on farmer well depth. Each column presents estimates from a model with a different outcome variable, as shown in the column headers. The data is from the main agricultural household survey and the observations are at the farmer-by-crop level for all but the first column where the data is at the farmer-by-parcel level. All the model specifications control for the toposequence (elevation and slope), along with subdivisional and plot size effects, as defined in Table \ref{tab:ivProfitsDepth}. We use our preferred candidate instrument set which is labelled Main in Table \ref{tab:instruments} . Standard errors are clustered at the feeder, the primary sampling unit. The statistical significance of a coefficient at certain thresholds is indicated by  \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.} \\" ///
				 "\end{tabular*}" ///
				"\end{table}") ///
		drop(`CONTROLS' _cons elevation slope) transform( `std'*@ `std' )
		
// Crop level estimate
eststo clear
eststo crop_level: estpost sum crop_hyv, detail
estout using "`TABLES'/ag_adaptation_crop_level.tex", cells("mean(fmt(a2)) sd(fmt(a2)) p25(fmt(a2)) p50(fmt(a2)) p75(fmt(a2)) count(fmt(a2))") ///
                label style(tex) mlabels(none) collabels(none) replace

	
}


}



		




