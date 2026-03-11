# 🏥 Training: Building a Clinical Trial Dashboard (DataSentinel)

Welcome to this step-by-step training. We are going to build **DataSentinel**, a professional dashboard to audit clinical data. We will build everything piece by piece, from Scratch to a fully functional tool for auditing clinical datasets.

---

## Phase 1: Global Anatomy

Every Shiny app follows the same "Trinity" structure:
1. **The Library (Global):** Loading the tools.
2. **The UI (The Body):** What the user sees.
3. **The Server (The Brain):** How the app thinks.

```r
# --- PART 0: The Minimal App Structure ---
library(shiny)
library(shinydashboard)

# 1. UI: The Layout
ui <- dashboardPage(
  header = dashboardHeader(title = "Empty App"),
  sidebar = dashboardSidebar(),
  body = dashboardBody()
)

# 2. SERVER: The Logic (Empty for now)
server <- function(input, output, session) {
  # No logic yet...
}

# 3. CONNECTION: Launching the app
shinyApp(ui, server)
```
### The Communication Flow:
* **User** interacts with an Input in the **UI**.
* The **UI** sends that value to the **Server**.
* The **Server** reacts, processes the data, and creates a result.
* The **Server** sends that result back to the **UI** to be displayed.

  
## Phase 2: Global Configuration
At the very top of the `app.R` file, Load all packages needed to run the dashboard logic.
We use `rio` because it can read CSV, XLSX, SAS and Stata files commonly used in clinical trials.

```r
# --- PART 1: Global Settings ---
library(shiny)
library(shinydashboard) # Standard Clinical UI
library(tidyverse)      # For data cleaning
library(rio)            # Universal import (SAS, Stata, CSV)
library(DT)             # Interactive Tables

# Increase upload limit to 200MB
options(shiny.maxRequestSize = 200 * 1024^2)
```
## Phase 3: implementation of the data importation engine
### --- PART A: UI ---

```r
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
      tabItem(tabName = "import",
        fluidRow(
          box(
            title = "Step 1: Clinical Data Upload", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            fileInput("file_input", "Select Clinical File (.csv, .sas7bdat, .dta)", width = "100%"),
            actionButton("run_analysis", "Initialize Engine", class = "btn-block btn-success")
          )
        )
      ) # End tabItem
    ) # End tabItems
  ) # End dashboardBody
) # End dashboardPage

server <- function(input, output, session) {
  # We will add Logic here
}

shinyApp(ui, server)
```
### Part B: The Server (The Brain)

Now that we have a button in the **UI**, we need to tell the **Server** how to process the file when the user clicks it. In Shiny, the server is where the "magic" happens.

#### The Code Logic

```r
server <- function(input, output, session) {
  
  # 1. Create a Reactive Storage Room
  # Why: In Shiny, standard variables don't trigger updates. 
  # 'reactiveValues' is a special container that tells Shiny: 
  # "If the data inside changes, update all charts and tables automatically."
  data_holder <- reactiveValues(clean = NULL)
  
  # 2. Triggering the action
  # 'observeEvent' listens to the UI. 
  # It waits specifically for 'input$run_analysis' (our button) to be clicked.
  observeEvent(input$run_analysis, {
    
    # 'req' stands for 'Require'. 
    # It stops the code if 'input$file_input' is empty (to avoid errors).
    req(input$file_input) 
    
    # 3. Processing the File
    # 'input$file_input$datapath' is the temporary path where Shiny saves the uploaded file.
    # We use 'rio::import' to automatically detect if it's a CSV, SAS, or Stata file.
    df <- rio::import(input$file_input$datapath)
    
    # 4. Saving to the Storage Room
    # We move the imported data into our reactive container 'data_holder'.
    # Now, 'data_holder$clean' can be accessed by any other part of the app.
    data_holder$clean <- df
    
    # 5. User Feedback
    # 'showNotification' creates a small popup to tell the user the import worked.
    showNotification("Success: Clinical Data Loaded!", type = "message")
  })
}
```
### Part C: Data Preview (Visualizing the Results)

Now that the data is stored in the "Brain" (Server), we need to show it to the **User** in the "Body" (UI). We will use an interactive table to display the clinical records.

**UI - Creating the Placeholder**
Go back to the `ui` code. Inside the `tabItem(tabName = "import", ...)`, add a new `fluidRow` below the upload box. This tells Shiny: "Reserve this space for a table."

```r
# --- UI COMPLETE (Including Import & Preview) ---

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
      tabItem(tabName = "import",
        # Row 1: Upload Button
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
        
        # Row 2: Data Preview
        fluidRow(
          box(
            title = "Live Clinical Data Stream", 
            width = 12, 
            status = "info", 
            solidHeader = FALSE,
            DTOutput("preview_table")
          )
        )
      ) # End tabItem
    ) # End tabItems
  ) # End dashboardBody
) # End dashboardPage
```

**Server - Rendering the Table**

Now, we need to tell the **Server** (The Brain) how to fill the placeholder we just created in the UI. This code goes inside your `server` function, right after the `observeEvent` block.

```r
# --- SERVER LOGIC FOR PREVIEW ---
server <- function(input, output, session) {
  
  data_holder <- reactiveValues(clean = NULL)
  
  observeEvent(input$run_analysis, {
    req(input$file_input) 
    df <- rio::import(input$file_input$datapath)
    data_holder$clean <- df
    showNotification("Success: Clinical Data Loaded!", type = "message")
  })

  #### Preview logic: This function sends the processed data back to the UI placeholder 'preview_table'
  output$preview_table <- renderDT({
    # 1. The Safety Guard (req)
    # 'req' stands for 'require'. 
    # It ensures the table ONLY tries to render AFTER 'data_holder$clean' is filled.
    # Without this, the app would crash on startup because 'clean' starts as NULL.
    req(data_holder$clean)
    
    # 2. Generating the Table
    # 'datatable' creates the interactive HTML table from our data.
    datatable(
      head(data_holder$clean, 100), # Performance: Show only first 100 rows for the preview
      options = list(
        scrollX = TRUE,            # Mandatory for clinical data: allows horizontal scrolling
        pageLength = 10,           # Number of rows displayed per page
        dom = 'itp'                # UI elements: (i)nfo, (t)able, (p)agination
      ),
      rownames = FALSE
    )
  })

}
```

