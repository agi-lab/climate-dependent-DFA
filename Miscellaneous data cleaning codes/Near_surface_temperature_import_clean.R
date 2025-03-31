
################################################################################################
## Near surface temperature ----
################################################################################################

### Projections of near-surface temperature ----

#### Function to transform the NS data:

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

### Get the filenames of zip files:
filenames_NS_zip <- list.files("Data/CMIP6_ensemble_near_surface_temperature/Projections_mod", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_NS_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_NS_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_NS_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_near_surface_temperature/Projections_mod")
}
## Get the file names of all unzipped files:
filenames_NS_nc <- list.files("Data/CMIP6_ensemble_near_surface_temperature/Projections_mod", pattern="*.nc", full.names=TRUE)

Scenarios_list <- c("ssp126", "ssp245", "ssp370", "ssp585")
Model_names_tas_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    filesnames_sce <- filenames_NS_nc[grep(scenario, filenames_NS_nc)]
    Models_names <- c()
    for(i in 1:length(filesnames_sce)){
        Models_names[i] <- str_extract(filesnames_sce[i], "(?<=Amon_).*?(?=_ssp)")
    }
    Model_names_tas_list[[s]] <- Models_names
}
Models_ensemble_tas <- Reduce(intersect, Model_names_tas_list)

filenames_NS_nc <- filenames_NS_nc[grep(paste(Models_ensemble_tas,collapse="|"), filenames_NS_nc)]

scenarios_names <- c("ssp126", "ssp245", "ssp370", "ssp585")
filenames_NS_nc_list <- list()
for(i in 1:length(scenarios_names)){
    s <- scenarios_names[i]
    file_scenario <- filenames_NS_nc[grep(s, filenames_NS_nc)]
    mod_names <- str_extract(file_scenario, "(?<=Amon_).*?(?=_ssp)")
    # Find duplicated items
    duplicated_items <- duplicated(mod_names)
    # Get indices of non-duplicated items
    non_duplicated_indices <- which(!duplicated_items)
    filenames_NS_nc_list[[i]] <- file_scenario[non_duplicated_indices]
}

filenames_NS_nc <- unlist(filenames_NS_nc_list)

tas_ensemble_all_scenarios_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    files_list <- filenames_NS_nc[grep(scenario, filenames_NS_nc)]
    tas_ensemble_list <- c()
    for(i in 1:length(files_list)){
        tas_nc <- brick(files_list[i], varname = "tas")
        tas_mm <- transform_nc_tas_mm_func(australia_shape, tas_nc)
        colnames(tas_mm)[3] <- str_extract(files_list[i], "(?<=Amon_).*?(?=_ssp)") ## Rename the column with model name
        tas_ensemble_list[[i]] <- tas_mm
    }
    tas_ensemble_data_0 <- do.call(cbind, tas_ensemble_list) %>% dplyr::select(-c(Year, Month))
    tas_ensemble_data_1 <- cbind(Year = tas_mm$Year, Month = tas_mm$Month, tas_ensemble_data_0)
    ## Combine all the ensemble model outputs into a data.frame for each scenario
    tas_ensemble_all_scenarios_list[[s]] <- tas_ensemble_data_1
}

dirc <- "Data/CMIP6_ensemble_near_surface_temperature/Projections_mod/csv files"
for(s in 1:length(tas_ensemble_all_scenarios_list)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_tas_proj", ".csv")
    write.csv(tas_ensemble_all_scenarios_list[[s]], paste0(dirc, "/", file_name))
}


### Historical backcasts of near-surface temperature ----

## Get the filenames of zip files:
filenames_NS_hist_zip <- list.files("Data/CMIP6_ensemble_near_surface_temperature/Historical", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_NS_hist_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_NS_hist_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_NS_hist_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_near_surface_temperature/Historical")
}
## Get the file names of all unzipped files:
filenames_NS_hist_nc <- list.files("Data/CMIP6_ensemble_near_surface_temperature/Historical", pattern="*.nc", full.names=TRUE)


filenames_NS_hist_nc <- filenames_NS_hist_nc[grep(paste(Models_ensemble_tas,collapse="|"), filenames_NS_hist_nc)]

Model_names_tas_hist <- c()
for(i in 1:length(filenames_NS_hist_nc)){
    Model_names_tas_hist[i] <- str_extract(filenames_NS_hist_nc[i], "(?<=Amon_).*?(?=_historical)")
}

Models_ensemble_tas <- intersect(Models_ensemble_tas, Model_names_tas_hist)


tas_ensemble_hist_list <- list()
for(i in 1:length(filenames_NS_hist_nc)){
    tas_nc <- brick(filenames_NS_hist_nc[i], varname = "tas")
    tas_mm <- transform_nc_tas_mm_func(australia_shape, tas_nc)
    colnames(tas_mm)[3] <-  str_extract(filenames_NS_hist_nc[i], "(?<=Amon_).*?(?=_historical)") ## Rename the column with model name
    tas_ensemble_hist_list[[i]] <- tas_mm
}
tas_ensemble_hist_data_0 <- do.call(cbind, tas_ensemble_hist_list) %>% dplyr::select(-c(Year, Month))
tas_ensemble_hist_data <- cbind(Year = tas_mm$Year, Month = tas_mm$Month, tas_ensemble_hist_data_0)
