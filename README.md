# climate-dependent-DFA

## Table of Contents

- [Overview](#Overview)
- [Code overview](#Code-overview)
- [Data overview](#Data-overview)
- [Authors](#Authors)
- [Contact](#Contact)

## Overview

Climate change is expected to have significant long-term effects on the physical, financial, and economic environments, posing substantial risks to the financial stability of general insurers. While Dynamic Financial Analysis (DFA) is widely used to assess financial impacts, traditional DFA models often overlook climate risks. To address this gap, this study introduces a climate-dependent DFA framework that integrates climate risk into DFA, providing a comprehensive assessment of its long-term impact on the general insurance industry.

The proposed framework has three key features: (1) it captures the long-term impact of climate change on both assets and liabilities by considering physical and economic dimensions within an interconnected structure; (2) it addresses the uncertainty of climate impacts using stochastic simulations within climate scenario analysis, supporting actuarial applications; and (3) it is tailored to the unique characteristics of the general insurance sector.

This repository contains the results presented in our paper, "Dynamic Financial Analysis (DFA) of General Insurers under Climate Change." 

## Code overview

All code used to generate the results can be found in the Rmarkdown file: `DFA_model_final.Rmd`,  which contains the following sections that need to be run in the order specified: 

- **Loading required packages**: Load the required packages used in the paper.
- **Files and data path**: Define the file paths of all the data sources used in the paper. Those data sources are all stored in the `Data` folder. Unless a new data source is used, users do not need to change anything here. 
- **Define functions to be used**: This section defines all the functions used in the paper. 
- **Section 3.1 Data and calibration**: This section calibrates the model parameters based on historical data as per Section 3.1 in the paper. 
- **Section 3.2 Key simulation results from individual modules**: This section generates the results shown in Section 3.2 in the paper. 

    - The simulation control parameters are defined in **Define the control variables**. These include the number of simulations, random seed, maximum forecasting horizon, and asset allocations, etc. Users can modify these parameters to suit specific needs. After changing these parameters, only Sections **3.2** and **3.3** need to be rerun, and previous sections do not require rerunning.  
    - All graphs shown in Section 3.2 in the paper are plotted in **Presentations of simulation results**. 
    
- **Section 3.3 Risk and return measures**: This section presents the results shown in Section 3.3 in the paper.

## Data overview

Due to the large file size (around 36.6GB), the data used in this paper cannot be uploaded to GitHub. However, users can download all the data from the Dropbox link below:  

[**Download Data**](https://www.dropbox.com/scl/fo/7zva73raqce08phx2iorw/AB8hZsBbdVbEGrIf9i5jigw?rlkey=4x670mfk5j97gplde6vfslp34&st=60b8xd79&dl=0)  

Once the `Data` folder is downloaded, place it in the same directory as `DFA codes.Rproj` and `DFA_model_final.Rmd`. After this setup, users can run the RMarkdown file `DFA_model_final.Rmd` without further configuration.  

The main data folders used are outlined below:

- `Economic`: Contains historical data on macroeconomic variables (e.g., GDP, interest rates, and inflation rates) and projections of GDP, population, and oil and gas production under each SSP scenario.  
- `Equity return`: Contains the pseudo All-Ordinaries Shares total returns series and the financial statements of a representative oil and gas producer. Due to licensing restrictions, we are unable to provide the actual Total Returns series of the All-Ordinaries Shares Index and the financial statements of Woodside Energy Limited from FactSet. Users are encouraged to obtain this data directly from FactSet.  
- `Hazards loss`: Includes the ICA and EM-DAT datasets on catastrophe insurance losses in Australia.  
- `Precipitations`, `FWI`, `SST and MSLP`, `Near-surface temperature`, and `Air temperature`: Contain historical observations of precipitation, fire weather index, sea-surface temperature, mean sea-level pressure, near-surface temperature, and air temperature at the grid cell level across Australia (or nearby ocean areas).  
- `CMIP6_ensemble_precipitation`, `CMIP6_ensemble_SST`, `CMIP6_ensemble_MSLP`, `CMIP6_ensemble_near_surface_temperature`, and `CMIP6_ensemble_air_temperature`: Contain CMIP6 ensemble projections of the corresponding climate variables.

  ## Authors

  - Benjamin Avanzi
  - Yanfeng (Jim) Li
  - Greg Taylor
  - Bernard Wong

  ## Contact

  For any questions or further information, please contact lyf1998130@126.com.
