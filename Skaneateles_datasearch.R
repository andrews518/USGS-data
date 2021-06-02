# install.packages('dataRetrieval')
#install.packages('maps')
library(dataRetrieval)
#library(maps)
library(tidyverse)
library(openxlsx)

# A) USGS parameter names are contained within a data object called parameterCdFile ----
#   . Create a dataframe from this object and change name of parameter code column ----
#     This will be used later to create a column of parameter names instead of codes
  # paramCds <- parameterCdFile[,c(1,3,6)]
  #   names(paramCds)[c(1,3)] <- c("parm_cd", 'units')

# B) Search for monitoring sites in/around Skaneateles Lake using a bounding box ----
#    bounding box must be in order: West Lon, South Lat, East Lon, North Lat
sites <- whatNWISsites(bBox=c(-76.502778,42.716667,-76.166667,43.03335)) %>% 
#    Only pull data for lake and stream sites
  filter(site_tp_cd=='LK'|site_tp_cd=='ST')

#   . Pull out a list of site numbers from B ----
#    Take a look at site query result
  head(sites)
  
#   Make sure only stream and lake sites remain
#   List of site_tp_cd: https://maps.waterdata.usgs.gov/mapper/help/sitetype.html
  unique(sites$site_tp_cd) 
  
# Pull the site numbers into a vector
sitnums <- unique(sites$site_no)
  
# C) Look at the available data from sites found in section B (not a data download) ----
#    use "whatNWISdata()" to see what data is available for selected site numbers
  data_peek <- whatNWISdata(siteNumber = sitnums) %>% 
    # Apply data filters
    filter(begin_date>='2000-01-01')

#   . Examine data from B to see if they are from sites of interest ----
#   Create an object of stations not explicitly labelled as "Skaneateles" 
    nolabel <- unique(data_peek$station_nm[str_detect(data_peek$station_nm, 
                    # str_detect looks for a character string in a vector
                    # the .* tells the function to look through the whole string
                                              'SKANEATELES .*', 
                    # negate = T returns values without the character string that was specified
                                              negate = T)])
  
# Get a list of lat and long for outlier sites to check in Google Earth
#     This prints to the console and lat and long have to be manually entered into 
#     Google Earth to see where the sites fall unless the name tells us that it should
#     be kept/removed

  for (i in 1:NROW(nolabel)) {
   x <- data_peek[data_peek$station_nm==nolabel[i],]
   print(unique(x$station_nm))
   print(c(i,
           unique(c(x$dec_lat_va,x$dec_long_va))))
  }

#   . Sites to keep
  nolabel[2] # "GROUT BROOK NEAR FAIR HAVEN NY"
  nolabel[22] # "OD 178"
  
#   . Filter out sites determined to not be pertinent to study; ----
    # First make list of outlier sites to EXCLUDE
    badsites <- nolabel[c(1,3:21,23,24)] # These are sites to remove
    
#   . Create object with info about data available from sites of interest 
  skan_sites <- data_peek %>% 
    # only keep rows that are pertinent (station names NOT in `badsites` object)
    filter(!station_nm %in% badsites)
  
# D) Separate stream and Lake sites ----
#   . Pull out stream sites ----
  stream_dat <- skan_sites %>% 
    filter(site_tp_cd=='ST')
  
  # pull out a vector of site codes for stream sites of interest
  strm_sites <- unique(stream_dat$site_no)
  
#   . Pull out lake sites ----
  lake_dat <- skan_sites %>% 
    filter(site_tp_cd=='LK')

  # pull out a vector of the site codes for stream sites of interest
  lak_sites <- unique(lake_dat$site_no)
  
# E) Data download ----
#   . Lake Data ----
# Use the water quality specific pull function
  lake_wqdat <- readNWISqw(siteNumber = lak_sites,
                     parameterCd = 'All') %>% 
    filter(sample_dt>='2000-01-01')
  
  # Pull units from table attributes and add as column
  lkvar_info <- attr(lake_wqdat, 'variableInfo')[,c(1,3,6)]
    
    # rename columns to match dataframe prior to merge
    names(lkvar_info) <- c('parm_cd', 'parameter_name', 'units')
    
  # Pull site info from table attributes and add as column
    lksite_info <- attr(lake_wqdat, 'siteInfo')[,2:3]
    
    # Merge to make new columns with site names
    lake_wqdat <- merge(lake_wqdat, lksite_info, by = 'site_no', all.x = T)  
    # Add columns with names and units using a merge
    lake_wqdat <- merge(lake_wqdat, lkvar_info, by = 'parm_cd', all.x = T)

  # Rename columns
  lake_wqdat <- renameNWISColumns(lake_wqdat)
    
#     - write to file----
  # write.xlsx(lake_wqdat, file = 'USGS_Skan_lake_WQ.xlsx')
#   . Stream Data ----  
# Use the general pull for stream data
  final_strmdat <- readNWISdata(siteNumber = strm_sites,
                                startDate = '2000-01-01')
  # Rename columns
  final_strmdat <- renameNWISColumns(final_strmdat) 
  
  # Pull units from table attributes and add as column
  strmvar_info <- attr(final_strmdat, 'variableInfo')
    final_strmdat$units <- strmvar_info$unit
    
  # Pull site names from table attributes and add as column
  strmsite_info <- attr(final_strmdat, 'siteInfo')[,1:2]
    
  # Merge to make new columns
    final_strmdat <- merge(final_strmdat, strmsite_info, by = 'site_no', all.x = T)
#     - write to file----
  # write.xlsx(final_strmdat, file = 'USGS_Skan_streamflow.xlsx')
