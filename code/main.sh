#!/bin/sh

#####################################################################################################################
#                                 Rationing the Commons -- Main replication file
#                                       Nicholas Ryan & Anant Sudarshan
#
#   usage: ./main.sh [-h] [-v] [-r <step>] 
#           Option                  Meaning
#           -h                      Short help.
#           -H                      Long help.
#           -r <step>               Run analysis step number <step> and greater. Default = 1.
#           -c                      Run a clean build.
#   
#
#   README: This is the project level master file for replicating the exhibits that appear in the manuscript. 
#   Before executing this script you need to ensure that all software dependencies are resolved. We make this a little bit
#   easier by setting up auto-installers or virtual environments wherever possible. However, five broadly defined
#   environments need to be manually set up:
#       
#       1) Stata 15 with terminal utility [ "stata" should be on PATH ]
#       2) R and RStudio [ "Rscript" should be on PATH]
#       3) Anaconda [ "conda" AND "conda-env" should be on PATH ]
#       4) MATLAB 2019a or higher [ "matlab -batch" should be on PATH ] 
#       5) Bash or another POSIX compliant Unix shell [ Mac/Linux users can use the default shell;
#                                                       Windows users can use the Linux subsystem ]
#
#
#   PROJECT STRUCTURE OVERVIEW: This code for this project can be broadly divided into three sections: cleaning, marginal
#   analysis, and structural analysis. The cleaning section involves creating usable data from the raw files, along with
#   generating the variables that will be used later in the analysis. The final steps of the cleaning involve creating the 
#   working data for analysis, which combines the farmer survey, geological data, soil data, and weather data in one date file.
#   Some of the descriptive exhibits from the manuscript are generated in this section. Note that some cleaning steps require access 
#   to farmers' personally identifiable information (PII);  as such, you must be explicitly authorized to access this data in 
#   order to replicate these steps. To see a visualization of the project structure (with PII data marked), run ./main.sh -v. 
#
#   EXHIBITS: All tables and figures are contained in ~/exhibits/tables and ~/exhibits/figures respectively.
#   The exhibits found in the manuscript are wrapped in ~/exhibits/exhibits.tex which can be compiled with pdflatex 
#   to a viewable pdf document that acts as a container for these exhibits. In order to replicate specific exhibits, you can specify 
#   the corresponding steps (described below) as an option to this main script. The exhibit numbers referred to below are references to
#   the original manuscript. Note that if you are running a clean build, you will need to start from step 1 [ ./main.sh or ./main.sh -r 1]
#               
#                       PROGRAM-STEP            COMMAND             EXHIBITS
#                           6                   ./main.sh -r 6      Figure 2: Power supply in Rajasthan 
#                                                                   Figure D5: Extensive margin
#
#                           10                  ./main.sh -r 10     Table 1: Summary statistics on farmer survey sample
#                                                                   Table 2: Hedonic regressions of profit on well depth
#                                                                   Table C4: First Stage
#                                                                   Table C5: Robustness to instruments
#                                                                   Table C6: Robustness to controls
#                                                                   Table D8: Hedonic regressions of yield on depth
#
#                           
#
#                           11                  ./main.sh -r 11     Table D9: Instrumental variable estimates of farmer adaptation to water scarcity
#
#                           12                  ./main.sh -r 12     Table C7: First stage estimates from production function estimation
#
#                           13                  ./main.sh -r 13     Table 3: Production function estimates
#                                                                   Table 4: Counterfactual production and social surplus
#                                                                   Table 5: Distributional effects of Pigouvian Reform
#                                                                   Table D10: Optimality of ration
#                                                                   Table E11: Parameters used in the dynamic models
#                                                                   Figure 4: Optimality of ration
#                                                                   Figure 5: Distribution of productivity
#                                                                   Figure 6: Shadow cost of status quo ration
#                                                                   Figure 7: Change in profit due to Pigouvian reform       
#
#                           14                  ./main.sh -r 14     Figure 3: Variation in well depth                                     
#   
#   
#   
# 
#
#
#
#
#   
#   
#
#
#
#
#
#####################################################################################################################


############################# COMMAND-LINE ARGUMENTS ##########################################


# ~~~~~~~~~~~~ Meta variables for control flow ~~~~~~~~~~~~~~~~~~~~
# Step of the analysis
stage=1

