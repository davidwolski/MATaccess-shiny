library(plotly)
library(leaflet)
navbarPage("MATaccess", id="nav",
           
           tabPanel("Map",
                    
                    # Row 1
                    fluidRow(
                      
                      
                      column(12,
                             
                             # Application title
                             titlePanel("County-level prediction of overdose mortality rates")
                             
                      )
                    ),
                    
                    # Row 2
                    fluidRow(
                      
                      column(width = 4,
                             
                             # Sidebar with a slider input for number of bins 
                             sliderInput(inputId = "year",
                                         label = "Year",
                                         min = 2010,
                                         max = 2018,
                                         value = 2018,
                                         sep = "",
                                         ticks = TRUE)
                      ),
                      
                      column(width = 4,
                             
                             selectInput(
                               "states", 
                               "States", 
                               state_selector, 
                               multiple=FALSE)
                      ),
                      
                      column(width = 4,
                             
                             conditionalPanel(
                               "input.states",
                               selectInput("counties", 
                                           "Counties", 
                                           c("All counties"=""), 
                                           multiple=FALSE)
                             )
                      )
                     
                    ),
                    
                    fluidRow(
                      
                      column(width = 12,
                             
                             # Show map
                             leafletOutput("map", width = "100%", height = 500)
                      )
                    ),
                    
                    
                    fluidRow(
                      
                      column(width = 6,
                             # Show a plot of county-level model
                             plotlyOutput("myplot")
                      ),
                      
                      column(width = 6, 
                             # Display results as text 
                             htmlOutput("textresults")
                      )
                    )
                    
                    
           ),
           
           tabPanel("Data Explorer",
                    hr(),
                    DT::dataTableOutput("countytable", width = "50%")
           )
)
