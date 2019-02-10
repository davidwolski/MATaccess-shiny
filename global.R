library(dplyr)

# Load data ---------------------------------------------------------------

load('merged-results.RData')
load('model-validation.RData')
load('treatment-locations.RData')
load('state-county-shapefiles.RData')

merged_res_select <- left_join(merged_res_select, validation_linmod_select)

state_selector <- c("All states"="", 
                    structure(state.abb, names=state.name) %>% 
                      .[. %in% unique(merged_res_select$`State Abbreviated`)], 
                    if ("DC" %in% unique(merged_res_select$`State Abbreviated`)) {
                      "Washington, DC"="DC"
                    } )

# # Load county and state data
# # exclude_states <- c("AK", "AS", "MP", "GU", "HI", "PR", "VI")
# include_states <- c("MA", "OH")
# all_states <- states() %>%
#   .[which(.$STUSPS %in% include_states),]
# 
# all_counties <- counties() %>%
#   .[which(.$STATEFP %in% all_states$STATEFP),] %>% 
#   geo_join(.,all_states[,c("STATEFP", "STUSPS", "NAME")], 
#            by =  c("STATEFP"="STATEFP"),
#            how = "inner")
