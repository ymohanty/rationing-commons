#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This is a file which creates all the interaction variables
#Date: 19 June 2019
#Author: Viraj Jorapur (modified by Yashaswi Mohanty)

#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

# PROJECT PATH
args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/projects/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}


# ===========================
# INSTALL MISSING PACKAGES
# ===========================

# this selectively checks if a set of packages are installed and installs any that are missing
#   (you do not need to understand this piece of code to proceed)

mPackages <- installed.packages()
# Details of installed packages
stInstalled <- rownames( mPackages )
# Isolate thep package names
stRequired <- c( 'checkpoint')
#  The required packages

for ( stName in stRequired ){
  if ( !( stName %in% stInstalled ) ){
    cat('****************** Installing ', stName, '****************** \n')
    install.packages( stName, dependencies=TRUE, INSTALL_opts=c('--no-lock'), repos='http://cran.us.r-project.org' )
  }
  library( stName, character.only=TRUE )
}

#======================== PRELIMINARIES==============================================
library(checkpoint)
checkpoint("2020-07-18",project = project_path, checkpointLocation = paste0(project_path,"/code/"))

library(foreign)
library(tidyverse)
library(readstata13)

#===============================================================================================================
#===============================================================================================================
#Getting the shapefiles from the destinations


data_path <- "/data"
input_path<-paste(project_path,data_path,"/geology/clean",sep="")
output_data_path <- paste(project_path,data_path,"/geology/clean",sep="")
setwd(input_path)
#===============================================================================================================

#Getting the GPS Data for the locations of farmers
geo_variables<-read.csv("geo-coded_variables.csv")

#===============================================================================================================
#===============================================================================================================
# Generating order 2 polynomials for all the numeric variables
#===============================================================================================================
#===============================================================================================================

for (i in 1:65) {
  z<-paste("rock_area2_", i, sep = "")
  x<-paste("rock_area_", i, sep = "")
  geo_variables[z]<- round(geo_variables[x]^2, 3)
  z<-paste("rock_areaelev2_", i, sep = "")
  x<-paste("rock_areaelev_", i, sep = "")
  geo_variables[z]<- round(geo_variables[x]^2, 3)
}

geo_variables["dist2fault_km2"]<-round(geo_variables$dist2fault_km^2, 3)


geo_variables["ltot_1km2"]<-round(geo_variables$ltot_1km^2, 3)
geo_variables["ltot_5km2"]<-round(geo_variables$ltot_5km^2, 3)


geo_variables["mean_slope_fault2"]<-round(geo_variables$mean_slope_fault^2, 3)

geo_variables["diff_elevation_fault2"]<-round(geo_variables$diff_elevation_fault^2, 3)


#===============================================================================================================
#===============================================================================================================
# Generating interaction variables for ltot_1km
#===============================================================================================================
#===============================================================================================================