# Boolean to indicate whether we are
# runninig a clean build
clean_build=0

while getopts ":hHr:c" opt; do
  case ${opt} in
    h )
      echo "usage: ./main.sh [-h] [-v] [-r <step>]\n"
      echo "Option                                  Meaning"
      echo "-h                                      Show this message."
      echo "-H                                      Detailed help."
      echo "-r <step>                               Run analysis step number <step> and greater. Default = 1. Possible range 1-15."
      echo "-c                                      Run a clean build."
      exit
      ;;
    r )
       stage=$OPTARG
       if [ "$stage" -gt 15 ] || [ "$stage" -lt 1 ]; then
            >&2 echo "Error: provide step arguments between 1 and 15inclusive. ./main.sh -h for help"
            exit 1
       fi
       ;;
    c )
        if [ "$stage" -ne 1 ]; then
            >&2 echo "Error: clean builds must start at the beginning of the analysis. [ -r 1 ]"
            exit 1
        fi
        echo "Are you sure you wish to run a clean build? [y/n]"    
        read clean_build
        if [ "$clean_build"  == "y" ]; then
            clean_build=1
        fi
        ;;
    H )
        # Paths
        home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
        cd $home/..
        project_root=$(pwd)
        cd $home

        # Intro
        echo "\n\n"
        cat readme.txt
        echo "\n\n"
        exit 0
        ;;
    \? )
      >&2 echo "Invalid option: $OPTARG"
      >&2 echo "usage: ./main.sh [-h] [-r <step>] [-c]"
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requries an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))


clear
################################# FUNCTION DEFINITIONS ##########################################

# @Override
# Override echo for Linux operating systems
machine="$(uname -s)"
if [ "$machine" == "Linux" ]; then
    echo () {
        printf "$1\n\n"
    }
fi


