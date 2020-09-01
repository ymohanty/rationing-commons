program paper_prod_func
	syntax varname[if] [in], endog(varlist) ///
	instr(varlist)  controls(varlist) filename(string) ///
	title(string) ref(string) [ weight(varlist) ]
	
	// Estimate OLS, no controls
	_reg_ols `varlist', regressors(`endog') controls(_Isd*) eststo("ols") cluster(f_id)
	
	// Estimate OLS, controls
	_reg_ols `varlist', regressors(`endog') controls(`controls') eststo("ols_controls") cluster(f_id)
	
	// Estimate IV, no controls
	_ivreg `varlist', endog(`endog') ivset(`instr') controls(_Isd*) eststo("iv") cluster(f_id)
	
	// Estimate IV, controls
	_ivreg `varlist', endog(`endog') ivset(`instr') controls(`controls') eststo("iv_controls") cluster(f_id)
	
	// Output -- Paper
	esttab ols ols_controls iv iv_controls using "`filename'_paper.tex", ///
		title(`title'\label{tab:`ref'}) ///
		nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{2SLS}&\multicolumn{1}{c}{2SLS}\\" ///
				 "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				 "\midrule \\") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		alignment(D{.}{.}{-1}) ///
		stats(toposeq soil_indicator SPACE DEPMEAN R_SQ FARMER N, fmt(a2) label("Toposequence" "Soil quality" " " "Mean dep. var" "$\text{Adj. } R^2$" "Farmers" "N")) ///
		prefoot(" ") ///
		label width(1\hsize) nogaps ///
		postfoot("\bottomrule" ///
				 "\multicolumn{5}{p{\hsize}}{\footnotesize This table reports coefficients from regressions of the logarithm of total value of output against the logarithms of inputs to the production function. These inputs consist of water, labour, capital and land. The specification and estimation method used varies by column, as indicated in the column headers. Subdivisional effects, as described in the footnotes of Table \ref{tab:ivProfitsDepth}, are present in every specification. The toposequence includes controls for elevation and slope. Soil quality consists of controls for the acidity/alkalinity of the soil along with variables describing the presence of eight minerals which affect surface productivity. The statistical significance of a coefficient at certain thresholds is indicated by  \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.} \\" ///
				 "\end{tabular*}" ///
				"\end{table}") ///
		drop(`controls' _cons) 
		
	// Output -- Slides
	esttab ols iv using "`filename'_slides.tex", ///
		title(`title'\label{tab:`ref'}) ///
		nomtitles nonumbers ///
		posthead("&\multicolumn{1}{c}{OLS}&\multicolumn{1}{c}{2SLS}\\" ///
				 "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}\\" ///
				 "\midrule \\") ///
		b(a2) se(a2) star(* 0.10 ** 0.05 *** 0.01) margin replace booktabs ///
		alignment(D{.}{.}{-1}) ///
		stats(SPACE DEPMEAN R_SQ FARMER N, fmt(a2) label(" " "Mean dep. var" "$\text{Adj. } R^2$" "Farmers" "N")) ///
		prefoot(" ") ///
		label width(1\hsize) nogaps ///
		postfoot("\bottomrule" ///
				 "\multicolumn{3}{p{\hsize}}{\footnotesize \sym{*} $ p < 0.10$, \sym{**} $ p < 0.05$, \sym{***} $ p < 0.01$.} \\" ///
				 "\end{tabular*}" ///
				"\end{table}") ///
		drop(_Isd* _cons) 
		
end
		 
		
	
	
