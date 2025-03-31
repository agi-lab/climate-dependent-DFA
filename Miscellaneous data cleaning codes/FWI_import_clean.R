

################################################################################################
## FWI ----
################################################################################################

### Projections of extreme FWI  ----


#### Import the future projections of FWI

filenames_FWI_1 <- list.files("Data/FWI/fwixx_hurs_part1", pattern="*.nc", full.names=TRUE)
filenames_FWI_2 <- list.files("Data/FWI/fwixx_hurs_part2", pattern="*.nc", full.names=TRUE)
filenames_FWI_3 <- list.files("Data/FWI/fwixx_hurs_part3", pattern="*.nc", full.names=TRUE)
filenames_FWI_4 <- list.files("Data/FWI/fwixx_hurs_part4", pattern="*.nc", full.names=TRUE)
filenames_FWI_5 <- list.files("Data/FWI/fwixx_hurs_part5", pattern="*.nc", full.names=TRUE)
filenames_FWI_6 <- list.files("Data/FWI/fwixx_hurs_part6", pattern="*.nc", full.names=TRUE)
filenames_FWI_7 <- list.files("Data/FWI/fwixx_hurs_part7", pattern="*.nc", full.names=TRUE)

filenames_FWI <- c(filenames_FWI_1, filenames_FWI_2,
                   filenames_FWI_3, filenames_FWI_4,
                   filenames_FWI_5, filenames_FWI_6, filenames_FWI_7)

filenames_FWI_proj <- filenames_FWI[grep('r1i1p1f1', filenames_FWI)]


## Write a function to import and cleanse the `nc` data file:

#### Function to transform the projected FWI nc data files

transform_nc_FWI_proj_func_1 <- function(australia_shape, nc_data){
    # Transform the Australian shape file to the same coordinate system as the FWI data:
    australia_shape_1 <- spTransform(australia_shape, crs(nc_data))
    # Crop the temperature data such that only the Australian region is covered:
    nc_data_masked = mask(nc_data, australia_shape_1)
    ## Convert to data frame format for further valuation:
    nc_data_df_0 <- as.data.frame(nc_data_masked, xy = TRUE)
    ## Convert to long format and remove the values that are outside the Australian boundary
    nc_data_df_1 <- as.data.frame(na.omit(pivot_longer(nc_data_df_0, cols = starts_with("X", ignore.case = FALSE), names_to = "Dates", values_to = "fwixx"))) %>% mutate(Year = as.numeric(substr(Dates, start = 2, stop = 5))) %>%
        group_by(Year) %>% summarise(mfwixx = mean(fwixx), xfwixx = max(fwixx))
    return(nc_data_df_1)
}


#### Find the common FWI models accross all scenarios

Scenarios_list <- c("ssp126", "ssp245", "ssp370", "ssp585")
Model_names_FWI_list <- list()
for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    filesnames_sce <- filenames_FWI_proj[grep(scenario, filenames_FWI_proj)]
    Models_names <- c()
    for(i in 1:length(filesnames_sce)){
        Models_names[i] <- str_extract(filesnames_sce[i], "(?<=ann_).*?(?=_ssp)")
    }
    Model_names_FWI_list[[s]] <- Models_names
}
Models_ensemble_FWI_proj <- Reduce(intersect, Model_names_FWI_list)

#### Convert all the ensemble models projections of FWI to data frame format

FWI_ensemble_all_scenarios_list_mfwixx <- list()
FWI_ensemble_all_scenarios_list_xfwixx <- list()

