# =================================================================
# Full Application Code - part 1 : Data importation and preview
# =================================================================


#This is the complete and synchronized code. You can copy this into your `app.R` file to see the dashboard in action with the **Import Engine** and the **Live Preview**.

# =================================================================
# 1. GLOBAL CONFIGURATION
# =================================================================
library(shiny)
library(shinydashboard) # Professional UI Framework
library(tidyverse)      # Data processing
library(rio)            # Universal data import
library(DT)             # Interactive tables

# Increase file upload limit to 200MB for clinical datasets
options(shiny.maxRequestSize = 200 * 1024^2)

# =================================================================
# 2. USER INTERFACE (The Body)
# =================================================================
ui <- dashboardPage(
  header  = dashboardHeader(title = "Clinical DataSentinel"),
  
  sidebar = dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Universal Import", tabName = "import", icon = icon("file-import"))
    )
  ),
  
  body = dashboardBody(
    tabItems(
      # Tab 1: Import & Preview
      tabItem(tabName = "import",
              
              # Row 1: The Upload Box
              fluidRow(
                box(
                  title = "Step 1: Clinical Data Upload", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  fileInput("file_input", "Select Clinical File (.csv, .sas7bdat, .dta)", width = "100%"),
                  actionButton("run_analysis", "Initialize Engine", class = "btn-block btn-success")
                )
              ),
              
              # Row 2: The Data Preview Box
              fluidRow(
                box(
                  title = "Step 2: Live Clinical Data Stream", 
                  width = 12, 
                  status = "info", 
                  solidHeader = FALSE,
                  DTOutput("preview_table") # Placeholder for the table
                )
              )
      )
    )
  )
)

# =================================================================
# 3. SERVER LOGIC (The Brain)
# =================================================================
server <- function(input, output, session) {
  
  # A. Storage Room: Reactive values to hold the data across the app
  data_holder <- reactiveValues(clean = NULL)
  
  # B. Import Action: Triggers only when the button is clicked
  observeEvent(input$run_analysis, {
    req(input$file_input) # Ensure a file is uploaded
    
    # Import the file using rio (detects extension automatically)
    df <- rio::import(input$file_input$datapath)
    
    # Store the data in our reactive container
    data_holder$clean <- df
    
    # Notify the user
    showNotification("Success: Clinical Data Loaded!", type = "message")
  })
  
  # C. Preview Table: Sends the data back to the UI
  output$preview_table <- renderDT({
    # Wait for the data to be loaded before rendering
    req(data_holder$clean)
    
    datatable(
      head(data_holder$clean, 100), # Show first 100 rows
      options = list(
        scrollX = TRUE,            # Allow horizontal scroll for many variables
        pageLength = 10,           # Set default rows per page
        dom = 'itp'                # Simplify UI (Info, Table, Pagination)
      ),
      rownames = FALSE
    )
  })
}

# =================================================================
# 4. LAUNCHER
# =================================================================
shinyApp(ui, server)
