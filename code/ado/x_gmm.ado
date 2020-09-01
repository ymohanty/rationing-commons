/************************************************************************/
/* x_gmm.ado                                                            */
/*GMM ESTIMATION FOR X-SECTIONAL DATA WITH LOCATION-BASED DEPENDENCE	*/
/*for STATA 6.0                                                         */
/*			by	Jean-Pierre Dube						*/
/*				Northwestern University                 		*/
/*				July 10, 1999                           		*/
/*                                                                      */
/*			reference:                                     		*/
/*												*/
/*	Conley, Timothy G.[1996].  "Econometric Modelling of Cross		*/
/*	Sectional Dependence." Northwestern University Working Paper.	*/
/*												*/
/************************************************************************/
/************************************************************************/
/*  To invoke this command type:                                        */
/*	>>x_gmm coordlist cutofflist depvar regressorlist 			*/
/*	   instrumentlist,  xreg() inst() coord()					*/
/*												*/
/*  NOTE: (1) If you want a constant in the regression, specify one of  */
/*	your input variables as a 1. (ie. include it in list of		*/
/*	regressors).									*/
/*												*/
/*	(2) MUST specify positive value for xreg(), inst() and		*/
/*	coord() options.									*/
/*												*/
/*	(3)	xreg() denotes # regressors						*/
/*		inst()	denotes # instruments                           */
/*		coord()	denotes dimension of coordinates                */
/*												*/
/*	(4) Your list of instruments may contain some of the regressors	*/
/*												*/
/*	(5) Your cutofflist must correspond to coordlist (same order)	*/
/*												*/
/*  OUTPUT:                                                             */
/*		betagmm= 2 Step GMM estimator Allowing for Spatial		*/
/* 					Correlation						*/
/*		cov_dep= variance-covariance matrix	of betagmm			*/
/*		J=value of GMM criterion function test of				*/
/*				overidentifying conditions				*/
/*												*/
/*		For Comparison:								*/
/*		b2SLS=2SLS estimates (assuming spatial independence)		*/
/*		cov2SLS=var-cov matrix of b2SLS					*/
/************************************************************************/


program define x_gmm
	version 6.0
#delimit ;				/*sets `;' as end of line*/


/*FIRST I TAKE INFO. FROM COMMAND LINE AND ORGANIZE IT*/
local varlist	"req ex min(1)";	/*must specify at least one variable...
					   all must be existing in memory*/
local options	"xreg(int -1) inst(int -1) COord(int -1)";
	/* # regressors, # instruments, dimension of location coordinates*/

parse "`*'";				/*separate options and variables*/

if `xreg'<1{;
	if `xreg'==-1{;
		di in red "option xreg() required!!!";
		exit 198};
	di in red "xreg(`xreg') is invalid";
	exit 198};	

if `inst'<1{;
	if `inst'==-1{;
		di in red "option ins() required!!!";
		exit 198};
	di in red "inst(`inst') is invalid";
	exit 198};	

if `inst'<`xreg'{;
	di in red "underidentified system: `xreg' regressors and `inst' instruments!!!";
	exit 198};

if `coord'<1{;
	if `coord'==-1{;
		di in red "option coord() required!!!";
		exit 198};
	di in red "coord(`coord') is invalid";
	exit 198};

/*Separate input variables:
	coordinates, cutoffs, dependent, regressors, instruments*/

parse "`varlist'", parse(" ");	
local a=1;
while `a'<=`coord'{;
	tempvar coord`a';
	gen `coord`a''=``a'';	/*get coordinates*/
local a=`a'+1};

local aa=1;
while `aa'<=`coord'{;
	tempvar cut`aa';
	gen `cut`aa''=``a'';	/*get cutoffs*/
	local a=`a'+1;
local aa=`aa'+1};

tempvar Y;
gen `Y'=``a'';			/*get dep variable*/
local depend : word `a' of `varlist';

