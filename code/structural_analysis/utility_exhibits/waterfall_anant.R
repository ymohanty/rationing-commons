#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This file plots maps for Indian States with Subsidies for water
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
                 'gridExtra', 'waterfalls')
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
library(waterfalls)
library(extrafont)
library(crop)
#===============================================================================================================
#===============================================================================================================
#Getting Data for Status Quo

args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/Dropbox/water_scarcity",sep="")
} else {
  project_path<-args[1]
}
data_path <- "/analysis/data"

setwd(paste0(project_path, "/analysis/output/figures/"))
font_import()

values1<-c(3.00, -5.38, -4.80)*2.3
labels1<-c("Farmer\nProfit", "Power\nCost", "Water\nCost")

waterfall_map<-waterfall(values = values1, labels = labels1, 
                         calc_total = TRUE, 
                         total_axis_text = "Social\nSurplus", rect_border = NA, 
                         rect_text_labels = c("INR 6900", "INR -12374", "INR -11040"), 
                         total_rect_text = "INR -16514",
                         rect_text_size = 1.5) 
waterfall_map<-waterfall_map + theme_bw() 
waterfall_map<-waterfall_map + theme(axis.title.x = element_blank()) 
waterfall_map<-waterfall_map + scale_y_continuous(name="Value in Indian Rupees", 
                                                  limits = c(-20, 10), 
                                                  breaks = c(-20, -17.5, -15, -12.5,
                                                             -10, -7.5, -5, -2.5, 0, 
                                                             2.5, 5, 7.5, 10), 
                                                  labels = c("-20000", "", "-15000", "",
                                                             "-10000", "", "-5000", "", 
                                                             "0", "", "5000", "", "10000")) 
waterfall_map<-waterfall_map + theme(panel.grid = element_blank(),
                                     axis.line = element_line(colour = "black"),
                                     panel.border = element_blank(),
                                     axis.text.x = element_text(size=12, 
                                                                family = "Times New Roman"),
                                     axis.title.y = element_text(size=16, 
                                                                 family = "Times New Roman"),
                                     axis.text.y = element_text(size=12,
                                                                family = "Times New Roman"))
waterfall_map


pdf(file=(file <- "anant_status_quo.pdf"))
waterfall_map
dev.off.crop(file=file)


values1<-c(-1.13, 5.16, -6.10)*2.3
labels1<-c("Farmer\nProfit", "Power\nCost", "Water\nCost")

waterfall_map<-waterfall(values = values1, labels = labels1, 
                         calc_total = TRUE, 
                         total_axis_text = "Social\nSurplus", rect_border = NA, 
                         rect_text_labels = c("INR -2599", "INR 11868", "INR -14030"), 
                         total_rect_text = "INR -4761",
                         rect_text_size = 1.5) 
waterfall_map<-waterfall_map + theme_bw() 
waterfall_map<-waterfall_map + theme(axis.title.x = element_blank()) 
waterfall_map<-waterfall_map + scale_y_continuous(name="Value in Indian Rupees", 
                                                  limits = c(-20, 10), 
                                                  breaks = c(-20, -17.5, -15, -12.5,
                                                             -10, -7.5, -5, -2.5, 0, 
                                                             2.5, 5, 7.5, 10), 
                                                  labels = c("-20000", "", "-15000", "",
                                                             "-10000", "", "-5000", "", 
                                                             "0", "", "5000", "", "10000"))
waterfall_map<-waterfall_map + theme(panel.grid = element_blank(),
                                     axis.line = element_line(colour = "black"),
                                     panel.border = element_blank(),
                                     axis.text.x = element_text(size=12, 
                                                                family = "Times New Roman"),
                                     axis.title.y = element_text(size=16, 
                                                                 family = "Times New Roman"),
                                     axis.text.y = element_text(size=12,
                                                                family = "Times New Roman"))
waterfall_map


pdf(file=(file <- "anant_piguovian.pdf"))
waterfall_map
dev.off.crop(file=file)







