#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This file plots maps for weather data
#Date: 19 November 2019
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
stRequired <- c( 'sf','sp','rgdal','raster',
                 'RColorBrewer','foreign','tidyverse','readstata13',
                 'gstat','maptools','stplanr','rlist','GISTools', 'ggsn',
                 'gridExtra', 'lubridate')
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
library(lubridate)
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



cleaning_data<-readxl::read_excel(paste0(project_path,data_path,"/trial2.xlsx"))
cleaning_data<-cleaning_data[,c(1,2,15)]
cleaning_data<-as.data.frame(cleaning_data)

cuts<-sapply(cleaning_data[1],function(x){grepl("GROUND",x)})

cuts<-which(cuts)

final_matrix<-data.frame(state = character(),
                         district = character(),
                         ground_water_development = numeric())
for (i in 1:(length(cuts) + 1)) {
  if(i == 1) {
    start = 0
  } else {
    start = cuts[i-1]
  }
  if(i == length(cuts) + 1) {
    end = nrow(cleaning_data) + 1
  } else {
    end = cuts[i]
  }
  temp_matrix<-cleaning_data[(start+1):(end-1),]
  temp_matrix<-temp_matrix[1:(nrow(temp_matrix)-2),]
  temp_matrix1<-as.data.frame(temp_matrix[,c(2,3)])
  colnames(temp_matrix1)<-c("district","ground_water_development")
  temp_matrix1$state<-temp_matrix[1,1]
  temp_matrix1<-temp_matrix1[,c(3,1,2)]
  temp_matrix1<-temp_matrix1[-c(1:5),]
  final_matrix<-rbind(final_matrix,temp_matrix1)
}

final_matrix$water_assessment<-NA
final_matrix$water_assessment1<-NA
final_matrix$ground_water_development<-as.numeric(final_matrix$ground_water_development)
final_matrix$water_assessment<- ifelse(final_matrix$ground_water_development>100, 
                                       "Over-Exploited", final_matrix$water_assessment)
final_matrix$water_assessment<- ifelse(final_matrix$ground_water_development<=70, 
                                       "Safe", final_matrix$water_assessment)
final_matrix$water_assessment<- ifelse(final_matrix$ground_water_development>70 & 
                                         final_matrix$ground_water_development<=90, 
                                       "Semi-Critical", final_matrix$water_assessment)
final_matrix$water_assessment<- ifelse(final_matrix$ground_water_development>90 &
                                         final_matrix$ground_water_development<=100, 
                                       "Critical", final_matrix$water_assessment)

final_matrix$water_assessment<- ifelse(final_matrix$ground_water_development>100, 
                                       "Over-Exploited", final_matrix$water_assessment)

final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development<100, 
                                       "[0-100)", final_matrix$water_assessment1)
final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development>=100 & 
                                          final_matrix$ground_water_development<120, 
                                        "[100-120)", final_matrix$water_assessment1)
final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development>=120 & 
                                          final_matrix$ground_water_development<140, 
                                        "[120-140)", final_matrix$water_assessment1)
final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development>=140 & 
                                          final_matrix$ground_water_development<160, 
                                        "[140-160)", final_matrix$water_assessment1)
final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development>=160 & 
                                          final_matrix$ground_water_development<180, 
                                        "[160-180)", final_matrix$water_assessment1)
final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development>=180 & 
                                          final_matrix$ground_water_development<200, 
                                        "[180-200)", final_matrix$water_assessment1)
final_matrix$water_assessment1<- ifelse(final_matrix$ground_water_development>=200, 
                                        "[200-420)", final_matrix$water_assessment1)

write.csv(final_matrix, paste0(project_path,data_path,"/geology/clean/ground_water_development.csv"), row.names = FALSE)