local a=`a'+1;

local b=1;
while `b'<=`xreg'{;
	tempvar X`b';
	local ind`b'="`b'";
	gen `X`b''= ``a'';
	local ind`b' : word `a' of `varlist';
	local a=`a'+1;
local b=`b'+1};			/*get indep variable(s)*/

local c=1;
while `c'<=`inst'{;
	tempvar Z`c';
	gen `Z`c''=``a'';
	local a=`a'+1;
local c=`c'+1};			/*get instrument(s)*/

/*NOW I DO 2-STEP GMM AND COMPUTE THE COV MATRIX*/
quietly{;			/*so that steps are not printed on screen*/

	/*CREATE MATRICES A AND B FOR 2SLS*/
	tempname A B Zk Zkk W B_N A_N invN ZZ ZZ_N invZZ;
	scalar `invN'=1/_N;
	if `inst'==1{;
		mat accum `ZZ'=`Z1', noconstant};
	else{;
		mat accum `ZZ'=`Z1'-`Z`inst'', noconstant};
	mat `ZZ_N'=`ZZ'*`invN';
	mat `invZZ'=inv(`ZZ_N');
	capture mat drop `B';
	capture mat drop `A';
	local d=1;
	while `d'<=`inst'{;
		if `inst'==1{;
			mat vecaccum `Zk'=`Z`d'' `X1', noconstant};
		else{;
			mat vecaccum `Zk'=`Z`d'' `X1'-`X`xreg'', noconstant};
		mat vecaccum `Zkk'=`Z`d'' `Y', noconstant;
		mat `B'=nullmat(`B') \ `Zk';
		mat `A'=nullmat(`A') \ `Zkk';
	local d=`d'+1};
	mat `B_N'=`B'*`invN';
	mat `A_N'=`A'*`invN';

	/*REGULAR 2SLS PROCEDURE*/
	tempname sigma BinvZZ BinvZZB invBZZB cov BZZA;
	tempvar Ehat sighat Esquare XE Xtemp;
	mat `BinvZZ'=`B_N''*`invZZ';
	mat `BinvZZB'=`BinvZZ'*`B_N';
	mat `BZZA'=`BinvZZ'*`A_N';
	mat `invBZZB'=inv(`BinvZZB');
	mat b2SLS=`invBZZB'*`BZZA';			/*2SLS estimator*/
	gen `Xtemp'=0;
	gen `XE'=0;
	local e=1;
	while `e'<=`xreg'{;
		replace `Xtemp'=`X`e'';
		replace `XE'=`XE'+`Xtemp'*b2SLS[`e',1];
	local e=`e'+1};
	gen `Ehat'=`Y'-`XE';
	gen `Esquare'=`Ehat'*`Ehat';
	egen `sighat'=mean(`Esquare');
	scalar `sigma'=`sighat'*`invN';
	mat cov2SLS=`invBZZB'*`sigma';		/*standard 2SLS cov matrix*/


	/*GMM CORRECTING FOR SERIAL DEPENDENCE*/
	tempname BB BA invBB BAZUUZ ZUUZ1 ZUUZ2 ZUUZ ZUUZt fix;
	tempvar ZUUk X_tem u_tem uhat window;
	mat `BB'=`B''*`B';
	mat `invBB'=inv(`BB');
	mat `BA'=`B''*`A';
	mat bgmm1=`invBB'*`BA';
	gen `X_tem'=0;
	gen `u_tem'=0;
	local f=1;
	while `f'<=`xreg'{;
		replace `X_tem'=`X`f'';
		replace `u_tem'=`u_tem'+`X_tem'*bgmm1[`f',1];
	local f=`f'+1};
	gen `uhat'=`Y'-`u_tem';
	mat `ZUUZ'=J(`inst',`inst',0);
	gen `ZUUk'=0;
	gen `window'=1;		/*initializes mat.s/var.s to be used*/
	local i=1;
	while `i'<=_N{;		/*loop through all observations*/
		local j=1;
		replace `window'=1;
		while `j'<=`coord'{;	/*loop through coordinates*/
			if `i'==1{;
				gen dis`j'=0};
			replace dis`j'=abs(`coord`j''-`coord`j''[`i']);
			replace `window'=`window'*(1-dis`j'/`cut`j'');
			replace `window'=0 if dis`j'>=`cut`j'';
		local j=`j'+1};			/*create window*/
		capture mat drop `ZUUZ2';
		local k=1;
		while `k'<=`inst'{;
			replace `ZUUk'=`Z`k''[`i']*`uhat'*`uhat'[`i']*`window';
			if `inst'==1{;
				mat vecaccum
				   `ZUUZ1'=`ZUUk' `Z1', noconstant};
			else{;
				mat vecaccum
				   `ZUUZ1'=`ZUUk' `Z1'-`Z`inst'', noconstant};
			mat `ZUUZ2'=nullmat(`ZUUZ2') \ `ZUUZ1';
		local k=`k'+1};
		mat `ZUUZt'=`ZUUZ2'';
		mat `ZUUZ1'=`ZUUZ2' +`ZUUZt';
		scalar `fix'=.5;	/*to correct for double-counting*/
		mat `ZUUZ1'=`ZUUZ1'*`fix';
		mat `ZUUZ'=`ZUUZ' +`ZUUZ1';
	local i=`i'+1};
	mat `ZUUZ'=`ZUUZ'*`invN';

	/*STEP (2)*/
	tempname What BW BWB invBWB BWA;
	tempvar Ehat2;
	mat `What'=`ZUUZ';
	mat `What'=inv(`What');
	mat `BW'=`B''*`What';
	mat `BWB'=`BW'*`B';
	mat `invBWB'=inv(`BWB');
	mat `BWA'=`BW'*`A';
	mat betagmm=`invBWB'*`BWA';


