program define tabout
*! Version 3.0.9 beta Ian Watson 17apr2019
* fixed dropc problem (3.0.8 was an interim solution which rolled
* back to 3.0.4. This fix is a new fix) - thanks Floris Lazrak
* bug fix - wrong row and column totals in svy summary tables when some observations were missing, thanks Ulrich Brandt
*! Stata 14.2 (or later) version
* added units option for LaTeX output, allowing for options such as columnwidth in twidth, thanks Gilbert Montcho
* extended bug fix to plugc and plugr 3oct2018
* Version 3.0.4 beta Ian Watson 23may2018
* fixed bug in dropc and dropr options, thanks Charlotte Gill
* remember the space problem with style.css
* thanks to Peter Young for the multiplier option
* 2.0.7 Ian Watson 5jan2015
* bug fix - missing se option when doing counts for svy col and row totals, resulting in cell se not count se going into col and row totals, thanks Anwar Dudekula
* 2.0.6 Ian Watson 22nov2012
* added sort option, as per Thomas Odeny request
* bug fix - where variables have complete missing values, a warning is issues and program terminates, thanks Richard Fox
* 2.0.5 Ian Watson 31may2011
* added comma option, code contributed by Arjan Soede
* inserted warning in tutorial noting h1 thru h3 are limited to 256 characters, thanks Johannes Geyer
* 2.0.42 Ian Watson 10nov2010
* fixed typo in fweight option, thanks Jonathan Gardner
* 2.0.41 Ian Watson 7nov2010
* added omitted line for do_pop global macro, thanks Mitch Abdon
* 2.0.4 Ian Watson 1nov2010
* fixed bug for long variable list, thanks Eric Booth
* fixed bug with parsing when last variable is a string one, thanks Mikko RÃƒÆ’Ã‚Â¶nkkÃƒÆ’Ã‚Â¶
* changed "-1" to "-999" in various presentation functions, thanks Axel Engellandt
* various enhancements requesed by Stata users
* missing option, thanks Cathy Redmond
* semi-colon delimiter, thanks Ulrich Atz
* weighted pop estimates for svy option, thanks Nirmala Devi Naidoo
* frequency weights now allow long integers, thanks Thomas Masterson
* 2.0.3 Ian Watson 1apr2007
* fixed obs for svy basic tables (now uses ObsSub)
* 2.0.2 Ian Watson 21mar2007
* added string to syntax for cisep (was missing)
* changed options for bracket: cibnone and sebnone
* instead of nocib noseb
* fixed oneway problems (N labels, add_nrow indexing)
* added dots for svy commands
* 2.0.1 Ian Watson 16mar2007
* fixed percent in oneway
* removed $ around <> in texclean
* added noffset option
* made nwt global in svy_sum
* removed wtstr in ta from summary tables
* fixed typo in cblock rblock
* fixed typo in nwt option
* 2.0.0 Ian Watson 30nov2006 
* 1.2.0 Ian Watson 13mar2005
* 1.1.8 Ian Watson 30nov2004
* 1.1.0 Ian Watson 28oct2004 
* Program to produce publication quality tables
* See tabout_tutorial.pdf at www.ianwatson.com.au

    version 9.2
    syntax varlist [if] [in] [fweight aweight iweight] using/ [, ///
    REPlace  ///
    APPend  ///
    Contents(string)  ///
    Format(string)  ///
    clab(string) ///  ///
    LAYout(string)  ///
    npos(string)  ///
    nlab(string)  ///
    nwt(string)  ///
    NOFFset(string) ///  
    stats(string)  ///
    stpos(string)  ///
    stlab(string)  ///
    stform(string) ///
    ppos(string)  ///
    plab(string) /// 
    pform(string) /// 
    cisep(string)  ///
    MULTiplier(string)  ///
    Level(string)  ///
    delim(string)  ///
    MONey(string)  ///
    CHKWTnone  ///
    dropc(string)  ///
    dropr(string)  ///
    plugc(string)  ///
    plugr(string)  ///
    PLUGLab(string)  ///
    PLUGSYMbol(string) ///
    show(string)  ///
    wide(string)  ///
    TOTal(string)  ///
    PTOTal(string)  ///
    h1(string)  ///
    h2(string)  ///
    h3(string) ///
    h1c(string) ///
    h2c(string) ///
    h3c(string) ///
    ltrim(string) ///
    topf(string) ///
    botf(string) ///
    topstr(string) ///
    botstr(string) ///
    PSymbol(string) ///
    tp(string) ///
    style(string)  ///
    font(string) ///
    css(string) ///
    units(string)  ///
    TWidth(string)  ///
    LWidth(string)  ///
    CWidth(string) ///
    FAMily(string)  ///
    fsize(string)  ///
    ROTate(string)  ///
    sheet(string) ///
    LOCation(string) ///
    indent(string) ///
    title(string) ///
    fn(string) ///
    PAPer(string) ///
    doctype(string) ///
    caplab(string) ///
    cappos(string) ///
    * ///
    ]

*------------------------ setup -------------------------


*------------------------ config file -------------------


global dotss "nois _dots 0, title(Survey results being calculated)"
global dots "nois _dots 5 0"
global delim = cond("`delim'"~="","`delim'","|")
  

local optionlist "debug ci2col open topbody botbody stars"
local optionlist = "`optionlist' pop body compile noborder"
local optionlist = "`optionlist' nohlines noplines seb cib ntc ssf"
local optionlist = "`optionlist' landscape tleft sum sort svy dpcomma"
local optionlist = "`optionlist' hright oneway mi nnoc chkwtnone"

local infile = cond("`tp'"~="","`tp'","")

if "`infile'" !="" {
    tempname tpfile

    capture findfile "`infile'"
        if _rc {
            di
            di as error "Your template file `infile' was not found."
            di
            clearglobs 
            exit 601
        }

    file open `tpfile' using "`infile'", read
        di
        di as text "Some tabout options loaded from template file: `infile'"
    file read `tpfile' line
        while r(eof) == 0 {
            file read `tpfile' line
            if "`line'" !="" {
                if (regexm("`optionlist'", "`line'")) != 0 {
                   local options = "`options'" + " `line'"
                } 
                else {
                    if (regexm("`line'", "\(")) == 0 {
                        tokenize "`line'", parse("(")
                        local value = "`1'"
                        local newcmd = `"local `1' = "`value'""'
                    }
                    else {
                        tokenize "`line'", parse("(")
                        local value = regexr("`3'", "\)", "")
                        local newcmd = `"local `1' = "`value'""'
                    }
                    `newcmd'
                }
            }
        }
    file close `tpfile'
}


    global debug = "qui"
    global do_pseudo =  0
    global do_open = 0
    global do_topbody = 0
    global do_botbody = 0
    global do_stars = 0
    global do_pop = 0
    global do_body = 0
    global do_compile = 0
    global do_border = 1
    global do_hlines = 1
    global do_plines = 1
    global noseb  = 0
    global nocib = 0
    global ntc = 0
    global dpcomma = "."
    global ssf = 0
    global do_land = 0
    global do_tleft = 0
    global do_sum = 0
    global do_svy = 0
    global do_sort = 0
    global do_hright = 0
    global oneway = 0
    global mi = ""
    global do_nnoc = 0
    global chkwtnone = ""

    
    local m : word count `options'
    tokenize `options'
    forval p = 1/`m' {
        if ("``p''" == "debug") global debug = "" 
        if ("``p''" == "ci2col") global do_pseudo = 1 
        if ("``p''" == "open") global do_open = 1 
        if ("``p''" == "topbody") global do_topbody = 1 
        if ("``p''" == "botbody") global do_botbody = 1 
        if ("``p''" == "stars") global do_stars = 1 
        if ("``p''" == "pop") global do_pop = 1 
        if ("``p''" == "body") global do_body = 1 
        if (substr("``p''", 1, 4) == "comp") global do_compile = 1 
        if (substr("``p''", 1, 6) == "nobord") global do_border = 0 
        if (substr("``p''", 1, 4) == "nohl") global do_hlines = 0 
        if (substr("``p''", 1, 4) == "nopl") global do_plines = 0 
        if (substr("``p''", 1, 3) == "seb") global noseb = 1 
        if (substr("``p''", 1, 3) == "cib") global nocib = 1 
        if ("``p''" == "ntc") global ntc = 1 
        if (substr("``p''", 1, 3) == "dpc") global dpcomma = "," 
        if ("``p''" == "ssf") global ssf = 1 
        if (substr("``p''", 1, 4) == "land") global do_land = 1 
        if (substr("``p''", 1, 3) == "one") global oneway = 1 
        if (substr("``p''", 1, 5) == "chkwt") global chkwtnone = "`chkwtnone'"
        if ("``p''" == "sum") global do_sum = 1 
        if ("``p''" == "svy") global do_svy = 1 
        if ("``p''" == "sort") global do_sort = 1 
        if ("``p''" == "hright") global do_hright = 1 
        if ("``p''" == "mi") global mi = "`mi'" 
        if ("``p''" == "nnoc") global do_nnoc = 1 
    }

tokenize "`using'", parse(".")
global fstem = "`1'"

tempvar touse 
mark `touse' `if' `in'

   
    global mainfile = "`using'"

    if ("`style'"~="") {
        if ("`style'"=="tex") global style = "tex"
            else if ("`style'"=="csv") global style = "csv"
                else if ("`style'"=="semi") global style = "semi"
                    else if (substr("`style'",1,3)=="htm") global style = "htm"
                        else if ("`style'"=="xlsx") global style = "xlsx" 
                            else if ("`style'"=="xls") global style = "xls"
                                else if ("`style'"=="docx") global style = "docx"
                                    else global style = "tab"
    }
    else global style = "tab"
    
    global doctype = cond("`doctype'" != "", "`doctype'", "article")


    if ("$style" == "tex") {
        if ("`paper'" == "letter") global paper = "letterpaper"
        else if ("`paper'" == "legal") global paper = "legalpaper"
        else  global paper = "a4paper"
    }
    else if ("$style" == "docx") {
        global paper = cond("`paper'" != "", "`paper'", "letter")
    }


    if ( "$style" == "xls" | "$style" == "xlsx" | "$style" == "docx") {
         if  (c(stata_version) < 13) {
            di
            di as error "The xls, xlsx and docx styles are only available"
            di as error "under Stata 13 or later. If you are using an earlier"
            di as error "version of Stata, you have several other options:"
            di
            di as error "For spreadsheet files, consider using either the"
            di as error "csv or tab styles and naming the file"
            di as error "$stem.xls for importing as a delimited text file"
            di as error "into your spreadsheet application. You will need to"
            di as error "do your own formatting inside your spreadsheet."
            di
            di as error "For word processing files, consider using the html"
            di as error "style and opening the file in your word processor. You"
            di as error "can then save it as a docx file and it will preserve"
            di as error "all the formatting which you applied in tabout, such as "
            di as error "borders, font family and font size, bolding etc."
            di
            clearglobs
            exit
        }
    }


    if ("$style" == "tex") {
        global spacer1 = "~=~"  
        global spacer2 = ".~"  
    }
    else {
        global spacer1 = " = "  
        global spacer2 = " . "  
    }
   
    if ($do_compile == 1 & "$style" == "tex") {
       if missing("$tex") {
            di
            di as error "You are using the tex style and have"
            di as error "also chosen to compile your LaTeX code."
            di as error "But you have not defined a global tex "
            di as error "variable indicating the path to your tex"
            di as error "distribution files."
            di
            di as error "Compile and open options ignored."
            di
            global do_compile = 0
            global do_open = 0
        }
    }



    local opt ""
    local opt = cond("`replace'" == "replace","replace", ///
                    cond("`append'" == "append","append", ///
                        ""))

    if ("$style" == "docx" & "`opt'" == "append") {
        di
        di as err "You cannot use the append option with "
        di as err "the docx output style."
        di
        di as err "Consider using html or importing a"
        di as err "spreadsheet based on xlsx. Both of"
        di as err "these options will allow you to use"
        di as err "append with a word processing file."
        di
        clearglobs
        exit
    }

    if ("$style" == "docx") {
        local badmatch = 0
        if ("`h1'" != "" & "`h1c'" == "") local badmatch = 1
        if ("`h2'" != "" & "`h2c'" == "") local badmatch = 1
        if ("`h3'" != "" & "`h3c'" == "") local badmatch = 1
        if (`badmatch' == 1) {
            di
            di as err "If you use h2 or h3 you must"
            di as err "also use h2c or h3c to match."
            di as err "Ignore this message if you have set"
            di as err "any of these to nil."
            di
        }
    }


    capture confirm file "$mainfile"
    if !_rc global exists = 1
        else global exists = 0 

    if ("`opt'"=="") { 
        if ($exists == 1) {
         di
         di as err "The file $mainfile already exists, but you haven't"
         di as err "used either the replace or append option. Please change"
         di as err "the file name or include replace or append."
         di
         clearglobs
         exit
        }
    }
    
    global replace = 0
    if ("`opt'"=="replace") { 
        if ("$style" == "xls" | "$style" == "xlsx" | "$style" == "docx") {
            global replace = "1"
        }
        else {
            tempname outfile
            capture file open `outfile' using "$mainfile", write replace
            capture file write `outfile' ""
                if _rc==111 {
                  di
                  di as err "File `using'"
                  di as err "could not be written to your disk."
                  di as err "This may be due to the directory being"
                  di as err "read only. Try specifying a different"
                  di as err "directory where you have write privileges". 
                  di as err "If it is your working directory, "
                  di as err "check that you have write privileges to it."
                  di as err "It might also be the case that this file"
                  di as err "is already open inside another application"
                  di as err "and the operating system has locked it."
                  di as err "If so, try closing it before running tabout."
                  di
                  clearglobs
                  exit
            }
            capture file close `outfile'
        } 
    }

       
    local weightstr1 = cond("`weight'"~="","`weight'","none")
    local weightstr2 = cond("`weight'"~="",subinstr("`exp'"," ","",.),"none")
    
    if ("`weightstr1'"~="none") { 
        local wtvar = substr("`weightstr2'",2,.)
        local wttype : type `wtvar'
        if ("`weightstr1'"=="fweight" & "`wttype'" ~= "byte" & "`wttype'" ~= "int" & "`wttype'" ~= "long" & "$chkwtnone"=="") {
            di
            di as err "Problem with frequency weights {search r(401)}"
            di
            clearglobs
            exit
        }
    }
    

*------------------------ contents options -------------------------
        
        local nogood = 0
        local vnogood = 0
        local snogood = 0
        if ("`contents'" ~= "") {
        local a = "freq cell row col cum"
        local b = "se ci lb ub"
        local c = "N mean var sd skewness kurtosis sum uwsum min max count median iqr r9010 r9050 r7525 r1050 p1 p5 p10 p25 p50 p75 p90 p95 p99"
                
        local n : word count `contents'
        tokenize `contents'
        forval x = 1/`n' {
            local testwd = "``x''"
            if ($do_sum==0 & $do_svy==0) {
                if (strpos("`a'","`testwd'")==0) local nogood = 1
            }
            if ($do_sum==1) {
                if (strpos("`a'","`testwd'")~=0) local nogood = 1
            }
        }
        
        if (`nogood'==1) {
        di
        di as err "Invalid type of entry in contents option, or you may"
        di as err "have forgotten to turn on the sum or svy option" 
        di
        show_allowtable
        clearglobs
        exit
        }
        
        if ($do_sum==1) {
            local k : word count `contents'
            local fword : word 1 of `contents'
            local sword : word 2 of `contents'
            local tword : word 3 of `contents'
            local statkind = "`fword'"
            local statvar = "`sword'"
            if ($do_svy==1) {
                if ("`fword'"~="mean") {
                    di
                    di as err "Only mean is allowed for survey analysis"
                    di
                    show_allowtable
                    clearglobs
                    exit
                }
                if (strpos("`b'","`tword'")==0){
                    di
                    di as err "Only one summary statistic is allowed for survey analysis"
                    di
                    show_allowtable
                    clearglobs
                    exit
                }
                else {
                    local svy_sumvar = "`sword'"
                    local contents = subinstr("`contents'","`sword'","",.)
                    local contents = subinstr("`contents'","mean","SV",.)
                }
            }
            else {
                local n : word count `contents'
                tokenize `contents'
                forval x = 1/`n' {
                    local testwd = "``x''"
                    if (mod(`x',2))==1 {
                        if (strpos("`c'","`testwd'")==0) local snogood = 1
                    }
                    else {
                        capture confirm variable `testwd'
                        if (_rc~=0) {
                            local vnogood = 1
                            local err_msg = "Variable `testwd' not found {search r(111)}"
                        }
                    }
                }
            }
            if (`k'>2) {
                if (strpos("`c'","`tword'")~=0) global oneway = 1
            }
        }
    }
    else local contents = "freq"
    if (`snogood'==1) {
        di
        di as err "Invalid type of entry in contents option, or you may"
        di as err "have forgotten to turn on the sum or svy option" 
        di
        show_allowtable
        clearglobs
        exit
    }
    if (`vnogood'==1) {
        di
        di as err "`err_msg'"
        di
        clearglobs
        exit
    }

    
*------------------------ survey options -------------------------      

    
    local svyporp = cond("`multiplier'"~="", real("`multiplier'"), 1)
    local svylevel = cond("`level'"~="",real("`level'"), 95)


