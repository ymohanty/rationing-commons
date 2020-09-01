 
*! S. HSIANG 6/2010: PROGRAM TO ESTIMATE SPATIAL HAC ERRORS FOR OLS REGRESSION MODEL [V3 UPDATE 6/2018]

/*-----------------------------------------------------------------------------

 v1 S. HSIANG 6/10 [SMH2137@COLUMBIA.EDU]

 v2 UPDATE 6/13 [SHSIANG@PRINCETON.EDU]:
	INTRODUCED 'DROPVAR' OPTION BASED ON CODE PROVIDED BY KYLE MENG
 
 V3 UPDATE 6/18 [SHSIANG@BERKELEY.EDU]: 
	CORRECTED ERROR (LINE 428) FOUND BY MATHIAS THOENIG THAT INCORRECTLY 
	COMPUTED WEIGHTS FOR INTER-TEMPORAL AUTOCORRELATION ESTIMATES WITHIN PANEL 
	UNITS. SIGN OF BIAS IN V2 IS INDETERMINATE, DEPENDS ON LAG LENGTH AND DATA 
	STRUCTURE.
 
 ------------------------------------------------------------------------------

 This may contain errors. Please notify me of any errors you find.
 
 ------------------------------------------------------------------------------

 Syntax:
 
 ols_spatial_HAC Yvar Xvarlist, lat(latvar) lon(lonvar) Timevar(tvar) Panelvar(pvar) [DISTcutoff(#) LAGcutoff(#) bartlett DISPlay star dropvar]

 Function calculates non-parametric (GMM) spatial and autocorrelation 
 structure using a panel data set.  Spatial correlation is estimated for all
 observations within a given period.  Autocorrelation is estimated for a
 given individual over multiple periods up to some lag length. Var-Covar
 matrix is robust to heteroskedasticity.
 
 A variable equal to 1 is required to estimate a constant term.
 
 Example commands:
 
 ols_spatial_HAC dep indep1 indep2 const, lat(C1) lon(C2) t(year) p(id) dist(300) lag(3) bartlett disp

 ols_spatial_HAC dep indep*, lat(C1) lon(C2) timevar(year) panelvar(id) dist(100) lag(2) star dropvar

 ------------------------------------------------------------------------------
 
 Requred arguments: 
 
 Yvar: dependent variable  
 Xvarlist: independnet variables (INCLUDE constant as column)
 latvar: variable containing latitude in DEGREES of each obs
 lonvar: same, but longitude
 tvar: varible containing time variable
 pvar: variable containing panel variable (must be numeric, see "encode")
 
 ------------------------------------------------------------------------------
 
 Optional arguments:
 
 distcutoff(#): {abbrev dist(#)} describes the distance cutoff in KILOMETERS for the spatial kernal (the distance at which spatial correlation is assumed to vanish). Default is 1 KM.
 
 lagcutoff(#): {abbrev lag(#)} describes the maximum number of temporal periods for the linear Bartlett window that weights serial correlation across time periods (the distance at which serial correlation is assumed to vanish). Default is 0 PERIODS (no serial correlation). {Note, Greene recommends at least T^0.25}  
 
 ------------------------------------------------------------------------------
 
 Options:
 
 bartlett: use a linear bartlett window for spatial correlations, instead of a uniform kernal
 
 display: {abbrev disp} display a table with estimated coeff and SE & t-stat using OLS, adjusting for spatial correlation and adjusting for both spatial and serial correlation. Can be used with star option. Ex:
 
 -----------------------------------------------
     Variable |   OLS      spatial    spatHAC   
 -------------+---------------------------------
       indep1 |    0.568      0.568      0.568  
              |    0.198      0.206      0.240  
              |    2.876      2.761      2.369  
        const |    6.415      6.415      6.415  
              |    0.790      1.176      1.340  
              |    8.119      5.454      4.786  
 -----------------------------------------------
                                  legend: b/se/t
 

 star: same as display, but uses stars to denote significance and does not show SE & t-stat. Can be used with display option. Ex:
 
 -----------------------------------------------------
     Variable |    OLS        spatial      spatHAC    
 -------------+---------------------------------------
       indep1 |   0.568***     0.568***     0.568**   
        const |   6.415***     6.415***     6.415***  
 -----------------------------------------------------
                   legend: * p<.1; ** p<.05; *** p<.01
                   
                   
 dropvar: Drops variables that Stata would drop due to collinearity. This requires that an additiona regression is run, so it slows the code down. For large datasets, if this function is called many times, it may be faster to ensure that colinear variables are dropped in advance rather than using the option dropvar. If Stata returns "estimates post: matrix has missing values", than including the option dropvar may solve the problem. (This option written by Kyle Meng).
 
 ------------------------------------------------------------------------------
 
 Implementation:
 
 The default kernal used to weight spatial correlations is a uniform kernal that
 discontinously falls from 1 to zero at length locCutoff in all directions (it is isotropic). This is the kernal recommented by Conley (2008). If the option "bartlett" is selected, a conical kernal that decays linearly with distance in all directions is used instead.
 
 Serial correlation bewteen observations of the same individual over multiple periods seperated by lag L are weighted by 

       w(L) = 1 - L/(lagCutoff+1)
       
 ------------------------------------------------------------------------------

 Notes:

 Location arguments should specify lat-lon units in DEGREES, however
 distcutoff should be specified in KILOMETERS. 

 distcutoff must exceed zero. CAREFUL: do not supply
 coordinate locations in modulo(360) if observations straddle the
 zero-meridian or in modulo(180) if they straddle the date-line. 

 Distances are computed by approximating the planet's surface as a plane
 around each observation.  This allows for large changes in LAT to be
 present in the dataset (it corrects for changes in the length of
 LON-degrees associated with changes in LAT). However, it does not account
 for the local curvature of the surface around a point, so distances will
 be slightly lower than true geodesics. This should not be a concern so
 long as locCutoff is < O(~2000km), probably.

 Each time-series for an individual observation in the panel is treated
 with Heteroskedastic and Autocorrelation Standard Errors. If lagcutoff =
 0, than this estimate is equivelent to White standard errors (with spatial correlations 
 accounted for). If lagcutoff = infinity, than this treatment is
 equivelent to the "cluster" command in Stata at the panel variable level.

 This script stores estimation results in standard Stata formats, so most "ereturn" commands should work properly.  It is also compatible with "outreg2," although I have not tested other programs.

 The R^2 statistics output by this function will differ from analogous R^2 stats
 computed using "reg" since this function omits the constant. 
 ------------------------------------------------------------------------------

 References:

      TG Conley "GMM Estimation with Cross Sectional Dependence" 
      Journal of Econometrics, Vol. 92 Issue 1(September 1999) 1-45
      http://www.elsevier.com/homepage/sae/econworld/econbase/econom/frame.htm
      
      and 

      Conley "Spatial Econometrics" New Palgrave Dictionary of Economics,
      2nd Edition, 2008

      and

      Greene, Econometric Analysis, p. 546

	  and

	  Modified from scripts written by Ruben Lebowski and Wolfram Schlenker and Jean-Pierre Dube and Solomon Hsiang
	  Debugging help provided by Mathias Thoenig.
 
 -----------------------------------------------------------------------------*/

