library(shiny)
library(data.table)
library(tidyverse)


source("server.R")

ui <- fluidPage(titlePanel("Interactive Manhattan Plot"),
                tabsetPanel(
                  # Upload Files Panel
                  tabPanel(
                    "Upload File",
                    titlePanel("Uploading Files"),
                    sidebarLayout(
                      sidebarPanel(
                        fileInput('file1', 'Choose input file',
                                  accept = c('.tsv',
                                             '.csv')),
                                                checkboxInput('header', 'Header', TRUE),
                        radioButtons('sep', 'Separator',
                                     c(
                                       Comma = ',',
                                       Semicolon = ';',
                                       Tab = '\t'
                                     ),
                                     ','),
                        
                        
                        # Horizontal line ----
                        hr(),
                        textInput("chr_column", "Specify column containing chromosomes", "#CHROM"),
                        textInput("pos_column", "Specify column containing SNP position", "POS"),
                        textInput("pval_column", "Specify column containing P values", "P"),
                        
                        # Horizontal line ----
                        hr(),
                        
                        # Input: Select number of rows to display ----
                        shinyWidgets::awesomeCheckbox(
                          "preview",
                          "Show preview",
                          value = TRUE
                        ),
                        actionButton("upload_go", "Upload")
                        
                        
                      ),
                      mainPanel(DT::DTOutput('contents'))
                    )
                  ),
                  
                  # Plot and DT Panel
                  tabPanel(
                    "Manhattan Plot",
                    titlePanel("Manhattan Plot"),
                    sidebarLayout(
                      sidebarPanel(
                        selectInput("genome_version", "Specify the used genome assembly", choice=c("hg19", "hg38")),
                        h4("Specify a genomic interval:"),
                        selectInput(
                          "chromosome",
                          "Specify a Chromosome",
                          choices = 1:22
                        ),
                        div(
                          style = "display:inline-block;",
                          shinyWidgets::autonumericInput(
                            "start_pos",
                            "Start of interval",
                            value =
                              1 * 10e3,
                            decimalPlaces = 0,
                            decimalCharacter = ",",
                            digitGroupSeparator =
                              "."
                          )
                        ),
                        div(
                          style = "display:inline-block;",
                          shinyWidgets::autonumericInput(
                            "stop_pos",
                            "End of interval",
                            value =
                              7 * 10e7,
                            decimalPlaces = 0,
                            decimalCharacter = ",",
                            digitGroupSeparator =
                              "."
                          )
                        ),
                        textInput(
                          "genome_wide_significance",
                          "Specify the genome-wide significance threshold",
                          "5e-8"
                        ),
                        actionButton("update_plot", "Generate Plot")
                      ),
                      mainPanel(
                        plotOutput("manhattan_plot", height = "600px", brush = "plot_brush"),
                        #plotOutput("genomic_region"),
                        h2("Drag and draw to get details of selected points"),
                        DT::DTOutput("data_brush")
                      ),
                    )
                  ),
                  
                ))



shinyApp(ui, server)
