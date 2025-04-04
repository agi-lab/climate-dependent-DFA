
################################################################################################
## Air temperature ----
################################################################################################

## Write a function to transform the air temperature:

transform_nc_tas_mm_func <- function(australia_shape, nc_data){
    # Transform the Australian shape file to the same coordinate system as the temperature data:
    australia_shape_1 <- spTransform(australia_shape, crs(nc_data))
    # Crop the temperature data such that only the Australian region is covered:
    nc_data_masked = mask(nc_data, australia_shape_1)
    ## Convert to data frame format for further valuation:
    nc_data_df_0 <- as.data.frame(nc_data_masked, xy=TRUE)
    ## Convert to long format and remove the values that are outside the Australian boundary
    nc_data_df_1 <- as.data.frame(na.omit(pivot_longer(nc_data_df_0, cols = starts_with("X", ignore.case = FALSE), names_to = "Dates", values_to = "Temperature_K")))
    ## Get the monthly average temperature data:
    temp_avg_data <- nc_data_df_1 %>% group_by(Dates) %>% summarise(Temperature= mean(Temperature_K-273.15)) %>% ## Convert temperature in Kelvin to Celsius
        mutate(Year = as.numeric(substr(Dates, start = 2, stop = 5)), Month = as.numeric(substr(Dates, start = 7, stop = 8))) %>% dplyr::select(Year, Month, Temperature) ## mutate a Month and Year column
    return(temp_avg_data)
}

### Projections of air temperature ----

#### Import and upzip the air temperature CMIP6 projections
## Get the filenames of zip files:
filenames_AT_zip <- list.files("Data/CMIP6_ensemble_air_temperature/Projections", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_AT_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_AT_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_AT_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_air_temperature/Projections")
}
## Get the file names of all unzipped files:
filenames_AT_nc <- list.files("Data/CMIP6_ensemble_air_temperature/Projections", pattern="*.nc", full.names=TRUE)[-1]


#### Find the common tas models accross all scenarios
Scenarios_list <- c("ssp126", "ssp245", "ssp370", "ssp585")
Model_names_ta_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    filesnames_sce <- filenames_AT_nc[grep(scenario, filenames_AT_nc)]
    Models_names <- c()
    for(i in 1:length(filesnames_sce)){
        Models_names[i] <- str_extract(filesnames_sce[i], "(?<=Amon_).*?(?=_ssp)")
    }
    Model_names_ta_list[[s]] <- Models_names
}
Models_ensemble_ta <- Reduce(intersect, Model_names_ta_list)
filenames_AT_nc <- filenames_AT_nc[grep(paste(Models_ensemble_ta,collapse="|"), filenames_AT_nc)]


#### Remove duplicated model in each scenario (Air temperature)
scenarios_names <- c("ssp126", "ssp245", "ssp370", "ssp585")
filenames_AT_nc_list <- list()
for(i in 1:length(scenarios_names)){
    s <- scenarios_names[i]
    file_scenario <- filenames_AT_nc[grep(s, filenames_AT_nc)]
    mod_names <- str_extract(file_scenario, "(?<=Amon_).*?(?=_ssp)")
    # Find duplicated items
    duplicated_items <- duplicated(mod_names)
    # Get indices of non-duplicated items
    non_duplicated_indices <- which(!duplicated_items)
    filenames_AT_nc_list[[i]] <- file_scenario[non_duplicated_indices]
}

filenames_AT_nc <- unlist(filenames_AT_nc_list)



#### Convert all the ensemble models projections of ta to data frame format
ta_ensemble_all_scenarios_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    files_list <- filenames_AT_nc[grep(scenario, filenames_AT_nc)]
    ta_ensemble_list <- c()
    for(i in 1:length(files_list)){
        ta_nc <- brick(files_list[i])
        ta_mm <- transform_nc_tas_mm_func(australia_shape, ta_nc)
        colnames(ta_mm)[3] <- str_extract(files_list[i], "(?<=Amon_).*?(?=_ssp)") ## Rename the column with model name
        ta_ensemble_list[[i]] <- ta_mm
    }
    ta_ensemble_data_0 <- do.call(cbind, ta_ensemble_list) %>% dplyr::select(-c(Year, Month))
    ta_ensemble_data_1 <- cbind(Year = ta_mm$Year, Month = ta_mm$Month, ta_ensemble_data_0)
    ## Combine all the ensemble model outputs into a data.frame for each scenario
    ta_ensemble_all_scenarios_list[[s]] <- ta_ensemble_data_1
}



#### Write the results to csv files
dirc <- "Data/CMIP6_ensemble_air_temperature/Projections/csv files"
for(s in 1:length(ta_ensemble_all_scenarios_list)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_ta_proj", ".csv")
    write.csv(ta_ensemble_all_scenarios_list[[s]], paste0(dirc, "/", file_name))
}

### Historical backcasts of air temperature ----

#### Import and upzip the near-surface temperature CMIP6 backcast
## Get the filenames of zip files:
filenames_TA_hist_zip <- list.files("Data/CMIP6_ensemble_air_temperature/Historical", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_TA_hist_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_TA_hist_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_TA_hist_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_air_temperature/Historical")
}
## Get the file names of all unzipped files:
filenames_TA_hist_nc <- list.files("Data/CMIP6_ensemble_air_temperature/Historical", pattern="*.nc", full.names=TRUE)


#### Get the CMIP model names used in the historical data
filenames_TA_hist_nc <- filenames_TA_hist_nc[grep(paste(Models_ensemble_ta,collapse="|"), filenames_TA_hist_nc)][-16]

Model_names_ta_hist <- c()
for(i in 1:length(filenames_TA_hist_nc)){
    Model_names_ta_hist[i] <- str_extract(filenames_TA_hist_nc[i], "(?<=Amon_).*?(?=_historical)")
}

Models_ensemble_ta <- intersect(Models_ensemble_ta, Model_names_ta_hist)


#### Convert all the ensemble models historical backacts of ta to data frame format
ta_ensemble_hist_list <- list()
for(i in 1:length(filenames_TA_hist_nc)){
    ta_nc <- brick(filenames_TA_hist_nc[i])
    ta_mm <- transform_nc_tas_mm_func(australia_shape, ta_nc)
    colnames(ta_mm)[3] <-  str_extract(filenames_TA_hist_nc[i], "(?<=Amon_).*?(?=_historical)") ## Rename the column with model name
    ta_ensemble_hist_list[[i]] <- ta_mm
}
ta_ensemble_hist_data_0 <- do.call(cbind, ta_ensemble_hist_list) %>% dplyr::select(-c(Year, Month))
ta_ensemble_hist_data <- cbind(Year = ta_mm$Year, Month = ta_mm$Month, ta_ensemble_hist_data_0)
#Write the results to csv files:
write.csv(ta_ensemble_hist_data, "Data/CMIP6_ensemble_air_temperature/Historical/csv files/historical_ensemble_ta.csv")



