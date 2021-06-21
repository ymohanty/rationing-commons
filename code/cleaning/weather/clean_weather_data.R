#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This file cleans the weather data 
#Date: 12 November 2019
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
stRequired <- c('checkpoint')
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
library(ggsn)
library(gridExtra)
library(ncdf4)
library(FNN)
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
input_path<-paste(project_path,data_path,"/weather/raw",sep="")

setwd(input_path)

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


#===============================================================================================================
#===============================================================================================================
# Reading Climate Data
output_var<-c()
output_var$f_id<-farmer_lon_lat$f_id
output_var$SDO<-baseline_data$SDO
output_var<-as.data.frame(output_var)

for (var in c("ppt","soil","tmax","tmin")) {
  for(year in c("2016","2017")){
    fname=paste(paste("TerraClimate",var,year,sep="_"),".nc",sep="")
    ncin = nc_open(fname)
    out<-c()
    latitude<-ncvar_get(ncin,"lat")
    longitude<-ncvar_get(ncin,"lon")
    devlat<-sapply(farmer_lon_lat$lat, function(x){which.min(abs(latitude-x))})
    devlon<-sapply(farmer_lon_lat$lon, function(x){which.min(abs(longitude-x))})
    variable_var<-ncvar_get(ncin,var)
    dev_var<-cbind(devlon,devlat)
    out<-t(apply(dev_var, 1, function(x){variable_var[x[1],x[2],]}))
    out<-as.data.frame(out)
    col_names1<-seq(1:ncol(out))
    col_names1<-paste0(var,"_",year,"_",col_names1)
    colnames(out)<-col_names1
    output_var<-cbind(output_var,out)
  }
}

for(i in 3:ncol(output_var)){
  output_var[,i]<-round(output_var[,i],2)
}
#===============================================================================================================
#===============================================================================================================
# Saving the results

write.csv(output_var, paste0(project_path,"/data/weather/clean/weather.csv"),row.names = FALSE)

# Saving the results for the co-ordinates of the farmers

farmer_lon_lat<-farmer_lon_lat[,-1]

write.csv(farmer_lon_lat, paste0(project_path,"/data/geology/clean/farmer_lon_lat.csv"),row.names = FALSE)





 