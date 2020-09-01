/*******************************************************************************
Purpose: Creating maps for precipitation data

Author: Viraj Jorapur 

Date: 02 December, 2019
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

// Use the cleaned version of the data
	
	import delimited "`CLEAN_WEATHER_DATA'/weather.csv"
	
// Generating cumulative pre-monsoon rainfall

	egen cumulative_pre_rabi = rowtotal(ppt_2016_7-ppt_2016_10)
	egen cumulative_rabi = rowtotal(ppt_2016_11 ppt_2016_12 ppt_2017_1 ppt_2017_2 ppt_2017_3)
	
	la var cumulative_pre_rabi "Cumulative Pre-Rabi Rainfall (mm)"
	la var cumulative_rabi "Cumulative Rabi Rainfall (mm)"
	
	hist cumulative_pre_rabi, by(sdo) percent fcolor(khaki) ///
	graphregion(color(white)) plotregion(color(white))
	
	//graph export "`FIGURES'/hist_pre_rainfall.pdf", replace
	
	hist cumulative_rabi, by(sdo) percent fcolor(khaki) ///
	graphregion(color(white)) plotregion(color(white))
	
	//graph export "`FIGURES'/hist_rainfall.pdf", replace
	
	
	
// Generating Summary Statistics

// 	eststo clear
// 	estpost tabstat cumulative_pre_rabi,  by(sdo) ///
// 	listwise statistics(mean sd p25 p50 p75 count) columns(statistics) nototal
	
// 	esttab using "`TABLES'/weather/cumulative_pre_rabi.tex", cells("mean(fmt(2)) sd p25 p50 p75 count ") ///
// 	nomtitle title("Cumulative Pre-Rabi Rainfall (mm)") nonumber unstack nogaps label varwidth(36) booktabs noobs replace
	
// 	eststo clear
// 	estpost tabstat cumulative_rabi,  by(sdo) ///
// 	listwise statistics(mean sd p25 p50 p75 count) columns(statistics) nototal
	
// 	esttab using "`TABLES'/weather/cumulative_rabi.tex", cells("mean(fmt(2)) sd p25 p50 p75 count") ///
// 	nomtitle title("Cumulative Rabi Rainfall (mm)") nonumber unstack nogaps label varwidth(36) booktabs noobs replace
	
	
// Generating temperature data

	egen cumulative_pre_rabitmax = rowmean(tmax_2016_7-tmax_2016_10)
	egen cumulative_rabitmax = rowmean(tmax_2016_11 tmax_2016_12 tmax_2017_1 tmax_2017_2 tmax_2017_3)
	
	la var cumulative_pre_rabitmax "Cumulative Pre-Rabi Max Temp (Celsius)"
	la var cumulative_rabitmax "Cumulative Rabi Max Temp (Celsius)"
	
	hist cumulative_pre_rabitmax, by(sdo) percent fcolor(khaki) ///
	graphregion(color(white)) plotregion(color(white))
	
	//graph export "`FIGURES'/hist_pre_tmax.pdf", replace
	
	hist cumulative_rabitmax, by(sdo) percent fcolor(khaki) ///
	graphregion(color(white)) plotregion(color(white))
	
	//graph export "`FIGURES'/hist_tmax.pdf", replace
	
	
// Generating Summary Statistics

	eststo clear
	estpost tabstat cumulative_pre_rabitmax,  by(sdo) ///
	listwise statistics(mean sd p25 p50 p75 count) columns(statistics) nototal
	
	//esttab using "`TABLES'/weather/cumulative_pre_rabitmax.tex", cells("mean(fmt(2)) sd p25 p50 p75 count") ///
	//nomtitle title("Cumulative Pre-Rabi Max Temp (Celsius)") nonumber unstack nogaps label varwidth(36) booktabs noobs replace
	
	eststo clear
	estpost tabstat cumulative_rabitmax,  by(sdo) ///
	listwise statistics(mean sd p25 p50 p75 count) columns(statistics) nototal
	
	//esttab using "`TABLES'/weather/cumulative_rabitmax.tex", cells("mean(fmt(2)) sd p25 p50 p75 count") ///
	//nomtitle title("Cumulative Rabi Max Temp (Celsius)") nonumber unstack nogaps label varwidth(36) booktabs noobs replace
	
// Generating temperature data

	egen cumulative_pre_rabitmin = rowmean(tmin_2016_7-tmin_2016_10)
	egen cumulative_rabitmin = rowmean(tmin_2016_11 tmin_2016_12 tmin_2017_1 tmin_2017_2 tmin_2017_3)
	
	la var cumulative_pre_rabitmin "Cumulative Pre-Rabi Min Temp (Celsius)"
	la var cumulative_rabitmin "Cumulative Rabi Min Temp (Celsius)"
	
	hist cumulative_pre_rabitmin, by(sdo) percent fcolor(khaki) ///
	graphregion(color(white)) plotregion(color(white))
	
	//graph export "`FIGURES'/hist_pre_tmin.pdf", replace
	
	hist cumulative_rabitmin, by(sdo) percent fcolor(khaki) ///
	graphregion(color(white)) plotregion(color(white))
	
	//graph export "`FIGURES'/hist_tmin.pdf", replace
	
	
// Generating Summary Statistics

// 	eststo clear
// 	estpost tabstat cumulative_pre_rabitmin,  by(sdo) ///
// 	listwise statistics(mean sd p25 p50 p75 count) columns(statistics) nototal
	
// 	esttab using "`TABLES'/weather/cumulative_pre_rabitmin.tex", cells("mean(fmt(2)) sd p25 p50 p75 count") ///
// 	nomtitle title("Cumulative Pre-Rabi Min Temp (Celsius)") unstack nogaps label varwidth(36) booktabs nonumber noobs replace
	
// 	eststo clear
// 	estpost tabstat cumulative_rabitmin,  by(sdo) ///
// 	listwise statistics(mean sd p25 p50 p75 count) columns(statistics) nototal
	
// 	esttab using "`TABLES'/weather/cumulative_rabitmin.tex", cells("mean(fmt(2)) sd p25 p50 p75 count") ///
// 	nomtitle title("Cumulative Rabi Min Temp (Celsius)") unstack nogaps label varwidth(36) booktabs nonumber noobs replace
	
	
	export delimited "`CLEAN_WEATHER_DATA'/weather_augmented.csv", replace
	
	
	
