*! Unreleased/Untagged beta Yashaswi Mohanty 8aug2019
*! Stata 15.0 and later
program define mean_between, nclass byable(onecall) sortpreserve
		syntax varname [ if ] [ in ], ///
		[GENerate(string)|replace] ///
		[ BY(varlist) ] ///
		[ sort_by(varlist) ]
			
			
			// Handle by error
			if _by() & "`by'" != "" {
				di as err /*
					*/ "option by() may not be combined with by prefix"
				exit 190
			}
			
			// Handle gen error
			if "`generate'" != "" & "`replace'" != "" {
                di as err "options generate and replace are mutually exclusive"
                exit 198
			}

			if "`generate'" == "" & "`replace'" == "" {
                di as err "must specify either generate or replace option"
                exit 198
			}
			
			
			// Get 'by' variable
			if _by() {
				local by = "`_byvars'"
			}
		
 			sort `by' `sort_by'
			local y `varlist'

 			tempvar nexty prevy
				
			// Values before
			bys `by': gen double `prevy' = `y'[_n-1] 
			
			// Values after
			bys `by': gen double `nexty' = `y'[_n+1]
			
 			// Handle if the surrounding values are missing
			bys `by': replace `prevy' = `prevy'[_n-1] if `prevy' >= .
			bys `by': replace `nexty' = `nexty'[_n+1] if `nexty' >= .
			
			if "`generate'" != "" {	
				egen `generate' = rowtotal(`prevy' `nexty') 
				replace `generate' = max(min(`prevy',`nexty' ),`generate'/2)
				replace `generate' = . if `generate' == 0
			}
			else {
				tempvar imputed
				egen `imputed' = rowtotal(`prevy' `nexty')
				replace `imputed' = max(min(`prevy',`nexty' ),`imputed'/2)
				replace `imputed' = . if `imputed' == 0
				replace `y' = `imputed' `if'
				// bys `by': replace `y' = (`prevy' + `nexty')/2 `if'
			}
		
		
end
