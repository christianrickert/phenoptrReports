# Define server logic required to draw a histogram
shinyServer(function(input, output, server) {

  # Data container. Will contain
  # expression_columns - Names of mean expression columns
  # phenotypes - A list of phenotype_module
  # tissue_categories - User-selected tissue categories
  the_data = reactiveValues()

  # File selection
  # file_data may contain input_path, summary_path, score_path, output_dir
  # It is an ordinary list of reactive objects
  file_data = shiny::callModule(files_module, 'files')

  # Consolidated
  all_data = reactive({
    c(reactiveValuesToList(the_data), purrr::map(file_data, ~.()))
  })

  # Handle changes in file_data$input_path by initializing the analysis panel
  shiny::observe({
    # Remove any existing output panel
    purrr::safely(shiny::removeUI)('#well2')

    shiny::req(file_data$input_path())
    # shiny::req(file_data$output_dir())

    # Read the data file and get some info about it
    d = phenoptr::read_cell_seg_data(file_data$input_path())
    tissue_categories = unique(d$`Tissue Category`)
    the_data$expression_columns = stringr::str_subset(names(d), 'Mean$')

    the_data$available_phenotypes = available_phenotypes = names(d) %>%
      stringr::str_subset('Phenotype ') %>%
      stringr::str_remove('Phenotype ')


    # Create the initial GUI with tissue and phenotype selectors
    new_ui = shiny::div(id='well2', shiny::wellPanel(
      shiny::checkboxGroupInput('tissue_categories', 'Select tissue categories:',
                         choices=tissue_categories, inline=TRUE),
      paste('Available phenotypes:', paste(available_phenotypes, collapse=', ')),
      phenotype_module_ui('pheno0', the_data$expression_columns),
      shiny::actionButton('add', 'Add another phenotype')
    ))

    shiny::insertUI('#placeholder', 'afterBegin', new_ui)

    # Remember the phenotype selector
    the_data$phenotype_modules =
      list(shiny::callModule(phenotype_module, 'pheno0',
                             available_phenotypes))

  })

  # Handle Add button by adding another phenotype_module_ui
  observeEvent(input$add, {
    id = paste0('pheno', input$add)
    ui = phenotype_module_ui(id, the_data$expression_columns)
    insertUI('#add', 'beforeBegin', ui)
    the_data$phenotype_modules = c(the_data$phenotype_modules,
                            list(callModule(phenotype_module, id,
                                            the_data$available_phenotypes)))
  })

  # Update the error message
  shiny::observe({
    if (is.null(file_data$input_path())) {
      analysis_error = 'Please select a data file in the Files tab.'
    } else if (is.null(file_data$output_dir())) {
      analysis_error ='Please select an output directory in the Files tab.'
    } else if (length(input$tissue_categories)==0) {
      analysis_error = 'Please select tissue categories.'
    } else {
      analysis_error = ''
    }
    output$analysis_error = shiny::renderText(analysis_error)
  })

  # Update the output text in response to user selections
  output$results = renderText({
    the_data$tissue_categories = input$tissue_categories
    format_all(all_data())
  })

  # Process the result!!
  shiny::observeEvent(input$process, {
    shiny::req(input$process)
    shiny::showNotification('Processing, please wait!', duration=NULL,
                     closeButton=FALSE, type='message')

    # Create and save the script
    script = format_all(all_data())
    script_path = file.path(file_data$output_dir(), 'Script.R')
    write_lines(script, script_path)

    # Run the script to do some work!
    source(script_path, local=new.env())

    shiny::stopApp()
  })
})