mat `BW'=`B_N''*`What';
mat `BWB'=`BW'*`B_N';
mat cov_dep=inv(`BWB');			/*corrected covariance matrix*/
mat cov_dep=cov_dep*`invN';

/*Compute the GMM Criterion Statistics*/
tempname m qq zubar zu;
tempvar J Zuk u1 zubar;
gen `Zuk'=0;
replace `u_tem'=0;
local ii=1;
while `ii'<=`xreg'{;
	replace `X_tem'=`X`ii'';
	replace `u_tem'=`u_tem'+`X_tem'*betagmm[`ii',1];
local ii=`ii'+1};
gen `u1'=`Y'-`u_tem';
mat `m'=J(`inst',1,0);
capture mat drop `m';
local jj=1;
while `jj'<=`inst'{;
	replace `Zuk'=`Z`jj''*`u1';
	egen zubar`jj'=mean(`Zuk');
	scalar `zubar'=zubar`jj'[_N];
	mat `zu'=(1);
	mat `zu'=`zu'*`zubar';
	mat `m'=nullmat(`m') \ `zu';
local jj=`jj'+1};
mat `qq'=`m''*`What';
mat J=`qq'*`m';
gen `J'=J[1,1]*_N;

};					/*end quietly command*/

/*THIS PART CREATES AND PRINTS THE OUTPUT TABLE IN STATA*/
local z=1;
local v=`a';
di _newline(2) _skip(5)
"Results for 2-Step Spatial GMM";
di _newline	_col(20)	" number of observations=  "  _N;
di _newline	_col(20)	" crit. fn. test of overid. restrictions=  "  `J';
di _newline "Dependent variable= `depend'";
di _newline
"variable" _col(13) "2SLS Est." _col(29) "2SLS SE" _col(40) 
	"Spatial GMM Est."  _col(58) "Spatial GMM SE";
di 
"--------" _col(13) "-------------" _col(29) "---------" _col(40) 
	"-------------"  _col(58) "------------------";

while `z'<=`xreg'{;
	tempvar beta`z' beta1`z' se`z' see`z' se1`z' se2`z';
	gen `beta`z''=b2SLS[`z',1];
	gen `se`z''=cov2SLS[`z',`z'];
	gen `see`z''=sqrt(`se`z'');
	gen `beta1`z''=betagmm[`z',1];
	gen `se1`z''=cov_dep[`z',`z'];
	gen `se2`z''=sqrt(`se1`z'');
	di "`ind`z''" _col(13)  `beta`z''  _col(29)   `see`z''  _col(40) 
	   `beta1`z'' _col(58)  `se2`z'';
local z=`z'+1};
end;

exit;


