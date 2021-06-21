#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This file plots maps for predictions and true well depths
#Date: 06 September 2019
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
  project_path<-paste(Sys.getenv("HOME"),"/Google Drive (josh.mohanty@gmail.com)/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}

# Load checkpoint snapshot for reproducibility
library(checkpoint)
checkpoint("2020-07-18", R.version = "3.6.1",project = project_path, checkpointLocation = paste0(project_path,"/code/"))

# Load libraries
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
library(crop)
#===============================================================================================================
#===============================================================================================================s

data_path <- "/data"
input_path<-paste(project_path,data_path,"/geology/raw/gw_prospect_maps/shapefiles",sep="")
baseline_data_path <- paste(project_path,data_path,"/farmer_survey/intermediate",sep="")
output_data_path <- paste(project_path,data_path,"/geology/clean",sep="")
setwd(baseline_data_path)
#===============================================================================================================

#Getting the GPS Data for the locations of farmers
baseline_data<-read.dta13("baseline_survey.dta")

# Get location data from the encrypted PII 
farmer_location_data <- read.dta13('pii_farmer_locations.dta')

# Merge with baseline data
baseline_data <- baseline_data %>% left_join(farmer_location_data,by="f_id")

setwd(input_path)
#===============================================================================================================

#Reading all the hydrogeomorphic division data
hydrogeomorphic_division_D<-st_read("d2_dug/GANGDHAR BLOCK VECTOR/HYDROGEOMORPHIC_DIVISION.shp")

hydrogeomorphic_division_HN<-st_read("d3_hindoli_nainwa/vector/HYDROGEOMORPHIC_DIVISION.shp")

hydrogeomorphic_division_KBM<-st_read("d4_kotputli_mundawar_bansur/KOTPUTLI, MANDAWAR & BUNSUR BLOCK VECTOR/HYDROGEOMORPHIC_DIVISION.shp")
#===============================================================================================================
#===============================================================================================================
#Reading the Contour Files
contourDEM_D<-raster("contourDEM_D.grd")
contourDEM_HN<-raster("contourDEM_HN.grd")
contourDEM_KBM<-raster("contourDEM_KBM.grd")

rasterRockD<-raster("rasterRock_D.grd")
rasterRockHN<-raster("rasterRock_HN.grd")
rasterRockKBM<-raster("rasterRock_KBM.grd")
#===============================================================================================================
#===============================================================================================================
#Reading all the faults data
## Importing faults and inferred faults shapefiles for Kotputli, Bansur and Mundawar
faults_KBM<-sf::st_read("d4_kotputli_mundawar_bansur/KOTPUTLI, MANDAWAR & BUNSUR BLOCK VECTOR/FRACTURE_LINEAMENT.shp")
faults_I_KBM<-sf::st_read("d4_kotputli_mundawar_bansur/KOTPUTLI, MANDAWAR & BUNSUR BLOCK VECTOR/FRACTURE_LINEAMENT_Inferred.shp")

## Importing faults and inferred faults shapefiles for Hindoli and Nainwa
faults_HN<-sf::st_read("d3_hindoli_nainwa/vector/FRACTURE_LINEAMENT.shp")
faults_I_HN<-sf::st_read("d3_hindoli_nainwa/vector/FRACTURE_LINEAMENT_Inferred.shp")

## Importing faults and inferred faults shapefiles for Dug/Gangdhar
faults_D<-sf::st_read("d2_dug/GANGDHAR BLOCK VECTOR/FRACTURE_LINEAMENT.shp")
faults_I_D<-sf::st_read("d2_dug/GANGDHAR BLOCK VECTOR/FRACTURE_LINEAMENT_Inferred.shp")
#===============================================================================================================

#Getting all the shapefiles together
#Hydrogeomorphic Division Data


#Initially only keeping the relevant columns for the variables

hydrogeomorphic_division_D<-hydrogeomorphic_division_D %>% dplyr::select(c("ROCK_TYPE", "AQ_MAT", "SR_WELL", "geometry"))

hydrogeomorphic_division_HN<-hydrogeomorphic_division_HN %>% dplyr::select(c("ROCK_TYPE", "AQ_MAT", "SR_WELL","geometry"))

hydrogeomorphic_division_KBM<-hydrogeomorphic_division_KBM %>% dplyr::select(c("ROCK_TYPE", "AQ_MAT", "SR_WELL","geometry"))

hydrogeomorphic_division<-do.call("rbind", list(hydrogeomorphic_division_D, hydrogeomorphic_division_HN, hydrogeomorphic_division_KBM))

#Converting the levels of the success rate of wells into proper levels
success_rate<-as.character(hydrogeomorphic_division$SR_WELL)
success_rate[success_rate=="HIGH"]="High"
success_rate[success_rate=="LOW"]="Low"
success_rate[success_rate=="MODERATE"]="Moderate"
success_rate[success_rate=="MODERAT"]="Moderate"
success_rate[success_rate=="POOR"]="Low"
success_rate[success_rate=="-"]=NA
success_rate<-as.factor(success_rate)
hydrogeomorphic_division$SR_WELL<-success_rate
#===============================================================================================================

#Faults Data
##Renaming different variable names

colnames(faults_KBM)[1] <- "Type"
colnames(faults_I_KBM)[1] <- "Type"

##Appending
faults <- do.call("rbind", list(faults_KBM, faults_I_KBM, faults_HN, faults_I_HN, faults_D, faults_I_D))

###Creating fault UID
faults<- faults %>% mutate(fault_uid = 1:nrow(faults))

###Calculting angle of fault from North clockwise (bidirectional) and adding to faults data
faults <- faults %>% mutate(fault_angle = angle_diff(faults, angle = 0, bidirectional = FALSE, absolute = TRUE))

#===============================================================================================================

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

##Converting it to Simple Features
baseline_data<-st_as_sf(baseline_data,coords = c("g11_gpslongitude","g11_gpslatitude"),crs=st_crs(hydrogeomorphic_division))

##Converting all the shapefile to projected shapefiles for better management of data
hydrogeomorphic_division<-st_transform(hydrogeomorphic_division, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
hydrogeomorphic_division_D<-st_transform(hydrogeomorphic_division_D,crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
hydrogeomorphic_division_HN<-st_transform(hydrogeomorphic_division_HN,crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
hydrogeomorphic_division_KBM<-st_transform(hydrogeomorphic_division_KBM,crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
baseline_data<-st_transform(baseline_data,crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults<-st_transform(faults, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults_D<-st_transform(faults_D, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults_HN<-st_transform(faults_HN, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults_I_D<-st_transform(faults_I_D, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults_I_HN<- st_transform(faults_I_HN, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults_I_KBM<-st_transform(faults_I_KBM, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
faults_KBM<-st_transform(faults_KBM, crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")

circles<-st_buffer(baseline_data,5000)

circles1<-as(circles, "Spatial")
circles1_KBM<-circles1[circles1$SDO==c("Kotputli")|circles1$SDO==c("Bansur")|circles1$SDO==c("Mundawar"),]
circles1_HN<-circles1[circles1$SDO==c("Hindoli")|circles1$SDO==c("Nainwa"),]
circles1_D<-circles1[circles1$SDO==c("Dug"),]

#===============================================================================================================
#===============================================================================================================

# Getting the predictions

plotting_data<-paste(project_path, data_path, "/geology/clean", sep="")
setwd(plotting_data)

plotting_data<-read.csv("prediction.csv")

plotting_data<-plotting_data %>% dplyr::group_by(f_id) %>% dplyr::summarise(
                farmer_well_depth = mean(farmer_well_depth),
                depth_hat = mean(depth_hat))

baseline_data<- dplyr::left_join(baseline_data, plotting_data, by = "f_id")

#===============================================================================================================
#===============================================================================================================
#Plotting the actual data

D<-dplyr::filter(baseline_data, baseline_data$SDO == "Dug")
HN<-dplyr::filter(baseline_data, baseline_data$SDO == "Hindoli" | baseline_data$SDO == "Nainwa")
KBM<-dplyr::filter(baseline_data, baseline_data$SDO == "Kotputli" | baseline_data$SDO == "Bansur" | baseline_data$SDO == "Mundawar")



#Removing all the outliers for plotting of the maps

#Removing them for Dug
D_spatial<-as(D, "Spatial")
D_spatial<-D_spatial@coords
D_spatial<-as.data.frame(D_spatial)

D_spatialmax<-which.max(D_spatial$coords.x2)

D_spatial<-D_spatial[-D_spatialmax,]
D<-D[-D_spatialmax,]

D_spatialmax<-which.max(D_spatial$coords.x2)

D_spatial<-D_spatial[-D_spatialmax,]
D<-D[-D_spatialmax,]

#Removing them for Hindoli and Nainwa
HN_spatial<-as(HN, "Spatial")
HN_spatial<-HN_spatial@coords
HN_spatial<-as.data.frame(HN_spatial)

HN_spatialmax<-which.max(HN_spatial$coords.x2)

HN_spatial<-HN_spatial[-HN_spatialmax,]
HN<-HN[-HN_spatialmax,]

HN_spatialmax<-which.max(HN_spatial$coords.x2)

HN_spatial<-HN_spatial[-HN_spatialmax,]
HN<-HN[-HN_spatialmax,]

HN_spatialmax<-which.max(HN_spatial$coords.x2)

HN_spatial<-HN_spatial[-HN_spatialmax,]
HN<-HN[-HN_spatialmax,]

#Removing them for Kotputli, Bansur, and Mundawar

KBM_spatial<-as(KBM, "Spatial")
KBM_spatial<-KBM_spatial@coords
KBM_spatial<-as.data.frame(KBM_spatial)

KBM_spatialmax<-which.min(KBM_spatial$coords.x2)

KBM_spatial<-KBM_spatial[-KBM_spatialmax,]
KBM<-KBM[-KBM_spatialmax,]

KBM_spatialmax<-which.min(KBM_spatial$coords.x2)

KBM_spatial<-KBM_spatial[-KBM_spatialmax,]
KBM<-KBM[-KBM_spatialmax,]


#Removing missing observations

D<-na.omit(D)
HN<-na.omit(HN)
KBM<-na.omit(KBM)

#Taking away well depths which lie outside the quantiles

D<-dplyr::filter(D, D$farmer_well_depth>=quantile(D$farmer_well_depth)[2] 
                 & D$farmer_well_depth<=quantile(D$farmer_well_depth)[4])
HN<-dplyr::filter(HN, HN$farmer_well_depth>=quantile(HN$farmer_well_depth)[2]
                  & HN$farmer_well_depth<=quantile(HN$farmer_well_depth)[4])
KBM<-dplyr::filter(KBM, KBM$farmer_well_depth>=quantile(KBM$farmer_well_depth)[2]
                   & KBM$farmer_well_depth<=quantile(KBM$farmer_well_depth)[4])

#Getting the minimum and the maximum values for the legend plots
min_D<-min(D$farmer_well_depth, D$depth_hat)
max_D<-max(D$farmer_well_depth, D$depth_hat)

min_HN<-min(HN$farmer_well_depth, HN$depth_hat)
max_HN<-max(HN$farmer_well_depth, HN$depth_hat)

min_KBM<-min(KBM$farmer_well_depth, KBM$depth_hat)
max_KBM<-max(KBM$farmer_well_depth, KBM$depth_hat)

min_legend<-floor(min(min_HN, min_KBM))
max_legend<-ceiling(max(max_HN, max_KBM))
#===============================================================================================================
#===============================================================================================================
#Actual Plotting of the maps and saving in the correct folder

#Changing the folder

output_path <- paste(project_path,"/exhibits/figures", sep="")

setwd(output_path)

#===============================================================================================================
#===============================================================================================================

#Plotting for Dug (True Well Depths)

theme_set(theme_bw())
map_D<-ggplot(hydrogeomorphic_division_D) + geom_sf(fill = "white") + blank() +
  scalebar(hydrogeomorphic_division_D, dist = 15, dist_unit = "km", 
           transform = FALSE, st.dist = 0.08, location = "bottomright", st.size = 3)

#The next code maps the actual points of the farmer well depth. This is contained in the shapefile D
#Alpha used below determines how transparent the points will be

#The first map plots the actual well depth
#The size was 4 earlier

points_D<-geom_sf(data = D, aes(color = D$farmer_well_depth), 
                  size = 2, alpha = 0.55)

mid<-mean(D$farmer_well_depth)
#mid<- mean(max_legend, min_legend)
map_D<-map_D + points_D + 
  scale_color_gradient2(midpoint = mid, 
                        low = "blue", mid = "yellow", high = "red")

#Defining the label text, and the text size
map_D<- map_D + labs(color = "Well Depth ") 
#Setting Legend Text size
map_D<- map_D + theme(legend.title = element_blank(), 
                      legend.position = "right",
                      panel.border = element_blank()) + 
  guides(color = guide_colorbar(ticks=FALSE)) 

map_D + theme(legend.position = "none")

ggsave("D_welldepth.pdf")

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("D_welldepth.pdf", "D_welldepth.pdf"))

#===============================================================================================================
#===============================================================================================================

#Plotting for Dug (Predicted Well Depths)

theme_set(theme_bw())
map_Dpred<-ggplot(hydrogeomorphic_division_D) + geom_sf(fill = "white") + blank() +
  scalebar(hydrogeomorphic_division_D, dist = 15, dist_unit = "km", 
           transform = FALSE, st.dist = 0.08, location = "bottomright", st.size = 3)

#The next code maps the actual points of the farmer well depth. This is contained in the shapefile D
#Alpha used below determines how transparent the points will be

#The first map plots the actual well depth
#The size was 4 earlier

points_Dpred<-geom_sf(data = D, aes(color = D$depth_hat), 
                  size = 2, alpha = 0.55)

mid<-mean(D$depth_hat)
#mid<- mean(max_legend, min_legend)
map_Dpred<-map_Dpred + points_Dpred + 
  scale_color_gradient2(midpoint = mid, 
                        low = "blue", mid = "yellow", high = "red")

#Defining the label text, and the text size
map_Dpred<- map_Dpred + labs(color = "Well Depth ") 
#Setting Legend Text size
map_Dpred<- map_Dpred + theme(legend.title = element_text(size = 10), 
                      legend.position = "right",
                      panel.border = element_blank()) + 
  guides(color = guide_colorbar(ticks=FALSE)) 

map_Dpred + theme(legend.position = "none")

ggsave("Dpred_welldepth.pdf")

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("Dpred_welldepth.pdf", "Dpred_welldepth.pdf"))

#===============================================================================================================
#===============================================================================================================

#Plotting the legend for Dug

tmp <- ggplot_gtable(ggplot_build(map_D))
leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
legend <- tmp$grobs[[leg]]

grid.newpage()
pdf("legend_D.pdf", height = 1.4, width = 0.6)
grid.draw(legend)
dev.off()

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("legend_D.pdf", "legend_D.pdf"))


#===============================================================================================================
#===============================================================================================================

#Plotting the legend and  Dug (Predicted)

pred_D<- grid.arrange(map_Dpred + theme(legend.position = "none"), legend, 
                      nrow = 1, widths = c(9,1))

ggsave("pred_D_legend.pdf", pred_D)


#Cropping the image
#system2(command = "pdfcrop",
#        args = c("pred_D_legend.pdf", "pred_D_legend.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting together maps for Dug

together_D <- grid.arrange(arrangeGrob(map_D + theme(legend.position = "none")
                                       +labs(subtitle = "True Depths"),
                                       map_Dpred
                                       + theme(legend.position = "none")
                                       +labs(subtitle = "Predicted Depths"),
                                       nrow = 1), legend, nrow = 1, 
                                       widths = c(10,1))
ggsave("together_D.pdf", together_D)

#Cropping the image

#system2(command = "pdfcrop",
#        args = c("together_D.pdf", "together_D.pdf"))

png(file=(file<-"together_D.png"))
grid.arrange(arrangeGrob(map_D + theme(legend.position = "none")
                         +labs(subtitle = "True Depths"),
                         map_Dpred
                         + theme(legend.position = "none")
                         +labs(subtitle = "Predicted Depths"),
                         nrow = 1), legend, nrow = 1, 
             widths = c(10,1))
dev.off.crop(file=file)
#===============================================================================================================
#===============================================================================================================

#Plotting for Hindoli and Nainwa (True Well Depths)

theme_set(theme_bw())
map_HN<-ggplot(hydrogeomorphic_division_HN) + geom_sf(fill = "white") + blank() +
  scalebar(hydrogeomorphic_division_HN, dist = 15, dist_unit = "km", 
           transform = FALSE,st.dist = 0.08, location = "bottomright", st.size = 3)

#The next code maps the actual points of the farmer well depth. This is contained in the shapefile D
#Alpha used below determines how transparent the points will be

#The first map plots the actual well depth
#The size was 4 earlier

points_HN<-geom_sf(data = HN, aes(color = HN$farmer_well_depth), 
                  size = 2, alpha = 0.55)

mid<-mean(HN$farmer_well_depth)
map_HN<-map_HN + points_HN + 
  scale_color_gradient2(midpoint = mid, 
                        low = "blue", mid = "yellow", high = "red")

#Defining the label text, and the text size
map_HN<- map_HN + labs(color = "Well Depth ") 
#Setting Legend Text size
map_HN<- map_HN + theme(legend.title = element_blank(), 
                      legend.position = "right",
                      panel.border = element_blank()) + 
  guides(color = guide_colorbar(ticks=FALSE)) 

map_HN + theme(legend.position = "none")

ggsave("HN_welldepth.pdf")

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("HN_welldepth.pdf", "HN_welldepth.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting for Hindoli and Nainwa (Predicted Well Depths)

theme_set(theme_bw())
map_HNpred<-ggplot(hydrogeomorphic_division_HN) + geom_sf(fill="white") + blank() +
  scalebar(hydrogeomorphic_division_HN, dist = 15, dist_unit = "km", 
           transform = FALSE,st.dist = 0.08, location = "bottomright", st.size = 3)

#The next code maps the actual points of the farmer well depth. This is contained in the shapefile D
#Alpha used below determines how transparent the points will be

#The first map plots the actual well depth

#The size was 4 earlier
points_HNpred<-geom_sf(data = HN, aes(color = HN$depth_hat), 
                   size = 2, alpha = 0.55)

mid<-mean(HN$depth_hat)
map_HNpred<-map_HNpred + points_HNpred + 
  scale_color_gradient2(midpoint = mid, 
                        low = "blue", mid = "yellow", high = "red")

#Defining the label text, and the text size
map_HNpred<- map_HNpred + labs(color = "Well Depth ") 
#Setting Legend Text size
map_HNpred<- map_HNpred + theme(legend.title = element_blank(), 
                        legend.position = "right",
                        panel.border = element_blank()) + 
  guides(color = guide_colorbar(ticks=FALSE)) 

map_HNpred + theme(legend.position = "none")

ggsave("HNpred_welldepth.pdf")


#Cropping the image
#system2(command = "pdfcrop",
#        args = c("HNpred_welldepth.pdf", "HNpred_welldepth.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting the legend for Hindoli and Nainwa

tmp <- ggplot_gtable(ggplot_build(map_HN))
leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
legend <- tmp$grobs[[leg]]

grid.newpage()
pdf("legend_HN.pdf", height = 1.4, width = 0.6)
grid.draw(legend)
dev.off()

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("legend_HN.pdf", "legend_HN.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting together maps for HN

together_HN <- grid.arrange(arrangeGrob(map_HN + theme(legend.position = "none")
                                        +labs(subtitle = "True Depths"),
                                       map_HNpred
                                       + theme(legend.position = "none")
                                       +labs(subtitle = "Predicted Depths"),
                                       nrow = 1), legend, nrow = 1, 
                           widths = c(9,1))
ggsave("together_HN.pdf", together_HN)

png(file=(file<-"together_HN.png"))
together_HN <- grid.arrange(arrangeGrob(map_HN + theme(legend.position = "none")
                                        +labs(subtitle = "True Depths"),
                                        map_HNpred
                                        + theme(legend.position = "none")
                                        +labs(subtitle = "Predicted Depths"),
                                        nrow = 1), legend, nrow = 1, 
                            widths = c(9,1))
dev.off.crop(file=file)
#Cropping the image

#system2(command = "pdfcrop",
#        args = c("together_HN.pdf", "together_HN.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting for Kotputli, Bansur, and Mundawar (True Well Depths)

theme_set(theme_bw())
map_KBM<-ggplot(hydrogeomorphic_division_KBM) + geom_sf(fill="white") + blank() +
  scalebar(hydrogeomorphic_division_KBM, dist = 15, dist_unit = "km", 
           transform = FALSE,st.dist = 0.08, location = "bottomright", st.size = 3)

#The next code maps the actual points of the farmer well depth. This is contained in the shapefile D
#Alpha used below determines how transparent the points will be

#The first map plots the actual well depth
#The size was 4 earlier

points_KBM<-geom_sf(data = KBM, aes(color = KBM$farmer_well_depth), 
                   size = 2, alpha = 0.55)

mid<-mean(KBM$farmer_well_depth)
map_KBM<-map_KBM + points_KBM + 
  scale_color_gradient2(midpoint = mid, 
                        low = "blue", mid = "yellow", high = "red")

#Defining the label text, and the text size
map_KBM<- map_KBM + labs(color = "Well Depth ") 
#Setting Legend Text size
map_KBM<- map_KBM + theme(legend.title = element_blank(), 
                        legend.position = "right",
                        panel.border = element_blank()) + 
  guides(color = guide_colorbar(ticks=FALSE)) 

map_KBM + theme(legend.position = "none")

ggsave("KBM_welldepth.pdf")

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("KBM_welldepth.pdf", "KBM_welldepth.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting for Kotputli, Bansur, and Mundawar (Predicted Well Depths)

theme_set(theme_bw())
map_KBMpred<-ggplot(hydrogeomorphic_division_KBM) + geom_sf(fill="white") + blank() +
  scalebar(hydrogeomorphic_division_KBM, dist = 15, dist_unit = "km", 
           transform = FALSE,st.dist = 0.08, location = "bottomright", 
           st.size = 3)

#The next code maps the actual points of the farmer well depth. This is contained in the shapefile D
#Alpha used below determines how transparent the points will be

#The first map plots the actual well depth
#The size was 4 earlier

points_KBMpred<-geom_sf(data = KBM, aes(color = KBM$depth_hat), 
                       size = 2, alpha = 0.55)

mid<-mean(KBM$depth_hat)
map_KBMpred<-map_KBMpred + points_KBMpred + 
  scale_color_gradient2(midpoint = mid, 
                        low = "blue", mid = "yellow", high = "red")

#Defining the label text, and the text size
map_KBMpred<- map_KBMpred + labs(color = "Well Depth ") 
#Setting Legend Text size
map_KBMpred<- map_KBMpred + theme(legend.title = element_blank(), 
                                legend.position = "right",
                                panel.border = element_blank()) + 
  guides(color = guide_colorbar(ticks=FALSE)) 

map_KBMpred + theme(legend.position = "none")

ggsave("KBMpred_welldepth.pdf")

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("KBMpred_welldepth.pdf", "KBMpred_welldepth.pdf"))

#===============================================================================================================
#===============================================================================================================

#Plotting the legend for Kotputli, Bansur, and Mundawar

tmp <- ggplot_gtable(ggplot_build(map_KBM))
leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
legend <- tmp$grobs[[leg]]

grid.newpage()
pdf("legend_KBM.pdf", height = 1.4, width = 0.6)
grid.draw(legend)
dev.off()

#Cropping the image
#system2(command = "pdfcrop",
#        args = c("legend_KBM.pdf", "legend_KBM.pdf"))
#===============================================================================================================
#===============================================================================================================

#Plotting together maps for KBM

together_KBM <- grid.arrange(arrangeGrob(map_KBM + theme(legend.position = "none")
                                         +labs(subtitle = "True Depths"),
                                       map_KBMpred
                                       + theme(legend.position = "none")
                                       +labs(subtitle = "Predicted Depths"),
                                       nrow = 1), legend, nrow = 1, 
                           widths = c(9,1))
ggsave("together_KBM.pdf", together_KBM)

png(file=(file<-"together_KBM.png"))
together_KBM <- grid.arrange(arrangeGrob(map_KBM + theme(legend.position = "none")
                                         +labs(subtitle = "True Depths"),
                                         map_KBMpred
                                         + theme(legend.position = "none")
                                         +labs(subtitle = "Predicted Depths"),
                                         nrow = 1), legend, nrow = 1, 
                             widths = c(9,1))
dev.off.crop(file=file)
#Cropping the image

#system2(command = "pdfcrop",
#        args = c("together_KBM.pdf", "together_KBM.pdf"))