for(s in 1:length(Scenarios_list)){
    scenario <- Scenarios_list[s]
    files_list <- filenames_FWI_proj[grep(scenario, filenames_FWI_proj)]
    FWI_ensemble_list_m <- list()
    FWI_ensemble_list_x <- list()
    for(i in 1:length(files_list)){
        FWI_nc <- brick(files_list[i])
        FWI_mm <- transform_nc_FWI_proj_func_1(australia_shape, FWI_nc)
        FWI_mfwixx <- FWI_mm %>% dplyr::select(Year, mfwixx)
        FWI_xfwixx <- FWI_mm %>% dplyr::select(Year, xfwixx)

        colnames(FWI_mfwixx)[2] <- str_extract(files_list[i], "(?<=ann_).*?(?=_ssp)") ## Rename the column with model name
        colnames(FWI_xfwixx)[2] <- str_extract(files_list[i], "(?<=ann_).*?(?=_ssp)") ## Rename the column with model name

        FWI_ensemble_list_m[[i]] <- FWI_mfwixx
        FWI_ensemble_list_x[[i]] <- FWI_xfwixx
    }
    FWI_ensemble_data_0_m <- do.call(cbind, FWI_ensemble_list_m) %>% dplyr::select(-c(Year))
    FWI_ensemble_data_0_x <- do.call(cbind, FWI_ensemble_list_x) %>% dplyr::select(-c(Year))

    FWI_ensemble_data_1_m <- cbind(Year = FWI_mm$Year, FWI_ensemble_data_0_m)
    FWI_ensemble_data_1_x <- cbind(Year = FWI_mm$Year, FWI_ensemble_data_0_x)
    ## Combine all the ensemble model outputs into a data.frame for each scenario
    FWI_ensemble_all_scenarios_list_mfwixx[[s]] <- FWI_ensemble_data_1_m
    FWI_ensemble_all_scenarios_list_xfwixx[[s]] <- FWI_ensemble_data_1_x

}

#### Write the FWI projection results to csv files

dirc <- "Data/FWI/Projections"
for(s in 1:length(FWI_ensemble_all_scenarios_list_mfwixx)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_mfwixx_proj", ".csv")
    write.csv(FWI_ensemble_all_scenarios_list_mfwixx[[s]], paste0(dirc, "/", file_name))
}
for(s in 1:length(FWI_ensemble_all_scenarios_list_xfwixx)){
    file_name <- paste0(Scenarios_list[s], "_ensemble_xfwixx_proj", ".csv")
    write.csv(FWI_ensemble_all_scenarios_list_xfwixx[[s]], paste0(dirc, "/", file_name))
}

### Historical backcasts of extreme FWI  ----

filenames_FWI_CMIP_hist <- filenames_FWI_proj[grep('historical', filenames_FWI_proj)]

Model_names_FWI_hist <- c()
for(i in 1:length(filenames_FWI_CMIP_hist)){
    Model_names_FWI_hist[i] <- str_extract(filenames_FWI_CMIP_hist[i], "(?<=ann_).*?(?=_historical)")
}

Models_ensemble_FWI <- intersect(Models_ensemble_FWI_proj, Model_names_FWI_hist)


#### Convert all the ensemble models historical backcasts of FWI to data frame format
FWI_ensemble_hist_list_m <- list()
FWI_ensemble_hist_list_x <- list()

for(i in 1:length(filenames_FWI_CMIP_hist)){
    FWI_nc <- brick(filenames_FWI_CMIP_hist[i])
    FWI_mm <- transform_nc_FWI_proj_func_1(australia_shape, FWI_nc)

    FWI_mfwixx <- FWI_mm %>% dplyr::select(Year, mfwixx)
    FWI_xfwixx <- FWI_mm %>% dplyr::select(Year, xfwixx)

    colnames(FWI_mfwixx)[2] <- str_extract(filenames_FWI_CMIP_hist[i], "(?<=ann_).*?(?=_historical)") ## Rename the column with model name
    colnames(FWI_xfwixx)[2] <- str_extract(filenames_FWI_CMIP_hist[i], "(?<=ann_).*?(?=_historical)") ## Rename the column with model name
    FWI_ensemble_hist_list_m[[i]] <- FWI_mfwixx
    FWI_ensemble_hist_list_x[[i]] <- FWI_xfwixx
}
FWI_ensemble_hist_data_0_m <- do.call(cbind, FWI_ensemble_hist_list_m) %>% dplyr::select(-c(Year))
FWI_ensemble_hist_data_0_x <- do.call(cbind, FWI_ensemble_hist_list_x) %>% dplyr::select(-c(Year))

FWI_ensemble_hist_data_mfwixx <- cbind(Year = FWI_mm$Year, FWI_ensemble_hist_data_0_m)
FWI_ensemble_hist_data_xfwixx <- cbind(Year = FWI_mm$Year, FWI_ensemble_hist_data_0_x)

## Write the data to csv:

write.csv(FWI_ensemble_hist_data_mfwixx, "Data/FWI/Historical/mfwixx_ensemble_hist_data.csv")
write.csv(FWI_ensemble_hist_data_mfwixx, "Data/FWI/Historical/xfwixx_ensemble_hist_data.csv")
