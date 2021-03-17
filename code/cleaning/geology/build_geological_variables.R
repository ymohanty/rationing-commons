#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#This is a master file collecting all the geo-spatial variables and then storing them
#Master File
#Date: 27 March 2019 (11 July 2019)
#Author: Viraj Jorapur (modified by Yashaswi Mohanty)

#===============================================================================================================
#===============================================================================================================
#===============================================================================================================
#===============================================================================================================
#===============================================================================================================
#Getting the shapefiles from the destinations
args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/Google Drive (josh.mohanty@gmail.com)/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}

# Set checkpoint project checkpoints
install.packages("checkpoint")
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
library(ncdf4)
#======================== PRELIMINARIES==============================================
# Set file paths
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

#============= CREATE RASTER FILES ================
# Set up parallel function
fx <- function(name,circle) {
  return(raster::extract(name,circle))
}
# Vectorize variables
names <- c(rasterRockKBM,rasterRockHN,rasterRockD,contourDEM_KBM,contourDEM_HN,contourDEM_D)
circle_names <- c(circles1_KBM,circles1_HN,circles1_D,circles1_KBM,circles1_HN,circles1_D)

# Choose as many cores as you can on the local machine, up to 6.
numCores <- min(detectCores(),6)

# Run file raster file generation in parallel (time serial: 51 mins. Time parallel: 26 minutes (Whole program))
results <- mcmapply(fx,names,circle_names,mc.cores = numCores)

# rocksKBM<-raster::extract(rasterRockKBM,circles1_KBM)
# rocksHN<-raster::extract(rasterRockHN, circles1_HN)
# rocksD<-raster::extract(rasterRockD, circles1_D)
# elevKBM<-raster::extract(contourDEM_KBM, circles1_KBM)
# elevHN<-raster::extract(contourDEM_HN,circles1_HN)
# elevD<-raster::extract(contourDEM_D,circles1_D)

# Assign results
rocksKBM <- results[[1]]
rocksHN <- results[[2]]
rocksD <- results[[3]]
elevKBM <- results[[4]]
elevHN <- results[[5]]
elevD <- results[[6]]

#===============================================================================================================
#===============================================================================================================
#Creating the Controls for each farmer
#===============================================================================================================
#===============================================================================================================

#Creating controls by region and hence taking farmers by region

farmer_D<-baseline_data %>% dplyr::filter(SDO == "Dug")
farmer_HN<-baseline_data %>% dplyr::filter(SDO == "Hindoli"| 
                                             SDO== "Nainwa")
farmer_KBM<-baseline_data %>% dplyr::filter(SDO == "Kotputli"|
                                              SDO == "Bansur"|
                                              SDO == "Mundawar")

#Getting Slopes for each region in degrees from the DEM file

slope_D<-raster::terrain(contourDEM_D, opt = "slope", unit = "degrees")
slope_HN<-raster::terrain(contourDEM_HN, opt = "slope", unit = "degrees")
slope_KBM<-raster::terrain(contourDEM_KBM, opt = "slope", unit = "degrees")

#Getting Slopes for each farmer at their precise spots

slope_D<-data.frame(raster::extract(slope_D, 
                                    data.frame(st_coordinates(farmer_D))))
slope_HN<-data.frame(raster::extract(slope_HN, 
                                     data.frame(st_coordinates(farmer_HN))))
slope_KBM<-data.frame(raster::extract(slope_KBM, 
                                      data.frame(st_coordinates(farmer_KBM))))

#Getting Elevation for farmers at their precise spots

elevation_D<-data.frame(raster::extract(contourDEM_D, 
                                        data.frame(st_coordinates(farmer_D))))

elevation_HN<-data.frame(raster::extract(contourDEM_HN, 
                                         data.frame(st_coordinates(farmer_HN))))

elevation_KBM<-data.frame(raster::extract(contourDEM_KBM, 
                                          data.frame(st_coordinates(farmer_KBM))))

#Creating Controls by region
control_D<-cbind(slope_D, elevation_D)
colnames(control_D)<-c("slope", "elevation")
control_D$f_id<-farmer_D$f_id

control_HN<-cbind(slope_HN, elevation_HN)
colnames(control_HN)<-c("slope", "elevation")
control_HN$f_id<-farmer_HN$f_id

