*! Y. MOHANTY 3/2020: PROGRAM TO ESTIMATE SPATIAL CORRELATION ADJUSTED VCOV FOR IVPDS REGRESSION
* Adapted from S. HSIANG
program ivpds_spatial, eclass byable(recall)
version 15
syntax varname [if] [in], ///
	exog(varlist) endog(varlist) ivset(varlist) ///
 	lat(varname) long(varname)  ///
 	lcluster(varname) ivcluster(varname) [ cutoff(real 1) ]


	
/*--------FIRST DO IV-PDS, STORE RESULTS-------*/

display as txt "FIRST: ESTIMATE IV-PDS"

quietly: ivlasso `varlist' (`exog') (`endog' = `ivset'), loptions(cluster(`lcluster')) ivoptions(cluster(`ivcluster')) post(pds) partial(`exog') noconstant
local touse e(sample)
gen touse = `touse'

//generating a function of the included obs
quietly count if `touse'		
scalar n = r(N)					// # obs
scalar n_obs = r(N)


estimates store IV_PDS

local Y "`varlist'"
local X "`endog' `exog'"
local Z "`e(zselected)' `exog'"


// Count number of elements in each local ( L instruments, K regressors)
scalar k = 0
foreach i of loc X {
	scalar k = k + 1
}

scalar l = 0
foreach i of loc Z {
	scalar l = l +1
}



/*--------SECOND, IMPORT ALL VALUES INTO MATA-------*/
display as txt "SECOND: IMPORT VALUES INTO MATA"

mata {
	
	Y_var = st_local("Y") //importing variable assignments to mata
	X_var = st_local("X")
	Z_var = st_local("Z")
	lat_var = st_local("lat")
	lon_var = st_local("long")
	
	//NOTE: values are all imported as "views" instead of being copied and pasted as Mata data because it is faster, however none of the matrices are changed in any way, so it should not permanently affect the data. 

	st_view(Y=.,.,tokens(Y_var),"touse") //importing variables vectors to mata
	st_view(X=.,.,tokens(X_var),"touse")
	st_view(Z=.,.,tokens(Z_var),"touse")
	st_view(lat=.,.,tokens(lat_var),"touse")
	st_view(lon=.,.,tokens(lon_var),"touse")
	
	k = st_numscalar("k")
	l = st_numscalar("l")
	n = st_numscalar("n")
	b = st_matrix("e(b)")				// (estimated coefficients, row vector)
	dist_var = st_local("cutoff")
	dist_cutoff = strtoreal(dist_var)
	
	cutoff_matrix = J(n, n, 0)
	
/*--------THIRD, CORRECT VCE FOR SPATIAL CORR-------*/

	for (i = 1; i <= n; i++){
		for (j = 1; j <= n; j++){
			//----------------------------------------------------------------
			// step a: get non-parametric weight
	
			//This is a Euclidean distance scale IN KILOMETERS specific to i
        
			lon_scale = cos(lat[i,1]*pi()/180)*111 
			lat_scale = 111
			
			// Distance scales lat and lon degrees differently depending on
			// latitude.  The distance here assumes a distortion of Euclidean
			// space around the location of 'i' that is approximately correct for 
			// displacements around the location of 'i'
			//
			//	Note: 	1 deg lat = 111 km
			// 			1 deg lon = 111 km * cos(lat)
		
			dist = ((lat_scale*(lat[i,1]:-lat[j,1])):^2 + /// 	
						(lon_scale*(lon[j,1]:-lon[j,1])):^2):^0.5
			
			if (dist <= dist_cutoff) {
				cutoff_matrix[i,j] = 1
			}
			
		}
	}
	
	// Vector of residuals
	resid = Y - X*b'
	
	// Outer product of residuals
	outer_product = resid*resid'
	
	// Outer product of residuals with cross moments zeroed out if dist > cutoff
	e1 = outer_product:*cutoff_matrix

	
	ZeeZ = Z'*e1*Z
	
	ZeeZ_spatial = luinv ( ZeeZ / n)
	
	XZ = X'*Z / n
	
	V = luinv ( XZ * ZeeZ_spatial * XZ' ) / n
	
	
	// Ensures that the matrix is symmetric 
	// in theory, it should be already, but it may not be due to rounding errors for large datasets
	V = (V+V')/2 

	st_matrix("V_spatial", V)
	st_matrix("e1",e1)
	st_matrix("cutoff_matrix",cutoff_matrix)

} // mata

	
display as txt "THIRD: ESTIMATE VCOV"
//------------------------------------------------------------------
//storing results
matrix beta = e(b)

// the row and column names of the new VCE must match the vector b

matrix colnames V_spatial = `X'
matrix rownames V_spatial = `X'

// The correlation and distance functions
mata: e1 = colshape(st_matrix("e1"),1)
mata: cutoff_matrix = colshape(st_matrix("cutoff_matrix"),1)
mata: st_matrix("e1",e1)
mata: st_matrix("cutoff_matrix",cutoff_matrix)

matrix autocorr = e1, cutoff_matrix
matrix colnames autocorr = correlation dist 

preserve

svmat autocorr

drop if correlation == 0
lpoly correlation dist
graph export "Users/ymohanty/Dropbox/dist_correlation.pdf", replace

restore



// post new vcov matrix for postestimation

ereturn repost V = V_spatial, esample(touse)
disp as txt "STD. ERRORS UNDER IVPDS WITH SPATIAL CORRECTION"
estimates table IV_PDS, b(%7.4f) se(%7.4f) t(%7.3f) stats(N r2)

end


