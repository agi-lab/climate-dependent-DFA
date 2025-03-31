
################################################################################################
## Sea-surface temperature and gradients ----
################################################################################################

### Projections of SST and gradients ----

transform_nc_SEA_proj_func <- function(nc_data, lon_range = c(-Inf, Inf), lat_range = c(-Inf, Inf), Monthly = F){
    ## Convert to data frame format for further valuation:
    nc_data_df_0 <- as.data.frame(nc_data, xy = TRUE) %>% filter(x>=lon_range[1] & x<=lon_range[2]) %>% filter(y>=lat_range[1] & y<=lat_range[2])
    ## Convert to long format and remove the values that are outside the Australian boundary
    nc_data_df_1 <- as.data.frame(na.omit(pivot_longer(nc_data_df_0, cols = starts_with("X", ignore.case = FALSE), names_to = "Dates", values_to = "Value"))) %>% mutate(Year = as.numeric(substr(Dates, start = 2, stop = 5)))  %>% mutate(Month = as.numeric(substr(Dates, start = 7, stop = 8)))
    nc_data_mm <- nc_data_df_1 %>% group_by(Year, Month) %>% summarise(var_mm = mean(Value, na.rm = T))
    nc_data_avg <- nc_data_mm %>% group_by(Year) %>% summarise(var_mean = mean(var_mm),
                                                               var_max = max(var_mm),
                                                               var_thre = sum(var_mm >= 26))
    if(Monthly == T){return(nc_data_mm)} else{return(nc_data_avg)}
}


## Get the filenames of zip files:
filenames_SST_zip <- list.files("Data/CMIP6_ensemble_SST/Projections", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_SST_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_SST_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_SST_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_SST/Projections")
}
## Get the file names of all unzipped files:
filenames_SST_nc <- list.files("Data/CMIP6_ensemble_SST/Projections", pattern="*.nc", full.names=TRUE)

Scenarios_list <- c("ssp126", "ssp245", "ssp370", "ssp585")
Model_names_SST_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    filesnames_sce <- filenames_SST_nc[grep(scenario, filenames_SST_nc)]
    Models_names <- c()
    for(i in 1:length(filesnames_sce)){
        Models_names[i] <- str_extract(filesnames_sce[i], "(?<=Omon_).*?(?=_ssp)")
    }
    Model_names_SST_list[[s]] <- Models_names
}
Models_ensemble_SST <- Reduce(intersect, Model_names_SST_list)
Models_ensemble_SST <- Models_ensemble_SST[Models_ensemble_SST!="MIROC6" & Models_ensemble_SST != "CanESM5-CanOE"]

## Get the filenames of zip files:
filenames_SST_hist_zip <- list.files("Data/CMIP6_ensemble_SST/Historical", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_SST_hist_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_SST_hist_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_SST_hist_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_SST/Historical")
}
## Get the file names of all unzipped files:
filenames_SST_hist_nc <- list.files("Data/CMIP6_ensemble_SST/Historical", pattern="*.nc", full.names=TRUE)

filenames_SST_hist_nc <- filenames_SST_hist_nc[grep(paste(Models_ensemble_SST,collapse="|"), filenames_SST_hist_nc)]

Model_names_SST_hist <- c()
for(i in 1:length(filenames_SST_hist_nc)){
    Model_names_SST_hist[i] <- str_extract(filenames_SST_hist_nc[i], "(?<=Omon_).*?(?=_historical)")
}

Models_ensemble_SST <- intersect(Models_ensemble_SST, Model_names_SST_hist)
filenames_SST_nc <- filenames_SST_nc[grep(paste(Models_ensemble_SST,collapse="|"), filenames_SST_nc)]

scenarios_names <- c("ssp126", "ssp245", "ssp370", "ssp585")
filenames_SST_nc_list <- list()
for(i in 1:length(scenarios_names)){
    s <- scenarios_names[i]
    file_scenario <- filenames_SST_nc[grep(s, filenames_SST_nc)]
    mod_names <- str_extract(file_scenario, "(?<=Omon_).*?(?=_ssp)")
    # Find duplicated items
    duplicated_items <- duplicated(mod_names)
    # Get indices of non-duplicated items
    non_duplicated_indices <- which(!duplicated_items)
    filenames_SST_nc_list[[i]] <- file_scenario[non_duplicated_indices]
}

filenames_SST_nc <- unlist(filenames_SST_nc_list)

mod_names <- str_extract(filenames_SST_hist_nc, "(?<=Omon_).*?(?=_historical)")
# Find duplicated items
duplicated_items <- duplicated(mod_names)
# Get indices of non-duplicated items
non_duplicated_indices <- which(!duplicated_items)
filenames_SST_hist_nc <- filenames_SST_hist_nc[non_duplicated_indices]

