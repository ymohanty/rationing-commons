# Rationing the Commons

## Software dependencies and data

### Resolving dependencies   
This is the project level master file for replicating the exhibits that appear in the manuscript. Before executing this script you need to ensure that all software dependencies are resolved. We make this a little bit easier by setting up auto-installers or virtual environments wherever possible. However, five broadly defined environments need to be manually set up:
       
       * Stata 15 with terminal utility [ "stata" should be on PATH ]
       * R and RStudio [ "Rscript" should be on PATH]
       * Anaconda [ "conda" and "conda-env" should be on PATH ]
       * MATLAB 2019a or higher [ "matlab" should be on PATH ] 
       * Bash or another POSIX compliant Unix shell [ Mac/Linux users can use the default shell;
                                                       Windows users can use the Linux subsystem ]
                                                       
### Getting data


### Executing the project

To execute the project you need the main shell script using

```
cd code/
./main.sh
```

The main script can take a number of arguments

```   
usage: ./main.sh [-h] [-v] [-r <step>] 
        Option                  Meaning
        -h                      Short help.
        -H                      Long help.
        -r <step>               Run analysis step number <step> and greater. Default = 1.
        -c                      Run a clean build.
```
                                                       
## Project overview
This code for this project can be broadly divided into three sections: cleaning, marginal analysis, and structural analysis. The cleaning section involves creating usable data from the raw files, along with generating the variables that will be used later in the analysis. The final steps of the cleaning involve creating the working data for analysis, which combines the farmer survey, geological data, soil data, and weather data in one date file.Some of the descriptive exhibits from the manuscript are generated in this section. Note that some cleaning steps require access to farmers' personally identifiable information (PII);  as such, you must be explicitly authorized to access this data in order to replicate these steps.

```
├── code
│   ├── ado [Stata-ADO files]
│   ├── cleaning
│   │   ├── farmer_survey 
│   │   ├── geology 
│   │   ├── merge
│   │   ├── pending_consumers 
│   │   ├── soil
│   │   └── weather
│   ├── maps
│   ├── marginal_analysis
│   │   └── logs
│   ├── rationing_commons_venv [Python virtual environment]
│   │   ├── bin
│   │   ├── conda-meta
│   │   ├── include
│   │   ├── lib
│   │   ├── share
│   │   └── ssl
│   └── structural_analysis
│       ├── @gmm
│       ├── @waterCounter
│       ├── @waterData
│       ├── @waterDynamics
│       ├── @waterModel
│       ├── @waterPlanner
│       ├── @waterPolicy
│       ├── archive
│       ├── logs
│       ├── panel_data_toolbox
│       ├── utility
│       └── utility_exhibits
├── data
│   ├── farmer_survey
│   │   ├── clean
│   │   └── intermediate [PII]
│   ├── geology
│   │   ├── clean
│   │   └── raw
│   ├── pending_consumers [PII]
│   │   └── clean
│   ├── soil
│   │   ├── clean
│   │   └── raw
│   ├── weather
│   │   ├── clean
│   │   └── raw
│   └── work
└── exhibits
    ├── figures
    │   └── static
    └── tables
        └── static
 ```
 
## Exhibits

All tables and figures are contained in ~/exhibits/tables and ~/exhibits/figures respectively.The exhibits found in the manuscript are wrapped in ~/exhibits/exhibits.tex which can be compiled with pdflatex to a viewable pdf document that acts as a container for these exhibits. In order to replicate specific exhibits, you can specify the corresponding steps (described below) as an option to this main script. The exhibit numbers referred to below are references to the original manuscript
               
                PROGRAM-STEP            COMMAND             EXHIBITS
                    6                   ./main.sh -r 6      Figure 2: Power supply in Rajasthan 
                                                            Figure D5: Extensive margin

                    10                  ./main.sh -r 10     Table 1: Summary statistics on farmer survey sample
                                                            Table 2: Hedonic regressions of profit on well depth
                                                            Table C4: First Stage
                                                            Table C5: Robustness to instruments
                                                            Table C6: Robustness to controls
                                                            Table D8: Hedonic regressions of yield on depth

                           

                    11                  ./main.sh -r 11     Table D9: Instrumental variable estimates of farmer adaptation to water scarcity

                    12                  ./main.sh -r 12     Table C7: First stage estimates from production function estimation

                    13                  ./main.sh -r 13     Table 3: Production function estimates
                                                            Table 4: Counterfactual production and social surplus
                                                            Table 5: Distributional effects of Pigouvian Reform
                                                            Table D10: Optimality of ration
                                                            Table E11: Parameters used in the dynamic models
                                                            Figure 4: Optimality of ration
                                                            Figure 5: Distribution of productivity
                                                            Figure 6: Shadow cost of status quo ration
                                                            Figure 7: Change in profit due to Pigouvian reform   
