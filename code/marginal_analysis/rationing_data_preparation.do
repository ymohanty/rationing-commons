//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//					Marginal Analysis: Data preparation
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cd "`WORKING_DATA'"

tempfile prepped_data

// import delimited baseline_profits_instruments.csv, delimiters(",") asfloat
use marginal_analysis_sample_crop_level, clear

// Drop merge variable
drop _merge

//describe
label data "Farmer profits merged with geological instruments"

destring impu_profit f5_4_1_tot_op_perha f5_4_12_net_profit_perha_wins ///
  f5_4_12_net_profit_perha_w_own elevation slope, replace force
  


lab var f5_4_1_tot_op_perha            "Yield (quintals/ha)"
lab var f5_4_1_tot_prod 				"Output (quintals)"
lab var f5_4_12_net_profit_perha_wins  "Cash profit (Rs/ha)"
lab var f5_4_12_net_profit_perha_w_own "Profit (Rs/Ha, with own consumption)"
lab var farmer_well_depth               "Well depth (feet)"
lab var sdo_price 						"Median price for crop in SDO (Rs)"

// Rename key variables
rename f5_4_1_tot_op_perha             yield
rename f5_4_12_net_profit_perha_wins   profit_cash_wins
rename f5_4_12_net_profit_perha_w_own  profit_cashwown
rename f5_4_1_tot_prod 				   output
rename b2_1_1_hrs_avg				   electric_supply
// rename f5_4_val_not_sold			   val_output_consumed

// Generate profit when household labour is valued at NREGA wage and when household
// labour is valued at zero wage.
gen profit_consumption = profit_cashwown
replace profit_cashwown = impu_profit_per_hectare if missing(profit_cash_wins)

gen profit_cashwown_zero_lab = profit_consumption
gen profit_cashwown_nreg_lab = profit_consumption

replace profit_cashwown_zero_lab = impu_profit_per_hectare_zero_lab if missing(profit_cash_wins)
replace profit_cashwown_nreg_lab = impu_profit_per_hectare_nreg_lab if missing(profit_cash_wins)

// Replace profit with imputed profits if cash profit not reported and value of 
// own consumption is reported. Create new profit + own consumption variable



// Winsorize variables
tempvar newwins
winsor profit_cashwown, generate(profit_cashwown_wins) p(0.01) highonly
winsor yield, generate(yield_wins) p(0.01) highonly
replace yield = yield_wins
winsor profit_cash_wins, generate(`newwins') p(0.01) highonly 
replace profit_cash_wins = `newwins' 
lab var profit_cashwown_wins "Total profit (Rs/ha)"
winsor profit_consumption, generate(profit_consumption_wins) p(0.01) highonly

winsor profit_cashwown_zero_lab, generate(profit_cashwown_zero_lab_wins) p(0.01) highonly
winsor profit_cashwown_nreg_lab, generate(profit_cashwown_nreg_lab_wins) p(0.01) highonly

sum profit_cashwown_zero_lab_wins profit_cashwown_nreg_lab_wins

// Label profit + own consumption
la var profit_consumption_wins "Profit with own consumption (Rs/ha)"


// Relabel  production inputs
gen land = 1/107639*f1_4_3_area_und_crp_sqft
la var land "Land (ha)"
  
gen water = tot_water_crop/1000
la var water "Water ('000 ltr)"

gen capital = capital_cost/1000
la var capital "Capital ('000 INR)"

gen labour = tot_days
la var labour "Labor (worker-days)"

// Generate revenue
gen revenue = sdo_price*output
la var revenue "Total value of output (Rs)"


// la var val_output_sold "Value of output sold"


// Generate revenue per hectare
gen revenue_perha = sdo_price*yield
la var revenue_perha "Total value of output (Rs/ha)"

// Relabel margins of adaptation
gen water_requirement = f1_3_wat_intst
la var water_requirement "Water requirement (mm)"

gen share_value_output_sold = f5_4_9_tot_value_sold/revenue
la var share_value_output_sold "Share of value sold"

la var prop_area_sprinkler "Prop. under sprinker irrigation"

// Generate variables in thousands
gen revenue_t = revenue/1000
la var revenue_t "Total value of output (INR '000s)"

gen revenue_perha_t = revenue_perha/1000
la var revenue_perha_t "Total value of output (INR '000s/ha)"

gen val_output_consumed_t =f5_4_val_not_sold/1000
gen val_output_consumed_perha_t = val_output_consumed_t/land
la var val_output_consumed_perha_t "\hspace{2 em} Value of output consumed"

gen val_output_sold_t = f5_4_9_tot_value_sold/1000
gen val_output_sold_perha_t = val_output_sold_t/land
la var val_output_sold_perha_t "\hspace{2 em} Value of output sold"

gen profit_cash_t = profit_cash_wins/1000
la var profit_cash_t "Cash profit (INR '000s/ha)"

gen profit_total_t = profit_cashwown_wins/1000
la var profit_total_t "Total profit (INR '000s/ha)"

gen profit_total_nrega_wage_t = profit_cashwown_nreg_lab_wins/1000
la var profit_total_nrega_wage_t "\hspace{1 em} Own labor at MNREGA wage"

gen profit_total_zero_wage_t = profit_cashwown_zero_lab_wins/1000
la var profit_total_zero_wage "Total profit, own labor at zero wage (INR '000s/ha)"

gen profit_consumption_t = profit_consumption_wins/1000
la var profit_consumption_t "Profit with own consumption (INR '000s/ha)"


replace elec_exp_sub_irr = elec_exp_sub_irr/1000
la var elec_exp_sub_irr "Electricity (subsidized) ('000 INR)"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//									END
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
