################################################################################################
## MSLP ----
################################################################################################

### Projections of MSLP ----

transform_nc_SEA_proj_func <- function(nc_data, lon_range = c(-Inf, Inf), lat_range = c(-Inf, Inf), Monthly = F){
    ## Convert to data frame format for further valuation:
    nc_data_df_0 <- as.data.frame(nc_data, xy = TRUE) %>% filter(x>=lon_range[1] & x<=lon_range[2]) %>% filter(y>=lat_range[1] & y<=lat_range[2])
    ## Convert to long format and remove the values that are outside the Australian boundary
    nc_data_df_1 <- as.data.frame(na.omit(pivot_longer(nc_data_df_0, cols = starts_with("X", ignore.case = FALSE), names_to = "Dates", values_to = "Value"))) %>% mutate(Year = as.numeric(substr(Dates, start = 2, stop = 5)))  %>% mutate(Month = as.numeric(substr(Dates, start = 7, stop = 8)))
    nc_data_mm <- nc_data_df_1 %>% group_by(Year, Month) %>% summarise(var_mm = mean(Value, na.rm = T))
    nc_data_avg <- nc_data_mm %>% group_by(Year) %>% summarise(var_mean = mean(var_mm))
    if(Monthly == T){return(nc_data_mm)} else{return(nc_data_avg)}
}


## Get the filenames of zip files:
filenames_MSLP_zip <- list.files("Data/CMIP6_ensemble_MSLP/Projections", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_MSLP_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_MSLP_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_MSLP_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_MSLP/Projections")
}
## Get the file names of all unzipped files:
filenames_MSLP_nc <- list.files("Data/CMIP6_ensemble_MSLP/Projections", pattern="*.nc", full.names=TRUE)

Scenarios_list <- c("ssp126", "ssp245", "ssp370", "ssp585")
Model_names_MSLP_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    filesnames_sce <- filenames_MSLP_nc[grep(scenario, filenames_MSLP_nc)]
    Models_names <- c()
    for(i in 1:length(filesnames_sce)){
        Models_names[i] <- str_extract(filesnames_sce[i], "(?<=Amon_).*?(?=_ssp)")
    }
    Model_names_MSLP_list[[s]] <- Models_names
}
Models_ensemble_MSLP <- Reduce(intersect, Model_names_MSLP_list)
#Models_ensemble_MSLP <- Models_ensemble_MSLP[Models_ensemble_MSLP!="MIROC6" & Models_ensemble_MSLP != "CanESM5-CanOE"]

## Get the filenames of zip files:
filenames_MSLP_hist_zip <- list.files("Data/CMIP6_ensemble_MSLP/Historical", pattern="*.zip", full.names=TRUE)
## Unzip all the files:
for (i in 1:length(filenames_MSLP_hist_zip)){
    zipped_nc_names <- grep('\\.nc$', unzip(filenames_MSLP_hist_zip[i], list=TRUE)$Name, ignore.case=TRUE, value=TRUE)
    unzip(filenames_MSLP_hist_zip[i], files = zipped_nc_names, exdir = "Data/CMIP6_ensemble_MSLP/Historical")
}
## Get the file names of all unzipped files:
filenames_MSLP_hist_nc <- list.files("Data/CMIP6_ensemble_MSLP/Historical", pattern="*.nc", full.names=TRUE)

filenames_MSLP_hist_nc <- filenames_MSLP_hist_nc[grep(paste(Models_ensemble_MSLP,collapse="|"), filenames_MSLP_hist_nc)]

Model_names_MSLP_hist <- c()
for(i in 1:length(filenames_MSLP_hist_nc)){
    Model_names_MSLP_hist[i] <- str_extract(filenames_MSLP_hist_nc[i], "(?<=Amon_).*?(?=_historical)")
}

Models_ensemble_MSLP <- intersect(Models_ensemble_MSLP, Model_names_MSLP_hist)
filenames_MSLP_nc <- filenames_MSLP_nc[grep(paste(Models_ensemble_MSLP,collapse="|"), filenames_MSLP_nc)]