for (i in 1:2) {
  if (i==1) {z<-"ltot_1km"}
  else {z<-paste("ltot_1km", i, sep = "")}
  for (m in 1:2) {
    if (m==1){rock_area<-paste("rock_area","_", sep='')
    rock_elev<-paste("rock_areaelev","_", sep="")}
    else {rock_area<-paste("rock_area", m, sep='')
    rock_area<-paste(rock_area, "_", sep="")
    rock_elev<-paste("rock_areaelev", m, sep='')
    rock_elev<-paste(rock_elev, "_", sep="")}
    for(j in 1:65){
      x<-paste("ltot1km_area", i,m,j, sep = "")
      rock_type<-paste(rock_area, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
      x<-paste("ltot1km_areaelev", i,m,j, sep = "")
      rock_elev<-paste(rock_elev, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
    }
  }
  for (m in 1:2) {
    if(m==1){dist<-"dist2fault_km"
    ltot<-"ltot_5km"
    slope<-"mean_slope_fault"
    elev<-"diff_elevation_fault"}
    else {dist<-paste("dist2fault_km",m,sep = "")
    ltot<-paste("ltot_5km",m, sep="")
    slope<-paste("mean_slope_fault",m, sep="")
    elev<-paste("diff_elevation_fault",m, sep="")}
    x<-paste("ltot1km_ltot5km",i,m, sep="")
    geo_variables[x]<-geo_variables[ltot]*geo_variables[z]
    x<-paste("ltot1km_dist",i,m, sep="")
    geo_variables[x]<-geo_variables[dist]*geo_variables[z]
    x<-paste("ltot1km_slope",i,m, sep="")
    geo_variables[x]<-geo_variables[slope]*geo_variables[z]
    x<-paste("ltot1km_elev",i,m, sep="")
    geo_variables[x]<-geo_variables[elev]*geo_variables[z]
  }
}

#===============================================================================================================
#===============================================================================================================
# Generating interaction variables for ltot_5km
#===============================================================================================================
#===============================================================================================================

for (i in 1:2) {
  if (i==1) {z<-"ltot_5km"}
  else {z<-paste("ltot_5km", i, sep = "")}
  for (m in 1:2) {
    if (m==1){rock_area<-paste("rock_area","_", sep='')
    rock_elev<-paste("rock_areaelev","_", sep="")}
    else {rock_area<-paste("rock_area", m, sep='')
    rock_area<-paste(rock_area, "_", sep="")
    rock_elev<-paste("rock_areaelev", m, sep='')
    rock_elev<-paste(rock_elev, "_", sep="")}
    for(j in 1:65){
      x<-paste("ltot5km_area", i,m,j, sep = "")
      rock_type<-paste(rock_area, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
      x<-paste("ltot5km_areaelev", i,m,j, sep = "")
      rock_elev<-paste(rock_elev, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
    }
  }
  for (m in 1:2) {
    if(m==1){dist<-"dist2fault_km"
    slope<-"mean_slope_fault"
    elev<-"diff_elevation_fault"}
    else {dist<-paste("dist2fault_km",m,sep = "")
    slope<-paste("mean_slope_fault",m, sep="")
    elev<-paste("diff_elevation_fault",m, sep="")}
    x<-paste("ltot5km_dist",i,m, sep="")
    geo_variables[x]<-geo_variables[dist]*geo_variables[z]
    x<-paste("ltot5km_slope",i,m, sep="")
    geo_variables[x]<-geo_variables[slope]*geo_variables[z]
    x<-paste("ltot5km_elev",i,m, sep="")
    geo_variables[x]<-geo_variables[elev]*geo_variables[z]
  }
}

#===============================================================================================================
#===============================================================================================================
# Generating interaction variables for dist2fault
#===============================================================================================================
#===============================================================================================================

for (i in 1:2) {
  if (i==1) {z<-"dist2fault_km"}
  else {z<-paste("dist2fault_km", i, sep = "")}
  for (m in 1:2) {
    if (m==1){rock_area<-paste("rock_area","_", sep='')
    rock_elev<-paste("rock_areaelev","_", sep="")}
    else {rock_area<-paste("rock_area", m, sep='')
    rock_area<-paste(rock_area, "_", sep="")
    rock_elev<-paste("rock_areaelev", m, sep='')
    rock_elev<-paste(rock_elev, "_", sep="")}
    for(j in 1:65){
      x<-paste("dist2fault_area", i,m,j, sep = "")
      rock_type<-paste(rock_area, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
      x<-paste("dist2fault_areaelev", i,m,j, sep = "")
      rock_elev<-paste(rock_elev, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
    }
  }
  for (m in 1:2) {
    if(m==1){slope<-"mean_slope_fault"
    elev<-"diff_elevation_fault"}
    else {slope<-paste("mean_slope_fault",m, sep="")
    elev<-paste("diff_elevation_fault",m, sep="")}
    x<-paste("dist2fault_slope",i,m, sep="")
    geo_variables[x]<-geo_variables[slope]*geo_variables[z]
    x<-paste("dist2fault_elev",i,m, sep="")
    geo_variables[x]<-geo_variables[elev]*geo_variables[z]
  }
}

#===============================================================================================================
#===============================================================================================================
# Generating interaction variables for mean_slope_fault
#===============================================================================================================
#===============================================================================================================

for (i in 1:2) {
  if (i==1) {z<-"mean_slope_fault"}
  else {z<-paste("mean_slope_fault", i, sep = "")}
  for (m in 1:2) {
    if (m==1){rock_area<-paste("rock_area","_", sep='')
    rock_elev<-paste("rock_areaelev","_", sep="")}
    else {rock_area<-paste("rock_area", m, sep='')
    rock_area<-paste(rock_area, "_", sep="")
    rock_elev<-paste("rock_areaelev", m, sep='')
    rock_elev<-paste(rock_elev, "_", sep="")}
    for(j in 1:65){
      x<-paste("slope_area", i,m,j, sep = "")
      rock_type<-paste(rock_area, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
      x<-paste("slope_areaelev", i,m,j, sep = "")
      rock_elev<-paste(rock_elev, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
    }
  }
  for (m in 1:2) {
    if(m==1){elev<-"diff_elevation_fault"}
    else {elev<-paste("diff_elevation_fault",m, sep="")}
    x<-paste("slope_elev",i,m, sep="")
    geo_variables[x]<-geo_variables[elev]*geo_variables[z]
  }
}

#===============================================================================================================
#===============================================================================================================
# Generating interaction variables for diff_elevation_fault
#===============================================================================================================
#===============================================================================================================

for (i in 1:2) {
  if (i==1) {z<-"diff_elevation_fault"}
  else {z<-paste("diff_elevation_fault", i, sep = "")}
  for (m in 1:2) {
    if (m==1){rock_area<-paste("rock_area","_", sep='')
    rock_elev<-paste("rock_areaelev","_", sep="")}
    else {rock_area<-paste("rock_area", m, sep='')
    rock_area<-paste(rock_area, "_", sep="")
    rock_elev<-paste("rock_areaelev", m, sep='')
    rock_elev<-paste(rock_elev, "_", sep="")}
    for(j in 1:65){
      x<-paste("elev_area", i,m,j, sep = "")
      rock_type<-paste(rock_area, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
      x<-paste("elev_areaelev", i,m,j, sep = "")
      rock_elev<-paste(rock_elev, j, sep="")
      geo_variables[x]<-geo_variables[rock_type]*geo_variables[z]
    }
  }
}

# Remove PII from data
geo_variables <- geo_variables %>% dplyr::select(-X,-g11_gpsaltitude, -g11_gpsaccuracy, -avg_source_depth)

setwd(output_data_path)
write.csv(geo_variables, "clean_geological_variables.csv")