control_KBM<-cbind(slope_KBM, elevation_KBM)
colnames(control_KBM)<-c("slope", "elevation")
control_KBM$f_id<-farmer_KBM$f_id

#Creating Controls for all the farmers
control<-as.data.frame(rbind(control_KBM, control_HN, control_D))

baseline_coordinates<-data.frame(st_coordinates(baseline_data))
baseline_coordinates$f_id<-baseline_data$f_id


#Making the baseline data geometryless

st_geometry(baseline_data)<-NULL

#Joining Baseline data and the controls
baseline_data<-dplyr::left_join(baseline_data, control, by = "f_id")

baseline_data<-dplyr::left_join(baseline_data, baseline_coordinates, by = "f_id")

baseline_data<-st_as_sf(baseline_data,
                        coords = c("X", "Y"),
                        crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 
                  +units=m +no_defs")

baseline_data <- baseline_data %>% dplyr::select(-slope,-elevation,slope, elevation)

#===============================================================================================================
#===============================================================================================================
# Rock Types at Precise Farmer Locations
#===============================================================================================================
#===============================================================================================================

#Creating Dummies for Rock Types


#Taking the factor names from the ROCK_TYPE variable in the hydrogeomorphic shapefile

number_rock_types<-factor(hydrogeomorphic_division$ROCK_TYPE)

#Creating a matrix to create indicator dummies for each farmer and each rock-type
rock_types<-matrix(0,nrow = nrow(baseline_data),ncol = length(levels(number_rock_types)))

#Converting the matrix into a dataframe for easier data manipulations
rock_types<-as.data.frame(rock_types)

#Setting the column names of the dataframe to be the rock-types
colnames(rock_types)<-levels(number_rock_types)

#Getting the coordinates for each farmer which is stored in the geometry column
rock_types<-cbind(rock_types,baseline_data$geometry)

#Converting the rock-types into a shapefile
rock_types<-st_as_sf(rock_types)

#===============================================================================================================

#Getting Rock Types for each farmer

#st_join uses the default operation intersect for merging
#In this case, will give ROCK_TYPE for each farmer 
baseline_data<-st_join(baseline_data,dplyr::select(hydrogeomorphic_division,ROCK_TYPE))


#Converting Rock Factors into numbers
rock_numbers<-as.numeric(baseline_data$ROCK_TYPE)

#Converting Rock Factors into numbers
rock_numbers<-as.numeric(baseline_data$ROCK_TYPE)

#Modifying Rock Types matrix to reflect rock types for each farmer
for (i in 1:nrow(rock_types)) {
  if(!is.na(rock_numbers[i])){rock_types[i,rock_numbers[i]]=1}
} 

f_id<-baseline_data$f_id
rock_types<-mutate(rock_types, f_id = f_id)
st_geometry(rock_types)<-NULL
#Joining the rock-types of each farmer to its geometry
baseline_data<-inner_join(baseline_data,rock_types, by = "f_id")

#Dropping away the ROCK_TYPE column to just give us indicators for the rock-types
baseline_data<-dplyr::select(baseline_data,-ROCK_TYPE)

# Make slope and elevation the last variables
baseline_data <- baseline_data %>% dplyr::select(-slope,-elevation,slope, elevation)

#Renaming the columns containing the variable information
for (i in 6:70) {
  colnames(baseline_data)[i]<-paste("rock_type", i-5, sep="_")
}

#===============================================================================================================
#===============================================================================================================
# Aquifer at Precise Farmer Locations
#===============================================================================================================
#===============================================================================================================

#Creating Dummies for Aquifer Types


#Taking the factor names from the AQ_MAT variable in the hydrogeomorphic shapefile

number_aquifer_types<-factor(hydrogeomorphic_division$AQ_MAT)

#Creating a matrix to create indicator dummies for each farmer and each acquifer-type
aquifer_types<-matrix(0,nrow = nrow(baseline_data),ncol = length(levels(number_aquifer_types)))

#Converting the matrix into a dataframe for easier data manipulations
aquifer_types<-as.data.frame(aquifer_types)

#Setting the column names of the dataframe to be the aquifer-types
colnames(aquifer_types)<-levels(number_aquifer_types)

#Getting the coordinates for each farmer which is stored in the geometry column
aquifer_types<-cbind(aquifer_types,baseline_data$geometry)

#Converting the rock-types into a shapefile
aquifer_types<-st_as_sf(aquifer_types)

#===============================================================================================================

#Getting Aquifer Types for each farmer

#st_join uses the default operation intersect for merging
#In this case, will give AQ_MAT for each farmer 
baseline_data<-st_join(baseline_data, dplyr::select(hydrogeomorphic_division,AQ_MAT))

#Converting Aquifer Factors into numbers
aquifer_numbers<-as.numeric(baseline_data$AQ_MAT)

#Modifying Rock Types matrix to reflect rock types for each farmer 
for (i in 1:nrow(aquifer_types)) {
  if(!is.na(aquifer_numbers[i])){aquifer_types[i,aquifer_numbers[i]]=1}
}


aquifer_types<-mutate(aquifer_types, f_id = f_id)
st_geometry(aquifer_types)<-NULL
#Joining the rock-types of each farmer to its geometry
baseline_data<-inner_join(baseline_data,aquifer_types, by = "f_id")

#Dropping away the AQ_MAT column to just give us indicators for the aquifer-types
baseline_data<-dplyr::select(baseline_data,-AQ_MAT)


# Make slope and elevation the last variables
baseline_data <- baseline_data %>% dplyr::select(-slope,-elevation,slope, elevation)

#Renaming the columns containing the variable information
for (i in 71:90) {
  colnames(baseline_data)[i]<-paste("aquifer_type", i-70, sep="_")
}


#===============================================================================================================
#===============================================================================================================
# Success Types of Wells at Precise Farmer Locations
#===============================================================================================================
#===============================================================================================================

#Creating Dummies for Success Types


#Taking the factor names from the SR_WELL variable in the hydrogeomorphic shapefile

number_success_types<-factor(hydrogeomorphic_division$SR_WELL)

#Creating a matrix to create indicator dummies for each farmer and each success-type
success_types<-matrix(0,nrow = nrow(baseline_data),ncol = length(levels(number_success_types)))

#Converting the matrix into a dataframe for easier data manipulations
success_types<-as.data.frame(success_types)

#Setting the column names of the dataframe to be the success-types
colnames(success_types)<-levels(number_success_types)

#Getting the coordinates for each farmer which is stored in the geometry column
success_types<-cbind(success_types,baseline_data$geometry)

#Converting the success-types into a shapefile
success_types<-st_as_sf(success_types)

#===============================================================================================================

#Getting Success Types for each farmer

#st_join uses the default operation intersect for merging
#In this case, will give SR_WELL for each farmer
baseline_data<-st_join(baseline_data,dplyr::select(hydrogeomorphic_division,SR_WELL))


#Converting Success Factors into numbers
success_numbers<-as.numeric(baseline_data$SR_WELL)




#Modifying Success Types matrix to reflect success types for each farmer

for (i in 1:nrow(success_types)) {
  if(!is.na(success_numbers[i])){success_types[i,success_numbers[i]]=1}
}

f_id<-baseline_data$f_id
success_types<-mutate(success_types, f_id = f_id)
st_geometry(success_types)<-NULL

#Joining the success-types of each farmer to its geometry
baseline_data<-inner_join(baseline_data,success_types, by = "f_id")

#Dropping away the SR_WELL column to just give us indicators for the success-types
baseline_data<-dplyr::select(baseline_data,-SR_WELL)

# Make slope and elevation the last variables
baseline_data <- baseline_data %>% dplyr::select(-slope,-elevation,slope, elevation)

#Renaming the columns containing the variable information
for (i in 91:93) {
  colnames(baseline_data)[i]<-paste("success_type", i-90, sep="_")
}


#===============================================================================================================
#===============================================================================================================
# Rock Types in 5km Radius
#===============================================================================================================
#===============================================================================================================

total_value<-rep(NA, nrow(circles1_KBM))
rockKBM<-matrix(NA,nrow = nrow(circles1_KBM), ncol = length(levels(hydrogeomorphic_division_KBM$ROCK_TYPE)))
rockKBM<-as.data.frame(rockKBM)
colnames(rockKBM)<-levels(hydrogeomorphic_division_KBM$ROCK_TYPE)
for (i in 1:nrow(circles1_KBM)) {
  rock_type<-rocksKBM[[i]]
  total_value[i]<-length(rocksKBM[[i]])
  b<-as.data.frame(table(rock_type))
  rockKBM[i,as.numeric(as.character(b$rock_type))]<-b$Freq
}


rockKBM<-rockKBM/total_value

rockKBM$f_id<-circles1_KBM$f_id

total_value<-rep(NA, nrow(circles1_HN))
rockHN<-matrix(NA,nrow = nrow(circles1_HN), ncol = length(levels(hydrogeomorphic_division_HN$ROCK_TYPE)))
rockHN<-as.data.frame(rockHN)
colnames(rockHN)<-levels(hydrogeomorphic_division_HN$ROCK_TYPE)
for (i in 1:nrow(circles1_HN)) {
  rock_type<-rocksHN[[i]]
  total_value[i]<-length(rocksHN[[i]])
  b<-as.data.frame(table(rock_type))
  rockHN[i,as.numeric(as.character(b$rock_type))]<-b$Freq
}

rockHN<-rockHN/total_value

rockHN$f_id<-circles1_HN$f_id

total_value<-rep(NA, nrow(circles1_D))
rockD<-matrix(NA,nrow = nrow(circles1_D), ncol = length(levels(hydrogeomorphic_division_D$ROCK_TYPE)))
rockD<-as.data.frame(rockD)
colnames(rockD)<-levels(hydrogeomorphic_division_D$ROCK_TYPE)
for (i in 1:nrow(circles1_D)) {
  rock_type<-rocksD[[i]]
  total_value[i]<-length(rocksD[[i]])
  b<-as.data.frame(table(rock_type))
  rockD[i,as.numeric(as.character(b$rock_type))]<-b$Freq
}

rockD<-rockD/total_value

rockD$f_id<-circles1_D$f_id

rock_areas<-plyr::rbind.fill(rockKBM, rockHN, rockD)

rock_areas<-rock_areas%>%dplyr::select(-f_id,f_id)

for (i in 1:65) {
  colnames(rock_areas)[i]<-paste("rock_area", i, sep="_")
}

rock_areas[is.na(rock_areas)]<-0

baseline_data<-inner_join(baseline_data, rock_areas, by="f_id")

#===============================================================================================================
#===============================================================================================================
#Getting Rock Areas in Elevation Points
#===============================================================================================================
#===============================================================================================================
#Getting height for all the farmers
#Converting to Spatial Dataframes because it is necessary to get heights from the raster file

heightKBM<-elevKBM

for (i in 1:nrow(circles1_KBM)) {
  farmer_height<-baseline_data$g11_gpsaltitude[circles1_KBM$f_id[i]==baseline_data$f_id]
  heightKBM[[i]]<-ifelse(heightKBM[[i]]>=farmer_height, heightKBM[[i]], NA)
}

rockKBM<-rocksKBM

for (i in 1:nrow(circles1_KBM)) {
  rockKBM[[i]]<-ifelse(is.na(heightKBM[[i]]), NA, rockKBM[[i]])
}

total_value<-rep(NA, nrow(circles1_KBM))
rock_elevKBM<-matrix(NA,nrow = nrow(circles1_KBM), ncol = length(levels(hydrogeomorphic_division_KBM$ROCK_TYPE)))
rock_elevKBM<-as.data.frame(rock_elevKBM)
colnames(rock_elevKBM)<-levels(hydrogeomorphic_division_KBM$ROCK_TYPE)
for (i in 1:nrow(circles1_KBM)) {
  rock_type<-rockKBM[[i]]
  total_value[i]<-length(rocksKBM[[i]])
  b<-as.data.frame(table(rock_type))
  rock_elevKBM[i,as.numeric(as.character(b$rock_type))]<-b$Freq
}


rock_elevKBM<-rock_elevKBM/total_value

rock_elevKBM$f_id<-circles1_KBM$f_id

heightHN<-elevHN

for (i in 1:nrow(circles1_HN)) {
  farmer_height<-baseline_data$g11_gpsaltitude[circles1_HN$f_id[i]==baseline_data$f_id]
  heightHN[[i]]<-ifelse(heightHN[[i]]>=farmer_height, heightHN[[i]], NA)
}

rockHN<-rocksHN

for (i in 1:nrow(circles1_HN)) {
  rockHN[[i]]<-ifelse(is.na(heightHN[[i]]), NA, rockHN[[i]])
}

total_value<-rep(NA, nrow(circles1_HN))
rock_elevHN<-matrix(NA,nrow = nrow(circles1_HN), ncol = length(levels(hydrogeomorphic_division_HN$ROCK_TYPE)))
rock_elevHN<-as.data.frame(rock_elevHN)
colnames(rock_elevHN)<-levels(hydrogeomorphic_division_HN$ROCK_TYPE)
for (i in 1:nrow(circles1_HN)) {
  rock_type<-rockHN[[i]]
  total_value[i]<-length(rocksHN[[i]])
  b<-as.data.frame(table(rock_type))
  rock_elevHN[i,as.numeric(as.character(b$rock_type))]<-b$Freq
}


rock_elevHN<-rock_elevHN/total_value

rock_elevHN$f_id<-circles1_HN$f_id


heightD<-elevD

for (i in 1:nrow(circles1_D)) {
  farmer_height<-baseline_data$g11_gpsaltitude[circles1_D$f_id[i]==baseline_data$f_id]
  heightD[[i]]<-ifelse(heightD[[i]]>=farmer_height, heightD[[i]], NA)
}

rockD<-rocksD

for (i in 1:nrow(circles1_D)) {
  rockD[[i]]<-ifelse(is.na(heightD[[i]]), NA, rockD[[i]])
}

total_value<-rep(NA, nrow(circles1_D))
rock_elevD<-matrix(NA,nrow = nrow(circles1_D), ncol = length(levels(hydrogeomorphic_division_D$ROCK_TYPE)))
rock_elevD<-as.data.frame(rock_elevD)
colnames(rock_elevD)<-levels(hydrogeomorphic_division_D$ROCK_TYPE)
for (i in 1:nrow(circles1_D)) {
  rock_type<-rockD[[i]]
  total_value[i]<-length(rocksD[[i]])
  b<-as.data.frame(table(rock_type))
  rock_elevD[i,as.numeric(as.character(b$rock_type))]<-b$Freq
}


rock_elevD<-rock_elevD/total_value

rock_elevD$f_id<-circles1_D$f_id

rock_areas<-plyr::rbind.fill(rock_elevKBM, rock_elevHN, rock_elevD)

rock_areas<-rock_areas%>%dplyr::select(-f_id,f_id)

for (i in 1:65) {
  colnames(rock_areas)[i]<-paste("rock_areaelev", i, sep="_")
}

rock_areas[is.na(rock_areas)]<-0

baseline_data<-inner_join(baseline_data, rock_areas, by="f_id")


#===============================================================================================================
#===============================================================================================================
# Distance to faults from Farmer Locations
#===============================================================================================================
#===============================================================================================================


##Creating an object to store the distance
dist <- data.frame(fault_dist = 1: nrow(baseline_data))

##Calculating the distance and storing in the 'dist2fault' dataframe
###Using 'st_distance' to calculate distance of all faults to the 'i'th farmer
###Finding the fault with the minimum distance and Subsetting it
###Then finding the distance of the closest fault and saving it in the 'i'th row of the dist_2fault
for (i in 1:nrow(baseline_data)) {
  dist[i, 1] <- st_distance(baseline_data[i,], faults[which.min(
    st_distance(faults, baseline_data[i,])), ]) 
}

#Converting distance from meters to kilometers
dist <- dist %>% mutate(fault_dist_km = dist$fault_dist/1000)

#Copying the closest distance of each farmer as a new vector in the original database
baseline_data <- baseline_data %>% mutate(dist2fault_km = dist$fault_dist_km)

#===============================================================================================================
#===============================================================================================================
# Total Length of Water Conducive Fractures within 1 km
#===============================================================================================================
#===============================================================================================================

#Creating respondent ID to sort the intersection with faults
baseline_data<- baseline_data %>% mutate(resp_ID = 1: nrow(baseline_data))

#Creating circles of radius 1km around each point in the respondents data
circles_1km<-st_buffer(baseline_data,1000)

#Finding intersection of 1 km circles and faults                               
ints <- st_intersection(faults, circles_1km)                            

#Finding the total length of faults within each circle
fault_len_1km_radius <- tapply(st_length(ints), ints$resp_ID, sum)

#Matching and adding the total length in meters
circles_1km$ltot_1km = rep(0,nrow(circles_1km))
circles_1km$ltot_1km[match(names(fault_len_1km_radius),circles_1km$resp_ID)] = fault_len_1km_radius

#Converting total length into km and adding vector to originl respondent file 

circles_1km<- circles_1km %>% mutate(ltot_1km = circles_1km$ltot_1km/1000)
baseline_data<- baseline_data %>% mutate(ltot_1km = circles_1km$ltot_1km)

#===============================================================================================================
#===============================================================================================================
# Total Length of Water Conducive Fractures within 5 km
#===============================================================================================================
#===============================================================================================================

#Creating a circle of 5km radius
circles_5km<-st_buffer(baseline_data, 5000)


#Finding intersection of 5 km circles and faults                               
ints <- st_intersection(faults, circles_5km)                            

#Finding the total length of faults within each circle
fault_len_5km_radius <- tapply(st_length(ints), ints$resp_ID, sum)

#Matching and adding the total length in meters
circles_5km$ltot_5km = rep(0,nrow(circles_5km))
circles_5km$ltot_5km[match(names(fault_len_5km_radius),circles_5km$resp_ID)] = fault_len_5km_radius

#Converting total length into km and adding vector to originl respondent file 

circles_5km<- circles_5km %>% mutate(ltot_5km = circles_5km$ltot_5km/1000)
baseline_data<- baseline_data %>% mutate(ltot_5km = circles_5km$ltot_5km)
baseline_data<-dplyr::select(baseline_data, -"resp_ID")

#==============================================================================================================
#===============================================================================================================
#===============================================================================================================
##Finding the fault midpoints
#===============================================================================================================

###Converting to sp object as it has better functions for midpoint calculation
faults_sp <- sf:::as_Spatial(faults$geom)
faults_midpoints <- SpatialLinesMidPoints(faults_sp)

###Converting back to sf object
faults_midpoints<-st_as_sf(faults_midpoints,crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")

###Creating fault_UID and removing an erronous observation added when finding midpoints
colnames(faults_midpoints)[1] <- "fault_UID"

###Finding the slope direction (aspect) at the midpoints
aspectKBM <- raster::terrain(contourDEM_KBM, opt= 'aspect', unit='degrees', neighbors=8)
aspectHN<- raster::terrain(contourDEM_HN, opt= 'aspect', unit='degrees', neighbors=8)
aspectD<- raster::terrain(contourDEM_D, opt= 'aspect', unit='degrees', neighbors=8)

#Getting the slopes at each point
faults_midpoints<- faults_midpoints %>% mutate(mp_aspectKBM = raster::extract(aspectKBM, data.frame(st_coordinates(faults_midpoints))))
faults_midpoints<- faults_midpoints %>% mutate(mp_aspectHN = raster::extract(aspectHN, data.frame(st_coordinates(faults_midpoints))))
faults_midpoints<- faults_midpoints %>% mutate(mp_aspectD = raster::extract(aspectD, data.frame(st_coordinates(faults_midpoints))))

total_aspect<-faults_midpoints[,c(2,3,4)]
st_geometry(total_aspect)<-NULL
total_aspect<-apply(total_aspect, 1, sum, na.rm=TRUE)

faults_midpoints<-faults_midpoints%>%mutate(mp_aspect=total_aspect)

rm(total_aspect)
faults_midpoints<-dplyr::select(faults_midpoints,-c(mp_aspectKBM, mp_aspectHN, mp_aspectD))

###Slope needs to be made bi-directional as angle with fault cannot be more than 180 degrees
faults_midpoints$mp_aspect <- ifelse(faults_midpoints$mp_aspect>180, faults_midpoints$mp_aspect-180, faults_midpoints$mp_aspect)

#===============================================================================================================
#Merging the slope and fault directions and getting relative orientation
#===============================================================================================================

slope_fault_mp <- data.frame(slope = faults_midpoints$mp_aspect,
                             fault_uid = faults_midpoints$fault_UID
)
faults <- merge(faults, slope_fault_mp, by = "fault_uid")

rm(slope_fault_mp)
###Relative orientation 
faults<- faults %>% mutate(rel_orient_slope = faults$fault_angle - faults$slope)

###Modulous of relative orientation
faults$rel_orient_slope <- ifelse(faults$rel_orient_slope<0, 0- faults$rel_orient_slope, faults$rel_orient_slope)

faults_midpoints<-st_transform(faults_midpoints,crs = "+proj=utm +zone=42 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")

#===============================================================================================================
#Mean relative orientation of slope and faults within 5 km of farmer's location
#===============================================================================================================

mean_slope_faults <- NA

###Finding the fault whose midpoints are within the 5km radius, getting their mean orientation and adding to baseline data
a <- st_intersects(circles, faults_midpoints)

for (i in 1:nrow(baseline_data)) {
  b<-mean(faults[a[[i]],5]$rel_orient_slope)
  mean_slope_faults[i]<-b
}

baseline_data<- baseline_data %>% mutate(mean_slope_fault = NA)

baseline_data$mean_slope_fault <- mean_slope_faults
#===============================================================================================================
##Extracting elevations from contour for Baseline respondents
##Finding the closest fault for each respondent
#===============================================================================================================

##Creating an object to store the distance
closest_fault <- data.frame(fault = 1: nrow(baseline_data))

##Calculating the distance and storing in the 'dist2fault' dataframe
###Using 'st_distance' to calculate distance of all faults to the 'i'th farmer
###Finding the fault with the minimum distance and Subsetting it
###Then finding the distance of the closest fault and saving it in the 'i'th row of the dist_2fault
for (i in 1:nrow(baseline_data)) {
  closest_fault[i,1] <- faults[which.min(st_distance(faults, baseline_data[i,])), 1] 
}

#===============================================================================================================
##Finding elevation of fault midpoints
#===============================================================================================================

###Finding and adding elevation at each point
faults_midpoints<- faults_midpoints %>% mutate(fault_elevD = raster::extract(contourDEM_D, data.frame(st_coordinates(faults_midpoints))))
faults_midpoints<- faults_midpoints %>% mutate(fault_elevHN = raster::extract(contourDEM_HN, data.frame(st_coordinates(faults_midpoints))))
faults_midpoints<- faults_midpoints %>% mutate(fault_elevKBM = raster::extract(contourDEM_KBM, data.frame(st_coordinates(faults_midpoints))))

total_midpoints<-faults_midpoints[,c(3,4,5)]
st_geometry(total_midpoints)<-NULL
total_midpoints<-apply(total_midpoints, 1, sum, na.rm=TRUE)

faults_midpoints<-faults_midpoints%>%mutate(fault_elev=total_midpoints)


rm(total_midpoints)

faults_midpoints<-dplyr::select(faults_midpoints,-c(fault_elevD, fault_elevHN,fault_elevKBM))

#===============================================================================================================
###Merging faults elevation data with baseline data
#===============================================================================================================

faults_closest_elev <- data.frame(fault_elev = faults_midpoints$fault_elev,
                                  fault_UID = faults_midpoints$fault_UID
)

nearest_faults<-rep(NA,nrow(closest_fault))
for (i in 1:nrow(closest_fault)) {
  nearest_faults[i]<-faults_closest_elev[closest_fault[[1]][i],1]
}
baseline_data <- baseline_data%>%mutate(diff_elevation_fault = nearest_faults)

baseline_data$diff_elevation_fault<-baseline_data$diff_elevation_fault - baseline_data$g11_gpsaltitude

baseline_data<-dplyr::select(baseline_data, -geometry, geometry)

#===============================================================================================================
### Adding temperature and precipitation controls
#===============================================================================================================

#===============================================================================================================
###Converting everything to decimal places 2
#===============================================================================================================

for (i in 1:65) {
  variable<-paste("rock_area_", i, sep="")
  baseline_data[[variable]]<-round(baseline_data[[variable]],3)
  variable<-paste("rock_areaelev_", i, sep="")
  baseline_data[[variable]]<-round(baseline_data[[variable]],3)
}

baseline_data$dist2fault_km<-round(baseline_data$dist2fault_km, 3)
baseline_data$ltot_1km<-round(baseline_data$ltot_1km, 3)
baseline_data$ltot_5km<-round(baseline_data$ltot_5km, 3)
baseline_data$mean_slope_fault<-round(baseline_data$mean_slope_fault, 3)
baseline_data$diff_elevation_fault<-round(baseline_data$diff_elevation_fault, 3)
baseline_data$mean_slope_fault[is.na(baseline_data$mean_slope_fault)]<-0


baselinecsv<-baseline_data
st_geometry(baselinecsv)<-NULL



# Change to Output PATH
setwd(output_data_path)

write.csv(baselinecsv, "geo-coded_variables.csv")

baseline_data<-as(baseline_data, "Spatial")
baseline_data<-as(baseline_data, "SpatialPointsDataFrame")
writeOGR(obj = baseline_data, dsn="geo-coded_variables", layer = "baseline_data", driver = "ESRI Shapefile",overwrite_layer = TRUE)


# #=================================================================================================================
# ########################################## CLIMATE DATA ########################################################## 
# #=================================================================================================================
# data_path <- "/data"
# input_path<-paste(project_path,data_path,"/weather/raw",sep="")
# 
# setwd(input_path)
# 
# baseline_data_path <- paste(project_path,data_path,"/farmer_survey/clean",sep="")
# baseline_data<-read.dta13(paste0(baseline_data_path,"/clean_baseline_survey.dta"))
# 
# # Get location data from the encrypted PII 
# farmer_location_data <- read.dta13('pii_farmer_locations.dta')
# 
# # Merge with baseline data
# baseline_data <- baseline_data %>% left_join(farmer_location_data,by="f_id")
# 
# 
# 
# #Cleaning the Baseline Data
# 
# ##Deleting observations which do not have GPS coordinates (613/6377 do not have GPS data)
# baseline_data<-baseline_data[complete.cases(baseline_data$g11_gpslongitude), ]
# 
# ##Keeping only the relevant variables(SDO names and gps location)
# baseline_data<-baseline_data %>% dplyr::select(f_id, SDO, g11_gpsaltitude, 
#                                                g11_gpslatitude, g11_gpslongitude, avg_source_depth, g11_gpsaccuracy)
# 
# ##Cleaning away the missing values (1902/5744 do not have a well and thus not useful for analysis)
# baseline_data<-baseline_data[!is.na(baseline_data$avg_source_depth),]
# 
# ##Removing outliers of well depth above 1200
# baseline_data<-subset(baseline_data, avg_source_depth < 1200)
# 
# farmer_lon_lat<-data.frame(f_id = baseline_data$f_id,
#                            lon = baseline_data$g11_gpslongitude,
#                            lat = baseline_data$g11_gpslatitude)
# 
# 
# #===============================================================================================================
# #===============================================================================================================
# # Reading Climate Data
# output_var<-c()
# output_var$f_id<-farmer_lon_lat$f_id
# output_var$SDO<-baseline_data$SDO
# output_var<-as.data.frame(output_var)
# 
# for (var in c("ppt","soil","tmax","tmin")) {
#   for(year in c("2016","2017")){
#     fname=paste(paste("TerraClimate",var,year,sep="_"),".nc",sep="")
#     ncin = nc_open(fname)
#     out<-c()
#     latitude<-ncvar_get(ncin,"lat")
#     longitude<-ncvar_get(ncin,"lon")
#     devlat<-sapply(farmer_lon_lat$lat, function(x){which.min(abs(latitude-x))})
#     devlon<-sapply(farmer_lon_lat$lon, function(x){which.min(abs(longitude-x))})
#     variable_var<-ncvar_get(ncin,var)
#     dev_var<-cbind(devlon,devlat)
#     out<-t(apply(dev_var, 1, function(x){variable_var[x[1],x[2],]}))
#     out<-as.data.frame(out)
#     col_names1<-seq(1:ncol(out))
#     col_names1<-paste0(var,"_",year,"_",col_names1)
#     colnames(out)<-col_names1
#     output_var<-cbind(output_var,out)
#   }
# }
# 
# for(i in 3:ncol(output_var)){
#   output_var[,i]<-round(output_var[,i],2)
# }
# #===============================================================================================================
# #===============================================================================================================
# # Saving the results
# 
# write.csv(output_var, paste0(project_path,"/data/geology/clean/weather.csv"),row.names = FALSE)
# 
# # Saving the results for the co-ordinates of the farmers
# 
# farmer_lon_lat<-farmer_lon_lat[,-1]
# 
# write.csv(farmer_lon_lat, paste0(project_path,"/data/geology/clean/farmer_lon_lat.csv"),row.names = FALSE)

