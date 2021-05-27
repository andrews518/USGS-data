# install.packages('dataRetrieval')
#install.packages('maps')
library(dataRetrieval)
library(maps)
library(tidyverse)

# Search for monitoring sites using a bounding box ----
  # bounding box must be in order: West Lon, South Lat, East Lon, North Lat
sites <- whatNWISsites(bBox=c(-76.502778,42.716667,-76.166667,43.03335)) %>% 
  # Only pull data for lake and stream sites
  filter(site_tp_cd=='LK'|site_tp_cd=='ST')

  # Take a look at query result
head(sites)

# Filter results to only site types of interest ----
  # Look at what type of sites remain
  # List of site_tp_cd: https://maps.waterdata.usgs.gov/mapper/help/sitetype.html
  unique(sites$site_tp_cd)
  # . Decide which sites to keep and filter ----
  # Pull out a list of site codes
  sitnums <- unique(sites$site_no)
#unique(sites$station_nm[sites$site_tp_cd=='LK'|sites$site_tp_cd=='ST'])
  
# Look at the available data for all sites within bounding box ----
  # use "whatNWISdata()" to see what data is available for selected site numbers
  try <- whatNWISdata(siteNumber = sitnums) %>% 
    filter(begin_date>='2000-01-01')
  # . Create an object of stations not explicitly labelled "Skaneateles" ----
  nolabel <- unique(try$station_nm[str_detect(try$station_nm, 
                                              'SKANEATELES .*', 
                                              negate = T)])
  
  # Get a list of lat and long for outlier sites to check in Google Earth
  for (i in 1:NROW(nolabel)) {
   x <- try[try$station_nm==nolabel[i],]
   print(unique(x$station_nm))
   print(c(i,
           unique(c(x$dec_lat_va,x$dec_long_va))))
  }

  # Filter out sites determined to not be pertinent to study
  # First make list of outlier sites to exclude
  badsites <- nolabel[c(1,3:21,23,24)]
  junk <- try %>% 
    filter(!station_nm %in% badsites)
  
  stream_dat <- junk %>% 
    filter(site_tp_cd=='ST')
  
  strm_sites <- unique(stream_dat$site_no)
  
  lake_dat <- junk %>% 
    filter(site_tp_cd=='LK')
  
  lak_sites <- unique(lake_dat$site_no)
  
# Pull data for selected sites ----
stream_dat <- readNWISdata(siteNumber = strm_sites,
                           startDate = '2000-01-01')
  
stream_dat <- renameNWISColumns(stream_dat) 

lake_dat <- readNWISdata(siteNumber = lak_sites,
                         startDate = '2000-01-01')

  lake_dat <- renameNWISColumns(lake_dat)
  