*------------------------ cell labelling options -------------------------
    
    if ("`clab'"~="") global clab = "`clab'"
    else {
        if ($do_sum==1) {
            if ($do_svy==0) global clab = ""
            else {
                global clab = "Mean"
                local c : word count `contents'
                tokenize `contents'
                forval x = 2/`c' {
                    global clab = "$clab " + upper("``x''")
                }
            }
        }
        else {
            global clab = ""
            local c : word count `contents'
            tokenize `contents'
            forval x = 1/`c' {
                if ($do_svy==0) {
                    if ("``x''"=="freq") local hstr = "No."
                        else    local hstr = "%"
                }
                else  {
                    if (`svyporp'==1) local suf="Prop."
                        else {                        
                            if (`svyporp'==100) local suf = "%"
                                else local suf = "Per_`svyporp'"
                        }
                    if ("``x''"=="freq") local hstr = "No."
                    else if ("``x''"=="se") local hstr = "SE"
                    else if ("``x''"=="ci") local hstr = "CI"
                    else if ("``x''"=="lb") local hstr = "LB"
                    else if ("``x''"=="ub") local hstr = "UB"
                    else local hstr = "`suf'"
                }
                global clab = "$clab `hstr'"
            }
        }
    }       
    
    local categ = cond("`contents'"~="","`contents'","FR")
    global numcat : word count `categ'
    tokenize "`categ'"
    global category ""
    forval i = 1/$numcat {
        local letter = upper(substr("``i''",1,2))
        global category "$category `letter' "
    }
    local nogood = 0
    if $do_svy==1 {
        tokenize "$category"
        forval x = 1/$numcat {
            local cat= "``x''"
            if (`x'==1) {
                if "`cat'"=="FR" local svycat = "count"
                    else if "`cat'"=="CE" local svycat = "cell"
                    else if "`cat'"=="CO" local svycat = "col"
                    else if "`cat'"=="RO" local svycat = "row"
                    else local svycat = "cell"
            }
            else {
                if ("`cat'"=="FR" | "`cat'"=="CE" | "`cat'"=="CO" | ///
                "`cat'"=="RO") {
                    local nogood = 1 
                }
            }
        }
    }

    if (`nogood'==1) {
        di
        di as err "Only one category (freq cell col or row) can be used with svy option."
        di
        show_allowtable
        clearglobs
    exit
    }

    global cisep = cond("`cisep'"~="","`cisep'",",")
    
    
    local formbad = 0
    local format = cond("`format'"~="","`format'","1c")
    tokenize "a b d e f g h i j k l n o q r s t u v w x y z"
    forval x = 1/23 {
        if (strpos(lower("`format'"),"``x''")~=0) local formbad = 1
    }
    if (`formbad'==1) { 
        di
        di as err "Error in format. Only the letters c, m and p are allowed."
        di
        clearglobs
        exit
    }
    
    
    global layout = cond("`layout'"~="","`layout'","col")
    
    if ("`layout'"~=""){
        if ("`layout'"=="cb" | "`layout'"=="cblock")  ///
            global layout = "c_block"
        else if ("`layout'"=="rb" | "`layout'"=="rblock")  ///
            global layout = "r_block"
        else if ("`layout'"=="col") global layout = "col"
        else if ("`layout'"=="row") global layout = "row"
        else global layout = "col"
    }
    else global layout = "col"
        
    
*------------------------ output options -------------------------
    
    global h1 = cond("`h1'"~="","`h1'","")
    global h2 = cond("`h2'"~="","`h2'","")
    global h3 = cond("`h3'"~="","`h3'","")
    global h1c = cond("`h1c'"~="","`h1c'","")
    global h2c = cond("`h2c'"~="","`h2c'","")
    global h3c = cond("`h3c'"~="","`h3c'","")
    global ltrim = cond("`ltrim'"~="","`ltrim'","1")

    if ("`ptotal'"=="none"){
        global showtot = 0
        global finaltot = 0
    }
    else if ("`ptotal'"=="single"){
        global showtot = 0
        global finaltot = 1
    }
    else {
        global showtot = 1
        global finaltot = 0
    }
    
    if ("`total'")~="" {
        if ("`total'"=="d"){
            global vtotal = "Total"
            global htotal = "Total"
            
        }
        else {
            tokenize "`total'"
            if ("`1'"=="d") global vtotal = "Total"
                else global vtotal = subinstr("`1'","_"," ",.)
            if ("`2'"=="d") global htotal = "Total"
                else global htotal = subinstr("`2'","_"," ",.)
        }
    }
    else {
        global vtotal = "Total"
        global htotal = "Total"
    }       
    

    if "`font'" ~= "" {
        if "`font'" == "bold" global tfont "bold"
        else if "`font'" == "italic"  global tfont "italic"
        else global tfont "plain"
        }
    else global tfont "plain"

    if ("$style"=="htm") {
        global units = cond("`units'" != "", "`units'", "px")
    }
    else if ("$style"=="tex") {
        global units = cond("`units'" != "", "`units'", "cm")
    }
    else {
        global units = cond("`units'" != "", "`units'", "%")
    }

    if ("`rotate'"~="") {
        global angle = "`rotate'"
    }
    else global angle = "0"
    
    global texdef = "14"

    global dropc = cond("`dropc'" ~= "","`dropc'","")
    global dropr = cond("`dropr'" ~= "","`dropr'","")
    global plugc = cond("`plugc'" ~= "","`plugc'","")
    global plugr = cond("`plugr'" ~= "","`plugr'","")
    global pluglab = cond("`pluglab'" ~= "","`pluglab'","")
    global plugsymbol = cond("`plugsymbol'" ~= "","`plugsymbol'"," ")


    if ("`css'" != "") {
        capture findfile "`css'"
        if _rc {
            di
            di as error "The html style file `css' was not found "
            di as error "It should be in the working directory or the tabout directory"
            dir
            exit 601
        }
        else {
            global css = "`css'"
        }
    }

    global twidth = cond("`twidth'" ~= "","`twidth'","")
    global lwidth = cond("`lwidth'" ~= "","`lwidth'","")
    global cwidth = cond("`cwidth'" ~= "","`cwidth'","")
    global fontsize = cond("`fsize'" ~= "","`fsize'","")


    global family = ""
    global rmfamily = ""
    global ssfamily = ""
    if ("`family'" != "") { 
        tokenize "`family'", parse("$delim")
        global family = "`1'"
        global rmfamily = "`1'"
        if ("`3'" != "") global ssfamily = "`3'"
            else global ssfamily = "`1'"
    }
    
    if ("$family" != "" & "`style'" == "tex") global texapp = "$tex/xelatex"
    else global texapp = "$tex/pdflatex"
    
    global indent = cond("`indent'" != "", "`indent'", "2")
    
    global sheetname = cond("`sheet'" != "", "`sheet'", "Sheet1")
    global rowpos = "1"        
    global colpos = "1"        


    if ("`location'" != "") {
        tokenize "`location'"
        global rowpos = "`1'"
        if ("`2'" == "") {
            di
            di as error "Location option requires two numbers,"
            di as error "row and column (in that order),"
            di as error "separated by a space."
            di
            clearglobs
            exit
        }
        else global colpos = "`2'"

    } 

    global title = cond("`title'" ~= "","`title'","")
    global fn = cond("`fn'" ~= "","`fn'","")
    global caplab = cond("`caplab'" != "","`caplab'","")
    global cappos = cond("`cappos'" != "","`cappos'","above")
    global do_caption = cond("$caplab" ! = "", 1, 0)
  
    global money = cond("`money'"~="","`money'","$")
    
  
    global prefile = cond("`topf'" ~= "", "`topf'" , "")
    global postfile = cond("`botf'" ~= "", "`botf'", "")
    global topinsert = cond("`topstr'" ~= "", "`topstr'", "nil")
    global botinsert = cond("`botstr'" ~= "", "`botstr'", "nil")

    global ps = cond("`psymbol'" ~= "", "`psymbol'", "#")
    global do_customtop = cond("$prefile" ~= "", 1, 0)
    global do_custombot = cond("$postfile" ~= "", 1, 0)
    
    
    if ($do_customtop==1) { 
    tempname infile
    capture file open `infile' using "$prefile", read
        if _rc~=0 {
            di
            di as err "File $prefile not found."
            di as err "Check and retype file specification."
            di
            clearglobs
            capture file close `infile'
            exit        
        }
    capture file close `infile'
    }

    if ("$botinsert"~="" & "$ps"=="") {
        di 
        di as err "You must specify the psymbol as well as the filename"
        di
        clearglobs
        exit
    }
    
    if ($do_custombot==1) { 
    tempname infile
    capture file open `infile' using "$postfile", read
        if _rc~=0 {
            di
            di as err "File $postfile not found."
            di as err "Check and retype file specification."
            di
            clearglobs
            capture file close `infile'
            exit        
        }
    capture file close `infile'
    }



*------------------------ display options -------------------------

    
    global colwide = cond("`wide'"~="", "`wide'","10")
    global show = cond("`show'"~="","`show'","output") 

*------------------------ n options -------------------------   
    
    global do_n = 0
    global n_pos = "col"
    global n_wt = ""
    global n_offset = "0"
    
    if "`noffset'"!="" {
        local noffs = real("`noffset'")-1
        global n_offset = string(`noffs')
    }
    
    if "`npos'"~="" {
            if ("`npos'")=="d" global n_pos = "col"
                else global n_pos = "`npos'"
            global do_n 1
    }

    if "`nlab'"~="" {
        if ("`nlab'"=="d") {
            if ("`npos'"=="lab") global n_lab = "(n=#)"
                else global n_lab = "N"
        }
        else global n_lab = "`nlab'"
        global do_n 1
    }
    else {
        if ("`npos'"=="lab") global n_lab = "(n=#)"
            else global n_lab = "N"
    }       
        
    
    if "`nwt'"~="" {
            if ("`nwt'")=="d" global n_wt = ""
                else global n_wt = "[iw=`nwt']"
            global do_n 1
    }

    
    
        
*------------------------ stats options -------------------------


    if ("`stats'"~="") {
        global stats = "`stats'"
        global do_stats = 1
        global stpos = cond("`stpos'" ~= "", "`stpos'", "row")
        global stlab = cond("`stlab'" ~= "", "`stlab'", "")
        global stform = cond("`stform'" ~= "", "%9" + ///
                 "$dpcomma" + "`stform'f", "%9" + "$dpcomma" + "3f")
        global ppos = cond("`ppos'" ~= "", "`ppos'", "below")
        global plab = cond("`plab'" ~= "", "`plab'", "")
        global pform = cond("`pform'" ~= "", "%9" + ///
                 "$dpcomma" + "`pform'f", "%9" + "$dpcomma" + "3f")
    }
    else {
        global stats = ""
        global do_stats = 0
        global stlab = ""
        global stpos = ""
        global stform = ""
        global ppos = ""
        global plab = ""
        global pform = ""
    }
    
    if ($do_svy==0 & "$stats"~="" & /// 
    ("`weightstr1'"=="aweight" | "`weightstr1'"=="iweight")) {
        di
        di as err "Only fweights are allowed with the stats option"
        di
        clearglobs
        exit
    }

   
    if ($do_stars==1 & ("$stats"=="V" | "$stats"=="taub" | "$stats"=="gamma")) { 
        di
        di as err "The stars option is only available for chi2 and lrchi2"
        di
        clearglobs
        exit
    }
    


*===================== main routine =============================   

    if ($do_svy==1) {
        local fvar : word 1 of `varlist'
        capture qui svy: total `fvar'   
            if (_rc==119) {
            di
            di as err "Your data needs to be {help svyset} for this table"
            di
            clearglobs
            exit
        }
        $dotss
    }

    local nvars : word count `varlist'
    if `nvars'==1 global oneway 1
    
    if ($oneway==0 & $do_sort==1) {
            di
            di as err "The sort option is only allowed for oneway tables"
            di
            clearglobs
            exit
    }
    
    local hvar : word `nvars' of `varlist'
    local hvarname : variable label `hvar'
    if ("`hvarname'"=="") label var `hvar' "`hvar'" 
    qui levelsof `hvar', local(levels)
    global nlevels: word count `levels'


    tokenize `varlist'
    local n = `nvars'-1
    forval i = 1/`n' {
        local vvar "`vvar' ``i''"
    }
    global fpass = 1
    global lpass = 0
    local colmat = "matcol(colvals)"
    local rowmat = "matrow(rowvals)"
    if $oneway==1 {
        local vvar "`vvar' `hvar'"
        local hvar = ""
        local colmat = "nil"
        global do_stats = 0
        global stats = ""
    }

    global droph = ""
    if ("`hvar'"~="") local htype : type `hvar'
    if (substr("`htype'",1,3)=="str") { 
        capture encode `hvar', gen(_`hvar'_x)
        local hvar = "_`hvar'_x"
        global droph = "`hvar'"
    }
    
    if ("$style"=="tex") texfix
    
    if ($finaltot==1) {
        tempvar paneltot
        gen `paneltot' = 1
        la var `paneltot' "!PTOTAL!"
        la def paneltot 1 "$vtotal", modify
        la val `paneltot' paneltot
        local vvar "`vvar' `paneltot'"
    }
    global single = 0
    local nvvars : word count `vvar'
    if (`nvvars' == 1) global single = 1

    local lastvar : word `nvvars' of `vvar'
    mat check = J(1,1,0)
    global dropv = ""
            /* core loop starts here */
    global panelnum = 1
    scalar plugcounter = 1
    foreach v of local vvar {
        if ("`v'"=="`lastvar'") global lpass = 1
        local vvarname : variable label `v'
        if ("`vvarname'"=="") label var `v' "`v'" 

        local vtype : type `v'
        if (substr("`vtype'",1,3)=="str") { 
            capture encode `v', gen(_`v'_x)
            local v = "_`v'_x"
            global dropv = "$dropv `v'"
        }
                 
        if $do_svy==0 {
            if $oneway==1 local hvar = "_xx_ph_xx_" 
            if ($do_sum==0) { 
                do_mat `v' `hvar' `weightstr1' `weightstr2' `colmat' `touse'
                do_write `v' `hvar' "`format'"
            }
            else {
                if ($oneway==0) sum_twoway `v' `hvar' ///
                    `weightstr1' `weightstr2' ///
                    `colmat' `statkind' `statvar' `touse'
                else sum_oneway "`contents'" `v' ///
                    `weightstr1' `weightstr2' `touse'
                sum_write `v' `hvar' "`format'" "`contents'"
            }
        }
        else if $do_svy==1 {
            if $oneway==1 local hvar = "_xx_ph_xx_"
            if ($do_sum==0) ///
                svy_mat `v' `hvar' `svycat' `svylevel' `svyporp' `touse'
                else svy_sum `svy_sumvar' `v' `hvar' `svylevel' `colmat' `touse' 
            do_write `v' `hvar' "`format'" 
        }
    global fpass = 0
    global panelnum = $panelnum + 1
    }

di
di as text "Table output written to: `using'"
di
if ("$style" == "xls" | "$style" == "xlsx" | "$style" == "docx") ///
    global show = "none"
if ("$show"=="all" | "$show"=="output") {
    type "`using'"
}



local pdf_file = "$fstem.pdf"

* if ("`os_type'"=="Windows") local shell_cmd = "winexec "
*     else local shell_cmd = "shell open "
if  ($do_compile==1) {
    if ("$style" == "tex") {
        if ("$show" =="comp") shell $texapp "`using'"
            else qui shell $texapp "`using'"
        di
        di as text "Table output file compiled to: `pdf_file'"
        di
    }
} 

if  ($do_open==1) {
    if ("$style" == "tex") shell open "`pdf_file'"
    else shell open  "`using'"
}


local j = colsof(check)
local warning = 0
forval x = 3/`j' {
    local k = `x'-1
    if (check[1,`x']~=check[1,`k']) local warning = 1
}
if (`warning'==1) {
    di
    di as err "Warning: not all panels have the same number of columns."
    di as err "Include show(all) in your syntax to view panels."
    di as err "Consider using the missing option for twoway tables, or"
    di as err "the plug option for summary tables or twoway tables."
    di
}

if ("$droph"~="") drop $droph
if ("$dropv"~="") {
    local ndrops : word count $dropv
    tokenize $dropv
    forval x = 1/`ndrops' {
        capture drop ``x''
    }
}

clearglobs
end

*======================== sub routines ========================

*------------------------ error message display table ----------------------

program show_allowtable
di as input "{c TLC}{hline 22}{c TT}{hline 38}{c TT}{hline 22}{c TRC}"
di as input "{c |} {it:Type of table}        {c |}      {it:Allowable cell contents}         {c |}   {it:Available layout}   {c |}"
di as input "{c |} {it:}                     {c |}             {it:contents( )}                 {c |}     {it:layout( )}        {c |}"
di as input "{c LT}{hline 22}{c +}{hline 38}{c +}{hline 22}{c RT}"
di as input "{c |} {bf:basic}                {c |} freq cell row col cum                {c |} col row  cb rb       {c |}"
di as input "{c |} {bf:}                     {c |} {bf:any number of above, in any order}    {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} {it:for example: contents(freq col)}         {c |}                      {c |}"
di as input "{c LT}{hline 22}{c +}{hline 38}{c +}{hline 22}{c RT}"
di as input "{c |} {bf:basic with SE or CI}  {c |} freq cell row col se ci lb ub        {c |} col row cb rb        {c |}"
di as input "{c |} {bf:}                     {c |} {bf:only one of:} freq cell row col       {c |}                      {c |}"
di as input "{c |} {bf:}(turn on {it:svy} option) {c |} {it:(must come first in the cell)}        {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} {bf:and any number of:} se ci lb ub       {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} {it:for example: contents(col se lb ub)}     {c |}                      {c |}"
di as input "{c LT}{hline 22}{c +}{hline 38}{c +}{hline 22}{c RT}"
di as input "{c |} {bf:summary}              {c |} {bf:any number of:} N mean var sd skewness{c |} no options (fixed)   {c |}"
di as input "{c |} {bf:}-as a oneway table   {c |} kurtosis sum uwsum min max count     {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} median iqr r9010 r9050 r7525 r1050   {c |}                      {c |}"
di as input "{c |} {bf:}(turn on {it:sum} option; {c |} p1 p5 p10 p25 p50 p75 p90 p95 p99    {c |}                      {c |}"
di as input "{c |} {bf:}also may need to turn{c |} {bf:with each followed by variable name}  {c |}                      {c |}"
di as input "{c |} {bf:}on {it:oneway} option)    {c |} {it:for example: contents(min wage mean age)}{c |}                      {c |}"
di as input "{c LT}{hline 22}{c +}{hline 38}{c +}{hline 22}{c RT}"
di as input "{c |} {bf:summary}              {c |} {bf:only one of:} N mean var sd skewness  {c |} no options (fixed)   {c |}"
di as input "{c |} {bf:}-as a twoway table   {c |} kurtosis sum uwsum min max count     {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} median iqr r9010 r9050 r7525 r1050   {c |}                      {c |}"
di as input "{c |} {bf:}(turn on {it:sum} option) {c |} p1 p5 p10 p25 p50 p75 p90 p95 p99    {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} {bf:followed by one variable name}        {c |}                      {c |}"
di as input "{c |} {bf:}                     {c |} {it:for example: contents(sum income)}       {c |}                      {c |}"
di as input "{c LT}{hline 22}{c +}{hline 38}{c +}{hline 22}{c RT}"
di as input "{c |} {bf:summary with SE or CI}{c |} mean {bf:followed by one variable name}   {c |} col row cb rb        {c |}"
di as input "{c |} {bf:}(turn on {it:sum} option  {c |} {bf:and any number of:} se ci lb ub       {c |}                      {c |}"
di as input "{c |} {bf:} and {it:svy} option)     {c |} {it:for example: contents(mean weight se ci)}{c |}                      {c |}"
di as input "{c BLC}{hline 22}{c BT}{hline 38}{c BT}{hline 22}{c BRC}"
end

*------------- routines to construct basic matrices -------------------------

*------------------------ basic tables -------------------------
program do_mat
    args  v hvar weightstr1 weightstr2 colmat touse

	
	
	if ("`colmat'"=="nil") local colmat = "" 
    local wtstr = cond("`weightstr1'"=="none","","[`weightstr1'`weightstr2']") 
     if $oneway==1 local hvar = ""
     if $do_sort==1 local dosort = "sort"
    $debug ta `v' `hvar' `wtstr' if `touse', matcell(raw) ///
            matrow(rowvals) `colmat' $stats $mi `dosort'
    local nobs = r(N)
    if (`nobs' == .) {
         di
         di as err "Some of your variables consist entirely of missing values"
         di
         clearglobs
         exit
    }
    if $do_stats==1 {

         local df =  (r(r)-1)*(r(c)-1)
         if ("$stats"=="chi2") {
            global sval = string(r(chi2),"$stform")
            global pval = string(r(p),"$pform")
            if ("$stpos"=="row") local default =  "Pearson chi2(`df')" 
                else local default =  "Chi2(`df')"               
            if ("$stlab" =="") global slab = "`default'"
                else global slab = "$stlab"
            if ("$plab" =="") {
                if $do_stars == 0 global plab = "P-value"
                else global plab = "Significance"
            }
        }
        else
        if ("$stats")=="gamma" {
			global sval = string(r(gamma),"$stform")
            global pval = string(r(ase_gam),"$pform")
            if ("$stlab" =="") global slab = "Gamma"
                else global slab = "$stlab" 
            if ("$plab" =="") global plab = "ASE"
        }
        else
        if ("$stats"=="V") {
            global sval = string(r(CramersV),"$stform")
            global pval = ""
            if ("$stlab" =="") global slab = "Cramer's V"
                else global slab = "$stlab"
            if ("$plab" =="") global plab = ""
        }
        else
        if ("$stats"=="taub") {
            global sval = string(r(taub),"$stform")
            global pval = string(r(ase_taub),"$pform")
            if ("$stpos"=="row") local default =  "Kendall's tau-b" 
                else local default =  "Tau-b"               
            if ("$stlab" =="") global slab = "`default'"
                else global slab = "$stlab"
            if ("$plab" =="") global plab = "ASE"
        }
        if ("$stats"=="lrchi2") {
            global sval = string(r(chi2_lr),"$stform")
            global pval = string(r(p_lr),"$pform")
            if ("$stpos"=="row") local default =  "Likelihood-ratio chi2(`df')"
                else local default =  "LR chi2(`df')"               
            if ("$stlab" =="") global slab = "`default'"
                else global slab = "$stlab"
            if ("$plab" =="") {
                if $do_stars == 0 global plab = "P-value"
                else global plab = "Significance"
            }
        }
     }
    
    if $do_n==1 {
        $debug ta `v' `hvar' $n_wt if `touse', matcell(obs)
        mata: build_nmats("obs")
    }
    mata: build_mats($oneway)
end


*------------------------ basic tables with svy option ---------------------

