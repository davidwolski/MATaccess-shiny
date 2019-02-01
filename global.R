library(dplyr)
library(tigris)


# Load data ---------------------------------------------------------------

load('merged-results.RData')
load('model-validation.RData')
load('treatment-locations.RData')

merged_res_select <- left_join(merged_res_select, distinct(validation_select))

# Load county and state data
# exclude_states <- c("AK", "AS", "MP", "GU", "HI", "PR", "VI")
include_states <- c("MA", "CA", "FL", "OH")
all_states <- states() %>%
  .[which(.$STUSPS %in% include_states),]

all_counties <- counties() %>%
  .[which(.$STATEFP %in% all_states$STATEFP),] %>% 
  geo_join(.,all_states[,c("STATEFP", "STUSPS", "NAME")], 
           by =  c("STATEFP"="STATEFP"),
           how = "inner")
