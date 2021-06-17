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

# Set up file paths
args = commandArgs(trailingOnly = TRUE)
if ( Sys.getenv("RSTUDIO") == 1) {
  project_path<-paste(Sys.getenv("HOME"),"/Dropbox/replication_rationing_commons",sep="")
} else {
  project_path<-args[1]
}

library(checkpoint)
checkpoint("2020-07-18",project = project_path, checkpointLocation = paste0(project_path,"/code/"))


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

#===============================================================================================================
#===============================================================================================================

data_path <- "/data"
input_path<-paste(project_path,data_path,"/geology/raw/gw_prospect_maps/shapefiles",sep="")
baseline_data_path <- paste(project_path,data_path,"/farmer_survey/clean",sep="")
output_data_path <- paste(project_path,data_path,"/geology/clean",sep="")
setwd(baseline_data_path)
#===============================================================================================================

#Getting the GPS Data for the locations of farmers
baseline_data<-read.dta13("baseline_survey_farmer_crop_level.dta")

#===============================================================================================================
#===============================================================================================================
#Old code

#feet_to_meter<-0.3048
#gallon_to_liter <- 3.785
#min_to_hours <- 1/60


#baseline1<-baseline_data %>% dplyr::select(c(f_id, avg_source_depth, 
#                                             net_pump_cap, avg_pump_diameter,
#                                             tot_hrs_water_drawn,
#                                             tot_hrs_water_drawn_wnsr))

#baseline1$avg_source_depth<-baseline1$avg_source_depth*feet_to_meter
#baseline1$avg_pump_diameter<-baseline1$avg_pump_diameter*feet_to_meter


#baseline1<-baseline1 %>% dplyr::mutate(flow_gl_per_min = (-avg_source_depth + 
#                        sqrt((avg_pump_diameter*avg_source_depth*9.8/
#                      (pi*((avg_pump_diameter/2)^2)))^2 + 
#                        4*avg_source_depth*net_pump_cap))/(2*avg_source_depth))
#baseline1$flow_l_per_hr<-baseline1$flow_gl_per_min*gallon_to_liter*min_to_hours

#baseline1$water_liter<-baseline1$flow_l_per_hr*baseline1$tot_hrs_water_drawn
#baseline1$water_liter_wnsr<-baseline1$flow_l_per_hr*baseline1$tot_hrs_water_drawn_wnsr

#baseline1$water_liter<-round(baseline1$water_liter, 2)
#baseline1$water_liter_wnsr<-round(baseline1$water_liter_wnsr, 2)
#===============================================================================================================
#===============================================================================================================
#New code
setwd(paste(project_path,"/code/cleaning/farmer_survey",sep=""))

#Sourcing the water flow function

source("waterflow_function.R")

#Get patterns for pumpset data

pump_set_variables1<-grep("b7_1_2_pmp_nmplte_cap_[1-4]_hp",
                         colnames(baseline_data), value = TRUE)
pump_depth_variables1<-grep("b7_3_3_surce_curr_dpth[1-4]_ft",
                            colnames(baseline_data), value = TRUE)
pump_diameter_variables1<-grep("b7_3_9_exp_pipe_diamtr_[1-4]_ft",
                               colnames(baseline_data), value = TRUE)

pump_set_variables2<-grep("c2_2_pmp_nmplte_cap_[1-6]_hp",
                          colnames(baseline_data), value = TRUE)


days_water_drawn<-grep("f2_3_4_dys_wtr_drwn_[1-9]",
                       colnames(baseline_data), value = TRUE)

hours_water_drawn<-grep("f2_3_6_hours_per_day_[1-9]",
                        colnames(baseline_data), value = TRUE)


parcel_irrigated_source<-grep("f2_3_7_parcel_irrigate_[1-9]$",
                              colnames(baseline_data), value = TRUE)