program svy_mat
    args v hvar svycat svylevel svyporp touse
    
    $dots
    if ("$stats"=="chi2") global stats = "pearson"
    if "`svycat'"=="count" local extra = "count"
        else local extra = ""
    if "`svycat'"=="cell" local svycat = "" 
    if $oneway==1 local hvar = ""   
    $dots
    $debug svy, subpop(`touse'): tab `v' `hvar', `svycat' se ci
    local studt = invttail(e(N_psu)-e(N_strata),(1-`svylevel'/100)/2)
    local row = e(r)
    local col = e(c)
    mat obs = e(ObsSub)
    mat rowvals = e(Row)
    mat rowvals = rowvals'
    mat colvals = e(Col)
    mat svymain = e(V)
    mat raw = e(b)
    $dots
		
    local format92f = "%9"+"$dpcomma"+"2f"
    if $do_stats==1 {
         if ("$stats"=="pearson") {
            local df =  (e(r)-1)*(e(c)-1)
            global sval = string(e(cun_Pear),"$stform")
            global pval = string(e(p_Pear),"$pform")
            global Fval = string(e(F_Pear),"$stform")
            local F1df = string(e(df1_Pear),"`format92f'")
            local F2df = string(e(df2_Pear),"`format92f'")

            if ("$stpos"=="row") {
                local default =  "Pearson: Uncorrected chi2(`df')" 
                local Fdefault =  "Design-based F(`F1df', `F2df')" 
                if ("$stlab" =="") {
                    global slab = "`default'"
                    global Fslab = "`Fdefault'"
                } 
                else {
                    tokenize "$stlab", parse("$delim")
                    global slab = "`1'"
                    global Fslab = "`3'"
                }
            }
            else {
                local default =  "Chi2(`df') / F(`F1df', `F2df')" 
                if ("$stlab" =="") global slab = "`default'"
                    else global slab = "$stlab"
            }
            if ("$plab" =="") {
                if $do_stars == 0 global plab = "P-value"
                else global plab = "Significance"
            }
        }
    }
    
    if $oneway==1 {
        $dots
        mata: svy_oneway(`svyporp')
        mata: svy_se_oneway(`svyporp',`row') 
    }
    else {
        $dots
        $debug svy, subpop(`touse'): tab `hvar' if `v'<., `extra' se
        mat svyrow = e(V)
        mat rawrt = e(b)
        $dots
        $debug svy, subpop(`touse'): tab `v' if `hvar'<., `extra' se
        mat svycol = e(V)
        mat rawct = e(b)
        if "`svycat'"=="" | "`svycat'"=="count" ///
            mata: svy_cell(`svyporp',`col')
        else    mata: svy_rowcol(`svyporp',`row',`col')
        mata: svy_se(`svyporp',`row',`col') 
    }
    $dots
    if $do_pop==1 {
        $debug ta `v' `hvar' $n_wt if `touse', matcell(obs)
        mata: build_nmats("obs")
    }
    else {
        mata: build_nmats("obs")
    }
    mata: cis(`svyporp',`studt',`"`extra'"')
    $dots
end

*------------------------ summary tables with svy option -------------------
program svy_sum
    args svy_sumvar v hvar svylevel colmat touse
    
    $dots
    if ("`colmat'"=="nil") local colmat = ""
    if $oneway==1 {
        local hvar = ""
        local over = ", over(`v')"
    }
    else local over = ", over(`v' `hvar')"

    $dots
    $debug svy, subpop(`touse'): mean `svy_sumvar' `over'
    local studt = invttail(e(N_psu)-e(N_strata),(1-`svylevel'/100)/2)
    mat svymain = e(V)
    mat raw = e(b)
    $dots

    if ($oneway==0) {
        $dots
        $debug svy, subpop(`touse'): mean `svy_sumvar' if `v'<., over(`hvar') 
        mat svyrow = e(V)
        mat rawrt = e(b)
        $dots
        $debug svy, subpop(`touse'): mean `svy_sumvar' if `hvar' <., over(`v') 
        mat svycol = e(V)
        mat rawct = e(b)
        $dots
        $debug svy, subpop(`touse'): mean `svy_sumvar' if `v'<. & `hvar' <.,
        mat gmean = e(b)
        mat svygmean = e(V)
        $dots
    }
    else {
        $dots
        $debug svy, subpop(`touse'): mean `svy_sumvar' if `v'<.,
        mat gmean = e(b)
        mat svygmean = e(V)
        $dots
    }
    
    $debug ta `v' `hvar' $n_wt if `touse', matcell(obs) ///
            matrow(rowvals) `colmat' 
    local row = r(r)        
    local col = r(c)
    
    $dots
    mata: svy_mean(`row',`col',$oneway)
    $dots
    mata: svy_meanse(`row',`col',$oneway)
    $dots
    mata: meancis(`studt')
    $dots
    mata: build_nmats("obs")
    $dots
end

*------------------------ summary tables as twoway (not svy) ----------------
program sum_twoway
    args  v hvar weightstr1 weightstr2 colmat statkind statvar touse
    
    $debug ta `v' `hvar' $n_wt if `touse', matcell(obs) ///
                matrow(rowvals) `colmat'
            
    local r = rowsof(obs)       
    local c = colsof(obs)
    mat mstat = J(`r',`c',0)
    mat rhs = J(`r',1,0)
    mat bot = J(1,`c',0)
    mat gm = J(1,1,0)
    local mtype = "mstat"
    forval x = 1/`r' {
        forval y = 1/`c' {
        local hvalnum = colvals[1,`y']
        local vvalnum = rowvals[`x',1]
        do_statres `statkind'  `statvar' ///
            `v' `hvar' `vvalnum' `hvalnum' ///
            `weightstr1' `weightstr2' `mtype' `touse'
        mat mstat[`x',`y'] = real(r(statres))
        }
    }
    local mtype = "rhs"
    forval x = 1/`r' {
        local vvalnum = rowvals[`x',1]
        local hvalnum = 0
        do_statres `statkind'  `statvar' ///
            `v' `hvar' `vvalnum' `hvalnum' ///
            `weightstr1' `weightstr2' `mtype' `touse'
        mat rhs[`x',1] = real(r(statres))   
    }
    local mtype = "bot"
    forval y = 1/`c' {
        local hvalnum = colvals[1,`y']
        local vvalnum = 0
        do_statres  `statkind'  `statvar' ///
            `v' `hvar' `vvalnum' `hvalnum' ///
            `weightstr1' `weightstr2' `mtype' `touse'
        mat bot[1,`y'] = real(r(statres))   
    }
    local mtype = "gm"
        local vvalnum = 0
        local hvalnum = 0
        do_statres `statkind'  `statvar' ///
            `v' `hvar' `vvalnum' `hvalnum' ///
            `weightstr1' `weightstr2' `mtype' `touse'
        mat gm[1,1] = real(r(statres))  

    mat mstat = mstat , rhs
    mat bot = bot, gm
    mat raw = mstat \ bot
    mata: build_nmats("obs")
end

*--------- summary tables oneway ie. multiple stats (not svy) -----------

program sum_oneway
    args  contents v weightstr1 weightstr2 touse
    
    $debug ta `v' $n_wt if `touse', matcell(obs) ///
            matrow(rowvals)
    local r = rowsof(obs)
    local hvar = "_xx_ph_xx_"
    local c : word count `contents'
    local s = `c'/2
    tokenize `contents'
    forval j = 1/`s' {
        local statkind = "`1'"
        local statvar = "`2'"
        mat m`j' = J(`r',1,0)
        mat t`j' = J(1,1,0)
        local mtype = "onew"
        forval x = 1/`r' {
            local vvalnum = rowvals[`x',1]
            local hvalnum = 0
            do_statres `statkind'  `statvar' ///
                `v' `hvar' `vvalnum' `hvalnum' ///
                `weightstr1' `weightstr2' `mtype' `touse'
            mat m`j'[`x',1] = real(r(statres))  
        }
        local mtype = "onet"
        local vvalnum = 0
        local hvalnum = 0
        do_statres `statkind'  `statvar' ///
            `v' `hvar' `vvalnum' `hvalnum' ///
            `weightstr1' `weightstr2' `mtype' `touse'
        mat t`j'[1,1] = real(r(statres))
        mat full`j' = m`j' \ t`j'
        if (`j'==1) mat raw = full`j'
            else mat raw = raw, full`j'
            
    mac shift 2     
    }
    mata: build_nmats("obs")
end


program do_statres , rclass
    args statkind  statvar v hvar ///
        vvalnum hvalnum weightstr1 weightstr2 mtype touse
    
    local wtstr = cond("`weightstr1'"=="none","","[`weightstr1'`weightstr2']")
    if ("`statkind'"=="uwsum") {
        local wtstr = ""
        local statkind = "sum"
    }
    if "`statkind'" == "median" local statkind "p50" 
    if "`statkind'" == "count" local statkind "N"
    if ("`mtype'"=="mstat") ///
        qui sum `statvar' `wtstr' if `touse' ///
            & `v' == `vvalnum' & `hvar' == `hvalnum', detail
    else if ("`mtype'"=="rhs") ///
        qui sum `statvar' `wtstr' if `touse' /// 
            & `v' == `vvalnum' & !mi(`hvar'), detail
    else if ("`mtype'"=="bot") ///
        qui sum `statvar' `wtstr' if `touse' /// 
            & !mi(`v') & `hvar' == `hvalnum', detail
    else if ("`mtype'"=="gm") ///
        qui sum `statvar' `wtstr' if `touse' /// 
            & !mi(`v') & !mi(`hvar'), detail
    else if ("`mtype'"=="onew") ///
        qui sum `statvar' `wtstr' if `touse' /// 
            & `v' == `vvalnum' , detail
    else if ("`mtype'"=="onet") ///
        qui sum `statvar' `wtstr' if `touse' /// 
            & !mi(`v') , detail     
        if "`statkind'" == "iqr" local statres = r(p75)-r(p25)
        else if "`statkind'" == "r9010" local statres = r(p90)/r(p10)
        else if "`statkind'" == "r9050" local statres = r(p90)/r(p50)
        else if "`statkind'" == "r7525" local statres = r(p75)/r(p25)
        else if "`statkind'" == "r1050" local statres = r(p10)/r(p50)
        else local statres = r(`statkind')
    return local statres "`statres'"
end
    
*--------------- prepare for sending to mata output routines --------------

program do_write
    args v hvar format 
    
    if $oneway==1 local hvar = ""   
    if $oneway==0 {
        local colname : value label `hvar'
        global hvarname : variable label `hvar'
    }
    local rowname : value label `v'
    global vvarname : variable label `v'
    local clab = "$clab"
    local layout = "$layout"
    mata: do_output($oneway,$numcat,$do_n,$do_svy)
end

program sum_write
    args v hvar format contents
    
    if $oneway==1 local hvar = ""   
    if $oneway==0 {
        local colname : value label `hvar'
        global hvarname : variable label `hvar'
    }
    local rowname : value label `v'
    global vvarname : variable label `v'
    local clab = "$clab"
    mata: sum_output($oneway,$do_n)
end



program texfix
    local bad = "$ & _ % ^"
    tokenize `bad'
    local tot = "$vtotal"
    forval x = 1/5 {
        if (strpos("$vtotal","``x''")~=0) ///
            local tot = subinstr("$vtotal","``x''","\\``x''",.)
    }
    global vtotal= "`tot'"
end


*------------------------ clearglobs -------------------------
program clearglobs

capture mac drop angle          
capture mac drop botinsert      
capture mac drop caplab 
capture mac drop cappos 
capture mac drop category
capture mac drop chkwtnone
capture mac drop cisep          
capture mac drop clab           
capture mac drop colpos
capture mac drop colwide        
capture mac drop css            
capture mac drop cwidth            
capture mac drop debug          
capture mac drop delim          
capture mac drop do_body        
capture mac drop do_border
capture mac drop do_botbody
capture mac drop do_caption
capture mac drop do_compile
capture mac drop do_custombot
capture mac drop do_customtop
capture mac drop do_hlines           
capture mac drop do_hright           
capture mac drop do_land           
capture mac drop do_n           
capture mac drop do_nnoc        
capture mac drop do_plines           
capture mac drop do_pop
capture mac drop do_open
capture mac drop do_pseudo      
capture mac drop do_sort         
capture mac drop do_stars
capture mac drop do_stats       
capture mac drop do_sum         
capture mac drop do_svy
capture mac drop do_tleft                    
capture mac drop do_top         
capture mac drop do_topbody
capture mac drop doctype
capture mac drop dots
capture mac drop dotss
capture mac drop dpcomma
capture mac drop dropc            
capture mac drop droph            
capture mac drop dropr            
capture mac drop dropv            
capture mac drop exists
capture mac drop family       
capture mac drop finaltot       
capture mac drop fn
capture mac drop fontsize       
capture mac drop fpass          
capture mac drop Fslab
capture mac drop fstem
capture mac drop Fval
capture mac drop h1             
capture mac drop h2             
capture mac drop h3             
capture mac drop h1c             
capture mac drop h2c             
capture mac drop h3c             
capture mac drop hright         
capture mac drop htotal         
capture mac drop hvarname       
capture mac drop layout         
capture mac drop lpass          
capture mac drop ltrim         
capture mac drop lwidth            
capture mac drop mainfile       
capture mac drop mi
capture mac drop money          
capture mac drop n_lab 
capture mac drop n_offset
capture mac drop n_pos          
capture mac drop n_wt          
capture mac drop nlevels         
capture mac drop nocib          
capture mac drop noseb          
capture mac drop ntc          
capture mac drop numcat         
capture mac drop oneway         
capture mac drop panelnum
capture mac drop paper
capture mac drop pform
capture mac drop plab
capture mac drop plugc
capture mac drop plugcounter          
capture mac drop pluglab
capture mac drop plugr          
capture mac drop plugsymbol
capture mac drop postfile       
capture mac drop ppos
capture mac drop prefile        
capture mac drop ps             
capture mac drop pval
capture mac drop replace
capture mac drop rmfamily
capture mac drop rowpos
capture mac drop sheetname
capture mac drop show           
capture mac drop showtot 
capture mac drop single         
capture mac drop slab
capture mac drop spacer1
capture mac drop spacer2
capture mac drop ssf       
capture mac drop ssfamily       
capture mac drop stats
capture mac drop stform
capture mac drop stpos
capture mac drop style          
capture mac drop sval
capture mac drop texapp
capture mac drop texdef
capture mac drop texreps
capture mac drop title
capture mac drop tfont          
capture mac drop topinsert      
capture mac drop twidth
capture mac drop units
capture mac drop vtotal         
capture mac drop vvarname       
capture mat drop      CE
capture mat drop      CO
capture mat drop      CU
capture mat drop      FR
capture mat drop      gm
capture mat drop      LB
capture mat drop      m1
capture mat drop      m2
capture mat drop      m3
capture mat drop      m4
capture mat drop      m5
capture mat drop      RO
capture mat drop      SE
capture mat drop      SV
capture mat drop      t1
capture mat drop      t2
capture mat drop      t3
capture mat drop      t4
capture mat drop      t5
capture mat drop      UB
capture mat drop     bot
capture mat drop     OBS
capture mat drop     obs
capture mat drop     raw
capture mat drop     rhs
capture mat drop    COBS
capture mat drop    ROBS
capture mat drop   check
capture mat drop   full1
capture mat drop   full2
capture mat drop   full3
capture mat drop   full4
capture mat drop   full5
capture mat drop   gmean
capture mat drop   mstat
capture mat drop   PCOBS
capture mat drop   rawct
capture mat drop   rawrt
capture mat drop  svycol
capture mat drop  svyrow
capture mat drop colvals
capture mat drop rowvals
capture mat drop svygmean
capture mat drop svymain



end

*======================== mata sub routines ========================

version 9.2
mata:

struct stystruct { 
    string scalar /// 
    fullline, h1line, h2line, h3line, ///
    startline, endline, fullwidth, ///
    prefirst, pre, post, rbeg, rend, ///
    h1beg, h1mid, h1midend, h1end, ///
    h2beg, h2mid, h2midend, h2end, ///
    h3beg, h3mid, h3midend, h3end, ///
    statsbeg, statsmid, statsend
}

struct fontstruct {
    string scalar ///
    fontsize, family, rmfamily, ssfamily, font
}

struct prepoststruct {
    string scalar ///
    prefile, topinsert, ///
    postfile, botinsert, ps, delim
}


/* ------------------- data building for basic tables ------------ */

void build_mats (real scalar oneway)
{
    RM = st_matrix("raw")
     FR = counts(RM)
    if (oneway==1) FR = exvector(FR)
     CE = J(rows(FR),cols(FR),0)
     RO = J(rows(FR),cols(FR),0)
     CO = J(rows(FR),cols(FR),0)
     CU = J(rows(FR),cols(FR),.)
     for (i=1; i<=rows(FR); i++) {
        h = i-1
          for (j=1; j<=cols(FR); j++) {
               CE[i,j] = FR[i,j] / FR[rows(FR),cols(FR)] * 100
               RO[i,j] = FR[i,j] / FR[i,cols(FR)] * 100
            CO[i,j] = FR[i,j] / FR[rows(FR),j] * 100
               if (i==1) CU[i,j] = CO[i,j] 
                else if (i<rows(FR)) CU[i,j] = CU[h,j] + CO[i,j]
        }
     }
    st_matrix("FR",FR)
    st_matrix("CE",CE)
    st_matrix("CO",CO)
    st_matrix("RO",RO)
    st_matrix("CU",CU)
}
 


/* ------------------ svy data building routines ------------------ */


void svy_mean   (real scalar r, ///
            real scalar c, ///
            real scalar oneway)
{   
    real matrix SV

    RM = st_matrix("raw")
    OB = st_matrix("obs")
    GM = st_matrix("gmean")
    if (oneway==0){ 
        RT = st_matrix("rawrt")
        CT = st_matrix("rawct")

        SV = J(r,c,0)
        k = 1
        for (i=1; i<=rows(OB); i++) {
            for (j=1; j<=cols(OB); j++) {
                if (OB[i,j]~=0) SV[i,j] = RM[1,k++]
                    else SV[i,j] = .
            }
        }
        CT = CT'
        if (rows(SV)==rows(CT)) SV = SV , CT
        RT = RT, GM
        if (cols(SV)==cols(RT)) SV = SV \ RT
    }
    else {
        GM = st_matrix("gmean")
        SV = RM'
        SV = SV \ GM
    }
    st_matrix("SV",SV)
}

void svy_meanse (real scalar r, /// 
            real scalar c, ///
            real scalar oneway)
                
{
    M = st_matrix("svymain")
    M = diagonal(M)
    OB = st_matrix("obs")
    GM = st_matrix("svygmean")
    if (oneway==0){
        C = st_matrix("svycol")
        C = diagonal(C)
        R = st_matrix("svyrow")
        R = diagonal(R)
        SE = J(r,c,0)
        k = 1
        for (i=1; i<=rows(OB); i++) {
            for (j=1; j<=cols(OB); j++) {
                if (OB[i,j]~=0) SE[i,j] = M[k++,1]
                    else SE[i,j] = .
            }
        }
        if (rows(SE)==rows(C)) SE = SE , C
        R = R'
        R = R, GM
        if (cols(SE)==cols(R)) SE = SE \ R 
    }
    else {
        G = st_matrix("svygmean")
        SE = M \ G
    }
    SE = sqrt(SE)
    st_matrix("SE",SE)
}     


void meancis    (real scalar studt)

{
    SE = st_matrix("SE")
    SV = st_matrix("SV")
    LB = J(rows(SE),cols(SE),0)
    UB = J(rows(SE),cols(SE),0)
    h = rows(SE)
    w = cols(SE)
    for (i=1; i<=rows(SE); i++) {
        for (j=1; j<=cols(SE); j++) {
            d = SV[i,j]
            se = SE[i,j]
            LB[i,j] = d - studt*se
            UB[i,j] = d + studt*se
        }
    }
    st_matrix("LB",LB)
    st_matrix("UB",UB)
}


void svy_rowcol     (real scalar porp, ///
                real scalar r, ///
                real scalar c)
{   
     RM = st_matrix("raw")
     RT = st_matrix("rawrt")
    CT = st_matrix("rawct")
    r = r+1
    type = st_local("svycat")
    if (type=="row") {
        SV = RM, RT
        SV = rowshape(SV,r)
        TT = J(r,1,1) 
        SV = SV, TT
    }
    else if (type=="col") {
        SV = colshape(RM,c)
        CT = CT'
        SV = SV, CT
        c = c+1
        TT = J(1,c,1)
        SV = SV \ TT
    }
    SV = SV*porp
    st_matrix("SV",SV)
}
    

void svy_col    (real scalar porp, ///
            real scalar r, ///
            real scalar c)
{   
     RM = st_matrix("raw")
    CT = st_matrix("rawct")
    c = c+1
    SV = colshape(RM,c)
    CT = CT'
    SV = SV, CT
    c = c+1
    TT = J(1,c,1)
    SV = SV \ TT
    SV = SV*porp
    st_matrix("SV",SV)
}



void svy_cell   (real scalar porp, ///
            real scalar c)
{
    RM = st_matrix("raw")
    RM = colshape(RM,c)
    C = rowsum(RM)
     R = colsum(RM)
    type = st_local("svycat")
     if (type=="count") T = rgtotal(R) 
        else T = 1
     M = RM,C
     BR = R,T
     SV = M \ BR
    SV = SV*porp
    st_matrix("SV",SV)
}     

void svy_oneway (real scalar porp) ///
            
{
    RM = st_matrix("raw")
    RM = colshape(RM,1)
    type = st_local("svycat")
     if (type=="count") T = cgtotal(RM) 
        else T = 1
     SV = RM \ T
     SV = SV*porp
    st_matrix("SV",SV)
}     

void svy_se (real scalar porp, ///
            real scalar r, ///
            real scalar c)
                
{
    M = st_matrix("svymain")
    M = diagonal(M)
    M = colshape(M,c)
    C = st_matrix("svycol")
    C = diagonal(C)
    R = st_matrix("svyrow")
    R = diagonal(R)
    R = rowshape(R,1)
     T = 1
    type = st_local("svycat")
     if (type=="row"){
        for (i=1; i<=rows(C); i++) {
            C[i,1]=.
        }
    }
    else if (type=="col") {
        for (j=1; j<=cols(R); j++) {
            R[1,j]=.
        }
    }
    SE = M,C
     BR = R,T
     SE = SE \ BR
    SE = sqrt(SE)
    SE[r+1,c+1] = .
    SE = SE*porp
    st_matrix("SE",SE)
}     


void svy_se_oneway  (real scalar porp, ///
                real scalar r)
{
    M = st_matrix("svymain")
    SE = diagonal(M)
    T = .
    SE = SE \ T
    SE = sqrt(SE)
    SE = SE*porp
    st_matrix("SE",SE)
}     


void cis    (real scalar porp, ///
        real scalar studt, ///
        string scalar type)
{
    SE = st_matrix("SE")
    SV = st_matrix("SV")
    LB = J(rows(SE),cols(SE),0)
    UB = J(rows(SE),cols(SE),0)
    h = rows(SE)
    w = cols(SE)
    for (i=1; i<=rows(SE); i++) {
        for (j=1; j<=cols(SE); j++) {
            if (type=="count") {
                d = SV[i,j]
                se = SE[i,j]
                LB[i,j] = d - studt*se
                UB[i,j] = d + studt*se
            }
            else {
                d = SV[i,j]
                se = SE[i,j]
                if (porp==100) d = d/100 
                LB[i,j] = porp/(1 + exp(-(log(d/(1-d)) ///
                    - studt*se/(porp*d*(1-d)))))
                UB[i,j] = porp/(1 + exp(-(log(d/(1-d)) ///
                    + studt*se/(porp*d*(1-d)))))
            }
        }
    }
    if (type=="count") {
        LB[h,w] = .
        UB[h,w] = .
    }
    st_matrix("LB",LB)
    st_matrix("UB",UB)
}


/* ----------------- n option data matrices --------------------- */

void build_nmats (string scalar obs)
{
    RM = st_matrix(obs)
    OBS = counts(RM)
    c = cols(OBS)
    r = rows(OBS)
    ROBS = OBS[r,.]
    COBS = OBS[.,c]
    PCOBS = trunc(colperc(COBS))
    st_matrix("ROBS",ROBS)
    st_matrix("COBS",COBS)
    st_matrix("PCOBS",PCOBS)
    st_matrix("OBS",OBS)
}     


/* ------- output matrices standard (incl svy) --------------------- */

void do_output (real scalar oneway, ///
            real scalar numcat, ///
            real scalar do_n, ///
            real scalar do_svy)

{
    do_ci = 0
    do_pseudo = strtoreal(st_global("do_pseudo"))
    htotal = st_global("htotal")
    vtotal = st_global("vtotal")
    
    categ = st_global("category")
    if (do_n==1) { 
        COBS = st_matrix("COBS")
        ROBS = st_matrix("ROBS")
        npos = st_global("n_pos")
        nlab = st_global("n_lab")
        noffset = strtoreal(st_global("n_offset"))
        do_nnoc = strtoreal(st_global("do_nnoc"))
		dpcomma = st_global("dpcomma")				
		if (do_nnoc==0) nform = "%14"+dpcomma+"0fc"
            else nform = "%14"+ dpcomma + "0f"
    }
    if (do_svy==0) {
        DP = (&st_matrix("FR"), &st_matrix("CE"), &st_matrix("CO"), ///
            &st_matrix("RO"), &st_matrix("CU"))
        LIST = ("FR", "CE", "CO", "RO", "CU" \ "1", "2", "3", "4", "5")
        CAT = tokens(categ)
    }
    else {
        DP = (&st_matrix("SV"), &st_matrix("SE"), &st_matrix("LB"), ///
            &st_matrix("UB"))
        LIST = ("SV", "SE", "LB", "UB" \ "1", "2", "3", "4")
        
        if (strpos(categ,"CI") ~=0) {
            categ = subinstr(categ,"CI","LB UB")
            do_ci = 1
            st_numscalar("do_ci", do_ci)
        }
        CAT = tokens(categ)
        CAT[1,1] ="SV"
    }
    
        
    FORMAT = tokens(st_local("format"))
    clab = st_local("clab")
    CLAB = tokens(clab)
    TEMP = CLAB
    if (clab~="") CLAB = subinstr(TEMP,"_"," ",.)
    if (do_ci==1)   numcat = numcat+1
    FORMAT = fixgaps(FORMAT,numcat)
    CLAB = fixgaps(CLAB,numcat)

    DOUBLEF = extraformat(FORMAT)
    FORMAT = DOUBLEF[1,.]
    EXTRA = DOUBLEF[2,.]
    for (j=1; j<=cols(FORMAT); j++) {
        formout = FORMAT[1,j]
        formback = fixformat(formout)
        FORMAT[1,j] = formback
    }
    
    ENTRY = CAT \ FORMAT \ EXTRA \CLAB
    CCOUNT = J(1,cols(ENTRY),"")
    for (j=1; j<=cols(ENTRY); j++) {
        for (i=1; i<=cols(LIST); i++) {
            if (ENTRY[1,j]==LIST[1,i]) ///
                CCOUNT[1,j] = LIST[2,i]
        }
    }
    ENTRY = ENTRY \ CCOUNT
    for (j=1; j<=cols(ENTRY); j++) {
        if (ENTRY[5,j]=="") { 
            ""
            "One of your cell entries is invalid"
            exit(0)
        }
    }
    
    layout = st_local("layout")
    fpass = 1
    k = 1
    if (do_ci==0){ 
        for (j=1; j<=cols(ENTRY); j++) {
            i = strtoreal(ENTRY[5,j])       
            M = *DP[i]
            numcols = cols(M)
            if (ENTRY[1,j]=="SE") do_se = 1
                else do_se = 0
            *DP[i] = ///
                makestr(M,ENTRY[2,j],ENTRY[3,j],do_se,do_pseudo,ENTRY[1,j])
            H3 = J(1,cols(M),ENTRY[4,j])
            if (layout=="col" | layout=="c_block" | layout=="r_block" ) ///
                *DP[i] = H3 \ *DP[i]
            k = k+1
            if (oneway==0) {
                HVARVALS = st_matrix("colvals")
                colname = st_local("colname")
                if (colname=="") HVARLABS = hvtostr(HVARVALS)
                    else    HVARLABS = st_vlmap(colname,HVARVALS)
                HVARLABS = HVARLABS , htotal
                *DP[i] = HVARLABS \ *DP[i]
            }
            finrows = rows(*DP[i])
            if (layout=="c_block") {
                if (fpass==1) DATA = *DP[i]
                else DATA = DATA, *DP[i]
            }
            if (layout=="r_block") {
                if (fpass==1) DATA = *DP[i]
                else DATA = DATA \ *DP[i]
               
            }
            fpass = fpass+1
            
        }
    }
    else {
        slast = cols(ENTRY)-1
        last = cols(ENTRY)
        for (j=1; j<=cols(ENTRY); j++) {
            i = strtoreal(ENTRY[5,j])       
            p = strtoreal(ENTRY[5,slast])       
            q = strtoreal(ENTRY[5,last])        
            M = *DP[i]
            SLM = *DP[p]
            LM = *DP[q]
            numcols = cols(M)
            if (j<slast) {
                if (ENTRY[1,j]=="SE") do_se = 1
                    else do_se = 0
                *DP[i] = ///
                    makestr(M,ENTRY[2,j],ENTRY[3,j],do_se,do_pseudo,ENTRY[1,j])
                H3 = J(1,cols(M),ENTRY[4,j])
            }
            else {
                *DP[i] = make_cistr(SLM,LM,ENTRY[2,j],ENTRY[3,j])
                H3 = J(1,cols(M),ENTRY[4,j])
                j = last
            }
            if (layout=="col" | layout=="c_block" | layout=="r_block") ///
                *DP[i] = H3 \ *DP[i]
            k = k+1
            if (oneway==0) {
                HVARVALS = st_matrix("colvals")
                colname = st_local("colname")
                if (colname=="") HVARLABS = hvtostr(HVARVALS)
                    else    HVARLABS = st_vlmap(colname,HVARVALS)
                HVARLABS = HVARLABS , htotal
                *DP[i] = HVARLABS \ *DP[i]
            }
            finrows = rows(*DP[i])
            if (layout=="c_block") {
                if (fpass==1) DATA = *DP[i]
                    else DATA = DATA, *DP[i]
            }
            if (layout=="r_block") {
                if (fpass==1) DATA = *DP[i]
                    else DATA = DATA \ *DP[i]
            }
            fpass = fpass+1
        }
    }
    if (do_ci==1){
        nwide = cols(ENTRY)-1
        NENTRY = J(rows(ENTRY),nwide,"")
        for (i=1; i<=rows(ENTRY); i++) {
            for (j=1; j<=cols(NENTRY); j++) {
                NENTRY[i,j]=ENTRY[i,j]
            }
        }
    ENTRY = NENTRY
    }
    if (layout=="col") { 
        fpass = 1
        for (j=1; j<=numcols; j++) {
            for (k=1; k<=cols(ENTRY); k++) {
                i = strtoreal(ENTRY[5,k])
                M = *DP[i]
                if (fpass==1) DATA = M[.,j]
                    else DATA = DATA, M[.,j]
                fpass = fpass+1
            }
        }
    }
    RVALS = st_matrix("rowvals")
    rowname = st_local("rowname")
    if (rowname=="") RLABELS = vvtostr(RVALS)
        else    RLABELS = st_vlmap(rowname,RVALS)
    RLABELS = RLABELS \ vtotal
    ORIGLABELS = RLABELS
    if (do_n==1) {
        if (npos=="tufte") ///
            RLABELS = add_nlab(RLABELS,PCOBS,1,nlab,nform)
            else if (npos=="lab") ///
                RLABELS = add_nlab(RLABELS,COBS,0,nlab,nform)
    }
    if (layout=="row") { 
        fpass = 1
        if (oneway==0) stpt=2
            else stpt=1
        for (j=stpt; j<=finrows; j++) {
            for (k=1; k<=cols(ENTRY); k++) {
                i = strtoreal(ENTRY[5,k])
                M = *DP[i]
                if (fpass==1) DATA = M[j,.]
                    else DATA = DATA \ M[j,.]
                fpass = fpass+1
            }
        }
        LABS = ENTRY[4,.]
        FINLABS = addlab_torow(RLABELS,LABS)
        DATA = FINLABS, DATA
        if (oneway==1) {
            BLANKS = J(1,numcols,"")
            TOPROW = "#H2", BLANKS
            NEXTROW = "#H3", BLANKS
        }
        else {
            TOPROW = "#H2", HVARLABS
            BLANKS = J(1,cols(HVARLABS),"")
            NEXTROW = "#H3", BLANKS
        }
        DATA = TOPROW \ NEXTROW \ DATA
    }
    if (layout=="col" | layout=="c_block" | layout=="r_block") {
        RLABELS = "#H2" \ "#H3" \ RLABELS
        if (oneway==1) {
            BLANKS = J(1,cols(DATA),"")
            DATA = BLANKS \ DATA
        }
        if (layout=="r_block") {
            if (do_n==1) { 
                k = rows(COBS)+2
                BLANKCOBS = J(k,1,-1)
            }
            if (oneway==1) ADDLABELS = "#H3" \ ORIGLABELS
            else ADDLABELS = "#H2" \ "#H3" \ ORIGLABELS
            p = 1
            counter = numcat
            while (p<counter) {
                if (do_n==1) COBS = COBS \ BLANKCOBS
                RLABELS = RLABELS \ ADDLABELS
                p = p+1
            }
        }
        DATA = RLABELS, DATA
    }
    if (do_svy==1 & (layout=="col" | layout=="c_block")) ///
        DATA = empty_col(DATA) 

    if (do_n==1) {
        if (npos=="col") ///
            DATA = build_ncol(DATA,COBS,nlab,numcat,layout,noffset,nform)
        else if (npos=="row") ///
                DATA = add_nrow(DATA,ROBS,nlab,numcat,layout,noffset, ///
                        nform,oneway)
        else if (npos=="both") {
            DATA = build_ncol(DATA,COBS,nlab, numcat,layout,noffset,nform)
            DATA = add_nrow(DATA,ROBS,nlab,numcat,layout,noffset,nform,oneway)
        }
    }
    DATA = strip_neg(DATA)
    DATA = strip_rows(DATA) 
    
    if (layout=="row") numrows=numcat
        else numrows = 1
    if (do_n==1 & (npos=="row" | npos=="both")) numrows = numrows+1     
    
    DATA = reshape_data(DATA)
    write_roadmap(DATA, oneway, numrows)
}

/* ----- output matrices for summary tables (except svy) ------------ */


void sum_output (real scalar oneway, ///
            real scalar do_n)

{
    htotal = st_global("htotal")
    vtotal = st_global("vtotal")
    if (do_n==1) {      
        npos = st_global("n_pos")
        nlab = st_global("n_lab")
        noffset = strtoreal(st_global("n_offset"))
        do_nnoc = strtoreal(st_global("do_nnoc"))
        dpcomma = st_global("dpcomma")
        if (do_nnoc==0) nform = "%14"+dpcomma+"0fc"
            else nform = "%14"+dpcomma+"0f"
    }
    
    RM = st_matrix("raw")
    numcols = cols(RM)
    FORMAT = tokens(st_local("format"))
    FORMAT = fixgaps(FORMAT,numcols)
    DOUBLEF = extraformat(FORMAT)
    FORMAT = DOUBLEF[1,.]
    EXTRA = DOUBLEF[2,.]
    for (j=1; j<=cols(FORMAT); j++) {
        formout = FORMAT[1,j]
        formback = fixformat(formout)
        FORMAT[1,j] = formback
    }
    if (oneway==0) DATA = makestr(RM,FORMAT[1,1],EXTRA[1,1],0,0,"NIL")
    else if (oneway==1) {
        for (j=1; j<=cols(RM); j++) {
            if (j==1) { 
                OM = RM[.,j]
                M = makestr(OM,FORMAT[1,j],EXTRA[1,j],0,0,"NIL")
                DATA = M
            }
            else {
                OM = RM[.,j]
                M = makestr(OM,FORMAT[1,j],EXTRA[1,j],0,0,"NIL")
                DATA = DATA, M
            }
        }
    }
    RVALS = st_matrix("rowvals")
    rowname = st_local("rowname")
    if (rowname=="") RLABELS = vvtostr(RVALS)
        else    RLABELS = st_vlmap(rowname,RVALS)
    RLABELS = RLABELS \ vtotal
    if (do_n==1) {
        if (npos=="tufte") ///
            RLABELS = add_nlab(RLABELS,st_matrix("PCOBS"),1,nlab,nform)
            else if (npos=="lab") ///
                RLABELS = add_nlab(RLABELS,st_matrix("COBS"),0,nlab,nform)
    }
    CELL = tokens(st_local("contents"))
    c = (cols(CELL))/2
    CELL1 = J(1,c,"")
    CELL2 = J(1,c,"")
    j = 1
    p = 1
    while (p<=cols(CELL1)) {
        k = j+1
        CELL1[1,p]= strproper(CELL[1,j])
        CELL2[1,p] = CELL[1,k]
        j = j+2
        p = p+1
    }
    clab = (st_local("clab"))
    if (clab~="") {
        CLAB = tokens(clab)
        CLAB = fixgaps(CLAB,numcols)
        H3LAB = CLAB
    }
    else {
        H3LAB = CELL2
    }
    
    if (oneway==1) {
            TOPROW =  CELL1
            NEXTROW =  H3LAB
        }
    else {
        HVARVALS = st_matrix("colvals")
        colname = st_local("colname")
        if (colname=="") HVARLABS = hvtostr(HVARVALS)
            else    HVARLABS = st_vlmap(colname,HVARVALS)
        HVARLABS = HVARLABS , htotal
        TOPROW = HVARLABS
        if (clab~="")   cstr = CLAB[1,1]+" "
            else cstr = CELL1[1,1]+"_"+CELL2[1,1]+" "
        NEXTROW = tokens(numcols*cstr)
    }
    
    TEMP = NEXTROW  
    NEXTROW = subinstr(TEMP,"_"," ",.) 
        
    DATA = TOPROW \ NEXTROW \ DATA
    RLABELS = "#H2" \ "#H3" \ RLABELS
    DATA = RLABELS, DATA
    
    if (do_n==1) {
        numcat = 0
        layout = "nil"
        if (npos=="col") ///
            DATA = build_ncol(DATA,st_matrix("COBS"),nlab, numcat, ///
                        layout,noffset,nform)
        else if (npos=="row") ///
                DATA = add_nrow(DATA,st_matrix("ROBS"),nlab,numcat, ///
                    layout,noffset,nform,oneway)
        else if (npos=="both") {
            DATA = build_ncol(DATA,st_matrix("COBS"),nlab, ///
                numcat,layout,noffset,nform)
            DATA = add_nrow(DATA,st_matrix("ROBS"),nlab, numcat, ///
                layout,noffset,nform,oneway)
        }
    }
    DATA = strip_neg(DATA)
    numrows = 1
    if (do_n==1 & (npos=="row" | npos=="both")) numrows = numrows+1     
    DATA = reshape_data(DATA)
    write_roadmap(DATA, oneway, numrows)
}



/* ------------------------------------------------------------- */
/* ------------- reshaping routines if needed ------------------ */
/* ------------------------------------------------------------- */
      

/*this is the master routine, which calls the other routines below 
sequence is important and routines are shown below in this sequence*/


function reshape_data( ///
    string matrix DATA)
{   

    currentpanel = st_global("panelnum")
    ROWS = (1..rows(DATA))
    COLS = (1..cols(DATA))
    plugc = st_global("plugc")
    plugr = st_global("plugr")
    dropc = st_global("dropc")
    dropr = st_global("dropr")
    stpos = st_global("stpos")

    if (plugc != "" | plugr != "") {
        if (st_global("show") == "prepost") DATA
        if (plugc != "") DATA = plug_cols(DATA, currentpanel, ROWS, COLS, plugc)   
        if (plugr != "") DATA = plug_rows(DATA, currentpanel, ROWS, COLS, plugr)   
        if (st_global("show") == "prepost") DATA
    }

    if (dropc != "" | dropr != "") {
        if (st_global("show") == "prepost") DATA
        if (dropc != "") DATA = drop_cols(DATA, currentpanel, ROWS, COLS, dropc)   
        if (dropr != "") DATA = drop_rows(DATA, currentpanel, ROWS, COLS, dropr)   
        if (st_global("show") == "prepost") DATA
    }
    if (strtoreal(st_global("do_stats")) == 1)  {
        statsmat = stats_matrix(DATA, stpos)
        if (stpos == "col") DATA = DATA, statsmat
            else DATA = DATA \ statsmat
    }
    return(DATA)
}

function plug_cols( ///
    string matrix DATA, ///
    string scalar currentpanel, ///
    real matrix ROWS, ///
    real matrix COLS, ///
    string scalar plugc) 
{
    pluglab = st_global("pluglab")
    plugsymbol = st_global("plugsymbol")
    if (plugsymbol == "BLANK") plugsymbol = " "
    if (st_global("show") == "prepost") DATA
    plugcs = tokens(plugc, " ")
    k = length(plugcs)
    BLANKCOL = J(length(ROWS), 1, plugsymbol)
    for (i=1; i<=k; i++) { 
        breaker =  strpos(plugcs[i], ":")
        if (breaker > 0) {
            plugcpanel = substr(plugcs[i], 1, breaker - 1)
            plugcols = strtoreal(substr(plugcs[i], breaker + 1, .))
            if (currentpanel==plugcpanel) {
                NEWDATA = DATA[,1]
                for (j=2; j<=cols(DATA); j++) {
                    if (anyof(plugcols, j) > 0) {
                        NEWDATA = NEWDATA , BLANKCOL
                    }
                    NEWDATA = NEWDATA , DATA[, j]
                }
            DATA = NEWDATA
            }
        }  
    }
    return(DATA)
}

function plug_rows( ///
    string matrix DATA, ///
    string scalar currentpanel, ///
    real matrix ROWS, ///
    real matrix COLS, ///
    string scalar plugr) 
{
    pluglab = st_global("pluglab")
    plugsymbol = st_global("plugsymbol")
    if (plugsymbol=="BLANK") plugsymbol = " "
    if (st_global("show") == "prepost") DATA
    plugrs = tokens(plugr, ",")
    k = length(plugrs)
    BLANKROW = J(1, length(COLS), plugsymbol)
    for (i=1; i<=k; i++) { 
        splitter =  strpos(plugrs[i], ":")
        if (splitter > 0) {
            plugrpanel = substr(plugrs[i], 1, splitter - 1)
            plugrows = strtoreal(substr(plugrs[i], splitter + 1, .))
            if (currentpanel==plugrpanel) {
                NEWDATA = DATA[1,]
                for (j=2; j<=length(ROWS); j++) {
                    if (anyof(plugrows, j) > 0) {
                        NEWDATA = NEWDATA \ BLANKROW
                        if (pluglab !="") {
                            counter = st_numscalar("plugcounter")
                            labels = tokens(pluglab)
                            labels = subinstr(labels,"_"," ")
                            if (counter <= length(labels)) NEWDATA[j, 1] = labels[counter]
                            counter = counter + 1
                            st_numscalar("plugcounter", counter)
                        }
                    }
                    NEWDATA = NEWDATA \ DATA[j, ] 
                }
                DATA = NEWDATA
            }
        }  
    }
    return(DATA)
}

function drop_cols( ///
    string matrix DATA, ///
    string scalar currentpanel, ///
    real matrix ROWS, ///
    real matrix COLS, ///
    string scalar dropc)
{
    dropcols = strtoreal(tokens(dropc, " "))
    newcols = 1
    for (j=2; j<=length(COLS); j++) {
        if (anyof(dropcols, j) == 0)  newcols = newcols , j
    }
    COLS = newcols
    DATA = DATA[ROWS, COLS]
    return(DATA)
}
    
function drop_rows( ///
    string matrix DATA, ///
    string scalar currentpanel, ///
    real matrix ROWS, ///
    real matrix COLS, ///
    string scalar dropr)
{
    rowlist = tokens(dropr, " ")
    k = length(rowlist)
    for (i=1; i<=k; i++) { 
        breaker =  strpos(rowlist[i], ":")
        if (breaker > 0) {
            drpanel = substr(rowlist[i], 1, breaker - 1)
            droprows = strtoreal(substr(rowlist[i], breaker + 1, .))
            if (currentpanel==drpanel) {
                newrows = 1
                for (j=2; j<=length(ROWS); j++) {
                    if (anyof(droprows, j) == 0) ///
                    newrows = newrows , j
                }
            ROWS = newrows
            }
        }  
    }
    DATA = DATA[ROWS, COLS]
    return(DATA)
}    

function stats_matrix( ///
    string matrix DATA, ///
    string scalar stats_pos) 
{
    do_stars = strtoreal(st_global("do_stars"))
    do_svy = strtoreal(st_global("do_svy"))
    ppos = st_global("ppos")
    slab = st_global("slab")
    plab = st_global("plab")
    sval = st_global("sval")
    pval = st_global("pval")
    /*if using svy chi2*/
    Fslab = st_global("Fslab")
    Fval = st_global("Fval")
    spacer1 = st_global("spacer1")
    spacer2 = st_global("spacer2")

    if (do_stars==1) {
        rval = strtoreal(pval)
        if (rval <= 0.001) pval = "***"
        else if (rval > 0.001 & rval <= 0.01) pval = "**"
        else if (rval > 0.001 & rval <= 0.01) pval = "**"
        else if (rval > 0.01 & rval <= 0.05) pval = "*"
        else pval = "."
    }

    if (stats_pos == "col") {
        if (ppos=="beside") {
            statsmat = J(rows(DATA), 2, "")
            statsmat[1, 1] = slab
            statsmat[3, 1] = sval
            if (do_svy == 1) statsmat[4, 1] = Fval
            statsmat[1, 2] = plab
            statsmat[3, 2] = pval
        }
        else if (ppos=="below") {
            statsmat = J(rows(DATA), 1, "")
            statsmat[1, 1] = slab
            statsmat[3, 1] = sval
            if (do_svy == 1) {
                statsmat[4, 1] = Fval
                statsmat[2, 1] = plab
                statsmat[5, 1] = pval
            }
            else {
                statsmat[2, 1] = plab
                statsmat[4, 1] = pval
            }
        }
        else if (ppos=="only") {
            statsmat = J(rows(DATA), 1, "")
            statsmat[1, 1] = plab
            statsmat[3, 1] = pval
        }
        else if (ppos=="none") {
            statsmat = J(rows(DATA), 1, "")
            statsmat[1, 1] = slab
            statsmat[3, 1] = sval
            if (do_svy == 1) statsmat[4,1] = Fval
        }
    }
    else if (stats_pos == "row") {
        if (ppos == "beside") {
            if (do_svy == 1) {
                statsmat = J(3, cols(DATA), "")
                statsmat[1, 1] = "!STATISTICS!"
                statsmat[1, 2] = "3"
                statsmat[2, 1] = slab + spacer1 + sval 
                statsmat[3, 1] = Fslab + spacer1 + Fval + spacer2 ///
                    + plab + spacer1 + pval
            }
            else {
                statsmat = J(2, cols(DATA), "")
                statsmat[1, 1] = "!STATISTICS!"
                statsmat[1, 2] = "2"
                statsmat[2, 1] = slab + spacer1 + sval + spacer2 ///
                    + plab + spacer1 + pval
            }
        }
        else if (ppos == "below") {
            if (do_svy == 1) {
                statsmat = J(4, cols(DATA), "")
                statsmat[1, 1] = "!STATISTICS!"
                statsmat[1, 2] = "4"
                statsmat[2, 1] = slab + spacer1 + sval
                statsmat[3, 1] = Fslab + spacer1 + Fval
                statsmat[4, 1] = plab + spacer1 + pval
            }
            else {
                statsmat = J(3, cols(DATA), "")
                statsmat[1, 1] = "!STATISTICS!"
                statsmat[1, 2] = "3"
                statsmat[2, 1] = slab + spacer1 + sval
                statsmat[3, 1] = plab + spacer1 + pval
            }
        }
        if (ppos=="only") {
            statsmat = J(2, cols(DATA), "")
            statsmat[1, 1] = "!STATISTICS!"
            statsmat[1, 2] = "2"
            statsmat[2, 1] = plab + spacer1 + pval
        }
        else if (ppos=="none") {
            if (do_svy == 1) {
                statsmat = J(3, cols(DATA), "")
                statsmat[1, 1] = "!STATISTICS!"
                statsmat[1, 2] = "3"
                statsmat[2, 1] = slab + spacer1 + sval
                statsmat[3,1] = Fslab + spacer1 + Fval    
            }
            else {
                statsmat = J(2, cols(DATA), "")
                statsmat[1, 1] = "!STATISTICS!"
                statsmat[1, 2] = "2"
                statsmat[2, 1] = slab + spacer1 + sval
            }
        }
    }
    return(statsmat)
}


void check_cols (string matrix X)
{
    check = st_matrix("check")
    p = cols(X)
    check = check, p
    st_matrix("check", check)
}


function empty_col(string matrix X)

{
    Z = X
    Y = Z[.,1]
    for (j=2; j<=cols(Z); j++) {
        empty = 1
        for (i=3; i<=rows(Z); i++) {
            if (Z[i,j]~="") empty = 0
        }
        if (empty==0)   Y = Y, Z[.,j]
    }
    return(Y)
}
        
        
        
function strip_rows (string matrix X)
{
    Z = X
    k = cols(Z)
    Y = J(2,k,"")
    for (i=1; i<=2; i++) {
        Y[i,.] = Z[i,.]
    }
    for (i=3; i<=rows(Z); i++) {
        if (Z[i,1]~="#H2") { 
            if (Z[i,1]=="#H3") Z[i,1] = ""
            Y = Y \ Z[i,.]
        }
    }
    return(Y)
}           
            
function strip_neg (string matrix X)
{
    p = rows(X)
    q = cols(X)
    Z = J(p,q,"")
    
    for (i=1; i<=rows(Z); i++) {
        for (j=1; j<=cols(Z); j++) {
            if (X[i,j]~="-999") Z[i,j] = X[i,j]
        }
    }
    return(Z)
}           



function hvtostr( real matrix X)
{
    string matrix Z
    
    Y = X
    Z = J(1,cols(Y),"")
    for (j=1; j<=cols(Y); j++) {
        Z[1,j] = strofreal(Y[1,j])
    }
    return(Z)
}

function vvtostr( real matrix X)
{
    string matrix Z
    
    Y = X
    Z = J(rows(Y),1,"")
    for (i=1; i<=rows(Y); i++) {
        Z[i,1] = strofreal(Y[i,1])
    }
    return(Z)
}



function addlab_torow(string matrix X, ///
                    string matrix Y)
{
    Y[1,1] = " "+Y[1,1]
    t = rows(X)*cols(Y)
    A = J(t,1,"")
    k = 1
    for (i=1; i<=rows(X); i++) {
        for (j=1; j<=cols(Y); j++) {
            if (j==1)   A[k++,1] = X[i,1] + Y[1,j]
            else A[k++,1] = Y[1,j]
        }
    }
    return(A)
}


function extraformat (string matrix Z)
{
    string matrix Y
    Y = J(2,cols(Z),"")
    for (j=1; j<=cols(Z); j++) {
        if (strpos(Z[1,j],"p")) { 
            a = subinstr(Z[1,j],"p","")
            Y[1,j] = a
            Y[2,j] = "p"
        }
        if (strpos(Z[1,j],"m")) { 
            a = subinstr(Z[1,j],"m","")
            Y[1,j] = a
            Y[2,j] = "m"
        }
        if (Y[1,j]=="") {
            Y[1,j] = Z[1,j] 
            Y[2,j] = "nil"
        }
    }
    return(Y)
}
        

function fixformat (string scalar Z)
{
    string scalar X
    dpcomma = st_global("dpcomma")	
    fmt = substr(Z,1,1)
    k = strpos(Z,"c")
    if (k~=0) X = "%14"+dpcomma+fmt+"fc"
        else X = "%14"+dpcomma+fmt+"f"
    return(X)   
}


function fixgaps (string matrix Z, ///
                real scalar numcols)
{
    X = Z
    c = cols(X)
    if (c<numcols) {
        d = numcols-c
        last = X[1,c]
        Y = J(1,d,last)
        X = X,Y
    }
    else if (c>numcols) {
        Y = J(1,numcols,"")
        for (j=1; j<=cols(Y); j++) {
            Y[1,j]=X[1,j]
        }
        X = Y
    }
    return(X)
}
            


function makestr (real matrix Z, ///
                string scalar form, ///
                string scalar extra, ///
                real scalar do_se, ///
                real scalar do_pseudo, ///
                string scalar ctype)
{
    string matrix X

    if (do_se==1) {
        noseb = strtoreal(st_global("noseb"))
        if (noseb==0) {
            lbrack = "("
            rbrack = ")"
        }
        else {
            lbrack = ""
            rbrack = ""
        }
    }
    if (do_pseudo==1) {
        nocib = strtoreal(st_global("nocib"))
        cisep = st_global("cisep")
        if (nocib==0) {
            lcbrack = "["
            rcbrack = "]"
        }
        else {
            lcbrack = ""
            rcbrack = ""
        }
    }
    money = st_global("money")
    X = J(rows(Z),cols(Z)," ")
    for (i=1; i<=rows(Z); i++) {
        for (j=1; j<=cols(Z); j++) {
            a = strofreal(Z[i,j],form)
            if (extra~="nil") {
                if (extra=="p") a = a + "%"
                else if (extra=="m") a = money + a 
            }
            X[i,j] = a
            if (do_se==1)   X[i,j] = lbrack+a+rbrack
            if (do_pseudo & ctype=="LB") X[i,j] = lcbrack+a+cisep   
            if (do_pseudo & ctype=="UB") X[i,j] = a+rcbrack
            if (Z[i,j]==.) X[i,j] = "" 
        }
    }
    return(X)
}



function make_cistr (real matrix Z, ///
                real matrix Y, ///
                string scalar form, ///
                string scalar extra)
{

    cisep = st_global("cisep")
    nocib = strtoreal(st_global("nocib"))
    if (nocib==0) {
        lcbrack = "["
        rcbrack = "]"
    }
    else {
        lcbrack = ""
        rcbrack = ""
    }
    money = st_global("money")
    X = J(rows(Z),cols(Z)," ")
    for (i=1; i<=rows(Z); i++) {
        for (j=1; j<=cols(Z); j++) {
            a = strofreal(Z[i,j],form)
            b = strofreal(Y[i,j],form)
            if (extra~="nil") {
                if (extra=="p") {
                    a = a + "%"
                    b = b + "%"
                }
                else if (extra=="m") {
                    a = money + a 
                    b = money + b
                }
            }
            X[i,j] = lcbrack+a+cisep+b+rcbrack
            if (Z[i,j]==. & Y[i,j]==.) X[i,j] = "" 
        }
    }
    return(X)
}

                    
function labcols (string scalar z, ///
                real scalar j) ///
{
    string rowvector X
    for (i=1; i<=j; i++) {
        X= X, z
    }
    return(X)
}
                

function labrows (string scalar z, ///
                real scalar j) ///
{
    string colvector X
    for (i=1; i<=j; i++) {
        X= X \ z
    }
    return(X)
}

/* -------------------- adding n to table------------------ */

function add_nlab   (string matrix X, ///
                real matrix Y, ///
                real scalar tufte, ///
                string scalar nlab, ///
                string scalar nform)
{
    if (tufte==1){ 
        LB = J(rows(X),1," (")
        RB = J(rows(X),1,"%)")
    }
    else {
        lbreak = strpos(nlab,"#")-1
        rbreak = strpos(nlab,"#")+1
        LB = " " + substr(nlab,1,lbreak)  
        RB = substr(nlab,rbreak,.) 
    }
    A = X:+LB
    B = A:+strofreal(Y,nform)
    Z = B:+RB
    return(Z)
}


function add_nrow   (string matrix X, ///
                real matrix Y, ///
                string scalar nlab, ///
                real scalar numcat, ///
                string scalar layout, ///
                real scalar noffset, ///
                string scalar nform, ///
                real scalar oneway)
{
    if (noffset>=numcat) noffset = numcat-1
    string rowvector A
    D = strofreal(Y,nform)
    if (oneway==1) D = D[1,1]
    if (layout=="c_block"){
        if (noffset==0){
            extra = (cols(X)-cols(D))-1 //need to allow for label
            EX = J(1,extra,"-999")
            B = D, EX
        }
        else {
            dnum = cols(D)
            fnum = cols(X)
            space = dnum*noffset
            remainder = fnum-(dnum+space+1) // need to allow for label
            B = J(1,space,"-999")
            B = B, D
            if (remainder!=0) {
                RE = J(1,remainder,"-999")
                B = B, RE
            }
        }
    }
    else if (layout=="col") {
        vlevels = strtoreal(st_global("nlevels")) + 1
        ncols = cols(X)-1
        B = J(1,ncols,"-999")
        gap = ncols / vlevels
        k = noffset+1
        for (j=1; j<=cols(D); j++) {
             B[1,k] = D[1,j]
             k = k + gap
        }
    }
    else {
        ncols = cols(X)-1
        B = J(1,ncols,"-999")
        for (j=1; j<=cols(D); j++) {
             B[1,j] = D[1,j]
        }
    }
    L = "@N@"+ texclean(nlab)
    B = L, B
    Z = X \ B
    return(Z)
}


function build_ncol (string matrix X, ///
                real matrix Y, ///
                string scalar nlab, ///
                real scalar numcat, ///
                string scalar layout, ///
                real scalar noffset, ///
                string scalar nform)
{               
    if (noffset>=numcat) noffset = numcat-1
    string colvector A
    A = strofreal(Y,nform)
    D = ""
    m = 0
    for (i=1; i<=rows(Y); i++) {
        if (Y[i,1]!=-1) {
            m = m+1
            if (m==1) D = A[i,1]
            else  D = D \ A[i,1]
        }
    }
    if (layout=="r_block"){
        if (noffset==0){
            B = J(2,1,"-999")
            B = B \ A
        }
        else {
            C = J(2,1,"-999")
            D = C \ D
            dnum = rows(D)
            fnum = rows(X)
            space = dnum*noffset
            remainder = fnum-(dnum+space)
            B = J(space,1,"-999")
            B = B \ D
            if (remainder!=0) {
                RE = J(remainder,1,"-999")
                B = B \ RE
            }
        }
    }
    else if (layout=="row"){
        nrows = rows(X)
        B = J(nrows,1,"-999")
        k = noffset+3
        for (i=1; i<=rows(D); i++) {
            B[k,1] = D[i,1]
            k = k + numcat
        }
    }
    else {
        B = J(2,1,"-999")
        B = B \ D
    }
    B[1,1] = nlab
    W = X,B
return(W)   
}
    


/* ------------------ misc routines ------------------------ */


function colperc (real matrix Z)
{
    X = J(rows(Z),1,0)
    for (i=1; i<=rows(X); i++) {
        X[i,1]=(Z[i,1]/Z[rows(Z),1])*100
    }
    return(X)
}

function rowperc (real matrix Z)
{
    X = J(1,cols(Z),0)
    for (i=1; i<=cols(X); i++) {
        X[1,i]=(Z[1,i]/Z[1,cols(Z)])*100
    }
    return(X)
}


function rgtotal (real matrix Z)
{
    X = 0
    for (j=1; j<=cols(Z); j++) {
            X = X + Z[1,j]
    }
    return(X)
}

function cgtotal (real matrix Z)
{
    X = 0
    for (i=1; i<=rows(Z); i++) {
            X = X + Z[i,1]
    }
    return(X)
}

function counts (real matrix Z)
{
     R = rowsum(Z)
     C = colsum(Z)
     T = sum(R)
     MR = Z,R
     BR = C,T
     X = MR \ BR
     return(X)
}     


function exvector (real matrix Z)
{
    X = J(rows(Z),1,0)
    for (i=1; i<=rows(X); i++) {
        X[i,1]=Z[i,1]
    }
    return(X)
}

/* -------------------- displaying the results ---------------------- */

void show_data (string matrix X)
{           
            
    finaltot = strtoreal(st_global("finaltot"))
    lpass = strtoreal(st_global("lpass"))
    
    if (finaltot==1 & lpass==1) show = 0
        else show = 1
    if (show==1) {
        colwide = strtoreal(st_global("colwide"))
        Z = X
        for (i=1; i<=rows(Z); i++) {
            Z[i,1] = substr(Z[i,1],1,colwide)
        }
        for (j=1; j<=cols(Z); j++) {
            for (i=1; i<=2; i++) {
                Z[i,j] = substr(Z[i,j],1,colwide)
            }
        }
        Z[1,1] = ""
        Z[2,1] = ""
    }
}

/* ----------------------------------------------------------------- */
/* ------------------ writing output to files ---------------------- */
/* ----------------------------------------------------------------- */

/*write_roadmap is the main routine for organising the writing out:
breaks into three sections: one for xls, one for docx and one for ascii. 
All xls and docx are done together, to minimise file open and close operations.
write_roadmap also calls the body and topbody routines, then the toptable 
routine, then the write_ascii routine, where the actual cell contents
are finally written. */

void write_roadmap( ///
    string matrix DATA, ///
    real scalar oneway, ///
    real scalar numrows)
{

    if (st_global("show")=="all") show_data(DATA)
    fpass = strtoreal(st_global("fpass"))
    lpass = strtoreal(st_global("lpass"))
    style = st_global("style")
    do_customtop = strtoreal(st_global("do_customtop"))
    do_body = strtoreal(st_global("do_body"))
    do_topbody = strtoreal(st_global("do_topbody"))
    do_custombot = strtoreal(st_global("do_custombot"))
    do_botbody = strtoreal(st_global("do_botbody"))
    do_border = strtoreal(st_global("do_border"))
    do_hlines = strtoreal(st_global("do_hlines"))
    do_plines = strtoreal(st_global("do_plines"))
    do_n = strtoreal(st_global("do_n"))
    do_tleft = strtoreal(st_global("do_tleft"))
    texreps = (cols(DATA) - 1)   * "Y "
    st_global("texreps", texreps)
    do_land = strtoreal(st_global("do_land"))
    do_caption = strtoreal(st_global("do_caption"))

    family = st_global("family")
    ssfamily = st_global("ssfamily")
    rmfamily = st_global("rmfamily")
    fontsize = st_global("fontsize")
    font = st_global("tfont") 

    struct fontstruct scalar fnt
    if (family == "") fnt.family = "Arial"
        else fnt.family = family
    if (family != "" & style == "tex") {   
        fnt.rmfamily = rmfamily
        fnt.ssfamily = ssfamily
    }
    if (fontsize =="") {
        if (style == "tex") fnt.fontsize = "10"
        if (style == "htm") fnt.fontsize = "12"
        if (style == "xls" | style == "xlsx") fnt.fontsize = "10"
        if (style == "docx") fnt.fontsize = "10"
    }
    else fnt.fontsize = fontsize
    fnt.font = font

    struct prepoststruct scalar prpst 
        prpst.prefile = st_global("prefile")
        prpst.topinsert = st_global("topinsert")
        prpst.postfile = st_global("postfile")
        prpst.botinsert = st_global("botinsert")
        prpst.ps = st_global("ps")
        prpst.delim = st_global("delim")

    datawidth = cols(DATA) - 1  // to ignore label column
    if (do_n == 1 & (st_global("n_pos") == "col" | //
        st_global("n_pos") == "both")) datawidth = datawidth - 1
    if  (st_global("stpos") == "col") {
           if (st_global("ppos") == "beside") datawidth = datawidth - 2
               else datawidth = datawidth - 1
    }
    st_numscalar("dwidth", datawidth)
    h1extra = (cols(DATA) - 1) - datawidth
    st_numscalar("h1extra", h1extra)

    if (style == "xls" | style == "xlsx") {
        write_xls(style, fpass, lpass, DATA, fnt, oneway, ///
        numrows, do_border, do_hlines, do_plines)
    }
    else if (style == "docx") {
        write_docx(style, fpass, lpass, DATA, fnt, oneway, ///
        numrows, do_border, do_hlines, do_plines, do_tleft)
    }
    else  {
        if (fpass == 1) {
            if (do_body==1 | do_topbody==1) write_topbody(style, fnt)
            if (do_customtop == 1) write_prepost(prpst, 1)
            write_toptable(style, fnt, do_border, do_land, ///
                do_caption, do_tleft, DATA)
        }
        write_ascii(DATA, fnt, oneway, numrows, style) 
        if (lpass == 1) {
            write_bottomtable(style, do_border, do_land, ///
                do_caption, do_tleft, fnt)
            if (do_custombot==1) write_prepost(prpst, 0)
            if (do_body==1 | do_botbody==1) write_bottombody(style)
        }
    }
    check_cols(DATA)
}

void write_xls( ///
    string scalar style, ///
    real scalar fpass, ///
    real scalar lpass, ///
    string matrix X, ///
    struct fontstruct fnt, ///
    real scalar oneway, ///
    real scalar numrows, ///
    real scalar do_border, ///
    real scalar do_hlines, ///
    real scalar do_plines)
{

    outfile = st_global("mainfile")
    title = st_global("title")
    h1 = st_global("h1")
    h2 = st_global("h2")
    h3 = st_global("h3")
    h1cols = st_global("h1c")
    h2cols = st_global("h2c")
    h3cols = st_global("h3c")
    hvarname = st_global("hvarname")
    vvarname = st_global("vvarname")
    showtot = strtoreal(st_global("showtot"))
    single = strtoreal(st_global("single"))
    do_hright = strtoreal(st_global("do_hright"))
    do_n = strtoreal(st_global("do_n"))
    indent = strtoreal(st_global("indent"))
    fn = st_global("fn")
    class xl scalar b 
    b = xl()
    if (fpass == 1) {
        if (do_hright == 0) cellpos = "center" 
                else cellpos = "right"
        if (oneway == 1 & h1 =="") {
            h1 = "nil"
        }
        if (oneway == 1 & h2 =="") {
            if (do_n == 1) X[2, cols(X)] = X[1, cols(X)]
            h2 = "nil"
        }
        sheetname = st_global("sheetname")
        currentrow = strtoreal(st_global("rowpos"))
        currentcol = strtoreal(st_global("colpos"))
        st_numscalar("currentrow", currentrow)
        st_numscalar("currentcol", currentcol)
        numcols = cols(X)
        dropfirstsheet = 0
        /*b.set_error_mode("off")*/
        if (strtoreal(st_global("exists"))==0) {
            b.create_book(outfile, sheetname, style)
        } 
        else {
            b.load_book(outfile)
            if (strtoreal(st_global("replace"))==1) {
                b.clear_book(outfile)
                dropfirstsheet = 1
            }
        }
        sheets = b.get_sheets()
        already_exists = 0
        for(i=1;i<=rows(sheets);i++) {
            if (sheets[i] == sheetname) already_exists = 1
        }
        if (already_exists == 1) b.set_sheet(sheetname)
            else b.add_sheet(sheetname)
/*        if (dropfirstsheet == 1 & sheetname != "Sheet1") ///
             b.delete_sheet("Sheet1")
*/        if (title != "") {
            b.set_font(currentrow, currentcol, fnt.family, strtoreal(fnt.fontsize) * 1.2)
            if (fnt.font=="bold") b.set_font_bold(currentrow, currentcol, "on")
            if (fnt.font=="italic") b.set_font_italic(currentrow, currentcol, "on")
            b.put_string(currentrow, currentcol, title)
            currentrow = currentrow + 2
        }
        if (do_border==1) {
            toprow = currentrow
            topcols = (currentcol, currentcol + numcols - 1)
        }
        st_numscalar("currentrow", currentrow)
        numcols = st_numscalar("dwidth")
        currentcol = st_numscalar("currentcol")
        if (h1 != "nil") {
            if (h1 != "") {
                if (h1 != "" & h1cols != "") {
                    headstrs = tokens(h1, " ")
                    colnums = tokens(h1cols, " ")
                    numhead = length(colnums)
                    scol = currentcol + 1
                    for (j=1; j<=(numhead); j++) { 
                        headingstr =  strip_underscore(headstrs[j])
                        span = strtoreal(colnums[j])
                        bcols = (scol, scol + span - 1)
                        if (span != "1") {
                            b.set_horizontal_align(currentrow, bcols, "merge")
                        }
                        else {
                            b.set_horizontal_align(currentrow, bcols, cellpos)
                        }
                        b.set_font(currentrow, scol, fnt.family, strtoreal(fnt.fontsize))
                        if (fnt.font=="bold") b.set_font_bold(currentrow, scol, "on")
                        if (fnt.font=="italic") b.set_font_italic(currentrow, scol, "on")
                        b.put_string(currentrow, scol, headingstr)
                        scol = scol + span
                    }   
                }
            }
            else {
                headingstr = hvarname
                currentrow = st_numscalar("currentrow")
                bcols = (currentcol + 1, currentcol + numcols)
                b.set_horizontal_align(currentrow, bcols, "merge")
                b.set_font(currentrow, currentcol + 1, ///
                    fnt.family, strtoreal(fnt.fontsize))
                if (fnt.font=="bold") b.set_font_bold(currentrow, ///
                    currentcol + 1, "on")
                if (fnt.font=="italic") b.set_font_italic(currentrow, ///
                    currentcol + 1, "on")
                b.put_string(currentrow, currentcol + 1, headingstr)
            }
            st_numscalar("currentrow", ///
                currentrow + 1)                 
        }
        if (h2 != "nil") {
            currentrow = st_numscalar("currentrow")
            scol = currentcol + 1
            lcols = (scol, currentcol + numcols)
            if (do_hlines == 1) b.set_top_border(currentrow, lcols, "thin")
            if (single == 1) {
               b.set_horizontal_align(currentrow, currentcol, "left")
               b.set_font(currentrow, currentcol, fnt.family, strtoreal(fnt.fontsize))
                if (fnt.font=="bold") b.set_font_bold(currentrow, currentcol, "on")
                if (fnt.font=="italic") b.set_font_italic(currentrow, currentcol, "on")
               b.put_string(currentrow, currentcol, vvarname)
            }
            if (h2 != "" & h2cols != "") {
                headstrs = tokens(h2, " ")
                colnums = tokens(h2cols, " ")
                numhead = length(colnums)
                scol = currentcol + 1
                for (j=1; j<=(numhead); j++) { 
                    headingstr =  strip_underscore(headstrs[j])
                    span = strtoreal(colnums[j])
                    bcols = (scol, scol + span - 1)
                    if (span != "1") {
                        b.set_horizontal_align(currentrow, bcols, "merge")
                    }
                    else {
                        b.set_horizontal_align(currentrow, bcols, cellpos)
                    }
                    b.set_font(currentrow, scol, fnt.family, strtoreal(fnt.fontsize))
                    if (fnt.font=="bold") b.set_font_bold(currentrow, scol, "on")
                    if (fnt.font=="italic") b.set_font_italic(currentrow, scol, "on")
                    b.put_string(currentrow, scol, headingstr)
                    scol = scol + span
                }   
            }
            else {
                mcol = fixmulti(X[1, .])
                if (mcol[2, 1] != "na"){
                    for (j=1; j<=cols(mcol); j++) {
                        name = mcol[1, j]
                        ecol = scol + strtoreal(mcol[2, j] )
                        bcols = (scol, ecol)
                        if (mcol[2, j] != "1") {
                            b.set_horizontal_align(currentrow, bcols, "merge")
                        }
                        else {
                            b.set_horizontal_align(currentrow, bcols, cellpos)
                        }
                        b.set_font(currentrow, scol, fnt.family, strtoreal(fnt.fontsize))
                        if (fnt.font=="bold") b.set_font_bold(currentrow, scol, "on")
                        if (fnt.font=="italic") b.set_font_italic(currentrow, scol, "on")
                        b.put_string(currentrow, scol, name)
                        scol = scol + strtoreal(mcol[2, j])
                    }
                }
                else {
                    scol = currentcol + 1
                    ecol = scol + (cols(X) - 1)
                    cols = (scol, ecol)
                    name = mcol[1, ]
                    b.set_horizontal_align(currentrow, cols, cellpos)
                    b.set_font(currentrow, cols, fnt.family, strtoreal(fnt.fontsize))
                    if (fnt.font=="bold") b.set_font_bold(currentrow, cols, "on")
                    if (fnt.font=="italic") b.set_font_italic(currentrow, cols, "on")
                    b.put_string(currentrow, scol, name)
                }
            }
            st_numscalar("currentrow", currentrow + 1)
        }
        if (h3 != "nil") {
            currentrow = st_numscalar("currentrow")
            scol = currentcol + 1
            lcols = (scol, currentcol + numcols)
            bcols = (currentcol, currentcol + cols(X))
            if (do_hlines == 1) b.set_top_border(currentrow, lcols, "thin")
            if (h3 != "" & h3cols != "") {
                headstrs = tokens(h3, " ")
                colnums = tokens(h3cols, " ")
                numhead = length(colnums)
                scol = currentcol + 1
                for (j=1; j<=(numhead); j++) { 
                    headingstr =  strip_underscore(headstrs[j])
                    span = strtoreal(colnums[j])
                    bcols = (scol, scol + span - 1)
                    if (span != "1") {
                        b.set_horizontal_align(currentrow, bcols, "merge")
                    }
                    else {
                        b.set_horizontal_align(currentrow, bcols, cellpos)
                    }
                    b.set_font(currentrow, scol, fnt.family, strtoreal(fnt.fontsize))
                    if (fnt.font=="bold") b.set_font_bold(currentrow, scol, "on")
                    if (fnt.font=="italic") b.set_font_italic(currentrow, scol, "on")
                    b.put_string(currentrow, scol, headingstr)
                    scol = scol + span
                }   
            }
            else {
                X[2,1] = ""
                b.set_horizontal_align(currentrow, bcols, cellpos)
                b.set_font(currentrow, bcols, fnt.family, strtoreal(fnt.fontsize))
                b.put_string(currentrow, currentcol, X[2,])
            }
            st_numscalar("currentrow", currentrow + 1)
        }
        if (do_border == 1) b.set_top_border(toprow, topcols, "medium")
    }
    else {
        b.load_book(outfile)
        b.set_sheet(st_global("sheetname"))  
    }

    do_stats = strtoreal(st_global("do_stats"))
    stpos = st_global("stpos")
    currentcol = st_numscalar("currentcol")
    currentrow = st_numscalar("currentrow")
    lwidth = st_global("lwidth")
    cwidth = st_global("cwidth")
    currentcol = st_numscalar("currentcol")
    ecol = cols(X) - 1
    lcols = (currentcol, currentcol + ecol)
    if (do_plines == 1) b.set_top_border(currentrow, lcols, "thin")
    if (lwidth != "") lwidth = strtoreal(lwidth)
        else lwidth = 35
    if (cwidth != "") cwidth = strtoreal(cwidth)
        else cwidth = 12
    b.set_column_width(currentcol, currentcol + 1, lwidth)
    if (showtot==0) height = rows(X) - numrows
    else height = rows(X)
    width = cols(X)
    doing_stats = 0
    prntlinenum = 0
    for (i=1; i<=height; i++) { 
        if (substr(X[i, 1], 1, 3) == "@N@") {
            X[i, 1] = substr(X[i, 1], 4, .)
            prntlinenum = i - 3
        }
        if (X[i, 1] == "!STATISTICS!") {
            stmat = X[i + 1 .. height, ]
            X = X[1 .. i -1, ]
            height = rows(X)
            doing_stats = 1
        }
    }
    if (single == 0) {
        b.set_horizontal_align(currentrow, currentcol, "left")
        b.set_font(currentrow, currentcol, fnt.family, strtoreal(fnt.fontsize))
        if (fnt.font=="bold") b.set_font_bold(currentrow, currentcol, "on")
        if (fnt.font=="italic") b.set_font_italic(currentrow, currentcol, "on")
        b.put_string(currentrow, currentcol, vvarname)
        currentrow = currentrow + 1
    }

    labels = X[3..height, 1]
    rowblock = currentrow + height - 2
    colblock = currentcol + width -1
    labelrows = (currentrow, rowblock) 
    labelcols = (currentcol)
    data = X[3..height, 2..width]
    datarows = (currentrow, rowblock)
    datacols = (currentcol + 1, colblock )
    lcols = (currentcol, currentcol + cols(X)-1)
    b.set_horizontal_align(labelrows, labelcols, "left")
    b.set_font(labelrows, labelcols, fnt.family, strtoreal(fnt.fontsize))
    if (prntlinenum > 0 & do_plines == 1) b.set_top_border(currentrow //
        + prntlinenum, lcols, "thin")
    b.put_string(currentrow, currentcol, labels)
    b.set_horizontal_align(datarows, datacols, "right")
    b.set_text_indent(datarows, datacols, indent)
    b.set_column_width(currentcol + 1, currentcol + width - 1, cwidth)
    b.set_font(datarows, datacols, fnt.family, strtoreal(fnt.fontsize))
    b.put_string(currentrow, currentcol + 1, data)
    currentrow = currentrow + rows(labels) - 1
    if (do_plines == 1) b.set_bottom_border(currentrow, lcols, "thin")
    currentrow = currentrow + 1
    if (doing_stats == 1 ) {
        statsrows = (currentrow, currentrow + rows(stmat))
        statscols = (currentcol, currentcol + cols(stmat))
        b.set_horizontal_align(currentrow, statscols, "left")
        b.set_font(statsrows, statscols, fnt.family, strtoreal(fnt.fontsize)*0.9)
        b.put_string(currentrow, currentcol, stmat)
        currentrow = currentrow + rows(stmat)
        if (do_plines == 1) //
            b.set_bottom_border(currentrow - 1, lcols, "thin")
        st_numscalar("currentrow", currentrow)
    }
    else {
        st_numscalar("currentrow", currentrow)
    }
    if (lpass == 1) {
        currentcol = st_numscalar("currentcol")
        currentrow = st_numscalar("currentrow")
        numcols = cols(X)
        bcols = (currentcol, currentcol + numcols - 1)
        if (do_border==1) b.set_top_border(currentrow, bcols, "medium")
        if (fn != "") {
            b.set_horizontal_align(currentrow, bcols, "left")
            b.set_font(currentrow, currentcol, fnt.family, strtoreal(fnt.fontsize) * 0.8)
            b.put_string(currentrow, currentcol, fn)
            currentrow = currentrow + 1
        }
        st_numscalar("currentrow", currentrow)
        st_numscalar("currentcol", currentcol)
        }
}


void write_docx( ///
    string scalar style, ///
    real scalar fpass, ///
    real scalar lpass, ///
    string matrix X, ///
    struct fontstruct fnt, ///
    real scalar oneway, ///
    real scalar numrows, ///
    real scalar do_border, ///
    real scalar do_hlines, ///
    real scalar do_plines, ///
    real scalar do_tleft)
{

    h1 = st_global("h1")
    h2 = st_global("h2")
    h3 = st_global("h3")
    outfile = st_global("mainfile")
    title = st_global("title")
    h1 = st_global("h1")
    h2 = st_global("h2")
    h3 = st_global("h3")
    h1cols = st_global("h1c")
    h2cols = st_global("h2c")
    h3cols = st_global("h3c")
    hvarname = st_global("hvarname")
    vvarname = st_global("vvarname")
    showtot = strtoreal(st_global("showtot"))
    single = strtoreal(st_global("single"))
    do_land = strtoreal(st_global("do_land"))
    do_hright = strtoreal(st_global("do_hright"))
    do_n = strtoreal(st_global("do_n"))
    paper = st_global("paper")
    fn = st_global("fn")
    if (do_tleft == 1) talign = "left"
        else talign = "center"
    twidth = st_global("twidth")
    numcols = st_numscalar("dwidth")
    if (twidth != "") tablewidth = strtoreal(twidth) * 50
        else tablewidth = 0
    varrow = 2 
    if (fpass == 1) {
        if (do_hright == 0) cellpos = "center" 
                else cellpos = "right"
        if (oneway == 1 & h1 =="") h1 = "nil"
        if (oneway == 1 & h2 =="") {
            if (do_n == 1) X[2, cols(X)] = X[1, cols(X)]
            h2 = "nil"
        }
        hrows = 0
        if (h1 != "nil") hrows = hrows + 1
        if (h2 != "nil") hrows = hrows + 1
        if (h3 != "nil") hrows = hrows + 1
        st_numscalar("currentrow", 1)
        dh = _docx_new()
        st_numscalar("dh", dh)
        if (dh < 0) {
            printf("Error creating file: ")
            dh
        }
        m = _docx_set_font(dh, fnt.family)
        m = _docx_set_size(dh, strtoreal(fnt.fontsize) * 2)
        m = _docx_set_papersize(dh, paper)
        if (do_land == 1) m = _docx_set_landscape(dh, 1)
        if (title != "") {
            m = _docx_paragraph_new(dh, "")
            m = _docx_paragraph_set_halign(dh, talign)
            m = _docx_paragraph_set_textsize(dh, abs(strtoreal(fnt.fontsize) * 2.4))
            m = _docx_paragraph_add_text(dh, title)
            if (fnt.font=="bold") m = _docx_text_set_bold(dh, 1)
            if (fnt.font=="italic") m = _docx_text_set_italic(dh, 1)
            
        }
        tid = m = _docx_new_table(dh, hrows, cols(X))
        st_numscalar("tid", tid)
        if (tablewidth == 0) {
            m = _docx_table_set_width(dh, tid, "auto", 5000)
        }
        else {
            m = _docx_table_set_width(dh, tid, "pct", tablewidth)
        }
        m = _docx_table_set_alignment(dh, tid, talign)
        m = _docx_table_set_border(dh, tid, "insideV", "none", "000000")
        m = _docx_table_set_border(dh, tid, "insideH", "none", "000000")
        m = _docx_table_set_border(dh, tid, "start", "none", "000000")
        m = _docx_table_set_border(dh, tid, "end", "none", "000000")
        m = _docx_table_set_border(dh, tid, "top", "none", "000000")
        m = _docx_table_set_border(dh, tid, "bottom", "none", "000000")
        if (do_border == 1)  {
            linelist = (1)
            st_matrix("linelist", linelist)
        } 
        else {
            linelist = (0)
            st_matrix("linelist", linelist)  
        }
        if (h1 != "nil") {
            currentrow = st_numscalar("currentrow") 
            if (h1 != "" & h1cols != "") {
                headstrs = tokens(h1, " ")
                colnums = tokens(h1cols, " ")
                numhead = length(colnums)
                start = 2
                for (j=1; j<=(numhead); j++) { 
                    headingstr =  strip_underscore(headstrs[j])
                    span = strtoreal(colnums[j])
                    m = _docx_cell_set_colspan(dh, tid, ///
                        currentrow, start, span)
                    m = _docx_table_mod_cell(dh, tid, currentrow, ///
                        start, headingstr)
                     m = fixdocxfont(dh, tid, currentrow, start)    
                    m = _docx_cell_set_texthalign(dh, tid, currentrow, ///
                        start, "center")
                    start = start + span 
                }   
            }
            else headingstr = hvarname
            currentrow = st_numscalar("currentrow") 
            numcols = st_numscalar("dwidth")
            m = _docx_cell_set_colspan(dh, tid, currentrow, 2, numcols)
            m = _docx_table_mod_cell(dh, tid, currentrow, 2, headingstr)
            m = fixdocxfont(dh, tid, currentrow, 2)
            m = _docx_cell_set_texthalign(dh, tid, currentrow, 2, "center")
            st_numscalar("currentrow", currentrow + 1)
        }
        if (h2 != "nil") {
            currentrow = st_numscalar("currentrow")
            if (h2 != "" & h2cols != "") {
                headstrs = tokens(h2, " ")
                colnums = tokens(h2cols, " ")
                numhead = length(colnums)
                start = 2
                for (j=1; j<=(numhead); j++) { 
                    headingstr =  strip_underscore(headstrs[j])
                    span = strtoreal(colnums[j])
                    m = _docx_cell_set_colspan(dh, tid, ///
                        currentrow, start, span)
                    m = _docx_table_mod_cell(dh, tid, currentrow, ///
                        start, headingstr)
                    m = fixdocxfont(dh, tid, currentrow, start)
                    m = _docx_cell_set_texthalign(dh, tid, currentrow, ///
                        start, cellpos)
                    start = start + span 
                    }   
            }
            else {
                varrow = currentrow
                mcol = fixmulti(X[1, .])
                if (mcol[2, 1] != "na"){ /// will have multicols
                    scol = 2
                    for (j=1; j<=cols(mcol); j++) {
                        name = mcol[1, j]
                        span = strtoreal(mcol[2, j] )
                        if (mcol[2, j] != "1") {
                            m = _docx_cell_set_colspan(dh, tid, currentrow, scol, span)
                        }
                        m = _docx_table_mod_cell(dh, tid, currentrow, scol, name)
                        m = fixdocxfont(dh, tid, currentrow, scol)
                        m = _docx_cell_set_texthalign(dh, tid, currentrow, scol, cellpos)
                        scol = scol + strtoreal(mcol[2, j])
                    }
                }
                else { /// where no multicols
                    X[1,1] = ""
                    scol = 1
                    for (j=1; j<=cols(X); j++) {
                        name = X[1, j]
                        m = _docx_table_mod_cell(dh, tid, currentrow, scol, name)
                        m = fixdocxfont(dh, tid, currentrow, scol)
                        m = _docx_cell_set_texthalign(dh, tid, currentrow, scol, cellpos)
                        scol = scol + 1
                    }            
                }
            }
            st_numscalar("currentrow", currentrow + 1)
            if (do_hlines == 1)  {
                for (i=2; i<=numcols; i++) m = _docx_cell_set_border ///
                    (dh, tid, 2, i, "top", "thick", "000000")
                st_numscalar("currentrow", currentrow + 1)
            }
        }
        if (h3 != "nil") {
            currentrow = st_numscalar("currentrow")
            if (h3 != "" & h3cols != "") {
                headstrs = tokens(h3, " ")
                colnums = tokens(h3cols, " ")
                numhead = length(colnums)
                start = 2
                for (j=1; j<=(numhead); j++) { 
                    headingstr =  strip_underscore(headstrs[j])
                    span = strtoreal(colnums[j])
                    m = _docx_cell_set_colspan(dh, tid, ///
                        currentrow, start, span)
                    m = _docx_table_mod_cell(dh, tid, currentrow, ///
                        start, headingstr)
                    m = fixdocxfont(dh, tid, currentrow, start)    
                    m = _docx_cell_set_texthalign(dh, tid, currentrow, ///
                        start, cellpos)
                    start = start + span 
                    }   
            }
            else {
                X[2,1] = ""
                scol = 1
                for (j=1; j<=cols(X); j++) {
                    name = X[2, j]
                    m = _docx_table_mod_cell(dh, tid, currentrow, scol, name)
                    m = _docx_cell_set_texthalign(dh, tid, currentrow, scol, cellpos)
                    if (currentrow == 1) m = fixdocxfont(dh, tid, ///
                        currentrow, scol)
                    scol = scol + 1
                }
            }
            st_numscalar("currentrow", currentrow + 1)
            if (do_hlines == 1)  {
                numcols = numcols + 1
                for (i=2; i<=numcols; i++) m = _docx_cell_set_border ///
                    (dh, tid, 3, i, "top", "thick", "000000")
            } /// if hlines          
        } /// if h3 != "nill"
    } /// if first pass
    dh = st_numscalar("dh")
    tid = st_numscalar("tid")
    if (single == 1) {
        m = _docx_table_mod_cell(dh, tid, varrow, 1, vvarname)
        m = _docx_cell_set_texthalign(dh, tid, varrow, 1, "left")
        m = fixdocxfont(dh, tid, varrow, 1)
    }
    currentrow = st_numscalar("currentrow")
    if (do_plines == 1) linelist = updatelines(linelist, currentrow)
    do_stats = strtoreal(st_global("do_stats"))
    stpos = st_global("stpos")
    doing_stats = 0
    prntlinenum = 0
    for (i=1; i<=rows(X); i++) { 
        if (substr(X[i, 1], 1, 3) == "@N@") {
            X[i, 1] = substr(X[i, 1], 4, .)
            prntlinenum = i - 2
            Nrow = currentrow + prntlinenum
            if (do_plines == 1) linelist = updatelines(linelist, Nrow)
        }
        if (X[i, 1] == "!STATISTICS!") {
            stmat = X[i + 1 .. rows(X), ]
            X = X[1 .. i -1, ]
            doing_stats = 1
        }
    }
    if (single == 0) {
        m = _docx_table_add_row(dh, tid, currentrow - 1, cols(X))
        m = _docx_table_mod_cell(dh, tid, currentrow, 1, vvarname)
        m = _docx_cell_set_texthalign(dh, tid, currentrow, 1, "left")
        m = fixdocxfont(dh, tid, currentrow, 1)
        currentrow = currentrow + 1        
    }
    if (showtot==0) size = rows(X) - numrows
    else size = rows(X)
    for (i=3; i<=size; i++) {
        m = _docx_table_add_row(dh, tid, currentrow - 1, cols(X))
        for (j=1; j<=cols(X); j++) {
            m = _docx_table_mod_cell(dh, tid, currentrow, j, X[i, j] )
            if (j == 1) ///   
        m = _docx_cell_set_texthalign(dh, tid, currentrow, j, "left")
        else
        m = _docx_cell_set_texthalign(dh, tid, currentrow, j, "right")
        }
        currentrow = currentrow + 1
    }
    if (doing_stats == 1 ) {
        for (i=1; i<=rows(stmat); i++) {
            m = _docx_table_add_row(dh, tid, currentrow - 1, cols(X))
            for (j=1; j<=cols(stmat); j++) {
                m = _docx_cell_set_colspan(dh, tid, currentrow, 1, cols(X) )
                m = _docx_table_mod_cell(dh, tid, currentrow, j, stmat[i, j] )
                m = _docx_cell_set_textsize(dh, tid, currentrow, j, abs(strtoreal(fnt.fontsize) * 1.8))
                m = _docx_cell_set_texthalign(dh, tid, currentrow, j, "left")
            }
        currentrow = currentrow + 1
        }
        Srow = currentrow - rows(stmat)
        if (do_plines == 1) linelist = updatelines(linelist, Srow)
    }
    st_numscalar("currentrow", currentrow)
    if (lpass == 1) {
        currentrow = st_numscalar("currentrow")
        if (do_border == 1) linelist = updatelines(linelist, currentrow)
        if (fn != "") {
            m = _docx_table_add_row(dh, tid, currentrow - 1, cols(X))
            m = _docx_cell_set_colspan(dh, tid, currentrow, 1, cols(X) )
            m = _docx_table_mod_cell(dh, tid, currentrow, 1, fn)
            m = _docx_cell_set_textsize(dh, tid, currentrow, 1, abs(strtoreal(fnt.fontsize) * 1.6))
            m = _docx_cell_set_texthalign(dh, tid, currentrow, 1, "left")    
        }
        if (do_plines == 1) {
            linelist = st_matrix("linelist")
            for (j=1; j<=cols(linelist); j++) {
                for (i=1; i<=cols(X); i++) {
                m = _docx_cell_set_border ///
                (dh, tid, linelist[1,j], i, "top", "thick", "000000")
                }
            }
        }
        res = _docx_save(dh, outfile, 1)
        if (res < 0) {
            printf("Error saving file: ")
            res
        }
        m = _docx_close(dh)
    }
}

void write_ascii( ///
    string matrix X, ///
    struct fontstruct fnt, ///
    real scalar oneway, ///
    real scalar numrows, ///
    string scalar style)

{               
    done = 0
    ptab = ""
    suppress = 0
    do_n = strtoreal(st_global("do_n"))
    npos = st_global("n_pos")
    lwidth = st_global("lwidth")
    cwidth = st_global("cwidth")
    units = st_global("units")

    single = strtoreal(st_global("single"))
    fpass = strtoreal(st_global("fpass"))
    lpass = strtoreal(st_global("lpass"))
    showtot = strtoreal(st_global("showtot"))
    
    h1 = st_global("h1")
    h2 = st_global("h2")
    h3 = st_global("h3")
    h1cols = st_global("h1c")
    h2cols = st_global("h2c")
    h3cols = st_global("h3c")
    ltrim = st_global("ltrim")
    fwidth = strofreal(cols(X))
    pwidth = strofreal(st_numscalar("dwidth"))

    do_hlines = strtoreal(st_global("do_hlines"))
    do_plines = strtoreal(st_global("do_plines"))

    fullline = ""
    h1line = ""
    h2line = ""
    h3line = ""
    startline = ""
    endlineline = ""

    struct stystruct scalar sty
    
    if (style == "htm") {
        if (lwidth != "") lwidth = "width = " + lwidth + units + " "
        if (cwidth != "") cwidth = "width = " + cwidth + units + " "

        if  (do_hlines == 1) {
            sty.h1line = "<tr><td></td><td colspan=" + pwidth ///
            + " style='text-align:center; border-style: " ///
            + "none none solid none; border-width: 1px;'></td></tr>"
            sty.h2line = "<tr><td></td><td colspan=" + pwidth ///
            + " style='text-align:center; border-style: " ///
            + "none none solid none; border-width: 1px;'></td></tr>"
            sty.h3line = "<tr><td colspan=" + fwidth ///
            + " style='text-align:center; border-style: " ///
            + "none none solid none; border-width: 1px;'></td></tr>"
            sty.startline = "<tr><td></td><td colspan=" + pwidth ///
            + " style='text-align:center; border-style: " ///
            + "none none solid none; border-width: 1px;'>"
            sty.endline = "</td></tr>"
        }
        if (do_plines ==1) sty.fullline = "<tr><td colspan=" + fwidth ///
            + " style='text-align:center; border-style: " ///
            + "none none solid none; border-width: 1px;'></td></tr>"
        
        fontsize = st_global("fontsize")
        size = strtoreal(fontsize) * 0.9
        h1extra = st_numscalar("h1extra")

        sty.fullwidth = "<tr><td colspan=" + fwidth ///
            + " style='text-align:left;'>" ///
            + fixfont(st_global("vvarname")) + "</td></tr>"
        sty.prefirst = " <td " + lwidth + "style='text-align: left'>"
        sty.pre = " <td " + cwidth  + "style='text-align: right'>"
        sty.post = "</td>"
        sty.rbeg = "<tr>"
        sty.rend = "</tr>"
        sty.h1beg = "<td></td><td colspan="
        sty.h1mid = " style='text-align:center'>"
        sty.h1midend = ""
        sty.h1end = ""
        if (h1extra > 0) {
            for (j=1; j<=h1extra; j++) {
                sty.h1end = sty.h1end + "<td></td>"
            }
            sty.h1end = sty.h1end + "</td>"
        }
        else sty.h1end = "</td>"
        sty.h2beg = "</td><td colspan="
        sty.h2mid = " style='text-align:center'>"
        sty.h2midend = ""
        sty.h2end = "</td>"
        sty.h3beg = "</td><td colspan="
        sty.h3mid = " style='text-align:center'>"
        sty.h3midend = ""
        sty.h3end = "</td>"
        sty.statsbeg = "<td colspan="
        sty.statsmid = " style='text-align:left; font-size:" ///
            + strofreal(size) + "px;'>"
        sty.statsend = "</td>"
        k = check_empty(X, 2)
        if (h3 == "nil" | k == 1) sty.h2line=""

    } 
    else if (style == "tex") {
        pwidth = strofreal(st_numscalar("dwidth") + 1)
        dwidth = strofreal(st_numscalar("dwidth"))
        sty.h1line = "\cmidrule(l{" + ltrim + "em}){2-" + 
                pwidth + "} "

        if (do_hlines == 1) {
            sty.h3line = "\midrule "
            linespans = 0
            mcol = fixmulti(X[1, .])
            if (h2cols !="" | mcol[2, 1] != "na") linespans = 1
            if (linespans == 0) {
                sty.h2line = "\cmidrule(l{" + ltrim + "em}){2-" + pwidth + "} "
            } 
            else {
                sty.h2line = ""
                if (h2cols !="") colnums = tokens(h2cols, " ")
                else if ( mcol[2, 1] != "na") colnums = mcol[2, ]
                numhead = length(colnums)
                cstart = 2
                for (j=1; j<=(numhead); j++) {
                    colnum = colnums[j]
                    cend = (cstart + strtoreal(colnum)) - 1
                    span = "{" + strofreal(cstart) + "-" + ///
                        strofreal(cend) + "}"
                    sty.h2line = sty.h2line + "\cmidrule(l{" + 
                        ltrim + "em})" + span
                cstart = (cstart + strtoreal(colnum))
                }
            }
            k = check_empty(X, 2)
            if (h3 == "nil" | k == 1) sty.h2line=""
            sty.startline = ""
            sty.endline = ""
        } 
        if (do_plines == 1) sty.fullline = "\midrule "
        sty.fullwidth = ""
        sty.prefirst = ""
        sty.pre = " & "
        sty.post = ""
        sty.rbeg = ""
        sty.rend = " \\"
        sty.h1beg = "& \multicolumn{" 
        sty.h1mid = "}{c}{"
        sty.h1midend = "}"
        sty.h1end = "} "
        sty.h2beg = " & \multicolumn{"
        sty.h2mid = "}{c}{"
        sty.h2midend = "} "
        sty.h2end = ""
        sty.h3beg = " & \multicolumn{"
        sty.h3mid = "}{c}{"
        sty.h3midend = "} "
        sty.h3end = ""
        sty.statsbeg = "\multicolumn{"
        sty.statsmid = "}{@{} l}{\scriptsize{"
        sty.statsend = "}} " 
    }
    else if (style == "tab" | style == "csv" | style == "semi") {
        if (style == "csv") ptab = ","
        else if (style == "semi") ptab = ";"
        else ptab = char(09)
        sty.pre = ptab
        suppress = 1
    }


    if (oneway == 1 & do_n == 1 & (npos == "col" | npos== "both")) fixn = 1 
        else fixn = 0
    
    if (fpass == 1) {
        if (h1 != "nil") { 
            if (oneway == 0) write_h1(sty, fnt, h1, h1cols, suppress, ///
                do_hlines, X)
                else if (oneway == 1 & h1 !="") ///
                    write_h1(sty, fnt, h1, h1cols, suppress, do_hlines, X)
        }
        if (h2 != "nil") { 
            if (oneway == 0) write_h2(sty, fnt, h2, h2cols, suppress, ///
                do_hlines, X)
                else if (oneway == 1 & h2 !="") ///
                    write_h2(sty, fnt, h2, h2cols, suppress, do_hlines, X)
        }
        if (h3 != "nil") { 
            write_h3(sty, fnt, h3, h3cols, suppress, fixn, X)
        }
    }
    write_contents(sty, fnt, numrows, do_hlines, do_plines, suppress, X, fpass)
}   



void write_prepost( ///
    struct prepoststruct prpst, ///
    real scalar is_top)
{
    outfile = st_global("mainfile")
    fh_out = fopen(outfile, "a")
    if (is_top == 1) {
        infile = prpst.prefile
        insert = prpst.topinsert
    }
    else {
        infile = prpst.postfile
        insert = prpst.botinsert
    }
    fh_in = fopen(infile, "r")
    if (insert != "nil"){ 
        INS = tokens(insert, prpst.delim)
        INS = strip_delim(INS, prpst.delim)
        k = 0
        while ((line = fget(fh_in)) != J(0, 0, "")) {
            while (strpos(line, prpst.ps) > 0) {
                if (k <= cols(INS)) {
                    k = k + 1 
                    line = subinstr(line, prpst.ps, INS[1, k], 1)
                }
            }
            fput(fh_out, line)
        }
    }
    else {
        while ((line = fget(fh_in)) != J(0, 0, "")) {
            fput(fh_out, line)
        }
    }
    
    fclose(fh_out)
    fclose(fh_in)
}

void write_topbody( ///
    string scalar style, ///
    struct fontstruct fnt)
{
    outfile = st_global("mainfile")
    fh_out = fopen(outfile,"a")

    if (style == "htm") {
        css = st_global("css")
        fput(fh_out, "<!DOCTYPE html>")
        fput(fh_out, "<html>")
        if (css != "") fput(fh_out,"<style type='text/css' media='all'>@import  '" + css + "'</style> ")
        fput(fh_out, "<body>")
    }
    else if (style=="tex") {
        do_land = strtoreal(st_global("do_land"))
        do_caption = strtoreal(st_global("do_caption"))
        font = st_global("tfont")
        capfont = ""
        if (font == "bold") capfont = "bf"
            else if (font == "italic") capfont = "it" 
        if (fnt.rmfamily != "") {
            fontspec1 = "\usepackage{fontspec, xltxtra, xunicode}"
            fontspec2 =  "\setromanfont{" + fnt.rmfamily + "}"
            fontspec3 =  "\setsansfont{" + fnt.ssfamily + "}"
        }
        else {
            fontspec1 = ""
            fontspec2 = ""
            fontspec3 = ""
        }
        paper = st_global("paper") +", "
        doctype = st_global("doctype")
        ptsize = fnt.fontsize + "pt"
        angle = st_global("angle")
        fput(fh_out,"\documentclass[" + paper + ptsize + "]{" + doctype + "}")
        fput(fh_out,"\usepackage{multicol}")
        fput(fh_out, "\usepackage{tabularx}")
        fput(fh_out, "\usepackage{booktabs}")
        fput(fh_out, "\usepackage{lscape}")
        if (do_caption == 1) {
            fput(fh_out,"\usepackage{float}")
            fput(fh_out, "\usepackage{caption}")
            if (capfont != "") insert = ",font = " + capfont +"}"
                else insert = "}"
            fput(fh_out, "\captionsetup{font=small," + ///
                "justification=centering" + insert)
        }
        fput(fh_out, fontspec1)
        fput(fh_out, fontspec2)
        fput(fh_out, fontspec3)
        if (angle != "0") {
            fput(fh_out, "\newcommand{\rot}[2]{\rule{1em}{0pt}%")
            fput(fh_out, "\makebox[0cm][c]{\rotatebox{#1}{\ #2}}}")
        }
        fput(fh_out,"\begin{document}")
    }  
    fclose(fh_out)
}

void write_toptable( ///
    string scalar style, ///
    struct fontstruct fnt, ///
    real scalar do_border, ///
    real scalar do_land, ///
    real scalar do_caption, ///
    real scalar do_tleft, ///
    string matrix X)
{
    outfile = st_global("mainfile")
    title = st_global("title")
    units = st_global("units")
    caplab = st_global("caplab")
    cappos = st_global("cappos")

    fh_out = fopen(outfile,"a")
    ntc = strtoreal(st_global("ntc"))
    if (style == "htm") {
        if (ntc == 0) {
            st_numscalar("mult", 1.2)
            has_style = 0
            if (title !="") {
                titlestr = "<p style='margin-bottom: 8px;" + familysize("") ///
                 + " '>" + fixfont(title) + "</p>"
                fput(fh_out, titlestr) 
                has_style = 1          
            }
            twidth = st_global("twidth")
            width = ""
            frame = ""
            st_numscalar("mult", 1)    
            tablestart = "<table" 
            if (twidth != "") {
                width=" width=" + twidth + units + " "
                tablestart = tablestart + width
            }
            if (fnt.fontsize != "" | fnt.family != "" | ///
                do_border == 1) stylestart =  " style = '"
            else 
                stylestart =  ""
            tablestart = tablestart + stylestart + familysize("")
            if (do_border == 1) {
                frame = "border-style: solid none solid none; border-width: 2px;"
                tablestart = tablestart + frame
            }
            if (stylestart != "") tableend = " '>"
                else tableend = ">"
            fput(fh_out, tablestart + tableend)
        }
    }
    else if (style == "tex") {
        if (ntc == 0) {
            if (do_land == 1) fput(fh_out, "\begin{landscape}")
            twidth = st_global("twidth")
            texdef = st_global("texdef")
            if (twidth == "") twidth = texdef
                else twidth = twidth + units
            if (do_tleft == 0) fput(fh_out, "\begin{center}")
            if (do_caption == 1) fput(fh_out, "\begin{table}[H]")
            if (strtoreal(st_global("ssf")) == 1) ///
                fput(fh_out, "{\sffamily")
            title = texclean(st_global("title"))
            if (title != "") {
                if (do_caption == 1) {
                    if  (cappos == "above") fput(fh_out, ///
                         "\caption{\label{tab:" ///
                        + caplab  + "}" + title + "} \par \vspace{2ex}" )
                }
                else fput(fh_out, "\textbf{" + title + "} \par \vspace{2ex}")
            }
            fput(fh_out, "\footnotesize")
            fput(fh_out, "\newcolumntype{Y}{>{\raggedleft\arraybackslash}X}")
            texreps = st_global("texreps")
            fput(fh_out, "\begin{tabularx} {" + twidth + //
                "} {@{} l " + texreps + "@{}}")
            if (do_border == 1) fput(fh_out, "\toprule")  
        }
    }
    else if (style == "tab" | style == "csv" | style == "semi") {
        fput(fh_out, title)
     }
    fclose(fh_out)
}


void write_h1( ///
    struct stystruct sty, ///
    struct fontstruct fnt, ///
    string scalar heading, ///
    string scalar h1cols, ///
    real scalar suppress, ///
    real scalar do_hlines, ///
    string matrix X)
{
    outfile = st_global("mainfile")
    hvarname = st_global("hvarname")

    if (heading != "") {
        if (h1cols != "") {
            printstr = sty.rbeg + sty.prefirst
            headstrs = tokens(heading, " ")
            colnums = tokens(h1cols, " ")
            numhead = length(colnums)
            for (j=1; j<=(numhead); j++) {
                name =  fixfont(texclean(strip_underscore(headstrs[j])))
                colnum = colnums[j]
                if (suppress == 0) printstr = printstr + sty.h1beg ///
                    + colnum + sty.h1mid + name + sty.h1midend
                else {
                    numtabs = ""
                    k = strtoreal(colnum)
                    for (i=1; i<=k; i++) numtabs = numtabs + sty.pre
                    printstr = printstr + numtabs + name
                }
            }
            printstr = printstr + sty.post + sty.rend
        }
        else headingstr = heading
    }
    else headingstr = fixfont(hvarname)
    if (suppress == 1) span = sty.pre
    else  span = strofreal(st_numscalar("dwidth"))
    printstr =  sty.rbeg + sty.h1beg + span ///
        + sty.h1mid + texclean(headingstr) + sty.h1end + sty.rend
    fh_out = fopen(outfile,"a")
    fput(fh_out, printstr)
    if (do_hlines == 1 & suppress == 0) fput(fh_out, sty.h1line)
    fclose(fh_out)
}

void write_h2( ///
    struct stystruct sty, ///
    struct fontstruct fnt, ///
    string scalar heading, ///
    string scalar h2cols, ///
    real scalar suppress, ///
    real scalar do_hlines, ///
    string matrix X)
{
    outfile = st_global("mainfile")
    numcols = st_numscalar("dwidth")
    h2str = ""
    mcol = fixmulti(X[1, .])
    if (mcol[2, 1] != "na"){
        for (j=1; j<=cols(mcol); j++) {
            name = rotate(fixfont(texclean(mcol[1, j])))
            if (mcol[2, j] != "1") {
                if (suppress == 0) {
                    h2str = h2str + sty.h2beg ///
                        + mcol[2, j] + sty.h2mid + name + sty.h2midend 
                }
                else {
                    numtabs = ""
                    k = strtoreal(mcol[2,j])
                    for (i=1; i<=k; i++) numtabs = numtabs + sty.pre
                    h2str = h2str + numtabs + name
                }
            }
            else h2str = h2str + sty.pre + name + sty.post
        }
    }
    else {
        for (j=2; j<=cols(X); j++) {
            h2str = h2str + sty.pre ///
            + rotate(fixfont(texclean(X[1,j]))) + sty.post
        }
    }
    if (heading != "") {
        if (h2cols != "") {
            printstr = sty.rbeg + sty.prefirst
            headstrs = tokens(heading, " ")
            colnums = tokens(h2cols, " ")
            numhead = length(colnums)
            if (rowsum(strtoreal(colnums)) == numhead) singlecol = 1
                else singlecol = 0
            for (j=1; j<=(numhead); j++) {
                name =  ///
                    rotate(fixfont(texclean(strip_underscore(headstrs[j]))))
                colnum = colnums[j]
                if (suppress == 0) {
                    if (singlecol == 0) printstr = printstr + ///
                        sty.h2beg + colnum + sty.h2mid + name + sty.h2midend
                    else printstr = printstr + sty.pre + name
                }
                else {
                    if (singlecol == 0) {
                        numtabs = ""
                        k = strtoreal(colnum)
                        for (i=1; i<=k; i++) numtabs = numtabs + sty.pre
                        printstr = printstr + numtabs + name 
                    }
                    else printstr = printstr + sty.pre + name 
                }
            }
            printstr = printstr + sty.post + sty.rend
        }
        else  printstr = fixfont(heading)
    } 
    else  printstr = sty.rbeg + sty.prefirst  ///
        + h2str + sty.h2end + sty.rend
    fh_out = fopen(outfile,"a")
    fput(fh_out, printstr)
    if (do_hlines == 1  & suppress == 0) fput(fh_out, sty.h2line)
    fclose(fh_out)
}




void write_h3( ///
    struct stystruct sty, ///
    struct fontstruct fnt, ///
    string scalar heading, ///
    string scalar h3cols, ///
    real scalar suppress, ///    
    real scalar fixn, ///
    string matrix X)
{
    outfile = st_global("mainfile")
    numcols = st_numscalar("dwidth")
    lines = st_global("lines")
    h3str = ""
    for (j=2; j<=cols(X); j++) {
        if (fixn==1 & j==cols(X)) w = 1
            else w = 2
        h3str = h3str + sty.pre + texclean(X[w,j]) + sty.post
    }
    if (heading != "") {
        if (h3cols != "") {
            printstr = sty.rbeg + sty.prefirst
            headstrs = tokens(heading, " ")
            colnums = tokens(h3cols, " ")
            numhead = length(colnums)
            if (rowsum(strtoreal(colnums)) == numhead) singlecol = 1
                else singlecol = 0
            for (j=1; j<=(numhead); j++) {
                name =  texclean(strip_underscore(headstrs[j]))
                colnum = colnums[j]
                if (suppress == 0) {
                    if (singlecol == 0) printstr = printstr + ///
                        sty.h3beg + colnum + sty.h3mid + name + sty.h3midend
                    else printstr = printstr + sty.pre + name
                }
                else {
                    if (singlecol == 0) {
                        numtabs = ""
                        k = strtoreal(colnum)
                        for (i=1; i<=k; i++) numtabs = numtabs + sty.pre
                        printstr = printstr + numtabs + name 
                    }
                    else printstr = printstr + sty.pre + name 
                }
             }   
            printstr = printstr + sty.post + sty.rend
        }
        else printstr = heading
    }
    else printstr = sty.rbeg + sty.prefirst + h3str + sty.rend
    fh_out = fopen(outfile,"a")
    fput(fh_out, printstr)
    fclose(fh_out)
}

void write_contents( ///
    struct stystruct sty, ///
    struct fontstruct fnt, ///
    real scalar numrows, ///
    real scalar do_hlines, ///
    real scalar do_plines, ///
    real scalar suppress, ///
    string matrix X, ///
    real scalar fpass)
{
    outfile = st_global("mainfile")
    showtot = strtoreal(st_global("showtot"))
    single = strtoreal(st_global("single"))
    style = st_global("style")
    fh_out = fopen(outfile,"a")
    if (fpass == 1) {
        if (do_hlines == 1 & suppress == 0) fput(fh_out, sty.h3line)
    }
    else {
        if (do_plines == 1 & suppress == 0) fput(fh_out, sty.fullline)
    }
    vvarname = st_global("vvarname")
    varstr = fixfont(texclean(vvarname))
    if (single == 0 & suppress == 0) fput(fh_out, sty.fullwidth)
    if (vvarname != "!PTOTAL!")  printstr = sty.rbeg /// 
    + sty.prefirst + varstr + sty.post + sty.rend
    if (style != "htm")  fput(fh_out, printstr)
    if (showtot==0) size = rows(X) - numrows
    else size = rows(X)
    doing_stats = 0
    for (i=3; i<=size; i++) {
        if (substr(X[i,1], 1, 3) == "@N@") {
            printline = sty.fullline
            if (do_plines == 1 & suppress == 0) fput(fh_out, printline)
            printstr = sty.prefirst + texclean(substr(X[i,1], 4, .)) ///
            + sty.post
        }  
        else  printstr = sty.prefirst + texclean(X[i, 1]) + sty.post
        if (X[i, 1] == "!STATISTICS!") doing_stats = 1
        if (doing_stats == 0) {
            for (j=2; j<=cols(X); j++) {
                    printstr = printstr + sty.pre + ///
                        texclean(X[i, j]) + sty.post
            }
        }
        else {
            if (suppress == 0) spanwidth=strofreal(cols(X))
                else spanwidth = ""
            printstr = sty.statsbeg + spanwidth ///
                + sty.statsmid + texclean(X[i, 1]) + sty.statsend
        }
        if (X[i, 1] == "!STATISTICS!") {
            printline = sty.fullline
            if (do_plines == 1 & suppress == 0) fput(fh_out, printline)                
        } 
        else {
            fput(fh_out, sty.rbeg + printstr + sty.rend)
        }
    }
    fclose(fh_out)
}


void write_bottomtable( ///
    string scalar style, ///
    real scalar do_border, ///
    real scalar do_land, ///
    real scalar do_caption, ///
    real scalar do_tleft, ///
    struct fontstruct fnt)
{
    outfile = st_global("mainfile")
    title = st_global("title")
    fn = st_global("fn")
    caplab = st_global("caplab")
    cappos = st_global("cappos")
    fontsize = st_global("fontsize")
    family = st_global("family")
    fh_out = fopen(outfile,"a")
    ntc = strtoreal(st_global("ntc"))
    if (style == "htm") { 
        if (ntc == 0) {
            fput(fh_out, "</table>")
            if (fn !="") {
                st_numscalar("mult", 0.8)
                fnstr = "<p style = 'margin-top: 6px;"
                fnstr = fnstr + familysize("")
                fnstr = fnstr + " '>" + fn + "</p>"
                fput(fh_out, fnstr)           
            }
        }
    }
    else if (style == "tex") {
        if (ntc == 0) {
            if (do_border == 1) fput(fh_out, "\bottomrule")
            fput(fh_out, "\end{tabularx}")
            fn = texclean(st_global("fn"))
            twidth = st_global("twidth")
            texdef = st_global("texdef")
            units = st_global("units")
            if (twidth == "") twidth = texdef
                else twidth = twidth + units
            if (fn !="") fput(fh_out, "\par\smallskip\noindent\parbox{" ///
                + twidth + "}{\raggedright \scriptsize " + fn + "}")
            fput(fh_out, "\normalsize")
            if (do_caption == 1 & cappos != "above" & title !="") ///
                fput(fh_out, "\caption{\label{tab:" ///
                + caplab  + "}" + title + "} \par \vspace{2ex}" )
            if (do_caption == 1) fput(fh_out, "\end{table}")
            if (strtoreal(st_global("ssf")) == 1) ///
                fput(fh_out, "}")
            if (do_tleft == 0) fput(fh_out, "\end{center}")
            if (do_land == 1) fput(fh_out, "\end{landscape}")
        }
    }
    else if (style == "tab" | style == "csv" | style == "semi") {
        fput(fh_out, fn)
     }

fclose(fh_out)
}

void write_bottombody(
    string scalar style)
{
    outfile = st_global("mainfile")
    fh_out = fopen(outfile, "a")
    if (style == "htm") {           
        fput(fh_out, "</body>") 
        fput(fh_out, "</html>") 
    }
    else if (style == "tex") {
        fput(fh_out, "\end{document}")
    }
    fclose(fh_out)
}


/* ------------------ misc routines for writing  ---------------------- */
/* -----------invoked inline as needed and return string or matrix------*/

function fix_commas(string matrix X)
{
    Z = X
    for (i=1; i<=rows(Z); i++) {
        for (j=1; j<=cols(Z); j++) {
            if (strpos(Z[i,j],",")~=0) ///
                Z[i,j]=`"""'+Z[i,j]+`"""'
        }
    }
    return(Z)
}

function strip_delim( ///
    string matrix X, ///
    string scalar delim)
{
    Z = X
    Y = Z[1, 1]
    k = 2
    while (k <= cols(Z)) {
        if (Z[1, k] != delim) Y = Y, Z[1, k]
        k = k + 1
    }
    return(Y)
}

function fixdocxfont( ///
    real scalar dh, ///
    real scalar tid, /// 
    real scalar row, ///
    real scalar col)
{
    font = st_global("tfont")
    if (font=="bold") m = ///
    _docx_cell_set_textbold(dh, tid, row, col, 1)
    if (font=="italic") m = ///
    _docx_cell_set_textitalic(dh, tid, row, col, 1)
    return(m)
}


function fixfont( ///
    string scalar X)
{
    font = st_global("tfont")
    style = st_global("style") 
    if (style == "tex"){ 
        if (font == "bold") Z = "\textbf{" + X + "}" 
        else if (font == "italic") Z = "\emph{" + X + "}" 
        if (font == "plain") Z = X
    }
    else if (style == "htm") {
        if (font == "bold") Z = "<strong>" + X + "</strong>"
        else if (font=="italic") Z = "<em>" + X + "</em>" 
        if (font=="plain") Z = X
    }   
    else Z = X
    return(Z)
}

function familysize( ///
    string scalar X)
{
    fontsize = st_global("fontsize")
    family = st_global("family")
    if (fontsize != "" | family != "") {
        if (fontsize != "") {
            mult = st_numscalar("mult")
            size = strtoreal(fontsize) * mult
            X = X + "font-size: " + strofreal(size) + "px;"
        }
        if (family != "") X = X + " font-family: " + family + ";"
    }
    return(X)
}


function updatelines( ///
    real matrix thelines, ///
    real scalar therow)
{
    thelines = st_matrix("linelist")
    thelines = thelines, therow
    st_matrix("linelist", thelines)
    thelines = st_matrix("linelist")
    return(thelines)
}


function fixmulti( ///
    string matrix inrow)
{
    w = cols(inrow)
    mstr = J(1,w,"")
    mnum = J(1,w,0)
    k = 1
    mstr[1,1] = inrow[1,2]
    mnum[1,1] = 1
    for (j=3; j<=w; j++) {
        p = j-1
        if (inrow[1,j]==inrow[1,p]) mnum[1,k] = mnum[1,k]+1
        else {
            k = k+1
            mstr[1,k] = inrow[1,j]
            mnum[1,k] = 1
        } 
    }
    count = sum(mnum)
    multi1 = mstr[1,1]
    multi2 = strofreal(mnum[1,1])
    j = 2
    while (mnum[1,j]~=0) {
        multi1 = multi1, mstr[1,j]
        multi2 = multi2, strofreal(mnum[1,j])
        j = j+1
    }
    multi = multi1 \ multi2
    if (cols(multi)==count) multi[2,1] = "na"
    return(multi)
} 

function rotate( /// 
    string scalar X)
{
    style = st_global("style")
    angle = st_global("angle")
    if (style=="tex" & angle~="0") {
        Z = "\rot{"+angle+"}{"+X+"}"
    }
    else Z = X
    return(Z)
}


function texclean( /// 
    string scalar X)
{
    a = X
    style = st_global("style")
    if (style=="tex"){ 
        b = subinstr(a,"$","\\$")
        c = subinstr(b,"&","\&")
        d = subinstr(c,"_","\_")
        e = subinstr(d,"%","\%")
        f = subinstr(e,"<","$<$")
        g = subinstr(f,">","$>$")
        h = subinstr(g,"+","$+$")
    }
    else h = a
    return(h)
}

function strip_underscore( /// 
    string scalar X)
{
    a = subinstr(X,"_"," ",.)
    return(a)
}

function check_empty( ///
    string matrix B, ///
    real scalar rowcheck)
{    
    Z = 1
    for (j=2; j<=cols(B); j++) {
        if (B[rowcheck,j] != " ") Z = 0
    }
    return(Z)
/*note that test is against space, because _ is converted to space*/
}

end
