#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This file plots maps for Indian States which ration power for agricultural use
#Date: 23 September 2019
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
                 'gstat','maptools','stplanr','rlist','GISTools', 'ggsn',
                 'gridExtra')
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
library(GISTools)
library(parallel)
library(ggsn)
library(gridExtra)
library(crop)
#===============================================================================================================
#===============================================================================================================
#Getting the shapefiles from the destinations
args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/Google Drive (josh.mohanty@gmail.com)/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}
data_path <- "/data"
input_path<-paste(project_path,data_path,"/geology/raw/india_admin_boundaries/census2001",sep="")

setwd(input_path)
india<-st_read("95feindiamap_state.shp")
#===============================================================================================================
#===============================================================================================================
#Plotting

india<-india %>% dplyr::filter(NAME != "Andaman & Nicobar Islands")
telangana<-st_read("telangana_shapefile.shp")
india<-india[,c(1,2,3,6)]
#Getting the subsidy states

subsidy_states<-c("Rajasthan", "Punjab", "Telangana",
                  "Andhra Pradesh", "Tamil Nadu", 
                  "Gujarat", "Haryana", 
                  "Karnataka", "Madhya Pradesh", "Maharashtra")

subsidy_states<-india %>% dplyr::filter(NAME %in% subsidy_states)
subsidy_states$pop_cut<-cut(subsidy_states$TOT_POP, 4, labels=c("(21.1, 40.1]",
                                                                "(40.1, 59.0]",
                                                                "(59.0, 77.9]",
                                                                "(77.9, 97.0]"))

subsidy_states$pop_cut1<-ifelse(subsidy_states$TOT_POP <= 40*10^6, "(20,40]", NA)
subsidy_states$pop_cut1<-ifelse(subsidy_states$TOT_POP > 40*10^6 & 
                                  subsidy_states$TOT_POP <= 60*10^6, 
                                "(40,60]", subsidy_states$pop_cut1)
subsidy_states$pop_cut1<-ifelse(subsidy_states$TOT_POP > 60*10^6 & 
                                  subsidy_states$TOT_POP <= 80*10^6, 
                                "(60,80]", subsidy_states$pop_cut1)
subsidy_states$pop_cut1<-ifelse(subsidy_states$TOT_POP > 80*10^6 & 
                                  subsidy_states$TOT_POP <= 100*10^6, 
                                "(80,100]", subsidy_states$pop_cut1)

subsidy_states$pop_cut1<-factor(subsidy_states$pop_cut1, labels = c("(20, 40]",
                                                                    "(40, 60]",
                                                                    "(60, 80]",
                                                                    "(80, 100]"))
rajasthan<-dplyr::filter(subsidy_states, NAME == "Rajasthan")

#theme_set(theme_bw())

#map_water<-ggplot() + geom_sf(data = india, fill = "white", colour = "light grey", lwd = 0.4)

#map_water<-map_water + geom_sf(data = subsidy_states, 
#                               aes(alpha = pop_cut1),
#                               fill = "red",
#                               colour = "light grey",
#                               lwd = 0.4)

#map_water<-map_water+geom_sf(data= rajasthan,
#                             colour = "black",
#                             lwd = 0.8,
#                             fill = NA,
#                             inherit.aes = FALSE)

#map_water<-map_water + blank() + theme(panel.border = element_blank())

#map_water<-map_water + scale_alpha_discrete(name="Population in Millions")

#map_water<-map_water+theme(legend.position = c(1,0.25))

#map_water



#setwd(paste(project_path,"/analysis/output/figures", sep=""))

#ggsave("water_subsidy_states.pdf")


map_water<-ggplot() + geom_sf(data = india, fill = "white", colour = "black", lwd = 0.2)
map_water<-map_water + geom_sf(data=subsidy_states, fill = "light grey", colour = "black", lwd = 0.2)
map_water<-map_water+geom_sf(data = telangana, fill = "light grey", colour = "black", lwd = 0.2)
map_water<-map_water+theme_bw()+blank()+theme(panel.border = element_blank())
map_water

pdf(file=(file <- paste0(project_path,"/exhibits/figures/ration_states.pdf")))
map_water
#dev.off.crop(file=file)