# Handle errors from Stata, R and MATLAB subroutines by using regular expressions to 
# search for error messages in the log files.
# We do NOT want to clutter stdout with subroutine output and so all the output is kept in
# conveniently located logs.
handle_error () {
    local error=$(grep $1 "$2")
    if [ ! -z "$error" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            say error
        fi
        echo "That code ran with error(s): ${error}"
        echo "Check logs at: ${2}"
        exit 1
    fi
}


# @Override 
# Just a spinner to tell you we are not done yet!
wait () {
    local pid=$!
    local spinner="-\|/"

    local i=0
    echo "\n"
    while kill -0 $pid &>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\rWorking...${spinner:$i:1}"
        sleep .1
    done
    printf "\033[2K"
    echo "\rDone"
}


###################################### PROJECT LEVEL GLOBALS ################################################

# Paths
home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$home/.."
project_root="$(pwd)"
cd "$home"

# Intro
echo "\n\n"
cat readme.txt
echo "\n\n"

# Prompt for IRB authorization
echo "Are you authorized to view the PII related to this project [y/n]: "
read pii_auth

# STATA
if [ -x "$(command -v stata-mp)" ]; then
    stata="stata-mp"
elif [ -x "$(command -v stata-se)" ]; then
    stata="stata-se"
elif [ -x  "$(command -v stata)" ]; then
    stata="stata"
else
    echo "Error: please install the Stata terminal utility!"
    exit 1
fi

# R
if [ -x "$(command -v Rscript)" ]; then
    r="Rscript"
else
    echo "Error: please install R!"
    exit 1
fi

# PYTHON
if [ -x "$(command -v conda)" ]; then
    if [ -d "./rationing_commons_venv" ]; then
        echo "\n Activating conda virtual environment...\n"
        source activate ./rationing_commons_venv
    else
        echo "Generating conda virtual environment...\n"
        conda-env create --prefix rationing_commons_venv --file=environment.yml 

        echo "\n Activating conda virtual environment...\n"
        source activate ./rationing_commons_venv
    fi
else
    echo "Error: please install conda!"
    exit 1
fi


# MATLAB (R2019a)
if [ -x "$(command -v matlab)" ]; then
    matlab="matlab -batch"
else
    echo "Error: install or update MATLAB to R2019a or newer and add to path!"
    exit 1
fi

# Pre-analysis clear
sleep 1
clear


################################ CLEAR THE OUTPUT-SPACE ###########################
if [ "$clean_build" -eq 1 ]; then
    
    echo "Clearing the output space"
    sleep 1
    
    # Clean out data
    rm "${project_root}/data/work/"*
    rm "${project_root}/data/soil/clean/"*
    rm "${project_root}/data/farmer_survey/clean/"*

    # Remove unencrypted PII data if it exists
    rm "${project_root}/data/farmer_survey/intermediate/pii_farmer_locations.dta"
    rm "${project_root}/data/pending_consumers/raw.tar.gz"
    rm -r "${project_root}/data/pending_consumers/raw"

    # Clean out exhibits
    rm "${project_root}/exhibits/tables/"*
    rm "${project_root}/exhibits/figures/"*

    echo "Done"
    sleep 5
    clear

fi

################################# CLEANING ######################################


#~~~~~~~~~~~~~~~~~~~ DATA CONSTRUCTION ~~~~~~~~~~~~~~~~~~~~~

# The code in this section is used to clean the raw data and generate intermediate datasets.
# No exhibits are generated by code in this particular section.

# BASELINE SURVEY: Construction
if [ "$stage" -eq 1 ]; then

    cd "${home}/cleaning/farmer_survey"
    echo "STEP 1: Building the farmer crop level data from intermediate baseline data.\n"
    echo "Do-File: ${project_root}/code/cleaning/farmer_survey/build_farmer_crop_data.do\n"
    echo "Input(s) ${project_root}/data/farmer_survey/intermediate/clean_baseline_survey.dta\n"
    echo "Output(s): ${project_root}/data/farmer_survey/clean/clean_farmer_crop_level.dta\n"
    echo "EXHIBITS: None\n"
    echo "Logs: $(pwd)/logs/build_farmer_crop_data.log"
    $stata -b build_farmer_crop_data.do "${project_root}" &
    wait
    mv build_farmer_crop_data.log "${home}/cleaning/farmer_survey/logs"
    handle_error " r([0-9]*) " "${home}/cleaning/farmer_survey/logs/build_farmer_crop_data.log"

    echo "------------------------------------------------------------"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
fi



# PENDING CONSUMERS: Construction
# NOTE: The raw data for list of pending consumers contains personally identifiable information. To replicate this section you need to
# have been granted explicit access on the project IRB documents. 

if [ "$stage" -eq 2 ]; then

    if [ "$pii_auth" == "y" ]; then

        # Change directory to data
        cd "${project_root}/data/pending_consumers" 
        
        # Decrypt directory
        gpg --output raw.tar.gz --decrypt raw.tar.gz.gpg 2> gpg_error.log
        handle_error " failed " "gpg_error.log"
        rm gpg_error.log

        # Extract directory from zip
        tar xvf raw.tar.gz

        sleep 3
        clear

        # Run scripts
        cd "${home}/cleaning/pending_consumers"    
        echo "STEP 2: Clean consumer application data for farmers applying for an agricultural connection.\n"
        echo "Python File: ${project_root}/code/cleaning/pending_consumers/clean_consumer_data.py\n"
        echo "Input(s) ${project_root}/data/pending_consumers/raw/*\n"
        echo "Output(s): ${project_root}/data/pending_consumers/clean/waiting_times_all.dta\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/clean_pending_consumers.log"
        python clean_consumer_data.py "${project_root}/" 2>&1 "./logs/clean_pending_consumers.log" &
        wait
        handle_error ".*Error.*" "${home}/cleaning/pending_consumers/logs/clean_pending_consumers.log"

        # Clean out decrypted raw files
        cd "${project_root}/data/pending_consumers" 
        rm raw.tar.gz
        rm -r raw

    else
        echo "Skipping step $stage since this particular step uses PII"
        sleep 2
    fi
   
    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
fi

# GEOLOGICAL VARIABLES: Construction
# NOTE: The construction of geological variables requires access to farmer locations which is considered personally identifiable information. To replicate this section you need to
# have been granted explicit access on the project IRB documents. 
if [ "$stage" -eq 3 ]; then

    if [ "$pii_auth" == "y" ]; then

        # Chane direction to farmer survey
        cd "${project_root}/data/farmer_survey/intermediate"

        # Decrypt location data
        gpg --output pii_farmer_locations.dta --decrypt pii_farmer_locations.dta.gpg 2> gpg_error.log
        handle_error " failed " "gpg_error.log"
        rm gpg_error.log

        # Run scripts
        cd "${home}/cleaning/geology"
        echo "STEP 3a: Constructing the geological variables from the raw shapefiles\n"
        echo "R-script: ${project_root}/code/cleaning/geology/build_geological_variables.R\n"
        echo "Input(s): ${project_root}/data/geology/raw/gw_prospect_maps/shapefiles/\n"
        echo "Output(s): ${project_root}/data/geology/clean/geo-coded_variables\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/build.Rout AND build_error.Rout\n\n"
        $r --no-save --no-restore --verbose build_geological_variables.R "${project_root}" > ./logs/build_geological_variables.Rout 2> ./logs/build_geological_variables_err.Rout &
        wait
        handle_error ".rror.*" "${home}/cleaning/geology/logs/build_geological_variables_err.Rout"

        echo "STEP 3b: Creating interaction variables in the geological dataset for the instrument set.\n"
        echo "R-script: ${project_root}/code/cleaning/geology/interaction_variables.R\n"
        echo "Input(s): ${project_root}/data/geology/clean/geo-coded_variables.csv\n"
        echo "Output(s): ${project_root}/data/geology/clean/clean_geological_variables.csv\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/interaction_variables.Rout AND error_interaction_variables.Rout\n\n"
        $r --no-save --no-restore --verbose build_interaction_variables.R "${project_root}"  > ./logs/build_interaction_variables.Rout 2> ./logs/build_interaction_variables_err.Rout &
        wait
        handle_error ".rror.*" "${home}/cleaning/geology/logs/build_interaction_variables_err.Rout"

        # Remove PII 
        cd "${project_root}/data/farmer_survey/intermediate"
        rm pii_farmer_locations.dta
        
        # Remove intermediate data
        cd "${project_root}/data/geology/clean"
        rm geo-coded_variables.csv
        rm -r geo-coded_variables
    else
        echo "Skipping step $stage since this particular step uses PII"
        sleep 2
    fi

    echo "------------------------------------------------------------"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
  
fi

# WEATHER VARIABLES: Construction
# NOTE: The construction of weather variables requires access to farmer locations which is considered personally identifiable information. To replicate this section you need to
# have been granted explicit access on the project IRB documents. 
if [ "$stage" -eq  4 ]; then
    if [ "$pii_auth" == "y" ]; then

        # Chane direction to farmer survey
        cd "${project_root}/data/farmer_survey/intermediate"

        # Decrypt location data
        gpg --output pii_farmer_locations.dta --decrypt pii_farmer_locations.dta.gpg 2> gpg_error.log
        handle_error " failed " "gpg_error.log"
        rm gpg_error.log
    
        cd "${home}/cleaning/weather"
        echo "STEP 4a: Clean raw weather data.\n"
        echo "R-script: ${home}/cleaning/weather/clean_weather_data.R\n"
        echo "Input(s): ${project_root}/data/farmer_survey/clean/clean_baseline_survey.dta
                        ${project_root}/analysis/data/weather/raw/*\n"
        echo "Output(s): ${project_root}/analysis/data/weather/clean/weather.csv
                         ${project_root}/data/geology/clean/farmer_lon_lat.csv\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/clean_weather_data.Rout\n"
        $r --no-save --no-restore --verbose clean_weather_data.R "${project_root}"  > ./logs/clean_weather_data.Rout 2> ./logs/clean_weather_data_err.Rout &
        wait
        handle_error ".rror.*" "${home}/cleaning/weather/logs/clean_weather_data_err.Rout"

        echo "\n\n"

        echo "STEP 4b: Generate key precipitation variables.\n"
        echo "Do-file: ${home}/cleaning/weather/gen_weather_augmented.do\n"
        echo "Input(s): ${project_root}/data/weather/clean/weather.csv\n"
        echo "Output(s): ${project_root}/data/weather/clean/weather_augmented.csv\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/clean_weather_data.Rout\n"
        $stata -b gen_weather_augmented.do "${project_root}" &
        wait
        mv gen_weather_augmented.log "./logs"
        handle_error "r([0-9]*)" "${home}/cleaning/weather/logs/gen_weather_augmented.log"

        echo "\n\n"

        echo "STEP 4c: Generate key temperature variables.\n"
        echo "R-script: ${project_root}/code/cleaning/weather/daily_temp.R\n"
        echo "Input(s): ${project_root}/data/weather/raw/MODIS_temp_1k_daily/*\n
                        ${project_root}/data/geology/clean/farmer_lon_lat.csv\n"
        echo "Output(s): ${project_root}/data/weather/clean/daily_temp.csv"
        echo "          ${project_root}data/weather/clean/daily_temp_farmer.csv\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/daily_temp.Rout\n"
        $r --no-save --no-restore --verbose daily_temp.R "${project_root}" > ./logs/daily_temp.Rout 2> ./logs/daily_temp_err.Rout &
        wait
        handle_error ".rror.*" "${home}/cleaning/weather/logs/daily_temp_err.Rout"

        echo "\n\n"

        echo "STEP 4d: Generate weather control set.\n"
        echo "R-script: ${project_root}/code/cleaning/weather/weather_controls.R\n"
        echo "Input(s): ${project_root}/data/weather/clean/weather_augmented.csv\n
                        ${project_root}/data/weather/clean/daily_temp_farmer.csv\n"
        echo "Output(s): ${project_root}/data/weather/clean/weather_controls.csv\n"
        echo "EXHIBITS: None\n"
        echo "Logs: $(pwd)/logs/weather_controls.Rout\n"
        $r --no-save --no-restore --verbose weather_controls.R "${project_root}" > ./logs/weather_controls.Rout 2> ./logs/weather_controls_err.Rout &
        wait
        handle_error ".rror.*" "${home}/cleaning/weather/logs/weather_controls_err.Rout"

        echo "------------------------------------------------------------"

        # Remove PII
        cd "${project_root}/data/farmer_survey/intermediate"
        rm pii_farmer_locations.dta

        cd "${project_root}/data/weather/clean"
        rm farmer_lon_lat.csv
        rm weather_augmented.csv
        rm weather.csv
        rm daily_temp*

    else
        echo "Skipping step $stage since this particular step uses PII"
        sleep 2
    fi

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
fi


# ~~~~~~~~~~~~~~~~~~~~~~ IMPUTATIONS AND DESCRIPTIVE EXHIBITS ~~~~~~~~~~~~~~~~~~~~~~

# BASELINE SURVEY: Generate imputed water quantity
if [ "$stage" -eq 5 ]; then

    cd "${project_root}/code/cleaning/farmer_survey"
    echo "STEP 5: Compute the water flow from farmer wells using the method described in Appendix A section C.\n"
    echo "R-script: ${project_root}/code/cleaning/farmer_survey/water_flow.R\n"
    echo "Input(s): ${project_root}/data/farmer_survey/clean/farmer_crop_with_imputed_variables.dta\n"
    echo "Output(s): ${project_root}/data/geology/clean/water_flow.csv"
    echo "EXHIBITS: None\n"
    echo "Logs: $(pwd)/logs/water_flow.Rout\n"

    $r --no-save --no-restore --verbose water_flow.R "${project_root}" > ./logs/water_flow.Rout 2> ./logs/error_water_flow.Rout &
    wait
    handle_error ".rror.*" "${home}/cleaning/farmer_survey/logs/error_water_flow.Rout"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear


fi

# BASELINE SURVEY: Generate imputed profit variables
if [ "$stage" -eq 6 ]; then

    cd "${project_root}/code/cleaning/farmer_survey"
    echo "STEP 6: Creating the imputed variables (profits etc) in the farmer-crop level data and generate descriptive exhibits
                  on the power supply in Rajasthan.\n"
    echo "DO-file ${project_root}/code/cleaning/farmer_survey/impute_profits_farmer_crop.do\n"
    echo "Input(s): ${project_root}/data/farmer_survey/clean/clean_farmer_crop_level.dta\n"
    echo "Output(s): ${project_root}/data/farmer_survey/clean/baseline_survey_farmer_crop_with_imputed_variables.dta\n"
    echo "EXHIBITS:
                    Figure 2: Power supply in Rajasthan 
                    Figure D5: Extensive margin \n"
    echo "Logs: $(pwd)/logs/impute_profits_farmer_crop.log\n"
    $stata -b impute_profits_farmer_crop.do "${project_root}" &
    wait
    mv impute_profits_farmer_crop.log "${home}/cleaning/farmer_survey/logs"
    handle_error " r([0-9]*) " "${home}/cleaning/farmer_survey/logs/impute_profits_farmer_crop.log"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear


fi

# BASELINE SURVEY: Select variables for analysis
if [ "$stage" -eq 7 ]; then

    cd "${project_root}/code/cleaning/farmer_survey"
    echo "STEP 7: Selecting baseline data variables for analysis\n"
    echo "DO-file: ${project_root}/code/cleaning/farmer_survey/select_variables.do\n"
    echo "Input(s): ${project_root}/data/farmer_survey/clean/baseline_survey_farmer_crop_with_imputed_variables.dta\n"
    echo "Output(s): 
                    CROP-LEVEL: ${project_root}/data/farmer_survey/clean/baseline_survey_selected_variables_crop_level.dta
                    FARMER-LEVEL: ${project_root}/data/farmer_survey/clean/baseline_survey_selected_variables.dta\n"
    echo "EXHIBITS: None\n"
    echo "Logs: $(pwd)/logs/select_variables.log\n"

    $stata -b select_variables.do "${project_root}" &
    wait
    mv select_variables.log "${home}/cleaning/farmer_survey/logs"
    handle_error " r([0-9]*) " "${home}/cleaning/farmer_survey/logs/select_variables.log"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear

fi

# SOIL: Construction
if [ "$stage" -eq 8 ]; then

    cd "${home}/cleaning/soil/"
    echo "STEP 8: Clean and store soil quality data from extracted from Soil Health cards.\n"
    echo "Python-script: ${home}/cleaning/soil/clean_soil_data.py\n"
    echo "Input(s): ${project_root}/analysis/data/soil/raw/*.xlsx\n"
    echo "Output: ${project_root}/analysis/data/soil/clean/soil_controls.dta\n"
    echo "EXHIBITS: None\n"
    echo "Logs: ${home}/cleaning/soil/logs/clean_soil_data.log"
    
    python clean_soil_data.py "${project_root}/" 2> "${home}/cleaning/soil/logs/clean_soil_data.log" &
    wait
    handle_error ".*Error.*" "${home}/cleaning/soil/logs/clean_soil_data.log"

    echo "------------------------------------------------------------"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear

fi


# ~~~~~~~~~~~~~~~~~~~~~~ MERGE DATASETS TO CREATE WORKING DATA ~~~~~~~~~~~~~~~~~~~~~~

# MERGE: Survey + Geology + Soil + Weather
if [ "$stage" -eq 9 ]; then

    cd "${home}/cleaning/merge"
    echo "STEP 9: Merge the baseline survey with geological data, soil health data, and weather data.\n"
    echo "DO-file: ${home}/cleaning/merge/merge_all.do\n"
    echo "Input(s): 
                    SURVEY: ${project_root}/data/farmer_survey/clean/baseline_survey_selected_variables.dta
                    GEOLOGY: ${project_root}/data/geology/clean/clean_geological_variables.csv
                    SOIL: ${project_root}/data/soil/clean/soil_controls.dta
                    WEATHER: ${project_root}/data/weather/clean/soil_controls.dta\n"
    echo "Output(s):
                   CROP-LEVEL:  ${project_root}/data/work/marginal_analysis_sample_crop_level.dta
                   FARMER-LEVEL: {project_root}/data/work/marginal_analysis_sample.dta\n"
    echo "EXHIBITS: None\n"
    echo "Logs: ${home}/cleaning/merge/logs/merge_all.log\n"
    
    $stata -b merge_all.do "${project_root}" &
    wait
    mv merge_all.log "${home}/cleaning/merge/logs"
    handle_error " r([0-9]*) " "${home}/cleaning/merge/logs/merge_all.log"

    echo "------------------------------------------------------------"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
fi

############################ MARGINAL ANALYSIS ##################################

# MARGINAL ANALYSIS: Profit regressions
if [ "$stage" -eq 10 ]; then
    cd "${project_root}/code/marginal_analysis"
    echo "STEP 10: Run the reduced form regressions estimating the effect of water depth on profits.
                   Generate clean sample for production function analysis.\n"
    echo "Do-file: ${project_root}/code/marginal_analysis/rationing_main.do\n"
    echo "Input(s): ${project_rooot}/data/work/marginal_analysis_sample_crop_level.dta\n"
    echo "Output(s): 
                    MAIN SAMPLE: ${project_root}/analysis/data/work/production_inputs_outputs.dta 
                    MATLAB SAMPLE: ${project_root}/analysis/data/work/production_inputs_outputs.txt\n"
    echo "EXHIBITS:
                        Table 1: Summary statistics on farmer survey sample
                        Table 2: Hedonic regressions of profit on well depth
                        Table C4: First Stage
                        Table C5: Robustness to instruments
                        Table C6: Robustness to controls
                        Table D8: Hedonic regressions of yield on depth\n"

    echo "Logs: ${home}/marginal_analysis/logs/rationing_main.log\n"
          
    $stata -b rationing_main.do "${project_root}" &
    wait
    mv rationing_main.log "./logs"
    handle_error " r([0-9]*) " "${project_root}/code/marginal_analysis/logs/rationing_main.log"

    echo "------------------------------------------------------------"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
fi

# MARGINAL ANALYSIS: Farmer adaptation to water scarcity
if [ "$stage" -eq 11 ]; then
    
    cd "${project_root}/code/marginal_analysis" 
    echo "STEP 11: Run OLS and IV regressions to determine the effect of water scarcity on potential margins of adaptation for farmers.\n"
    echo "Do-file: ${project_root}/code/marginal_analysis/rationing_adaptation.do\n"
    echo "Input(s): 
            ${project_root}/data/farmer_survey/clean/farmer_crop_with_imputed_variables.dta
            ${project_root}/data/work/production_inputs_outputs.dta\n"
    echo "Output(s): None\n"
    echo "EXHIBITS:
                    Table D9: Instrumental variable estimates of farmer adaptation to water scarcity\n"
    echo "Logs: $(pwd)/logs/rationing_adaptation.log\n"
    $stata -b rationing_adaptation.do "${project_root}" &
    wait
    mv rationing_adaptation.log "./logs"
    handle_error " r([0-9]*) " "${project_root}/code/marginal_analysis/logs/rationing_adaptation.log"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear

fi


########################### STRUCTURAL ANALYSIS #################################

# STRUCTURAL ANALYSIS: First stage of the production function
if [ "$stage" -eq 12 ]; then

    cd "${project_root}/code/structural_analysis/" 
    echo "STEP 12: First stage of instrumental variable estimates of the production function.\n"
    echo "Do-file: ${project_root}/code/structural_analysis/input_instruments_ols\n"
    echo "Input(s): ${project_root}/data/work/production_inputs_outputs.dta\n"
    echo "Output(s): None\n"
    echo "EXHIBITS:         
                    Table C7: First stage estimates from production function estimation\n"
    echo "Logs: $(pwd)/logs/input_instruments_ols.log\n"
    $stata -b input_instruments_ols.do "${project_root}" &
    wait
    mv input_instruments_ols.log "./logs"
    handle_error " r([0-9]*) " "${project_root}/code/structural_analysis/logs/input_instruments_ols.log"

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear

fi

# STRUCTURAL ANALYSIS: Run the structural analysis main file
if [ "$stage" -eq 13 ]; then
    
    cd "${project_root}/code/cleaning/farmer_survey"
    echo "STEP 13a: Extract data on depths of wells dug over time from farmer survey.\n"
    echo "Do-file: ${project_root}/code/cleaning/farmer_survey/rationing_dynamics_data.do\n"
    echo "Input(s): ${project_root}/code/farmer_survey/clean/baseline_survey_farmer_crop_with_imputed_variables.dta\n"
    echo "Output(s): ${project_root}/analysis/data/work/depth_data.txt"
    echo "           ${project_root}/analysis/data/work/mean_init_conditions.txt\n"
    echo "EXHIBITS:
                 Figure E6: Depths of wells dug by year\n"
    echo "Logs:  $(pwd)/logs/rationing_dynamics_data.log\n"
    $stata -b rationing_dynamics_data.do "${project_root}" &
    wait
    mv rationing_dynamics_data.log "./logs"
    handle_error " \br([0-9]*);\b " "./logs/rationing_dynamics_data.log"

    echo "\n\n"

    cd "${project_root}/code/structural_analysis"
    echo "STEP 13b: Run the main file for structural analysis\n"
    echo "MATLAB-script: ${project_root}/code/structural_anaysis/rationing_main.m\n"
    echo "Input(s): ${project_root}/data/work/production_inputs_outputs.txt\n"
    echo "Output(s): None\n"
    echo "Exhibits: 
                    Table 3: Production function estimates
                    Table 4: Counterfactual production and social surplus
                    Table 5: Distributional effects of Pigouvian Reform
                    Table D10: Optimality of ration
                    Table E11: Parameters used in the dynamic models

                    Figure 4: Optimality of ration
                    Figure 5: Distribution of productivity
                    Figure 6: Shadow cost of status quo ration
                    Figure 7: Change in profit due to Pigouvian reform
                    "
    echo "Logs: $(pwd)/logs/rationing_main.log\n"
    $matlab "clear; project_root='${project_root}';  run('rationing_main.m')" > ./logs/rationing_main.log 2> ./logs/error_rationing_main.log &
    wait
    handle_error ".rror.*" "${project_root}/code/structural_analysis/logs/error_rationing_main.log"
    echo "------------------------------------------------------------"

    sleep 5

    # Increment analysis step 
    stage=$((stage + 1)) 
    clear
fi 

########################### MISCELLANEOUS EXHIBITS #################################

# MAPS
if [ "$stage" -eq 14 ]; then
    # === VARIATION IN DEPTH ===
    if [ "$pii_auth" == "y" ]; then

        # Chane direction to farmer survey
        cd "${project_root}/data/farmer_survey/intermediate"

        # Decrypt location data
        gpg --output pii_farmer_locations.dta --decrypt pii_farmer_locations.dta.gpg 2> gpg_error.log
        handle_error " failed " "gpg_error.log"
        rm gpg_error.log

        # Run script
        cd "${project_root}/code/maps/" 
        echo "STEP 14a: Generate maps showing the variation in groundwater depth.\n"
        echo "Rscript: ${project_root}/code/maps/depth_maps.R\n"
        echo "Input(s): ${project_root}/data/geology/*\n"
        echo "Output(s): None\n"
        echo "EXHIBITS:         
                        Figure 3: Variation in well depths\n"
        echo "Logs: $(pwd)/logs/error_depth_maps.log"
        $r --no-save --no-restore --verbose depth_maps.R "${project_root}" > ./logs/depth_maps.Rout 2> ./logs/error_depth_maps.Rout &
        wait
        handle_error " .rror.*" "${project_root}/code/maps/logs/error_depth_maps.Rout"
        echo "\n\n"

        # === GROUNDWATER LEVELS ===
        cd "${project_root}/code/maps/"
        echo "STEP 14b: Generate map showing the extent of groundwater depletion in India.\n"
        echo "Rscript: ${project_root}/code/maps/groundwater_level_map.R\n"
        echo "Input(s): ${project_root}/data/geology/*\n"
        echo "Output(s): None\n"
        echo "EXHIBITS:
                        Figure 1 (Panel A):   Groundwater exploitation\n"
        echo "Logs: $(pwd)/logs/error_groundwater_level_map.log"

        $stata -b gen_predicted_depth.do "${project_root}" &
        wait
        mv gen_predicted_depth.log "./logs"
        handle_error " \br([0-9]*);\b " "./logs/gen_predicted_depth.log"

        $r --no-save --no-restore --verbose groundwater_level_map.R "${project_root}" > ./logs/groundwater_level_map.Rout 2> ./logs/error_groundwater_level_map.Rout &
        wait
        handle_error " .rror.*" "${project_root}/code/maps/logs/error_groundwater_level_map.Rout"    
        echo "\n\n"

        # Remove PII
        cd "${project_root}/data/farmer_survey/intermediate"
        rm pii_farmer_locations.dta
    fi

    # === SUBSIDY STATES ===
    cd "${project_root}/code/maps/"
    echo "STEP 14b: Generate map showing the states of India that ration power for agricultural use.\n"
    echo "Rscript: ${project_root}/code/maps/ration_states_map.R\n"
    echo "Input(s): ${project_root}/data/geology/*\n"
    echo "Output(s): None\n"
    echo "EXHIBITS:
                    Figure 1 (Panel B):   States that ration power for agricultural use\n"
    echo "Logs: $(pwd)/logs/error_ration_states_map.log"

    $r --no-save --no-restore --verbose ration_states_map.R "${project_root}" > ./logs/ration_states_map.Rout 2> ./logs/error_ration_states_map.Rout &
    wait
    handle_error " .rror.*" "${project_root}/code/maps/logs/error_ration_states_map.Rout"    
    echo "\n\n"


    # Increment analysis step 
    stage=$((stage + 1)) 
    clear

fi


