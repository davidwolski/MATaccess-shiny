library(dplyr)


# Load data ---------------------------------------------------------------

load('merged-results.RData')
load('model-validation.RData')
load('treatment-locations.RData')
load('state-county-shapefiles.RData')

# Join validation and full model data
merged_res_select <- left_join(merged_res_select, validation_linmod_select)

# Get included states from results data frame
included_states <- unique(merged_res_select$`State Abbreviated`)

# Build state selector for input fields
state_selector <- c("All states"="", 
                    structure(state.abb, names=state.name) %>% 
                      .[. %in% included_states], 
                    if ("DC" %in% included_states) {
                      "Washington, DC"="DC"
                    } )
