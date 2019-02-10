library(dplyr)
library(DT)
library(ggplot2)
library(leaflet)
library(plotly)
library(RColorBrewer)
library(tigris)
library(shinyjs)
library(stringr)

function(input, output, session) {
  
  
  
  # Observer for county selection -------------------------------------------
  
  observe({
    counties <- if (is.null(input$states)) character(0) else {
      dplyr::filter(merged_res_select, `State Abbreviated` %in% input$states) %>%
        `$`('County') %>%
        unique() %>%
        sort()
    }
    stillSelected <- isolate(input$counties[input$counties %in% counties])
    updateSelectInput(session, "counties", choices = counties,
                      selected = stillSelected)
  })
  

  # Model results output ----------------------------------------------------

  output$textresults <- renderText({
    
    if (input$states != "" & input$counties != "") {
      
      df_year <- dplyr::filter(merged_res_select, 
                               Year == input$year,
                               `State Abbreviated` == input$states,
                               `County` == input$counties)
      
      if (input$year == 2018) {
        
        paste0(
          "<br>The predicted <b>", input$year, "</b> mortality rate for <b>", input$counties, ", ", input$states, "</b> is <b>", df_year$`Predicted Mortality Rate`, "</b> per 10,000 persons.",
          "<br>",
          "<br>",
          "This presents a predicted increase of <b>", df_year$`Predicted Mortality Increase`, "%</b> over the previous year.",
          "<br>",
          "<br>",
          "<br>",
          "The mean squared error (MSE) for a hold-out model that used 2010-2016 data to predict 2017 mortality rates was calculated as <b>", df_year$MSE, "</b>.", 
          "<br>",
          "<br>",
          "This puts <b>", input$counties, ", ", input$states, "</b> in the <b>", df_year$MSEpercentile, "th</b> percentile of all county models. The average MSE of all county models was calculated as <b>", df_year$averageMSE, "</b>."
        )
      }else{
        
        paste0(
          "<br>The actual <b>", input$year, "</b> mortality rate for <b>", input$counties, ", ", input$states, "</b> was <b>", df_year$`Mortality Rate`, "</b>.", 
          "<br>",
          "<br>",
          "This presented an increase of <b>", df_year$`Actual Mortality Increase`, "%</b> over the previous year."
        )
      }
    }
  })
  
  # Time Series Plot --------------------------------------------------------
  
  output$myplot <- renderPlotly({
    
    if (input$states != "" & input$counties != "") {
      
      df_year <- dplyr::filter(merged_res_select, 
                               `State Abbreviated` == input$states,
                               County == input$counties)
      ggplotly(
        ggplot(data = df_year) +
          geom_point(aes(x = Year, y = `Mortality Rate`),
                     color = "dodgerblue") +
          geom_line(aes(x = Year, y = `Predicted Mortality Rate`),
                    color = "tomato") +
          geom_ribbon(aes(x = Year,
                          ymin=`Prediction Lower Bound`, 
                          ymax=`Prediction Upper Bound`),
                      fill = "tomato1", 
                      alpha=0.2) +
          labs(x = "Year", y = "Mortality Rate (per 10,000)")
        
      )
    }else{
      
      ggplotly(ggplot())
    }
    
    
    
  })
  
  
  # Map ---------------------------------------------------------------------
  
  # Define Mapbox access token
  tokn <- "pk.eyJ1IjoiZGF2aWR3b2xza2kiLCJhIjoiY2pyaHpuYWdlMDN3ZjN5cGh0bTBwbG15eiJ9.RFghZvu7xA1w0JC420vEAQ"
  
  # Define color palette
  pal <- colorNumeric(
    palette = "YlOrRd",
    domain = range(0,max(merged_res_select$`Predicted Mortality Rate`, 
                         na.rm = TRUE), 
                   na.rm = TRUE)
  )
  
  
  output$map <- renderLeaflet({
    
    map <-  leaflet() %>%
      addProviderTiles("MapBox", 
                       options = providerTileOptions(id = "mapbox.light", 
                                                     noWrap = FALSE, 
                                                     accessToken = tokn))
    if (input$states == "" ) {
      # shinyjs::disable("recalc")
      
      map %>% 
        addPolygons(data = all_states,
                    fillColor = "#202020",
                    color = "#b2aeae", # you need to use hex colors
                    fillOpacity = 0.7, 
                    weight = 1, 
                    smoothFactor = 0.2,
                    popup = NULL, stroke = FALSE)
    }else if (input$states != "" & input$counties == "") {
      df_year <- dplyr::filter(merged_res_select, 
                               Year == input$year,
                               `State Abbreviated` == input$states) %>%
        geo_join(all_counties, ., "GEOID", "FIPS Code", how = "inner")
      
      state_popup <- paste0("<strong>Year: </strong>", 
                            df_year$Year,
                            "<br><strong>County: </strong>", 
                            df_year$County, 
                            "<br><strong>Est. Population: </strong>",
                            df_year$Population,
                            "<br><strong>Mortality Rates (per 10,000) </strong>",
                            "<br>Actual: ",
                            df_year$Mortality.Rate,
                            "<br>Predicted: ",
                            df_year$Predicted.Mortality.Rate,
                            "<br><strong>Opioid Prescribing Rate (per 100): </strong>",
                            df_year$Prescribing.Rate)
      
      map %>%  
        addPolygons(data = df_year,
                    fillColor = ~ pal(Predicted.Mortality.Rate),
                    color = "#b2aeae", # you need to use hex colors
                    fillOpacity = 0.5, 
                    weight = 1, 
                    smoothFactor = 0.2,
                    popup = state_popup, stroke = FALSE) %>% 
        addLegend(data = df_year,
                  "bottomleft", 
                  pal = pal, 
                  values = ~Predicted.Mortality.Rate,
                  title = "Predicted Mortality Rate <br> (per 10,000)",
                  opacity = 0.5)
    }else{
      df_year <- dplyr::filter(merged_res_select, 
                               Year == input$year,
                               `State Abbreviated` == input$states,
                               `County` == input$counties) %>%
        geo_join(all_counties, ., "GEOID", "FIPS Code", how = "inner")
      
      treatment_popup <- paste0("<strong>Facility Name: </strong>", 
                                treatment_clean$Name,
                                "<br><strong>City/State: </strong>", 
                                treatment_clean$City, 
                                ", ",
                                treatment_clean$`State Abbreviated`,
                                "<br><strong>Zip Code: </strong>", 
                                treatment_clean$Zip)
      
      map %>%
        addPolygons(data = df_year,
                    fillColor = ~ pal(Predicted.Mortality.Rate),
                    color = "#b2aeae", # you need to use hex colors
                    fillOpacity = 0.3, 
                    weight = 1, 
                    smoothFactor = 0.2,
                    popup = NULL, stroke = FALSE) %>%
        addCircleMarkers(data = treatment_clean, stroke = FALSE, 
                         clusterOptions = markerClusterOptions(), 
                         popup = treatment_popup) %>% 
        fitBounds(lng1 = df_year@bbox[[3]],lat1 = df_year@bbox[[4]],
                  lng2 = df_year@bbox[[1]],lat2 = df_year@bbox[[2]])
    }
  })
  
  # Output Table
  
  output$countytable <- DT::renderDataTable({
    df <- merged_res_select %>%
      dplyr::filter(
        input$states == "" | `State Abbreviated` %in% input$states,
        input$counties == "" | County %in% input$counties
      )
    DT::datatable(df, escape = FALSE)
  })
  
  
}
