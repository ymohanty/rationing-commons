/**********************************************************************
Project: Rationing the Commons

Name: load_file_paths.do	

Purpose: Loads all the project directories as locals.

Author:  Yashaswi Mohanty

Date  :   7/22/2019
***********************************************************************/


// Set up project variables
clear all
set more off
pause on
cap log close
set maxvar 20000
set matsize 10000
pause on

// ADOPATH
adopath ++ "`PROJECT_ROOT'/code/ado/"

//====================== Set up data directories =======================
local RAW_FARMER_SURVEY "`PROJECT_ROOT'/data/farmer_survey/intermediate"

// WITHIN RAW SURVEY

local CLEAN_FARMER_SURVEY "`PROJECT_ROOT'/data/farmer_survey/clean"

local RAW_GEOLOGICAL_DATA "`PROJECT_ROOT'/data/geology/raw/gw_prospect_maps/shapefiles"
local CLEAN_GEOLOGICAL_DATA "`PROJECT_ROOT'/data/geology/clean"

local RAW_SOIL_DATA "`PROJECT_ROOT'/data/soil/raw" 
local CLEAN_SOIL_DATA "`PROJECT_ROOT'/data/soil/clean"

local RAW_WAITING_DATA "`PROJECT_ROOT'/data/pending_consumers/raw"
local CLEAN_WAITING_DATA "`PROJECT_ROOT'/data/pending_consumers/clean"

local RAW_WEATHER_DATA "`PROJECT_ROOT'/data/weather/raw"
local CLEAN_WEATHER_DATA "`PROJECT_ROOT'/data/weather/clean"

local WORKING_DATA "`PROJECT_ROOT'/data/work"

//===================== Set up code directories =========================

// DATA CLEANING
local farmer_survey_cleaning_code "`PROJECT_ROOT'/code/cleaning/farmer_survey/"
local geological_data_cleaning_code "`PROJECT_ROOT'/code/cleaning/geology/"
local merged_data_cleaning_code "`PROJECT_ROOT'/code/cleaning/merge/"

// DATA ANALYSIS
local marginal_analysis "`PROJECT_ROOT'/code/marginal_analysis/"

//===================== Set up output paths =============================

local TABLES "`PROJECT_ROOT'/exhibits/tables"
local FIGURES "`PROJECT_ROOT'/exhibits/figures"

//==================== Packages =========================================


// Packages needed to run LASSO IV 
foreach package in univar pdslasso winsor estout ranktest tabout outtable reclink {
	cap which `package'
	if _rc == 111 ssc install `package'
}