#### Write a function to convert the latitude and longitude of ensemble members
convert_lon_ens_func <- function(lon, model){
    if(model %in% c("INM-CM4-8","INM-CM4-8", "MCM-UA-1-0", "MIROC-ES2L", "INM-CM5-0")){return(lon)} else if(model == "UKESM1-0-LL"){return(lon-73.5)} else if(model %in% c("FGOALS-f3-L", "FGOALS-g3")){return(lon+113.5)} else if(model == "ACCESS-CM2"){return(lon-80.5)} else if(model == "CNRM-CM6-1"){return(lon-90)}}


convert_lat_ens_func <- function(lat, model){
    if(model %in% c("INM-CM4-8","INM-CM4-8", "MCM-UA-1-0", "MIROC-ES2L", "INM-CM5-0")){return(lat)} else if(model == "UKESM1-0-LL"){return(((lat + 41) / 41) * (185.5 - 124.5) + 124.5)} else if(model %in% c("FGOALS-f3-L", "FGOALS-g3")){return(((lat + 41) / 41) * (142.5 - 86.5) + 86.5)} else if(model == "ACCESS-CM2"){return(((lat + 41) / 41)*(136.5-65.5) + 65.5)} else if(model == "CNRM-CM6-1"){return(((lat + 41) / 41) * (60.5 - 0.5) + 0.5)}}


#### Convert all the ensemble models projections of SST to data frame format
SST_ensemble_all_scenarios_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    files_list <- filenames_SST_nc[grep(scenario, filenames_SST_nc)]
    SST_ensemble_list <- c()
    print(scenario)
    for(i in 1:length(files_list)){
        #print(files_list[i])
        SST_nc <- brick(files_list[i], varname = "tos")
        lon_range <- convert_lon_ens_func(Lon_cyc_range, Models_ensemble_SST[i])
        lat_range <- convert_lat_ens_func(Lat_cyc_range, Models_ensemble_SST[i])
        SST_mm <- transform_nc_SEA_proj_func(SST_nc, lon_range = lon_range, lat_range = lat_range, Monthly = T) %>% rename(SST_mean_mm = var_mm)
        colnames(SST_mm)[3] <- str_extract(files_list[i], "(?<=Omon_).*?(?=_ssp)") ## Rename the column with model name
        SST_ensemble_list[[i]] <- SST_mm
    }
    SST_ensemble_data_0 <- do.call(cbind, SST_ensemble_list)
    cols_to_keep <- names(SST_ensemble_data_0)[!grepl("Year|Month", names(SST_ensemble_data_0))]
    SST_ensemble_data_0 <- SST_ensemble_data_0 %>% dplyr::select(all_of(cols_to_keep))
    SST_ensemble_data_1 <- cbind(Year = SST_mm$Year, Month = SST_mm$Month, SST_ensemble_data_0)
    ## Combine all the ensemble model outputs into a data.frame for each scenario
    SST_ensemble_all_scenarios_list[[s]] <- SST_ensemble_data_1
}

#### Convert all the ensemble models projections of SST gradients to data frame format

SST_grad_ensemble_all_scenarios_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    files_list <- filenames_SST_nc[grep(scenario, filenames_SST_nc)]
    SST_grad_ensemble_list <- c()
    for(i in 1:length(files_list)){
        SST_grad_nc <- brick(files_list[i], varname = "tos", stopIfNotEqualSpaced = F)
        lon_range_R1 <- convert_lon_ens_func(Lon_ECL_range_R1, Models_ensemble_SST[i])
        lon_range_R2 <- convert_lon_ens_func(Lon_ECL_range_R2, Models_ensemble_SST[i])
        lat_range <- convert_lat_ens_func(Lat_ECL_range, Models_ensemble_SST[i])
        SST_grad_mm <- transform_nc_SST_grad_proj_func(SST_grad_nc, lon_range_R1 = lon_range_R1, lat_range = lat_range, lon_range_R2 = lon_range_R2)
        colnames(SST_grad_mm)[3] <- str_extract(files_list[i], "(?<=Omon_).*?(?=_ssp)") ## Rename the column with model name
        SST_grad_ensemble_list[[i]] <- SST_grad_mm
    }

    SST_grad_ensemble_data_0 <- do.call(cbind, SST_grad_ensemble_list)
    cols_to_keep <- names(SST_grad_ensemble_data_0)[!grepl("Year|Month", names(SST_grad_ensemble_data_0 ))]
    SST_grad_ensemble_data_0 <- SST_grad_ensemble_data_0 %>% dplyr::select(all_of(cols_to_keep))

    SST_grad_ensemble_data_1 <- cbind(Year = SST_grad_mm$Year, Month = SST_grad_mm$Month, SST_grad_ensemble_data_0)
    ## Combine all the ensemble model outputs into a data.frame for each scenario
    SST_grad_ensemble_all_scenarios_list[[s]] <- SST_grad_ensemble_data_1
}



