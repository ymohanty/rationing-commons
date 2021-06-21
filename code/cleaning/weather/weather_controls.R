#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#Generates water flow for farmers
#Date: 24 September 2019 
#Author: Viraj Jorapur 

#===============================================================================================================
#===============================================================================================================
#===============================================================================================================
# ===========================
# INSTALL MISSING PACKAGES
# ===========================

# this selectively checks if a set of packages are installed and installs any that are missing
#   (you do not need to understand this piece of code to proceed)



mPackages <- installed.packages()
# Details of installed packages
stInstalled <- rownames( mPackages )
# Isolate thep package names
stRequired <- c( 'sf','sp','tmap','tmaptools','rgdal','raster',
                 'RColorBrewer','foreign','tidyverse','readstata13',
                 'gstat','maptools','stplanr','rlist','GISTools')
#  The required packages

for ( stName in stRequired ){
  if ( !( stName %in% stInstalled ) ){
    cat('****************** Installing ', stName, '****************** \n')
    install.packages( stName, dependencies=TRUE, INSTALL_opts=c('--no-lock'), repos='http://cran.us.r-project.org' )
  }
  library( stName, character.only=TRUE )
}

#======================== PRELIMINARIES==============================================


cat("\014") 

rm(list=ls())


library(sf)
library(sp)
#library(tmap)
#library(tmaptools)
library(rgdal)
library(raster)
library(RColorBrewer)
library(foreign)
library(tidyverse)
library(readstata13)
library(gstat)
library(maptools)
library(stplanr)
library(rlist)
library(GISTools)
library(parallel)

#===============================================================================================================
#===============================================================================================================
#Getting the shapefiles from the destinations
args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/Dropbox/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}
data_path <- "/data"



baseline_data_path <- paste(project_path,data_path,"/farmer_survey/intermediate",sep="")
baseline_data<-read.dta13(paste0(baseline_data_path,"/baseline_survey.dta"))

# Get location data from the encrypted PII 
farmer_location_data <- read.dta13(paste0(baseline_data_path,'/pii_farmer_locations.dta'))

# Merge with baseline data
baseline_data <- baseline_data %>% left_join(farmer_location_data,by="f_id")

#Cleaning the Baseline Data

##Deleting observations which do not have GPS coordinates (613/6377 do not have GPS data)
baseline_data<-baseline_data[complete.cases(baseline_data$g11_gpslongitude), ]

##Keeping only the relevant variables(SDO names and gps location)
baseline_data<-baseline_data %>% dplyr::select(f_id, SDO, g11_gpsaltitude, 
                                               g11_gpslatitude, g11_gpslongitude, avg_source_depth, g11_gpsaccuracy)

##Cleaning away the missing values (1902/5744 do not have a well and thus not useful for analysis)
baseline_data<-baseline_data[!is.na(baseline_data$avg_source_depth),]

##Removing outliers of well depth above 1200
baseline_data<-subset(baseline_data, avg_source_depth < 1200)

farmer_lon_lat<-data.frame(f_id = baseline_data$f_id,
                           lon = baseline_data$g11_gpslongitude,
                           lat = baseline_data$g11_gpslatitude)

weather_data<-read.csv(paste0(project_path,data_path,"/weather/clean/weather_augmented.csv"))
augment<-read.csv(paste0(project_path,data_path,"/weather/clean/daily_temp_farmer.csv"))

augment$f_id<-farmer_lon_lat$f_id

augment<-augment[,-c(1,2)]

weather_data<-dplyr::left_join(weather_data, augment)
#weather_data<-weather_data[,c(1,2,99:110)]
weather_data<-weather_data[,c(1,2,13:17,99,105:114)]

colnames(weather_data)[3:7]<-c("ppt_nov","ppt_dec","ppt_jan","ppt_feb","ppt_mar")

above_temp<-weather_data[,colnames(weather_data) %in% grep("above_",colnames(weather_data), value = TRUE)]

w<-rowSums(above_temp)

weather_data$temp_rabi_hdd<-w

below_temp<-weather_data[,colnames(weather_data) %in% grep("below_",colnames(weather_data), value = TRUE)]

w<-rowSums(below_temp)

weather_data$temp_rabi_cdd<-w

weather_data<-weather_data[,c(1,2,8,19,20)]

weather_data$cumulative_pre_rabi<-weather_data$cumulative_pre_rabi/10

write.csv(weather_data,paste0(project_path,data_path,"/weather/clean/weather_controls.csv"), row.names = FALSE)
          
          
          
          