presow_multiplier<-grep("f5_1_6_8_irr_cnt_presow_pcl([1-9]|1[0-5])$",
                        colnames(baseline_data), value = TRUE)

post_multiplier<-grep("f5_1_6_2_irr_cnt_crp_pcl([1-9]|1[0-5])$",
                        colnames(baseline_data), value = TRUE)
for (i in 1:15) {
  baseline_data[,paste0("irrigation_crop_parcel",i)]<-baseline_data[,
                paste0("f5_1_6_8_irr_cnt_presow_pcl",i)] + baseline_data[,
                paste0("f5_1_6_2_irr_cnt_crp_pcl",i)]
}

irrigation_multipliers<-grep("irrigation_crop_parcel*",
                             colnames(baseline_data), value = TRUE)

baseline1<-baseline_data %>% dplyr::select("f_id", "crop", "resp_num",
                            pump_set_variables1, pump_depth_variables1, 
                            pump_diameter_variables1,
                            pump_set_variables2, days_water_drawn,
                            hours_water_drawn, parcel_irrigated_source,
                            "f5_1_5_parcel_crop", irrigation_multipliers)
baseline1<-baseline1[order(baseline1$f_id),]

for (i in hours_water_drawn) {
  baseline1[,colnames(baseline1)==i]<-
    ifelse(baseline1[,colnames(baseline1)==i]>6, 6, 
           baseline1[,colnames(baseline1)==i])
  
  baseline1[,colnames(baseline1)==i]<-
    ifelse(baseline1[,colnames(baseline1)==i]==0, 6, 
           baseline1[,colnames(baseline1)==i])
}

for (i in 1:9) {
  baseline1[,paste0("tot_hours",i)]<-baseline1[,paste0("f2_3_4_dys_wtr_drwn_",
                                                i)]*
    baseline1[,paste0("f2_3_6_hours_per_day_",i)]
}

hours_used<-grep("tot_hours[1-9]$", colnames(baseline1), value = TRUE)

baseline1<-baseline1 %>% mutate(avg_depth=
                                  rowMeans(.[pump_depth_variables1],
                                           na.rm = TRUE))

baseline1<-baseline1 %>% mutate(avg_diameter=
                                  rowMeans(.[pump_diameter_variables1],
                                           na.rm = TRUE))

baseline1<-baseline1 %>% mutate(avg_capacity=
                                  rowMeans(.[pump_set_variables1],
                                           na.rm = TRUE))

baseline1<-baseline1 %>% mutate(tot_hours = 
                                  rowSums(.[hours_used],
                                          na.rm = TRUE))

                                           
for (x in 1:9) {
  baseline1[,paste0("pump_cap",x)]<-NA
  baseline1[,paste0("well_depth",x)]<-NA
  baseline1[,paste0("pipe_diameter",x)]<-NA
}                                                                                      
for (i in 1:13693) {
  pumps_variables<-baseline1[i,c(pump_set_variables1,pump_set_variables2)]
  pumps_variables<-colnames(pumps_variables)[which(!is.na(pumps_variables))]
  if(length(pumps_variables) != 0){
    for (j in 1:length(pumps_variables)) {
      baseline1[i,paste0("pump_cap",j)]<-baseline1[i,pumps_variables[j]]
      if(str_split(pumps_variables[j],"_",simplify = TRUE)[1]=="b7"){
        pump_number<-str_split(pumps_variables[j],"_",simplify = TRUE)[7]
        
        baseline1[i,paste0("well_depth",j)]<-baseline1[i,
                                                       paste0("b7_3_3_surce_curr_dpth",
                                                              pump_number,"_ft")]
        
        baseline1[i,paste0("pipe_diameter",j)]<-baseline1[i,
                                                          paste0("b7_3_9_exp_pipe_diamtr_",
                                                                 pump_number,"_ft")]
      } else{
        baseline1[i,paste0("well_depth",j)]<-baseline1[i, "avg_depth"]
        
        baseline1[i,paste0("pipe_diameter",j)]<-baseline1[i,"avg_diameter"]
      }
    }
  }
 
  if(sum(!is.na(baseline1[i, grep("tot_hours[1-9]$", colnames(baseline1))]))
     ==
     sum(!is.na(baseline1[i, grep("pump_cap[1-9]$", colnames(baseline1))]))) {
    next
  } else {
    replacement_values<-which(
      is.na(baseline1[i, grep("pump_cap[1-9]$", colnames(baseline1))]))
    
    number_replacement<-sum(!is.na
                            (baseline1[i, grep("tot_hours[1-9]$", 
                                               colnames(baseline1))])) - 
      sum(!is.na
          (baseline1[i, grep("pump_cap[1-9]$", 
                             colnames(baseline1))])) 
    if(number_replacement <= 0){
      next
    } else {
      for (x in 1:number_replacement) {
        baseline1[i, paste0("well_depth",replacement_values[x])]<-
          baseline1[i,"avg_depth"]
        
        baseline1[i, paste0("pipe_diameter",replacement_values[x])]<-
          baseline1[i,"avg_diameter"]
        
        baseline1[i, paste0("pump_cap",replacement_values[x])]<-
          baseline1[i,"avg_capacity"]
      }
    }
    
  }
}

