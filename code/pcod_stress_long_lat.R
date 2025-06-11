# title Pacific cod stress long/lat data retrieval
# create date: 5 June 2025
# modify data:
# contact info: rebecca.haehn@noaa.gov
# 
# load packages
library(here)
library(tidyverse)
library(janitor)
library(RODBC)
# 
### make sure you are connected to VPN first (and have Oracle database login)
channel <- odbcConnect(dsn = "AFSC", 
                       uid = rstudioapi::showPrompt(title = "Username", 
                                                    message = "Oracle Username", default = ""), 
                       pwd = rstudioapi::askForPassword("enter password"),
                       believeNRows = FALSE)

# import haul data from oracle
haul_table <- sqlQuery(channel, "
                      SELECT survey_definition_id, a.cruise, b.year, a.vessel,
                             a.stationid, a.haul, a.start_latitude, a.start_longitude,
                             a.end_latitude, a.end_longitude
                
                      FROM RACEBASE.HAUL a
         
                      JOIN RACE_DATA.V_CRUISES b
         
                      ON a.cruisejoin = b.cruisejoin 
         
                      WHERE
                        
                        survey_definition_id = 98 OR
                        survey_definition_id = 143 AND 
                        gear = 44;
                       ")

haul_table <- clean_names(haul_table) #clean up column names

# import .csv of hauls with stress data (csv provided by PI. File in "data" folder of directory)
stress_hauls <- read_csv(here("data", "Stress GPS.csv"), col_select = c("Date", "Cruise", "Haul"))
stress_hauls <- clean_names(stress_hauls) #clean up column names

# add in vessel code (in email from PI)
stress_hauls$vessel <- 162

#join oracle haul data with stress haul data
stress_long_lat <- stress_hauls %>%
  left_join(haul_table)
  
# export dataframe as csv
write_csv(stress_long_lat, here("output", "stress_lat_long.csv"))