program conley_viraj, eclass byable(recall)
version 15
syntax varlist(ts fv min=2) [if] [in], ///
				lat(varname numeric) lon(varname numeric) ///
				endog(varlist) ivset(varlist) lcluster(varname) ivcluster(varname) ///
				regtype(string) [LAGcutoff(integer 0) DISTcutoff(real 1) ///
				DISPlay star bartlett dropvar]
				
/*--------PARSING COMMANDS AND SETUP-------*/

display "`varlist'"

capture drop touse
marksample touse				// indicator for inclusion in the sample
gen touse = `touse'

loc Y = word("`varlist'",1)		

loc listing "`varlist'"

loc X ""
scalar k = 0

//make sure that Y is not included in the other_var list
foreach i of loc listing {
	if "`i'" ~= "`Y'"{
		loc X "`X' `i'"
		scalar k = k + 1 // # indep variables
		
	}
}

if "`dropvar'" == "dropvar"{
	
	quietly reg `Y' `X' if `touse', nocons
	
	mat omittedMat=e(b)
	local newVarList=""
	local i=1
	scalar k = 0 //replace the old k if this option is selected
	
	foreach var of varlist `X'{
		if omittedMat[1,`i']!=0{
			loc newVarList "`newVarList' `var'"
			scalar k = k + 1
		}
		local i=`i'+1
	}
	
	loc X "`newVarList'"
}

//generating a function of the included obs
quietly count if `touse'		
scalar n = r(N)					// # obs
scalar n_obs = r(N)

/*--------FIRST DO IV_PDS, STORE RESULTS-------*/

display "`Y'"
display "`X'"
display "`endog'"
display "`ivset'"

