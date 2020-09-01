#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

#Function to return water flow
#Date: 20 September 2019 
#Author: Viraj Jorapur 

#===============================================================================================================
#===============================================================================================================
#===============================================================================================================

water_flow <- function(matrix_water_flow){
  feet_to_meter<-0.3048
  gallon_to_liter <- 3.785
  hours_to_min <- 60
  g<-9.8
  hp_to_kw<-0.746
  friction_coefficient<-0.08
  
  
  matrix_water_flow<-as.data.frame(matrix_water_flow)
  colnames(matrix_water_flow)<-c("f_id", "source_depth","pump_cap",
                                 "pump_diameter", "hours_water")
  
  
  matrix_water_flow$source_depth<-feet_to_meter*matrix_water_flow$source_depth
  matrix_water_flow$pump_diameter<-feet_to_meter*matrix_water_flow$pump_diameter
#============ Following line is new addition ===================================
  matrix_water_flow$pump_cap<-hp_to_kw*matrix_water_flow$pump_cap
#===============================================================================
  
  matrix_water_liter<-matrix(data = NA, nrow = nrow(matrix_water_flow), ncol = 2)
  matrix_water_liter<-as.data.frame(matrix_water_liter)
  colnames(matrix_water_liter)<-c("f_id", "water_liters")
  
  
  #matrix_water_flow <- matrix_water_flow %>% dplyr::mutate(water_liters = 
  #                    (-source_depth + sqrt(source_depth^2 + 16*source_depth*g*
  #                                           pump_cap/(pi*pump_diameter)))/
  #                      (8*source_depth*g/(pi*pump_diameter)))
  
  #matrix_water_flow$water_liters<-matrix_water_flow$water_liters*
  #                                  gallon_to_liter*hours_to_min
  
  #matrix_water_flow$water_liters<-matrix_water_flow$water_liters*
  #                                  matrix_water_flow$hours_water
  
  #matrix_water_liter$f_id <- matrix_water_flow$f_id
  #matrix_water_liter$water_liters <- matrix_water_flow$water_liters
  
  #matrix_water_liter$water_liters<-round(matrix_water_liter$water_liters, 2)
  
  matrix_water_flow<-matrix_water_flow %>% dplyr::mutate(water_liters = 
              3.6*10^6*pump_cap*0.25/(g*source_depth))
  
  matrix_water_flow<-matrix_water_flow %>% dplyr::mutate(water_liter = water_liters
                                                         *hours_water)
  matrix_water_liter$f_id<-matrix_water_flow$f_id
  matrix_water_liter$water_liters<-round(matrix_water_flow$water_liter, 2)
  
  return(matrix_water_liter)
  
}