//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*

NAME:     create_farmer_crop.do

PURPOSE:  To Break out the parts of the data that live at the crop level from 
those that live at the farmer level and conduct crop-level cleaning separately

AUTHOR:   Vivek Singh Grewal (modified by Yashaswi Mohanty)

                                                                              */
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// PREAMBLE

if c(mode) == "batch" {
	local PROJECT_ROOT = strrtrim("`0'"	)
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

di "`PROJECT_ROOT'/code/"
include "`PROJECT_ROOT'/code/load_project_globals.do"

local SQFTHA 107639

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Data cleaning

// LOADING RAW DATA IN MEMORY
cd "`RAW_FARMER_SURVEY'"
use "baseline_survey.dta", clear

// Reshaping the data to Farmer X Crop level
drop f1_3_crops_plntd
reshape long f1_3_crops_plntd, ///
 i(f_id) j(crop)
order f_id crop f1_3_crops_plntd
label variable f1_3_crops_plntd "Crop Code set for baseline"
label variable crop "Crop serial number for particular farmer"
destring f1_3_crops_plntd, replace


drop if f1_3_crops_plntd ==.




// Reshaping the data that lives at crop level
// F1. Cropping overview
gen f1_4_1_crop_type = .
gen f1_4_2_crop_variety = .
gen f1_4_2_crp_variety_oth = "."
gen f1_4_10_animals_fed = .
gen f1_4_3_area_und_crp_sqft = .
gen f1_4_4_crp_sow_dt = "."
gen f1_4_5_crp_sow_week = .
gen f1_4_8_crp_hrvst_dt = "."
gen f1_4_9_crp_hrvst_week = .

label variable f1_4_1_crop_type "F1.4.1. What is the type of this crop?"
label variable f1_4_10_animals_fed "F1.4.10. How many livestock do you feed with Rajka? (Number of animals)"
label variable f1_4_2_crop_variety "F1.4.2. What is the variety of this crop?"
label variable f1_4_2_crp_variety_oth "Others Specify"
label variable f1_4_3_area_und_crp_sqft "F1.4.3. What was the total area under this crop? (Units:same as A2.8)"
label variable f1_4_4_crp_sow_dt "F1.4.4. When did you first sow this crop?"
label variable f1_4_5_crp_sow_week "Week of the Month"
label variable f1_4_8_crp_hrvst_dt "F1.4.8. When did you harvest/plan to harvest this crop?"
label variable f1_4_9_crp_hrvst_week "Week of the Month"


forvalues i=1/11 {
replace f1_4_1_crop_type = f1_4_1_crop_type_`i' if crop == `i'
replace f1_4_2_crop_variety = f1_4_2_crop_variety_`i' if crop == `i'
tostring f1_4_2_crp_variety_oth_`i', replace
replace f1_4_2_crp_variety_oth = f1_4_2_crp_variety_oth_`i' if crop == `i'
replace f1_4_10_animals_fed = f1_4_10_animals_fed_`i' if crop == `i'
replace f1_4_3_area_und_crp_sqft = f1_4_3_area_und_crp_`i'_sqft if crop == `i'
replace f1_4_4_crp_sow_dt = f1_4_4_crp_sow_dt_`i' if crop == `i'
replace f1_4_5_crp_sow_week = f1_4_5_crp_sow_week_`i' if crop == `i'
replace f1_4_8_crp_hrvst_dt = f1_4_8_crp_hrvst_dt_`i' if crop == `i'
replace f1_4_9_crp_hrvst_week = f1_4_9_crp_hrvst_week_`i' if crop == `i'
}


// F5.4. Crop Output

gen f5_4_1_tot_prod = .
gen f5_4_2_prod_level_exptn = .
gen f5_4_3_lost_pre_hrvst = .
gen f5_4_4_lost_post_hrvst = .
gen f5_4_5_crop_reimbrs_crdt = .
gen f5_4_6_amt_reimbrs_cred = .
gen f5_4_7_domestic_use = .
gen f5_4_19_selling = .
gen f5_4_8_tot_amt_sold = .
gen f5_4_9_tot_value_sold = .
gen f5_4_10_trnsprt_cost = .
gen f5_4_11_profit_loss = .
gen f5_4_12_tot_profit = .
gen f5_4_13_earn_profit = .
gen f5_4_14_corr_amt_prof = .
gen f5_4_15_tot_loss = .
gen f5_4_16_lost_conf = .
gen f5_4_17_loss_rsn = .
gen f5_4_17_loss_rsn_oth = .
gen f5_4_18_corr_amt_loss = .
gen f5_4_18_corr_amt_loss_11 =. //Correct loss variable for 11th crop is missing; Adding for convenience of running the loop
replace f5_4_19_selling= .

label variable f5_4_1_tot_prod "F5.4.1.What was the total production of this crop in this season?"
label variable f5_4_2_prod_level_exptn "F5.4.2.Was this production level above or below the expected level?"
label variable f5_4_3_lost_pre_hrvst "F5.4.3.How much of this crop was lost to rotting/insects/rodents before harvestin"
label variable f5_4_4_lost_post_hrvst "F5.4.4.How much of this crop was lost to rotting/insects/rodents after harvesting"
label variable f5_4_5_crop_reimbrs_crdt "F5.4.5.Did you give any part of this crop to reimburse for any credit you took"
label variable f5_4_6_amt_reimbrs_cred "F5.4.6.How much crop did you give as reimbursement for credit?"
label variable f5_4_7_domestic_use "F5.4.7. How much of this crop did you keep for domestic use?"
label variable f5_4_19_selling "F5.4.19 How much of this crop have you stored for selling in future?"
label variable f5_4_8_tot_amt_sold "F5.4.8.What was the total amount of this crop sold?"
label variable f5_4_9_tot_value_sold "F5.4.9.What was the total value of the crop sold?"	
label variable f5_4_10_trnsprt_cost "F5.4.10.How much total did it cost to transport all of this crop in Rabi - 2017"
label variable f5_4_11_profit_loss "F5.4.11.Would you say this crop earned money (Profit) or lost money (Loss) in this season?"
label variable f5_4_12_tot_profit "F5.4.12.In your estimate what was the total profit you made on this crop in this season"
label variable f5_4_13_earn_profit "F5.4.13.You said you earned profit of value mentioned in F5.4.12, is it correct?"
label variable f5_4_14_corr_amt_prof "F5.4.14.What was the correct amount of profit you earned on this crop?"
label variable f5_4_15_tot_loss "F5.4.15.In your estimate,what was the total amount of money you lost on this crop"
label variable f5_4_16_lost_conf "F5.4.16.You said you lost money of value mentioned in F5.4.15,is this correct"
label variable f5_4_17_loss_rsn "F5.4.17.What was the reason for this high loss?"
label variable f5_4_17_loss_rsn_oth "Others Specify"
label variable f5_4_18_corr_amt_loss "F5.4.18.What was the correct amount of money you lost on this crop?"
label variable f5_4_19_selling "F5.4.19.How much crop have you stored for selling in the future?"


forvalues i=1/11 {
	replace f5_4_1_tot_prod = f5_4_1_tot_prod_`i' if crop == `i'
	replace f5_4_2_prod_level_exptn = f5_4_2_prod_level_exptn_`i' if crop == `i'
	replace f5_4_3_lost_pre_hrvst = f5_4_3_lost_pre_hrvst_`i' if crop == `i'
	replace f5_4_4_lost_post_hrvst = f5_4_4_lost_post_hrvst_`i' if crop == `i'
	replace f5_4_5_crop_reimbrs_crdt = f5_4_5_crop_reimbrs_crdt_`i' if crop == `i'
	replace f5_4_6_amt_reimbrs_cred = f5_4_6_amt_reimbrs_cred_`i' if crop == `i'
	replace f5_4_7_domestic_use = f5_4_7_domestic_use_`i' if crop == `i'
	replace f5_4_19_selling = f5_4_19_selling_`i' if crop == `i'
	replace f5_4_8_tot_amt_sold = f5_4_8_tot_amt_sold_`i' if crop == `i'
	replace f5_4_9_tot_value_sold = f5_4_9_tot_value_sold_`i' if crop == `i'
	replace f5_4_10_trnsprt_cost = f5_4_10_trnsprt_cost_`i' if crop == `i'
	replace f5_4_11_profit_loss = f5_4_11_profit_loss_`i' if crop == `i'
	replace f5_4_12_tot_profit = f5_4_12_tot_profit_`i' if crop == `i'
	replace f5_4_13_earn_profit = f5_4_13_earn_profit_`i' if crop == `i'
	replace f5_4_14_corr_amt_prof = f5_4_14_corr_amt_prof_`i' if crop == `i'
	replace f5_4_15_tot_loss = f5_4_15_tot_loss_`i' if crop == `i'
	replace f5_4_16_lost_conf = f5_4_16_lost_conf_`i' if crop == `i'
	replace f5_4_17_loss_rsn = f5_4_17_loss_rsn_`i' if crop == `i'
	replace f5_4_17_loss_rsn_oth = f5_4_17_loss_rsn_oth_`i' if crop == `i'
	replace f5_4_18_corr_amt_loss = f5_4_18_corr_amt_loss_`i' if crop == `i'
	replace f5_4_19_selling = f5_4_19_selling_`i' if crop == `i'
}

// Generate winsorized profit
tempvar topcode
bys f1_3_crops_plntd: egen `topcode' = pctile(f5_4_12_tot_profit), p(99)
gen f5_4_12_tot_profit_wins = min(f5_4_12_tot_profit, `topcode') if !missing(f5_4_12_tot_profit)
la var f5_4_12_tot_profit_wins "Total profit on crop (winsorized) (Rs)"
gen f5_4_12_tot_profit_perha_wins = f5_4_12_tot_profit_wins/(f1_4_3_area_und_crp_sqft/`SQFTHA')
drop `topcode'


// Generate winsorized loss
bys f1_3_crops_plntd: egen `topcode'= pctile(f5_4_15_tot_loss), p(99)
gen f5_4_15_tot_loss_wins = min(f5_4_15_tot_loss, `topcode') if !missing(f5_4_15_tot_loss)
la var f5_4_15_tot_loss_wins "Total loss on crop (winsorized) (Rs) "
gen f5_4_15_tot_loss_perha_wins = f5_4_15_tot_loss_wins/(f1_4_3_area_und_crp_sqft/`SQFTHA')
drop `topcode'

// Generate net cash profit 
tempvar neg
gen `neg' = -f5_4_15_tot_loss_wins
egen f5_4_12_net_profit_wins = rowtotal(f5_4_12_tot_profit_wins `neg'), missing
drop `neg'

// Generate net cash profit per hectare
gen `neg' = -f5_4_15_tot_loss_perha_wins
egen f5_4_12_net_profit_perha_wins = rowtotal(f5_4_12_tot_profit_perha_wins `neg'), missing
la var f5_4_12_net_profit_perha_wins "Net profit per hectare (winsorized) (Rs)"
drop `neg'

// Generate net cash profit including own consumption
//* Amount not sold
egen f5_4_amt_not_sold = rowtotal(f5_4_7_domestic_use f5_4_19_selling), missing

//* Price of sale
gen f5_4_crop_price = f5_4_9_tot_value_sold/f5_4_8_tot_amt_sold

//* Value of not sold items using median SDO price 
//** Generate sdo code
destring sdo_feeder_code, generate(sdo_feeder_num) force
gen sdo_num = floor(sdo_feeder_num/100)
label var sdo_num "SDO number (1-6)"

//** Calculate SDO x Crop prices
bys sdo_num f1_3_crops_plntd: egen sdo_price = median(f5_4_crop_price)

//** Value not sold
gen f5_4_val_not_sold = f5_4_amt_not_sold * sdo_price
label var f5_4_val_not_sold "Value of crop not sold (Rs)"

bys f1_3_crops_plntd: egen `topcode' = pctile(f5_4_val_not_sold), p(99)
gen f5_4_val_not_sold_wins = min(f5_4_val_not_sold,`topcode') if !missing(f5_4_val_not_sold)
label var f5_4_val_not_sold_wins "Value of crop not sold (winsorized) (Rs)"
drop `topcode'

gen f5_4_val_not_sold_perha = f5_4_val_not_sold / (f1_4_3_area_und_crp_sqft/`SQFTHA')
label var f5_4_val_not_sold_perha "Value of crop not sold per hectare (Rs/Ha)"

gen f5_4_val_not_sold_perha_wins = f5_4_val_not_sold_wins / (f1_4_3_area_und_crp_sqft/`SQFTHA')
label var f5_4_val_not_sold_perha_wins "Value of crop not sold per hectare (winsorized) (Rs/Ha)"

// * Own consumption profit per hectare
egen f5_4_12_net_profit_w_own = rowtotal(f5_4_12_net_profit_wins f5_4_val_not_sold_wins), missing
label var f5_4_12_net_profit_w_own "Profit, with own consumption (Rs)"

egen f5_4_12_net_profit_perha_w_own = rowtotal(f5_4_12_net_profit_perha_wins f5_4_val_not_sold_perha_wins), missing
label var f5_4_12_net_profit_perha_w_own "Profit, with own consumption (Rs/Ha)"

// Generate yield per hectare
gen f5_4_1_tot_op_perha = f5_4_1_tot_prod/(f1_4_3_area_und_crp_sqft/`SQFTHA')
la var f5_4_1_tot_op_perha "Yield (Quintals/Ha)"



// F5.1. Crop Inputs: Irrigation

gen f5_1_1_irrigate_crop = .
gen f5_1_2_est_wtr_amt = .
gen f5_1_2_est_wtr_amt_oth = "."
gen f5_1_4_avg_irr = .
gen f5_1_5_parcel_crop = "."
gen f5_1_5_parcel_crop_crp_count = .
gen f5_1_6_5_irr_tech_pcl_fld = .
gen f5_1_6_5_irr_tech_pcl_frw = .
gen f5_1_6_5_irr_tech_pcl_brst = .
gen f5_1_6_5_irr_tech_pcl_spr = .
gen f5_1_6_5_irr_tech_pcl_drip = .
gen f5_1_6_5_irr_tech_pcl_otr = .


forvalues j=1/15 {
gen f5_1_6_9_area_crp_pcl`j'_sqft = .
}

forvalues j=1/15 {
gen f5_1_6_1_irriga_area_pcl`j'_sqft = .
}

forvalues j=1/15 {
gen f5_1_6_8_irr_cnt_presow_pcl`j' = .
}

forvalues j=1/15 {
gen f5_1_6_2_irr_cnt_crp_pcl`j' = .
}

forvalues j=1/15 {
gen f5_1_6_3_irr_frq_pcl`j' = .
}

forvalues j=1/15 {
gen f5_1_6_4_irr_adqcy_pcl`j' = .
}

forvalues j=1/15 {
gen f5_1_6_5_irr_tech_pcl_fld`j' = .
}

forvalues j=1/15 {
gen f5_1_6_5_irr_tech_pcl_frw`j' = .
}

forvalues j=1/15 {
gen f5_1_6_5_irr_tech_pcl_brst`j' = .
}

forvalues j=1/15 {
gen f5_1_6_5_irr_tech_pcl_spr`j' = .
}

forvalues j=1/15 {
gen f5_1_6_5_irr_tech_pcl_drip`j' = .
}

forvalues j=1/15 {
gen f5_1_6_5_irr_tech_pcl_otr`j' = .
}


forvalues j=1/15 {
gen f5_1_6_5_irr_tech_oth_pcl`j' = "."
}


forvalues j=1/15 {
gen byte f5_1_6_7_level_pcl`j' = .
}


label variable f5_1_1_irrigate_crop "F5.1.1 Did you irrigate this crop?"
label variable f5_1_2_est_wtr_amt "F5.1.2.How do you estimate how much water to give to this crop in each irrigation"
label variable f5_1_2_est_wtr_amt_oth "Others Specify"
label variable f5_1_4_avg_irr "F5.1.4.By estimate method you mentioned how much did you irrigate this crop"
label variable f5_1_5_parcel_crop "F5.1.5 Which of these parcels did you grow this crop on? (Tick all that apply)"
label variable f5_1_6_5_irr_tech_pcl_fld "No of parcels in which flood irrigation was used to irrigate this crop"
label variable f5_1_6_5_irr_tech_pcl_frw "No of parcels in which furrow irrigation was used to irrigate this crop"
label variable f5_1_6_5_irr_tech_pcl_brst "No of parcels in which border strip irrigation was used to irrigate this crop"
label variable f5_1_6_5_irr_tech_pcl_spr "No of parcels in which sprinkler irrigation was used to irrigate this crop"
label variable f5_1_6_5_irr_tech_pcl_drip "No of parcels in which drip irrigation was used to irrigate this crop"
label variable f5_1_6_5_irr_tech_pcl_otr "No of parcels in which other irrigation techniques were used to irrigate this crop"

forvalues x=1/15 {
label variable f5_1_6_9_area_crp_pcl`x'_sqft "F5.1.6.9.How much area did you plant of this crop in this parcel?"
label variable f5_1_6_1_irriga_area_pcl`x'_sqft "F5.1.6.1. How much area did you irrigate of this crop in this parcel?"
label variable f5_1_6_8_irr_cnt_presow_pcl`x' "F5.1.6.8 How many times did you irrigate this parcel before sowing this crop?"
label variable f5_1_6_2_irr_cnt_crp_pcl`x' "F5.1.6.2. How many times did you irrigate this crop in this parcel?"
label variable f5_1_6_3_irr_frq_pcl`x' "F5.1.6.3.How often did you irrigate this this crop in parcel `x'"
label variable f5_1_6_4_irr_adqcy_pcl`x' "F5.1.6.4. Was this crop under-irrigated, adequately irrigated or over-irrigated?"
label variable f5_1_6_5_irr_tech_pcl_fld`x' "F5.1.6.5 Did you use flood irrigation to irrigate this crop in parcel `x'"
label variable f5_1_6_5_irr_tech_pcl_frw`x' "F5.1.6.5 Did you use furrow irrigation to irrigate this crop in parcel `x'"
label variable f5_1_6_5_irr_tech_pcl_brst`x' "F5.1.6.5 Did you use border strip irrigation to irrigate this crop in parcel `x'"
label variable f5_1_6_5_irr_tech_pcl_spr`x' "F5.1.6.5 Did you use sprinkler irrigation to irrigate this crop in parcel `x'"
label variable f5_1_6_5_irr_tech_pcl_drip`x' "F5.1.6.5 Did you use drip irrigation to irrigate this crop in parcel `x'"
label variable f5_1_6_5_irr_tech_pcl_otr`x' "F5.1.6.5 Did you use any other irrigation technique to irrigate this crop in parcel `x'"
label variable f5_1_6_5_irr_tech_oth_pcl`x' "F5.1.6.5 Which other techinique did you use to irrigate this crop in parcel `x'"
label variable f5_1_6_7_level_pcl`x' "F5.1.6.7. Did you level parcel `x' before planting this crop?"
}


forvalues i=8/11{ //crop 8 to 11 do not have parcels 10 to 15; generating variables for ease of loops
forvalues j=10/15{

gen f5_1_6_1_irr_area_pcl`j'_`i'_sqft =.
gen f5_1_6_9_area_crp_pcl`j'_`i'_sqft =.
gen f5_1_6_8_irr_cnt_presow_pcl`j'_`i' =.
gen f5_1_6_2_irr_cnt_crp_pcl`j'_`i' =.
gen f5_1_6_3_irr_frq_pcl`j'_`i' =.
gen f5_1_6_4_irr_adqcy_pcl`j'_`i' =.
gen f5_1_6_5_irr_tech_pcl_fld_`j'_`i' =.
gen f5_1_6_5_irr_tech_pcl_frw_`j'_`i' =.
gen f5_1_6_5_irr_tech_pcl_brst_`j'_`i' =.
gen f5_1_6_5_irr_tech_pcl_spr_`j'_`i' =.
gen f5_1_6_5_irr_tech_pcl_drip_`j'_`i' =.
gen f5_1_6_5_irr_tech_pcl_otr_`j'_`i' =.
gen byte f5_1_6_7_level_pcl`j'_`i' =.
gen f5_1_6_5_irr_tech_oth_pcl`j'_`i' ="."

}
}



forvalues i=1/11 {
replace f5_1_1_irrigate_crop = f5_1_1_irrigate_crop_`i' if crop == `i'
replace f5_1_2_est_wtr_amt = f5_1_2_est_wtr_amt_`i' if crop == `i'
tostring f5_1_2_est_wtr_amt_oth_`i', replace
replace f5_1_2_est_wtr_amt_oth = f5_1_2_est_wtr_amt_oth_`i' if crop == `i'
replace f5_1_4_avg_irr = f5_1_4_avg_irr_`i' if crop == `i'
replace f5_1_5_parcel_crop = f5_1_5_parcel_crop_`i' if crop == `i'
replace f5_1_5_parcel_crop_crp_count = f5_1_5_parcel_crop_`i'_crp_count if ///
crop == `i'
replace f5_1_6_5_irr_tech_pcl_fld = f5_1_6_5_irr_tech_pcl_fld_`i' if crop == `i'
replace f5_1_6_5_irr_tech_pcl_frw = f5_1_6_5_irr_tech_pcl_frw_`i' if crop == `i'
replace f5_1_6_5_irr_tech_pcl_brst = f5_1_6_5_irr_tech_pcl_brst_`i' if crop == `i'
replace f5_1_6_5_irr_tech_pcl_spr = f5_1_6_5_irr_tech_pcl_spr_`i' if crop == `i'
replace f5_1_6_5_irr_tech_pcl_drip = f5_1_6_5_irr_tech_pcl_drip_`i' if crop == `i'
replace f5_1_6_5_irr_tech_pcl_otr = f5_1_6_5_irr_tech_pcl_otr_`i' if crop == `i'




forvalues j=1/15 {
replace f5_1_6_9_area_crp_pcl`j'_sqft = f5_1_6_9_area_crp_pcl`j'_`i'_sqft ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_1_irriga_area_pcl`j'_sqft = f5_1_6_1_irr_area_pcl`j'_`i'_sqft ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_8_irr_cnt_presow_pcl`j' = f5_1_6_8_irr_cnt_presow_pcl`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_2_irr_cnt_crp_pcl`j' = f5_1_6_2_irr_cnt_crp_pcl`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_3_irr_frq_pcl`j' = f5_1_6_3_irr_frq_pcl`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_4_irr_adqcy_pcl`j' = f5_1_6_4_irr_adqcy_pcl`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_5_irr_tech_pcl_fld`j' = f5_1_6_5_irr_tech_pcl_fld_`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_5_irr_tech_pcl_frw`j' = f5_1_6_5_irr_tech_pcl_frw_`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_5_irr_tech_pcl_brst`j' = f5_1_6_5_irr_tech_pcl_brst_`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_5_irr_tech_pcl_spr`j' = f5_1_6_5_irr_tech_pcl_spr_`j'_`i' ///
 if crop == `i'
 }
 
 forvalues j=1/15 {
replace f5_1_6_5_irr_tech_pcl_drip`j' = f5_1_6_5_irr_tech_pcl_drip_`j'_`i' ///
 if crop == `i'
}

forvalues j=1/15 {
replace f5_1_6_5_irr_tech_pcl_otr`j' = f5_1_6_5_irr_tech_pcl_otr_`j'_`i' ///
 if crop == `i'
 }
 
forvalues j=1/15 {
replace f5_1_6_5_irr_tech_oth_pcl`j' = f5_1_6_5_irr_tech_oth_pcl`j'_`i' ///
 if crop == `i'
 }
 
 forvalues j=1/15 {
replace f5_1_6_7_level_pcl`j' = f5_1_6_7_level_pcl`j'_`i' ///
 if crop == `i'
 }

}



// "F5.2: Crop inputs: Seeds and Fertilizers

gen f5_2_1_home_prod_seed = .
gen f5_2_2_purchase_seed = .
gen f5_2_3_seed_price = .
gen f5_2_4_purch_cred = .
gen f5_2_5_amt_purch_cred = .
gen f5_2_6_bio_fertilizer = .
gen f5_2_7_bio_fer_purch = .
gen f5_2_8_bio_fert_price = .
gen f5_2_9_bio_fert_cred = .
gen f5_2_10_amt_bio_purch_cred = .
gen f5_2_11_chem_fert_purch = .
gen f5_2_12_chem_fert_ttl_cst = .
gen f5_2_13_chem_fert_cred = .
gen f5_2_14_amt_chem_fert_cred = .
gen f5_2_16_pestcd_tot_cost = .
gen f5_2_17_pestici_cred = .
gen f5_2_18_pestcd_cred_val = .

label variable f5_2_1_home_prod_seed "F5.2.1How much home-produced seed/sapling did you use home-producefor crop"
label variable f5_2_2_purchase_seed "F5.2.2. How much seed/sapling did you purchase? (KG)"
label variable f5_2_3_seed_price "F5.2.3. What was the rate of one KG of seeds/saplings that you purchased?"
label variable f5_2_4_purch_cred "F5.2.4. Did you purchase some of all of this seed on credit?"
label variable f5_2_5_amt_purch_cred "F5.2.5. How much seed/sapling did you purchase on credit? (KG)"
label variable f5_2_6_bio_fertilizer "F5.2.6How much home-produced Bio-fertilizer did you use for this crop?(no of trolleys)"
label variable f5_2_7_bio_fer_purch "F5.2.7. How much bio-fertilizer did you purchase? (number of trolleys)"
label variable f5_2_8_bio_fert_price "F5.2.8.What was the rate of one trolley of bio-fertilizer you purchased? (Rs)"
label variable f5_2_9_bio_fert_cred "F5.2.9. Did you purchase some of all of this bio-fertilizer on credit?"
label variable f5_2_10_amt_bio_purch_cred "F5.2.10. How much bio-fertilizer did you purchase on credit? (number of trolleys"
label variable f5_2_11_chem_fert_purch "F5.2.11. How much chemical fertilizer did you purchase? (KG)"
label variable f5_2_12_chem_fert_ttl_cst "F5.2.12. What was the total cost of chemical fertlizer you purchased? (Rs)"
label variable f5_2_13_chem_fert_cred "F5.2.13. Did you purchase some or all of this chemical fertilizer on credit?"
label variable f5_2_14_amt_chem_fert_cred "F5.2.14. How much chemical fertilizer did you purchase with credit? (KG)"
label variable f5_2_16_pestcd_tot_cost "F5.2.16. What was the total cost of pesticides that you purchased? (Rs)"
label variable f5_2_17_pestici_cred "F5.2.17. Did you purchase some of all of the pesticides on credit?"
label variable f5_2_18_pestcd_cred_val "F5.2.18. What was the value of pesticides purchased with credit? (Rupees)"



forvalues i=1/11 {
replace f5_2_1_home_prod_seed = f5_2_1_home_prod_seed_`i' if crop == `i'
replace f5_2_2_purchase_seed = f5_2_2_purchase_seed_`i' if crop == `i'
replace f5_2_3_seed_price = f5_2_3_seed_price_`i' if crop == `i'
replace f5_2_4_purch_cred = f5_2_4_purch_cred_`i' if crop == `i'
replace f5_2_5_amt_purch_cred = f5_2_5_amt_purch_cred_`i' if crop == `i'
replace f5_2_6_bio_fertilizer = f5_2_6_bio_fertilizer_`i' if crop == `i'
replace f5_2_7_bio_fer_purch = f5_2_7_bio_fer_purch_`i' if crop == `i'
replace f5_2_8_bio_fert_price = f5_2_8_bio_fert_price_`i' if crop == `i'
replace f5_2_9_bio_fert_cred = f5_2_9_bio_fert_cred_`i' if crop == `i'
replace f5_2_10_amt_bio_purch_cred = f5_2_10_amt_bio_purch_cred_`i' if crop == `i'
replace f5_2_11_chem_fert_purch = f5_2_11_chem_fert_purch_`i' if crop == `i'
replace f5_2_12_chem_fert_ttl_cst = f5_2_12_chem_fert_ttl_cst_`i' if crop == `i'
replace f5_2_13_chem_fert_cred = f5_2_13_chem_fert_cred_`i' if crop == `i'
replace f5_2_14_amt_chem_fert_cred = f5_2_14_amt_chem_fert_cred_`i' if crop == `i'
replace f5_2_16_pestcd_tot_cost = f5_2_16_pestcd_tot_cost_`i' if crop == `i'
replace f5_2_17_pestici_cred = f5_2_17_pestici_cred_`i' if crop == `i'
replace f5_2_18_pestcd_cred_val = f5_2_18_pestcd_cred_val_`i' if crop == `i'

}


// F5.3: Crop Inputs: Labour

gen f5_3_1_hh_lab_sow = .
gen f5_3_1_hh_lab_days = .
gen f5_3_3_wage_lab_sow = .
gen f5_3_3_wage_lab_days = .
gen f5_3_4_avg_wage_sow = .
gen f5_3_5_hh_lab_irr = .
gen f5_3_5_hh_lab_days = .
gen f5_3_7_wage_lab_irr = .
gen f5_3_7_wage_lab_days = .
gen f5_3_8_avg_wage_irr = .
gen f5_3_9_hh_lab_hrvst = .
gen f5_3_9_hh_lab_days = .
gen f5_3_11_wage_lab_hrvst = .
gen f5_3_11_wage_lab_days = .
gen f5_3_12_avg_wage_hrvst = .

label variable f5_3_1_hh_lab_sow "How many number of workers from household were used for Land preparation and sowing?"
label variable f5_3_1_hh_lab_days "F5.3.1 For how many number of days were they used?"
label variable f5_3_3_wage_lab_sow "F5.3.3How many number of wage workers were used for Land preparation and sowing?"
label variable f5_3_3_wage_lab_days "F5.3.3 For how many number of days were they used?"
label variable f5_3_4_avg_wage_sow "F5.3.4What was the average wage per day of wage labour for land preparation & sowing"
label variable f5_3_5_hh_lab_irr "F5.3.5 How much Household labour was used for Irrigation?"
label variable f5_3_5_hh_lab_days "F5.3.5 For how many number of days were they used?"
label variable f5_3_7_wage_lab_irr "F5.3.7 How much wage labour was used for Irrigation?"
label variable f5_3_7_wage_lab_days "F5.3.7 For how many number of days were they used?"
label variable f5_3_8_avg_wage_irr "F5.3.8. What was the average wage per day of wage labour for Irrigation?"
label variable f5_3_9_hh_lab_hrvst "F5.3.9 How much Household labour was used for harvesting?"
label variable f5_3_9_hh_lab_days "F5.3.9 For how many number of days were they used?"
label variable f5_3_11_wage_lab_hrvst  "F5.3.11 How much wage labour was used for harvesting?"
label variable f5_3_11_wage_lab_days "F5.3.11 For how many number of days were they used?"
label variable f5_3_12_avg_wage_hrvst "F5.3.12. What was the average wage per day of wage labour for Harvesting?"



forvalues i=1/11 {
replace f5_3_1_hh_lab_sow = f5_3_1_hh_lab_sow_`i' if crop == `i'
replace f5_3_1_hh_lab_days = f5_3_1_hh_lab_days_`i' if crop == `i'
replace f5_3_3_wage_lab_sow = f5_3_3_wage_lab_sow_`i' if crop == `i'
replace f5_3_3_wage_lab_days = f5_3_3_wage_lab_days_`i' if crop == `i'
replace f5_3_4_avg_wage_sow = f5_3_4_avg_wage_sow_`i' if crop == `i'
replace f5_3_5_hh_lab_irr = f5_3_5_hh_lab_irr_`i' if crop == `i'
replace f5_3_5_hh_lab_days = f5_3_5_hh_lab_days_`i' if crop == `i'
replace f5_3_7_wage_lab_irr = f5_3_7_wage_lab_irr_`i' if crop == `i'
replace f5_3_7_wage_lab_days = f5_3_7_wage_lab_days_`i' if crop == `i'
replace f5_3_8_avg_wage_irr = f5_3_8_avg_wage_irr_`i' if crop == `i'
replace f5_3_9_hh_lab_hrvst = f5_3_9_hh_lab_hrvst_`i' if crop == `i'
replace f5_3_9_hh_lab_days = f5_3_9_hh_lab_days_`i' if crop == `i'
replace f5_3_11_wage_lab_hrvst = f5_3_11_wage_lab_hrvst_`i' if crop == `i'
replace f5_3_11_wage_lab_days = f5_3_11_wage_lab_days_`i' if crop == `i'
replace f5_3_12_avg_wage_hrvst = f5_3_12_avg_wage_hrvst_`i' if crop == `i'

}

// F6. Farm Machinery Usage

gen f6_1_1_hrs_use_crp_trctr = .
gen f6_1_1_hrs_use_crp_hvstr = .
gen f6_1_1_hrs_use_crp_trshr = .

label variable f6_1_1_hrs_use_crp_trctr "F6.2.1 How many hrs did you use tractor on crop `x'"
label variable f6_1_1_hrs_use_crp_hvstr "F6.2.1 How many hrs did you use harvester on crop `x'"
label variable f6_1_1_hrs_use_crp_trshr "F6.2.1 How many hrs did you use thresher on crop `x'"


forvalues i=1/11 {
replace f6_1_1_hrs_use_crp_trctr = f6_1_1_hrs_use_crp`i'_1 if crop == `i'
replace f6_1_1_hrs_use_crp_hvstr = f6_1_1_hrs_use_crp`i'_2 if crop == `i'
replace f6_1_1_hrs_use_crp_trshr = f6_1_1_hrs_use_crp`i'_3 if crop == `i'

}

*Saving data
save "`CLEAN_FARMER_SURVEY'/baseline_survey_farmer_crop_level.dta", replace
//log close