for (i in 1:9) {
  baseline1[,paste0("elec_source",i)]<-baseline1[,
            paste0("tot_hours",i)]*baseline1[,paste0("pump_cap",i)]
}
water_liter<-as.data.frame(matrix(NA, nrow = nrow(baseline1), ncol = 21))
colnames(water_liter)<-c("f_id", "crop", "resp_num",
                         "water_liter1","water_liter2",
                         "water_liter3","water_liter4","water_liter5",
                         "water_liter6","water_liter7","water_liter8",
                         "water_liter9", "elec_source1","elec_source2",
                         "elec_source3","elec_source4","elec_source5",
                         "elec_source6","elec_source7","elec_source8",
                         "elec_source9")
water_liter$f_id<-baseline1$f_id
water_liter$crop<-baseline1$crop
water_liter$resp_num<-baseline1$resp_num

for (i in 1:9) {
  water_liter[,paste0("elec_source",i)]<-baseline1[,paste0("elec_source",i)]
}
for(i in 1:9){
  matrix_water_flow<-matrix(NA, nrow = nrow(baseline1), ncol = 5)
  matrix_water_flow<-as.data.frame(matrix_water_flow)
  colnames(matrix_water_flow)<-c("f_id", "source_depth","pump_cap",
                                 "pump_diameter", "hours_water")
  
  matrix_water_flow$f_id<-baseline1$f_id
  matrix_water_flow$source_depth<-baseline1[,paste0("well_depth",i)]
  matrix_water_flow$pump_cap<-baseline1[,paste0("pump_cap",i)]
  matrix_water_flow$pump_diameter<-baseline1[,paste0("pipe_diameter",i)]
  matrix_water_flow$hours_water<-baseline1[,paste0("tot_hours",i)]
 
  water_liters<-water_flow(matrix_water_flow) 
  
  water_liter[,paste0("water_liter",i)]<-water_liters$water_liters
  water_liter[,paste0("water_liter",i)]<-ifelse(
    is.nan(water_liter[,paste0("water_liter",i)]),NA,
           water_liter[,paste0("water_liter",i)])
}


#Calculating total water drawn by farmer

water_variables<-grep("water_*", colnames(water_liter), value = TRUE)

water_liter<-water_liter %>% dplyr::mutate(tot_water_liter = 
                            rowSums(.[water_variables], na.rm = TRUE))

#Calculating total electricity used by farmer

elec_variables<-grep("elec_source[1-9]$", colnames(water_liter), value = TRUE)

water_liter<-water_liter %>% dplyr::mutate(tot_elec_hp = 
                                             rowSums(.[elec_variables], na.rm = TRUE))


