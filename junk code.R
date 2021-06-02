
# write.xlsx(junkstrm, file = 'USGS_WQ_stream.xlsx')

trash <- readNWISdv(siteNumbers = strm_sites,
                    parameterCd = '00060')

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
#   . Pull data for selected sites ----
lakesiteinfo <- readNWISsite(lak_sites)

write.xlsx(lakesiteinfo, file = "USGS_lakesite_info.xlsx")

junk <- readNWISqw(siteNumber = lak_sites,
                   parameterCd = 'All') %>% 
  filter(sample_dt>='2000-01-01')

junk <-  merge(junk, paramCds, by = "parm_cd", all.x = TRUE)

# write.xlsx(junk, file = 'USGS_WQ_lake.xlsx')