# install.packages('dataRetrieval')
#install.packages('maps')
library(dataRetrieval)
#library(maps)
library(tidyverse)
library(openxlsx)

# A) Search for monitoring sites using a bounding box ----
  # bounding box must be in order: West Lon, South Lat, East Lon, North Lat
sites <- whatNWISsites(bBox=c(-76.502778,42.716667,-76.166667,43.03335)) %>% 
  # Only pull data for lake and stream sites
  filter(site_tp_cd=='LK'|site_tp_cd=='ST')

  # Take a look at query result
head(sites)

  # Look at what type of sites remain
  # List of site_tp_cd: https://maps.waterdata.usgs.gov/mapper/help/sitetype.html
  unique(sites$site_tp_cd)
#   . Pull out a list of site codes from A ----
  sitnums <- unique(sites$site_no)
  
# B) Look at the available data from sites found in section A (not a data download) ----
  # use "whatNWISdata()" to see what data is available for selected site numbers
  data_peek <- whatNWISdata(siteNumber = sitnums) %>% 
    # Apply data filters
    filter(begin_date>='2000-01-01')
#   . Examine data from B to see if they are from sites of interest ----
  # Create an object of stations not explicitly labelled "Skaneateles" 
  nolabel <- unique(data_peek$station_nm[str_detect(data_peek$station_nm, 
                    # str_detect looks for a character string in a vector
                    # the .* tells the function to look through the whole string
                                              'SKANEATELES .*', 
                    # negate = T returns values without the character string that was specified
                                              negate = T)])
  
  # Get a list of lat and long for outlier sites to check in Google Earth
    # This prints to the console and lat and long have to be manually entered into 
    # Google Earth to see where the sites fall unless the name tells us that it should
    # be kept/removed
  for (i in 1:NROW(nolabel)) {
   x <- data_peek[data_peek$station_nm==nolabel[i],]
   print(unique(x$station_nm))
   print(c(i,
           unique(c(x$dec_lat_va,x$dec_long_va))))
  }

  # Filter out sites determined to not be pertinent to study
  # First make list of outlier sites to EXCLUDE
  badsites <- nolabel[c(1,3:21,23,24)] # These are sites to remove
#   . Create object with info about data available from sites of interest ----
  skandat <- data_peek %>% 
    # only keep rows that are pertinent (station names NOT in `badsites` object)
    filter(!station_nm %in% badsites)
  
# C) Create object containing parameter names to match with codes ----
#   . Create a dataframe containing the parameter names for unique parameter codes ----
  paramCds <- parameterCdFile
  names(paramCds)[1] <- "parm_cd"
  
# D) Separate stream and Lake sites ----
#   . Pull out stream sites ----
  stream_dat <- skandat %>% 
    filter(site_tp_cd=='ST')
  
  stream_dat <-  merge(stream_dat, paramCds, by = "parm_cd", all.x = TRUE)
  
  strm_sites <- unique(stream_dat$site_no)
  
#   . Pull out lake sites
  lake_dat <- skandat %>% 
    filter(site_tp_cd=='LK')
  
  lake_dat <-  merge(lake_dat, paramCds, by = "parm_cd", all.x = TRUE)

  lak_sites <- unique(lake_dat$site_no)
  
# E) Data download ----
#   . Pull data for selected sites ----
final_strmdat <- readNWISdata(siteNumber = strm_sites,
                           startDate = '2000-01-01')
  
  final_strmdat <- renameNWISColumns(final_strmdat) 
  
  # write to file----
  # write.xlsx(final_strmdat, file = 'USGS_Skan_streams.xlsx')

final_lakedat <- readNWISdata(siteNumber = lak_sites,
                         startDate = '2000-01-01')

final_lakedat <- renameNWISColumns(final_lakedat)
  
  # write to file----
  # write.xlsx(final_lakedat, file = 'USGS_Skan_lake.xlsx')

lakesiteinfo <- readNWISsite(lak_sites)

write.xlsx(lakesiteinfo, file = "USGS_lakesite_info.xlsx")