for (i in 1:9) {
  water_liter[,paste0("parcel_source",i)]<-baseline1[,
                                    paste0("f2_3_7_parcel_irrigate_",i)]
}

water_liter$crop_parcel<-baseline1$f5_1_5_parcel_crop

water_liter[, irrigation_multipliers]<-baseline1[, irrigation_multipliers]

#Getting water per crop

for (i in 1:9) {
  water_liter[[paste0("water_source",i)]] = NA
}

#Cleaning up the crop parcel variable
#Here we have many 31 and 32 numbers which i take away

crop_parcel<-str_split(water_liter$crop_parcel, " ", simplify = TRUE)
crop_parcel<-as.data.frame(crop_parcel)
crop_parcel<-as.data.frame(apply(crop_parcel, 2, as.numeric))
crop_parcel<-as.data.frame(apply(crop_parcel, 2, function(x){
  ifelse(x>30, x-30, x)}))
final_crop_parcel<-as.data.frame(matrix(NA, nrow =  nrow(crop_parcel), 
                                        ncol = 1))
colnames(final_crop_parcel)<-"crop_parcel"
for (i in 1:nrow(crop_parcel)) {
  a<-na.omit(as.numeric(crop_parcel[i,]))
  a<-paste(a, collapse = " ")
  final_crop_parcel[i,1]<-a
}

rm(crop_parcel)

#Substituting for the new crop numbers
water_liter$crop_parcel<-final_crop_parcel$crop_parcel

#Seperating water multipliers by crop

for (i in 1:nrow(water_liter)) {
  crop_sources<-as.character(str_split(water_liter[i, "crop_parcel"]," ", 
                                       simplify = TRUE))
  if(crop_sources == ""){
    next
  } else{
    irrigation_sources<-as.numeric(water_liter[i, irrigation_multipliers])
    water_liter[i,irrigation_multipliers]<-NA
    irrigation_sources<-na.omit(irrigation_sources)
    crop_sources<-paste0("irrigation_crop_parcel", crop_sources)
    for (j in length(unique(crop_sources))) {
      common_sources<-which(crop_sources==crop_sources[j])
      common_sources<-sum(irrigation_sources[common_sources])
      irrigation_sources[j]<-common_sources
    }
    crop_sources<-unique(crop_sources)
    irrigation_sources<-irrigation_sources[1:length(crop_sources)]
    water_liter[i,crop_sources]<-irrigation_sources
  }
}

water_liter<-dplyr::arrange(water_liter, f_id, crop)
#Using f5_1_2 to get water multipliers
water_multipliers<-baseline_data[,c("f_id", "crop", "f5_1_2_est_wtr_amt", 
                                    "f5_1_4_avg_irr")]

water_multipliers<-water_multipliers %>% group_by(f_id) %>%
  mutate(check_water_mult = ifelse(max(f5_1_2_est_wtr_amt)
                                   ==min(f5_1_2_est_wtr_amt) &
                        (f5_1_4_avg_irr !=0 | !is.na(f5_1_4_avg_irr)), 1, 0))
water_multipliers$check_water_mult<-ifelse(
  is.na(water_multipliers$check_water_mult), 0, 
  water_multipliers$check_water_mult)

water_multipliers<-dplyr::arrange(water_multipliers, f_id, crop)
for (i in 1:nrow(water_liter)) {
  if(water_multipliers$check_water_mult[i] == 0){
    next
  } else{
    water_liter[i, grep("irrigation_crop_parcel*", colnames(water_liter))]<-
      ifelse(is.na(water_liter[i, 
      grep("irrigation_crop_parcel*", colnames(water_liter))]),
      water_liter[i, grep("irrigation_crop_parcel*", colnames(water_liter))],
      water_multipliers$f5_1_4_avg_irr[i])
  }
}

