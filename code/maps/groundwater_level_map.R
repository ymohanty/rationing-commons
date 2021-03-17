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

# Project path
args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/Dropbox/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}

# Load checkpoint snapshot for reproducibility
library(checkpoint)
checkpoint("2020-07-18", project = project_path, checkpointLocation = paste0(project_path,"/code/"))


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
library(GISTools)
library(parallel)
library(ggsn)
library(gridExtra)
library(lubridate)
library(fuzzyjoin)
#===============================================================================================================
#===============================================================================================================

data_path <- "/data"

india_map<-st_read(paste0(project_path,data_path,"/geology/raw/india_admin_boundaries/census2001/95feindiamap_district.shp"))
ground_water_data<-read.csv(paste0(project_path,data_path,"/geology/clean/ground_water_development.csv"))

india_map<-india_map[,c("STATE_UT","NAME")]
colnames(india_map)[1:2]<-c("state","district")

ground_water_data$state<-as.character(ground_water_data$state)
ground_water_data$state[ground_water_data$state=="Telangana"]<-"Andhra Pradesh"
ground_water_data$state[ground_water_data$state=="Uttarakhand"]<-"Uttranchal"
ground_water_data$state[ground_water_data$state=="Odisha"]<-"Orissa"

india_map1<-stringdist_left_join(india_map, ground_water_data,
                                             by=c("state"="state", "district"="district"),
                                             max_dist = 1)

india_map1<-india_map1[,c("state.x","district.x","water_assessment", "water_assessment1")]
colnames(india_map1)[1:2]<-c("state","district")
india_map1$water_assessment<-as.character(india_map1$water_assessment)
india_map1$water_assessment[is.na(india_map1$water_assessment)]<-"No Data"
india_map1$water_assessment<-as.factor(india_map1$water_assessment)
india_map1$water_assessment<-factor(india_map1$water_assessment, 
                                    levels(india_map1$water_assessment)[c(3,1,5,4,2)])


india_map1$water_assessment1<-as.character(india_map1$water_assessment1)
india_map1$water_assessment1[is.na(india_map1$water_assessment1)]<-"No Data"
india_map1$water_assessment1<-as.factor(india_map1$water_assessment1)
india_map1$water_assessment1<-factor(india_map1$water_assessment1, 
                                    levels(india_map1$water_assessment1)[c(7,6,5,4,3,2,1,8)])



india_map1<-india_map1[!india_map1$state=="Andaman & Nicobar",]
india_map1<-india_map1[!india_map1$state=="Lakshadweep",]

cols<-c("Over-Exploited" = "#FF0000FF", "Critical" = "#FF000099", "Semi-Critical" = "#FF000033",
        "Safe" = "#0000FF4D", "No Data" = "#FFFFFFFF")

india<-st_union(india_map1)
rajasthan<-st_union(india_map1[india_map1$state=="Rajasthan",])
map_water<-ggplot(india_map1)
map_water<-map_water + geom_sf(aes(fill = water_assessment), colour = "lightgray", lwd=0.2)

map_water<-map_water + theme_bw() + blank() + theme(panel.border = element_blank())

map_water<-map_water + scale_fill_manual(values = cols,
                                         breaks = c("Over-Exploited","Critical",
                                                    "Semi-Critical","Safe", "No Data"))
map_water<-map_water + theme(legend.title = element_blank())
map_water<-map_water + theme(legend.position = c(0.8,0.2))
map_water<-map_water + geom_sf(data = india, colour = "black", lwd = 0.2, fill = NA)
map_water<-map_water + geom_sf(data = rajasthan, 
                               colour = "black", lwd = 0.7, fill = NA)
map_water


ggsave(paste0(project_path,"/exhibits/figures/groundwater_levels.pdf"))

pdf(file=(file <- paste0(project_path,"/exhibits/figures/gw_levels.pdf")), compress=TRUE)
map_water
dev.off.crop(file=file)


cols<-c("[200-420)" = "#FF0000FF", "[180-200)" = "#FF0000D9", "[160-180)" = "#FF0000B3",
        "[140-160)" = "#FF00008C", "[120-140)" = "#FF000066", "[100-120)" = "#FF000040",
        "[0-100)" = "#0000FF4D", "No Data" = "#FFFFFFFF")

map_water<-ggplot(india_map1)
map_water<-map_water + geom_sf(aes(fill = water_assessment1), colour = "lightgray", lwd=0.2)

map_water<-map_water + theme_bw() + blank() + theme(panel.border = element_blank())

map_water<-map_water + scale_fill_manual(values = cols)
map_water<-map_water + theme(legend.title = element_blank())
map_water<-map_water + theme(legend.position = c(0.8,0.2))
map_water<-map_water + geom_sf(data = india, colour = "black", lwd = 0.2, fill = NA)
map_water<-map_water + geom_sf(data = rajasthan, 
                               colour = "black", lwd = 0.7, fill = NA)
map_water


ggsave(paste0(project_path,"/exhibits/figures/groundwater_levels1.pdf"))