if "`regtype'" == "iv_pds" {
	quietly: ivlasso `Y' (`X') (`endog' = `ivset'), loptions(cluster(`lcluster')) ivoptions(cluster(`ivcluster')) post(pds) partial(`X') noconstant
	estimates store IV_PDS
	
	mat list e(b)
	local X1 "`endog' `X'"
	local Z1 "`e(zselected)' `X'"

	display "`X1'"
	display "`Z1'"

	scalar f = 0
	foreach var of varlist `Z1'{
		scalar f = f+1
	}

	scalar k = k+1

	display k
	display f
	display n
	ereturn display

	mata{

		Y_var = st_local("Y") //importing variable assignments to mata
		X_var = st_local("X1")
		Z_var = st_local("Z1")
		lat_var = st_local("lat")
		lon_var = st_local("lon")


		//NOTE: values are all imported as "views" instead of being copied and pasted as Mata data because it is faster, however none of the matrices are changed in any way, so it should not permanently affect the data. 

		st_view(Y=.,.,tokens(Y_var),"touse") //importing variables vectors to mata
		st_view(X=.,.,tokens(X_var),"touse")
		st_view(Z=.,.,tokens(Z_var),"touse")
		st_view(lat=.,.,tokens(lat_var),"touse")
		st_view(lon=.,.,tokens(lon_var),"touse")

		k = st_numscalar("k")				//importing other parameters
		f = st_numscalar("f")
		n1 = st_numscalar("n")
		b = st_matrix("e(b)")				// (estimated coefficients, row vector)
		dist_var = st_local("distcutoff")
		dist_cutoff = strtoreal(dist_var)

		e1 = Y - X*b'

		n1 = length(Y)
		ZeeZ = J(f, f, 0)
		windows_testing = J(n1, 1, 0)
		
		// Fixed radius estimates (2 km)
		ZeeZ_2 = J(f, f, 0)
		
		// Fixed radius estimates (3 km)
		ZeeZ_3 = J(f, f, 0)

		//loop over all observations in period ti
		for(i = 1; i<=n1; i++){
			lon_scale = cos(lat[i,1]*pi()/180)*111 
			lat_scale = 111
			distance_i = ((lat_scale*(lat[i,1]:-lat)):^2 + /// 	
						(lon_scale*(lon[i,1]:-lon)):^2):^0.5
			
			// Three sets of windows for each cutoff
			window_i = distance_i :<= dist_cutoff
			window_i_2 = distance_i :<= 2
			window_i_3 = distance_i :<= 3
			
			windows_testing[i,1] = sum(window_i)
			ZeeZh = ((Z[i,.]'*J(1,n1,1)*e1[i,1]):*(J(f,1,1)*e1':*window_i'))*Z
			ZeeZh_2 = ((Z[i,.]'*J(1,n1,1)*e1[i,1]):*(J(f,1,1)*e1':*window_i_2'))*Z
			ZeeZh_3 = ((Z[i,.]'*J(1,n1,1)*e1[i,1]):*(J(f,1,1)*e1':*window_i_3'))*Z
			
			ZeeZ = ZeeZ + ZeeZh
			ZeeZ_2 = ZeeZ_2 + ZeeZh_2
			ZeeZ_3 = ZeeZ_3 + ZeeZh_3
			
		}
		
		
		// -----------------------------------------------------------------
		// generate the VCE for only cross-sectional spatial correlation, 
		// return it for comparison
		
		XZ = (X'*Z) / n1

		ZX = (Z'*X) / n1

		ZeeZ_spatial = invsym(ZeeZ / n1)
		
		ZeeZ_2_spatial = invsym(ZeeZ_2 / n1)
		
		ZeeZ_3_spatial = invsym(ZeeZ_3 / n1)
		

		V = invsym(XZ * ZeeZ_spatial * ZX) / n1
		
		V_2 = invsym(XZ * ZeeZ_2_spatial * ZX) / n1
		
		V_3 = invsym(XZ * ZeeZ_3_spatial * ZX) / n1
		
		
		// Ensures that the matrix is symmetric 
		// in theory, it should be already, but it may not be due to rounding errors for large datasets
		V = (V+V')/2 
		
		V_2 = (V_2 + V_2')/2
		
		V_3 = (V_3 + V_3')/2
		
		// Calculate standard deviations and store as Stata matrices

		st_matrix("V_spatial", V)
		st_matrix("V_spatial_2", sqrt(V_2))
		st_matrix("V_spatial_3", sqrt(V_3))
		st_matrix("windows_testing", windows_testing)
		

	} // mata

	//------------------------------------------------------------------
	// storing old statistics about the estimate so postestimation can be used

	matrix beta = e(b)
	scalar r2_old = e(r2)
	local zselected_old = e(zselected)
	local zhighdim_old = e(zhighdim)
	scalar r2_a_old = e(r2_a)
	

	// the row and column names of the new VCE must match the vector b

	matrix colnames V_spatial = `X1'
	matrix rownames V_spatial = `X1'
	
	matrix colnames V_spatial_2 = `X1'
	matrix rownames V_spatial_2 = `X1'
	
	matrix colnames V_spatial_3 = `X1'
	matrix rownames V_spatial_3 = `X1'
	
	ereturn post beta V_spatial, esample(`touse')
 	ereturn matrix V_2 = V_spatial_2
 	ereturn matrix V_3 = V_spatial_3
	

	// then filling back in all the parameters for postestimation

	ereturn local cmd = "ivpds_spatial"

	ereturn scalar N = n_obs

	ereturn scalar r2 = r2_old
	ereturn local zselected = "`zselected_old'"
	ereturn local zhighdim = "`zhighdim_old'"
	ereturn scalar r2_a = r2_a_old
	

	ereturn local title = "Linear regression"
	ereturn local depvar = "`Y'"
	ereturn local predict = "regres_p"
	ereturn local model = "ols"
	ereturn local estat_cmd = "regress_estat"
} 
end