#Cleaning up the parcel source variable
#Here we have many 31 and 32 numbers which i take away
for (i in 1:9) {
  crop_parcel<-str_split(water_liter[[paste0("parcel_source",i)]], " ", 
                         simplify = TRUE)
  crop_parcel<-as.data.frame(crop_parcel)
  crop_parcel<-as.data.frame(apply(crop_parcel, 2, as.numeric))
  crop_parcel<-as.data.frame(apply(crop_parcel, 2, function(x){
    ifelse(x>30, x-30, x)}))
  final_crop_parcel<-as.data.frame(matrix(NA, nrow =  nrow(crop_parcel), 
                                          ncol = 1))
  colnames(final_crop_parcel)<-"crop_parcel"
  for (j in 1:nrow(crop_parcel)) {
    a<-unique(na.omit(as.numeric(crop_parcel[j,])))
    a<-paste(a, collapse = " ")
    final_crop_parcel[j,1]<-a
  }
  rm(crop_parcel)
  
  water_liter[[paste0("parcel_source",i)]]<-final_crop_parcel$crop_parcel
}

water_liter$hp_source1<-baseline1$pump_cap1
water_liter$hp_source2<-baseline1$pump_cap2
water_liter$hp_source3<-baseline1$pump_cap3
water_liter$hp_source4<-baseline1$pump_cap4
water_liter$hp_source5<-baseline1$pump_cap5
water_liter$hp_source6<-baseline1$pump_cap6
water_liter$hp_source7<-baseline1$pump_cap7
water_liter$hp_source8<-baseline1$pump_cap8
water_liter$hp_source9<-baseline1$pump_cap9

#===============================================================================================================
#===============================================================================================================
#Getting Water by Crop

for(farmer in unique(water_liter$f_id)){
  farmer_matrix<-water_liter[which(water_liter$f_id == farmer),]
  for(i in 1:9){
    parcels<-as.character(str_split(farmer_matrix[1,paste0("parcel_source",i)],
                                    " ",
                       simplify = TRUE))
    if(parcels == ""){
      next
    } else{
      parcels<-paste0("irrigation_crop_parcel",parcels)
      rows_correct<-farmer_matrix[parcels]
      rows_correct<-unname(apply(rows_correct, 1, function(x){
        ifelse(sum(!is.na(x))>0, TRUE, FALSE)
      }))
      rows_correct1<-farmer_matrix[rows_correct, irrigation_multipliers]
      rows_correct1<-as.data.frame(rowSums(rows_correct1, na.rm = TRUE))
      if(nrow(rows_correct1) == 0){
        next
      } else{
        colnames(rows_correct1)<-paste0("water_crop_source",i)
        rows_correct2<-as.data.frame(matrix(0, nrow = nrow(farmer_matrix),
                                            ncol = 1))
        colnames(rows_correct2)<-paste0("water_crop_source",i)
        rows_correct2[rows_correct,paste0("water_crop_source",i)]<-
          rows_correct1[[paste0("water_crop_source",i)]]
        rows_correct2[[paste0("water_crop_source",i)]]<-
          rows_correct2[[paste0("water_crop_source",i)]]/sum(rows_correct1)
        rows_correct3<-rows_correct2
        rows_correct4<-rows_correct2
        rows_correct2<-rows_correct2*farmer_matrix[[paste0("water_liter",i)]][1]
        rows_correct3<-rows_correct3*farmer_matrix[[paste0("elec_source",i)]][1]
        rows_correct4<-rows_correct4*farmer_matrix[[paste0("hp_source",i)]][1]
        farmer_matrix[[paste0("water_crop_source",i)]]<-
          rows_correct2[[paste0("water_crop_source",i)]]
        farmer_matrix[[paste0("elec_crop_source",i)]]<-
          rows_correct3[[paste0("water_crop_source",i)]]
        farmer_matrix[[paste0("hp_crop_source",i)]]<-
          rows_correct4[[paste0("water_crop_source",i)]]
        water_liter[which(water_liter$f_id==farmer), paste0("water_crop_source",i)]<-
          round(rows_correct2[[paste0("water_crop_source",i)]], 2)
        water_liter[which(water_liter$f_id==farmer), paste0("elec_crop_source",i)]<-
          round(rows_correct3[[paste0("water_crop_source",i)]], 2)
        water_liter[which(water_liter$f_id==farmer), paste0("hp_crop_source",i)]<-
          round(rows_correct4[[paste0("water_crop_source",i)]], 2)
      }
      
    }
    
  }
}


