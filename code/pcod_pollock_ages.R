# title Pacific cod and pollock ages
# create date: 02 December 2025
# modified date:
# contact info: rebecca.haehn@noaa.gov
# 
# # load packages
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
                      SELECT survey_definition_id, hauljoin, a.cruise, b.year, a.start_time, a.vessel,
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

species_agedata <- sqlQuery(channel, "
                      SELECT hauljoin, cruise, region, vessel, haul,
                      species_code,
                      specimenid, length, sex, weight, age, maturity,
                      maturity_table
                
                      FROM RACEBASE.SPECIMEN a
                 
                      WHERE
                       
                        species_code in (21720, 21740) AND
                        vessel in (162, 94, 148); 
                       ")
species_agedata <- clean_names(species_agedata) #clean up column names

filter <- species_agedata %>%
  left_join(haul_table) %>%
  filter(year %in% c(2021, 2022))

# export dataframe as csv
write_csv(filter, here("output", "pcod_pollock_ages.csv"))
