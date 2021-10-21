# max file upload size is 500 MB
options(shiny.maxRequestSize = 500*1024^2)


genomic_region_plot <- function(genome_version, start, stop){
  gtrack <- GenomeAxisTrack()
  itrack <- IdeogramTrack(genome = genome_version, chromosome = paste0("chr", chromosome))
  plotTracks(list(itrack, gtrack), from=start_pos, to=stop_pos)
}

server <- function(input, output) {
  # For uploading file panel
  load_data <- eventReactive(input$upload_go, {
    req(input$file1)
    df <- fread(input$file1$datapath,
                header=input$header,
                sep=input$sep)

    
    validate(need(input$chr_column %in% colnames(df), 
                  message="The specified chromosome column was not found in the dataframe. Please check again"))
    validate(need(input$pos_column %in% colnames(df), 
                  message="The specified SNP position column was not found in the dataframe. Please check again"))
    validate(need(input$pval_column %in% colnames(df), 
                  message="The specified P value column was not found in the dataframe. Please check again"))
    return(df)
    
  })
  
  # add a table of the file

  output$contents <- DT::renderDT({
    if (is.null(load_data())){
      return({})
    }
    else if (input$preview){
      return(head(load_data()))
    }
  })
    

  # Create the manhattan plot
  filter_data <- eventReactive(input$update_plot,{
    df <- load_data()
    index_chrom <- which(input$chr_column == colnames(df))
    index_pos <- which(input$pos_column == colnames(df))
    index_pval <- which(input$pval_column == colnames(df))
    
    df_filtered <- df %>%
      filter(.[[index_chrom]] == input$chromosome) %>%
      filter(.[[index_pos]] > input$start_pos) %>%
      filter(.[[index_pos]] < input$stop_pos) %>%
      mutate("-log10Pval" = -log10(.[[index_pval]])) %>%
      mutate(Color = ifelse(P<as.numeric(input$genome_wide_significance), "red", "black"))
    return(df_filtered)
  })
  
  output$manhattan_plot <- renderPlot({
    plot_data <- filter_data()
    genome_wide_significance <- isolate(as.numeric(input$genome_wide_significance))
    
    ggplot(plot_data,aes(x=POS, y=`-log10Pval`, color=Color))+
      geom_point()+
      geom_hline(yintercept = -log10(genome_wide_significance), color="red", 
                 linetype="dashed")+
      ylab(bquote(~-Log[10]~italic(P)))+
      xlab(isolate(paste0("Genomic Interval:\nchr", input$chromosome,":",
                  formatC(input$start_pos, format="e", digits=0),"<--->", 
                  formatC(input$stop_pos, format="e", digits=0))))+
      scale_color_identity()+
      theme(legend.position = "none")
  })

  
  # Create the Ideogram and the genomic range
  #output$genomic_region <- reactive({plotPNG(genomic_region_plot(input$genome_version, input$start_pos, input$stop_pos))})

  
  # Create a data table that only contains points that were selected
  output$data_brush <- DT::renderDT({
    data_in <- filter_data() %>%
      dplyr::select(-Color)
    
    n <- nrow(brushedPoints(data_in, brush=input$plot_brush)) # will return 0 if no are selected
    if (n==0)
      return()
    else
      brushedPoints(data_in, brush=input$plot_brush)
  })
}