water_liters<-grep("water_liter[1-9]$", colnames(water_liter), value = TRUE)
water_sources<-grep("water_crop_source[1-9]$", colnames(water_liter), value = TRUE)
elec_variables<-grep("elec_source[1-9]$", colnames(water_liter), value = TRUE)
elec_sources<-grep("elec_crop_source[1-9]$", colnames(water_liter), value = TRUE)
hp_variables<-grep("hp_source[1-9]$", colnames(water_liter), value = TRUE)
hp_sources<-grep("hp_crop_source[1-9]$", colnames(water_liter), value = TRUE)

water_liter$tot_hp<-rowSums(water_liter[hp_variables], na.rm = TRUE)
water_liter$tot_water_crop<-rowSums(water_liter[water_sources], na.rm = TRUE)
water_liter$tot_elec_crop_hp<-rowSums(water_liter[elec_sources], na.rm = TRUE)
water_liter$tot_hp_crop<-rowSums(water_liter[hp_sources], na.rm = TRUE)

water_liter<-water_liter %>% dplyr::group_by(f_id) %>%
  mutate(tot_water_check = sum(tot_water_crop))

water_liter<-water_liter %>% dplyr::group_by(f_id) %>%
  mutate(tot_elec_check_hp = sum(tot_elec_crop_hp))

water_liter<-water_liter %>% dplyr::group_by(f_id) %>%
  mutate(tot_hp_check = sum(tot_hp_crop))

water_liter$error_cal_water<-round(water_liter$tot_water_liter - 
  water_liter$tot_water_check, 2)

water_liter$error_cal_elec<-round(water_liter$tot_elec_hp - 
  water_liter$tot_elec_check_hp, 2)

water_liter$error_cal_hp<-round(water_liter$tot_hp - 
                                    water_liter$tot_hp_check, 2)

water_total<-grep("tot_water_*", colnames(water_liter), value = TRUE)
elec_total<-grep("tot_elec_*", colnames(water_liter), value = TRUE)
hp_total<-grep("tot_hp_*", colnames(water_liter), value = TRUE)
water_liter1<-water_liter[,c("f_id","resp_num","crop", water_liters, elec_variables, hp_variables,
                             water_sources, elec_sources, hp_sources, water_total,
                             elec_total, hp_total, "error_cal_water", "error_cal_elec",
                             "error_cal_hp")]

water_liter1<-water_liter1 %>% dplyr::select(-tot_water_crop, tot_water_crop)
water_liter1<-water_liter1 %>% dplyr::select(-tot_elec_crop_hp, tot_elec_crop_hp)
water_liter1<-water_liter1 %>% dplyr::select(-tot_hp_crop, tot_hp_crop)
colnames(water_liter1)[colnames(water_liter1)=="tot_hp_crop"]<-"pump_farmer_plot"
colnames(water_liter1)[colnames(water_liter1)=="tot_hp"]<-"pump_farmer"
water_liter1$tot_hours<-baseline1$tot_hours
water_liter1$liter_per_hour<-water_liter1$tot_water_liter/water_liter1$tot_hours

water_liter1$liter_per_hour<-round(water_liter1$liter_per_hour, 2)
#Write the output

setwd(output_data_path)

write.csv(water_liter1, "water_flow.csv", row.names = FALSE)