scenarios_names <- c("ssp126", "ssp245", "ssp370", "ssp585")
filenames_MSLP_nc_list <- list()
for(i in 1:length(scenarios_names)){
    s <- scenarios_names[i]
    file_scenario <- filenames_MSLP_nc[grep(s, filenames_MSLP_nc)]
    mod_names <- str_extract(file_scenario, "(?<=Amon_).*?(?=_ssp)")
    # Find duplicated items
    duplicated_items <- duplicated(mod_names)
    # Get indices of non-duplicated items
    non_duplicated_indices <- which(!duplicated_items)
    filenames_MSLP_nc_list[[i]] <- file_scenario[non_duplicated_indices]
}

filenames_MSLP_nc <- unlist(filenames_MSLP_nc_list)

mod_names <- str_extract(filenames_MSLP_hist_nc, "(?<=Amon_).*?(?=_historical)")
# Find duplicated items
duplicated_items <- duplicated(mod_names)
# Get indices of non-duplicated items
non_duplicated_indices <- which(!duplicated_items)
filenames_MSLP_hist_nc <- filenames_MSLP_hist_nc[non_duplicated_indices]


#### Convert all the ensemble models projections of MSLP to data frame format
MSLP_ensemble_all_scenarios_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    files_list <- filenames_MSLP_nc[grep(scenario, filenames_MSLP_nc)]
    MSLP_ensemble_list <- c()
    print(scenario)
    for(i in 1:length(files_list)){
        #print(files_list[i])
        MSLP_nc <- brick(files_list[i], varname = "psl")
        MSLP_mm <- transform_nc_SEA_proj_func(MSLP_nc, lon_range = Lon_cyc_range, lat_range = Lat_cyc_range, Monthly = T) %>% rename(MSLP_mean_mm = var_mm)
        colnames(MSLP_mm)[3] <- str_extract(files_list[i], "(?<=Amon_).*?(?=_ssp)") ## Rename the column with model name
        MSLP_ensemble_list[[i]] <- MSLP_mm
    }
    MSLP_ensemble_data_0 <- do.call(cbind, MSLP_ensemble_list)
    cols_to_keep <- names(MSLP_ensemble_data_0)[!grepl("Year|Month", names(MSLP_ensemble_data_0))]
    MSLP_ensemble_data_0 <- MSLP_ensemble_data_0 %>% dplyr::select(all_of(cols_to_keep))
    MSLP_ensemble_data_1 <- cbind(Year = MSLP_mm$Year, Month = MSLP_mm$Month, MSLP_ensemble_data_0)
    ## Combine all the ensemble model outputs into a data.frame for each scenario
    MSLP_ensemble_all_scenarios_list[[s]] <- MSLP_ensemble_data_1
}



#### Write the MSLP results to csv files

dirc <- "Data/CMIP6_ensemble_MSLP/Projections/csv files"
for(s in 1:length(MSLP_ensemble_all_scenarios_list)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_MSLP_proj", ".csv")
    write.csv(MSLP_ensemble_all_scenarios_list[[s]], paste0(dirc, "/", file_name))
}


### Historical backcasts of MSLP ----

#### Convert all the ensemble models historical backcasts of MSLP to dataframe format

MSLP_ensemble_hist_list <- list()
for(i in 1:length(filenames_MSLP_hist_nc)){
    MSLP_nc <- brick(filenames_MSLP_hist_nc[i], varname = "psl")
    mod_name_MSLP <- str_extract(filenames_MSLP_hist_nc[i], "(?<=Amon_).*?(?=_historical)") ## Rename the column with model name
    MSLP_mm <- transform_nc_SEA_proj_func(MSLP_nc, lon_range = Lon_cyc_range, lat_range = Lat_cyc_range, Monthly = T) %>% rename(MSLP_mean_mm = var_mm)
    colnames(MSLP_mm)[3] <-  mod_name_MSLP
    MSLP_ensemble_hist_list[[i]] <- MSLP_mm
}

MSLP_ensemble_hist_data_0 <- do.call(cbind, MSLP_ensemble_hist_list)
cols_to_keep <- names(MSLP_ensemble_hist_data_0)[!grepl("Year|Month", names(MSLP_ensemble_hist_data_0))]
MSLP_ensemble_hist_data_0 <- MSLP_ensemble_hist_data_0 %>% dplyr::select(all_of(cols_to_keep))
MSLP_ensemble_hist_data <- cbind(Year = MSLP_mm$Year, Month = MSLP_mm$Month, MSLP_ensemble_hist_data_0)
#Write the results to csv files:
write.csv(MSLP_ensemble_hist_data, "Data/CMIP6_ensemble_MSLP/Historical/csv files/MSLP_ensemble_hist_data.csv")