#### Write the SST results to csv files

dirc <- "Data/CMIP6_ensemble_SST/Projections/csv files"
for(s in 1:length(SST_ensemble_all_scenarios_list)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_SST_proj", ".csv")
    write.csv(SST_ensemble_all_scenarios_list[[s]], paste0(dirc, "/", file_name))
}

#### Write the SST gradients results to csv files

dirc <- "Data/CMIP6_ensemble_SST/Projections/csv files"
for(s in 1:length(SST_grad_ensemble_all_scenarios_list)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_SST_grad_proj", ".csv")
    write.csv(SST_grad_ensemble_all_scenarios_list[[s]], paste0(dirc, "/", file_name))
}


### Historical backcasts of SST and SST gradients ----

#### Convert all the ensemble models historical backacts of SST to dataframe format

SST_ensemble_hist_list <- list()
for(i in 1:length(filenames_SST_hist_nc)){
    SST_nc <- brick(filenames_SST_hist_nc[i], varname = "tos")
    mod_name_SST <- str_extract(filenames_SST_hist_nc[i], "(?<=Omon_).*?(?=_historical)") ## Rename the column with model name
    lon_range <- convert_lon_ens_func(Lon_cyc_range, mod_name_SST)
    lat_range <- convert_lat_ens_func(Lat_cyc_range, mod_name_SST)
    SST_mm <- transform_nc_SEA_proj_func(SST_nc, lon_range = lon_range, lat_range = lat_range, Monthly = T) %>% rename(SST_mean_mm = var_mm)
    colnames(SST_mm)[3] <-  mod_name_SST
    SST_ensemble_hist_list[[i]] <- SST_mm
}

SST_ensemble_hist_data_0 <- do.call(cbind, SST_ensemble_hist_list)
cols_to_keep <- names(SST_ensemble_hist_data_0)[!grepl("Year|Month", names(SST_ensemble_hist_data_0))]
SST_ensemble_hist_data_0 <- SST_ensemble_hist_data_0 %>% dplyr::select(all_of(cols_to_keep))
SST_ensemble_hist_data <- cbind(Year = SST_mm$Year, Month = SST_mm$Month, SST_ensemble_hist_data_0)
#Write the results to csv files:
write.csv(SST_ensemble_hist_data, "Data/CMIP6_ensemble_SST/Historical/csv files/SST_ensemble_hist_data.csv")

#### Convert all the ensemble models historical backacts of SST gradients to data frame format

SST_grad_ensemble_hist_list <- list()
for(i in 1:length(filenames_SST_hist_nc)){
    SST_grad_nc <- brick(filenames_SST_hist_nc[i], varname = "tos")
    mod_name_SST <- str_extract(filenames_SST_hist_nc[i], "(?<=Omon_).*?(?=_historical)")

    lon_range_R1 <- convert_lon_ens_func(Lon_ECL_range_R1, mod_name_SST)
    lon_range_R2 <- convert_lon_ens_func(Lon_ECL_range_R2, mod_name_SST)
    lat_range <- convert_lat_ens_func(Lat_ECL_range, mod_name_SST)

    SST_grad_mm <- transform_nc_SST_grad_proj_func(SST_grad_nc, lon_range_R1 = lon_range_R1, lat_range = lat_range, lon_range_R2 = lon_range_R2)
    colnames(SST_grad_mm)[3] <-  mod_name_SST
    SST_grad_ensemble_hist_list[[i]] <- SST_grad_mm
}
SST_grad_ensemble_hist_data_0 <- do.call(cbind, SST_grad_ensemble_hist_list)
cols_to_keep <- names(SST_grad_ensemble_hist_data_0)[!grepl("Year|Month", names(SST_grad_ensemble_hist_data_0))]
SST_grad_ensemble_hist_data_0 <- SST_grad_ensemble_hist_data_0 %>% dplyr::select(all_of(cols_to_keep))

SST_grad_ensemble_hist_data <- cbind(Year = SST_grad_mm$Year, Month = SST_grad_mm$Month, SST_grad_ensemble_hist_data_0)
#Write the results to csv files:
write.csv(SST_grad_ensemble_hist_data, "Data/CMIP6_ensemble_SST/Historical/csv files/SST_grad_ensemble_hist_data.csv")




