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
library(tmap)
library(tmaptools)
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
library(FNN)
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

setwd(paste0(project_path,data_path,"/weather/raw/MODIS_temp_1k_daily"))

files_list<-list.files(".")
files_list<-files_list[-length(files_list)]

final_data<-data.frame()

for(files in files_list){
  data<-read.csv(paste0("./",files,"/Daily-Temperature-MOD11A1-006-results.csv"))
  data$MOD11A1_006_LST_Day_1km<-ifelse(data$MOD11A1_006_LST_Day_1km > 0,
                                       data$MOD11A1_006_LST_Day_1km-273.15,
                                       data$MOD11A1_006_LST_Day_1km)
  data$Date<-as.Date(data$Date)
  pre_rabi<-(data$Date > as.Date("2016-06-30")) & (data$Date < as.Date("2016-11-01"))
  rabi<-(data$Date >= as.Date("2016-11-01")) & (data$Date <= as.Date("2017-03-31"))
  data$pre_rabi<-pre_rabi
  data$rabi<-rabi
  data<-data%>%dplyr::group_by(Latitude, Longitude)
  data$MOD11A1_006_LST_Day_1km<-ifelse(data$MOD11A1_006_LST_Day_1km>0,
                                       data$MOD11A1_006_LST_Day_1km-29,
                                       data$MOD11A1_006_LST_Day_1km)
  nested_data<-data%>%nest 
  new_data<-data.frame(Latitude = nested_data$Latitude,
                       Longitude = nested_data$Longitude)
  #new_data$above_pre_rabi<-NA
  #new_data$missing_pre_rabi<-NA
  #new_data$below_pre_rabi<-NA
  #new_data$above_rabi<-NA
  #new_data$missing_rabi<-NA
  #new_data$below_rabi<-NA
  new_data$above_nov<-NA
  new_data$below_nov<-NA
  new_data$above_dec<-NA
  new_data$below_dec<-NA
  new_data$above_jan<-NA
  new_data$below_jan<-NA
  new_data$above_feb<-NA
  new_data$below_feb<-NA
  new_data$above_mar<-NA
  new_data$below_mar<-NA
  for (a in 1:nrow(nested_data)) {
    temp_data<-as.data.frame(nested_data$data[a])
    
    greater_zero<-temp_data$MOD11A1_006_LST_Day_1km>0
    zero1<-temp_data$MOD11A1_006_LST_Day_1km==0
    lesser_zero<-temp_data$MOD11A1_006_LST_Day_1km<0
    
    #greater_zero1<-greater_zero & temp_data$pre_rabi
    #zero2<-zero1 & temp_data$pre_rabi
    #lesser_zero1<-lesser_zero & temp_data$pre_rabi
    #new_data$above_pre_rabi[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero1])
    #new_data$missing_pre_rabi[a]<-sum(zero2)
    #new_data$below_pre_rabi[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero1])
    
    #greater_zero2<-greater_zero & temp_data$rabi 
    #zero3<-greater_zero & temp_data$rabi 
    #lesser_zero2<-lesser_zero & temp_data$rabi 
    #new_data$above_rabi[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero2])
    #new_data$missing_rabi[a]<-sum(zero3)
    #new_data$below_rabi[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero2])
    
    greater_zero_nov<-greater_zero & (temp_data$Date <= as.Date("2016-11-30")
                        & temp_data$Date >= as.Date("2016-11-01"))
    lesser_zero_nov<-lesser_zero & (temp_data$Date <= as.Date("2016-11-30")
                                      & temp_data$Date >= as.Date("2016-11-01"))
    
    new_data$above_nov[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero_nov])
    new_data$below_nov[a]<-abs(sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero_nov]))
    
    greater_zero_dec<-greater_zero & (temp_data$Date <= as.Date("2016-12-31")
                                      & temp_data$Date >= as.Date("2016-12-01"))
    lesser_zero_dec<-lesser_zero & (temp_data$Date <= as.Date("2016-12-31")
                                    & temp_data$Date >= as.Date("2016-12-01"))
    
    new_data$above_dec[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero_dec])
    new_data$below_dec[a]<-abs(sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero_dec]))
    
    greater_zero_jan<-greater_zero & (temp_data$Date <= as.Date("2017-01-31")
                                      & temp_data$Date >= as.Date("2017-01-01"))
    lesser_zero_jan<-lesser_zero & (temp_data$Date <= as.Date("2017-01-31")
                                    & temp_data$Date >= as.Date("2017-01-01"))
    
    new_data$above_jan[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero_jan])
    new_data$below_jan[a]<-abs(sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero_jan]))
    
    
    greater_zero_feb<-greater_zero & (temp_data$Date <= as.Date("2017-02-28")
                                      & temp_data$Date >= as.Date("2017-02-01"))
    lesser_zero_feb<-lesser_zero & (temp_data$Date <= as.Date("2017-02-28")
                                    & temp_data$Date >= as.Date("2017-02-01"))
    
    new_data$above_feb[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero_feb])
    new_data$below_feb[a]<-abs(sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero_feb]))
    
    greater_zero_mar<-greater_zero & (temp_data$Date <= as.Date("2017-03-31")
                                      & temp_data$Date >= as.Date("2017-03-01"))
    lesser_zero_mar<-lesser_zero & (temp_data$Date <= as.Date("2017-03-31")
                                    & temp_data$Date >= as.Date("2017-03-01"))
    
    new_data$above_mar[a]<-sum(temp_data$MOD11A1_006_LST_Day_1km[greater_zero_mar])
    new_data$below_mar[a]<-abs(sum(temp_data$MOD11A1_006_LST_Day_1km[lesser_zero_mar]))
    
    
  }
  final_data<-rbind(final_data, new_data)
}


write.csv(final_data,paste0(project_path,data_path,"/weather/clean/daily_temp.csv"), row.names = FALSE)

# Getting the farmer's data and predicting farmer's values

farmer_lon_lat<-read.csv(paste0(project_path,data_path,"/geology/clean/farmer_lon_lat.csv"))

Z<-data.frame(Latitude = rep(NA, nrow(farmer_lon_lat)))
Z$Latitude<-farmer_lon_lat$lat
Z$Longitude<-farmer_lon_lat$lon
X<-final_data[,1:2]

for (i in 3:ncol(final_data)) {
  train<-knn.reg(train=X, test=Z,y=final_data[,i],k=5)
  farmer_lon_lat[,i]<-train$pred
}
colnames(farmer_lon_lat)[3:ncol(farmer_lon_lat)]<-colnames(final_data)[3:ncol(final_data)]

#farmer_lon_lat$missing_pre_rabi<-as.integer(farmer_lon_lat$missing_pre_rabi)
#farmer_lon_lat$missing_rabi<-as.integer(farmer_lon_lat$missing_rabi)

#farmer_lon_lat$above_pre_rabi<-round(farmer_lon_lat$above_pre_rabi,2)
#farmer_lon_lat$below_pre_rabi<-round(farmer_lon_lat$below_pre_rabi,2)
#farmer_lon_lat$above_rabi<-round(farmer_lon_lat$above_rabi,2)
#farmer_lon_lat$below_rabi<-round(farmer_lon_lat$below_rabi,2)

farmer_lon_lat[,3:ncol(farmer_lon_lat)]<-round(farmer_lon_lat[,3:ncol(farmer_lon_lat)],2)

write.csv(farmer_lon_lat,paste0(project_path,data_path,"/weather/clean/daily_temp_farmer.csv"), row.names = FALSE)
