  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*

NAME: merge_all.do

PURPOSE: This file merges the baseline survey, geological data, weather data, and
soil data.

AUTHOR: Viraj Jorapur 

*/
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//=============================== PREAMBLE =====================================
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


//=========================== PREP THE GEODATA & SOILDATA =================================
// load the csv for the geodata
import delimited "`CLEAN_GEOLOGICAL_DATA'/clean_geological_variables.csv", clear
drop v1 

// save a temporary file for the geological data
tempfile geo
save `geo', replace

// Load the soil data and save temporary dataset
tempfile soil 
use "`CLEAN_SOIL_DATA'/soil_controls.dta", clear
save `soil', replace

// Load the corrected name data
tempfile corrected_names
use "`CLEAN_FARMER_SURVEY'/temp_farmer_survey.dta"
save `corrected_names', replace

// Load the weather data
tempfile weather
import delimited "`CLEAN_WEATHER_DATA'/weather_controls.csv", clear
save `weather', replace

// Load the water variables, pump variables etc
tempfile water
import delimited "`CLEAN_GEOLOGICAL_DATA'/water_flow.csv", clear
save `water', replace


// ~~~~~~~~~ Farmer level ~~~~~~~~~
use "`CLEAN_FARMER_SURVEY'/baseline_survey_selected_variables.dta", clear

// Merge the geological data
merge 1:1 f_id using `geo', force


// Save data
save "`WORKING_DATA'/marginal_analysis_sample.dta", replace



// ~~~~~~~~~ Crop level ~~~~~~~~~~~
use "`CLEAN_FARMER_SURVEY'/baseline_survey_selected_variables_crop_level.dta", clear

// Merge in the corrected names
merge 1:1 f_id crop using `corrected_names'
drop _merge 


// Merge weather 
merge m:1 f_id using `weather', force
drop _merge

// Merge water
merge 1:1 f_id crop using `water', force
drop _merge

// Merge geological data
merge m:1 f_id using `geo', force
preserve
drop if resp_num == 1
save "`CLEAN_FARMER_SURVEY'/snowball_sample.dta", replace
restore
keep if _merge == 3
drop _merge

// Generate id
gen idm = _n 


//~~~~~~~~~~ Merge the soil quality data ~~~~~~~~~~~~~~
//~~~~~~~~~~ Clean village names at the feeder level ~~~~~~~~~~~~~~

// Replace names
replace village = corrected_village if corrected_village != "None"
replace block = corrected_block if corrected_block != "None"
replace district = corrected_district if corrected_district != "None"

// Number of duplicates
bys sdo_feeder_code village: gen freq = _N

// Create string version of sdo feeder code
tostring sdo_feeder_code, gen(sdo_feeder_code_s)

// List feeders and loop over villages within feeder and calculate the modal village names
// Check which village names are similar to these names and then replace them with the correct village names
// assuming the stringdistance is small enough
gen stringdist = 99999999
gen correct_name = ""
levelsof sdo_feeder_code_s, local(feeders)
foreach feeder_num of local feeders {
	levelsof village if freq > 3 & sdo_feeder_code_s == "`feeder_num'", local(high_freq_names)
	foreach village_name of local high_freq_names {
		ustrdist "`village_name'" village, gen(temp)
		replace correct_name = "`village_name'" if sdo_feeder_code_s == "`feeder_num'" & stringdist > temp
		replace stringdist = temp if sdo_feeder_code_s == "`feeder_num'" & stringdist > temp	 
		drop temp
	}
}

// "Correct" village name if string distance is small enough
replace village = correct_name if stringdist < 4

// Merge soil controls
reclink district block village using `soil', idmaster(idm) idusing(id) gen(match_score) require(district block) minscore(0.6)
sort f_id crop match_score
duplicates drop f_id crop match_score, force



save "`WORKING_DATA'/marginal_analysis_sample_crop_level.dta", replace





