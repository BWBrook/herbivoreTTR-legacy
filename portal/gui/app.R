find_repo_root_local <- function(start) {
  dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
  for (i in 0:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      break
    }
    dir <- parent
  }
  NULL
}

load_portal_runtime_local <- function(repo_root) {
  if (exists("run_portal_plan_v1", mode = "function", inherits = TRUE)) {
    return(invisible(TRUE))
  }

  files <- list.files(file.path(repo_root, "R"), pattern = "[.]R$", full.names = TRUE)
  for (f in files) {
    sys.source(f, envir = globalenv())
  }
  invisible(TRUE)
}

resolve_app_start_dir <- function() {
  frame1 <- tryCatch(sys.frame(1), error = function(e) NULL)
  ofile <- if (!is.null(frame1)) frame1$ofile else NULL

  if (is.character(ofile) && length(ofile) == 1L && nzchar(ofile)) {
    return(normalizePath(dirname(ofile), winslash = "/", mustWork = FALSE))
  }

  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

this_dir <- resolve_app_start_dir()
repo_root <- find_repo_root_local(this_dir)
if (is.null(repo_root)) {
  stop("Could not locate repository root from portal/gui/app.R")
}

load_portal_runtime_local(repo_root)

template_dir <- file.path(repo_root, "portal", "plans", "templates")
template_files <- list.files(template_dir, pattern = "[.]ya?ml$", full.names = TRUE)
template_names <- basename(template_files)

if (length(template_files) < 1L) {
  stop("No template YAML files found under portal/plans/templates")
}

default_plan_out <- file.path(repo_root, "portal", "plans", "my_portal_plan.yaml")

ui <- shiny::fluidPage(
  shiny::titlePanel("herbivoreTTR Ecologist GUI Stub"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::selectInput(
        inputId = "template",
        label = "Template",
        choices = stats::setNames(template_files, template_names),
        selected = template_files[[1]]
      ),
      shiny::actionButton("load_template", "Load Template"),
      shiny::tags$hr(),
      shiny::textInput("plan_out", "Save plan to", value = default_plan_out),
      shiny::actionButton("save_plan", "Save YAML"),
      shiny::tags$hr(),
      shiny::checkboxInput("dry_run", "Dry run only", value = FALSE),
      shiny::actionButton("run_plan", "Run Plan"),
      shiny::tags$hr(),
      shiny::verbatimTextOutput("run_log")
    ),
    shiny::mainPanel(
      shiny::h4("Editable YAML"),
      shiny::textAreaInput("plan_yaml", label = NULL, rows = 28, width = "100%", value = ""),
      shiny::h4("Run Index Preview"),
      shiny::tableOutput("run_index_table"),
      shiny::uiOutput("report_link")
    )
  )
)

server <- function(input, output, session) {
  rv <- shiny::reactiveValues(log = "", result = NULL)

  load_template_text <- function(path) {
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }

  shiny::observe({
    shiny::updateTextAreaInput(session, "plan_yaml", value = load_template_text(input$template))
  })

  shiny::observeEvent(input$load_template, {
    shiny::updateTextAreaInput(session, "plan_yaml", value = load_template_text(input$template))
    rv$log <- sprintf("Loaded template: %s", input$template)
  })

  shiny::observeEvent(input$save_plan, {
    out_path <- normalizePath(input$plan_out, winslash = "/", mustWork = FALSE)
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    writeLines(input$plan_yaml, con = out_path)
    rv$log <- sprintf("Saved YAML to: %s", out_path)
  })

  shiny::observeEvent(input$run_plan, {
    tmp <- tempfile(fileext = ".yaml")
    writeLines(input$plan_yaml, con = tmp)

    res <- tryCatch(
      {
        run_portal_plan_v1(plan = tmp, dry_run = isTRUE(input$dry_run))
      },
      error = function(e) {
        rv$result <- NULL
        rv$log <- paste("Run failed:", conditionMessage(e))
        NULL
      }
    )

    if (!is.null(res)) {
      rv$result <- res
      if (isTRUE(res$dry_run)) {
        rv$log <- paste(
          "Dry-run complete",
          sprintf("mode=%s", res$mode),
          sprintf("scenario_id=%s", res$scenario_id),
          sep = "\n"
        )
      } else {
        rv$log <- paste(
          "Run complete",
          sprintf("mode=%s", res$mode),
          sprintf("run_dir=%s", res$run_dir),
          sprintf("manifest=%s", res$manifest_path),
          sep = "\n"
        )
      }
    }
  })

  output$run_log <- shiny::renderText({
    rv$log
  })

  output$run_index_table <- shiny::renderTable({
    if (is.null(rv$result) || isTRUE(rv$result$dry_run)) {
      return(NULL)
    }
    if (!is.null(rv$result$run_index)) {
      return(rv$result$run_index)
    }
    if (!is.null(rv$result$run_index_path) && file.exists(rv$result$run_index_path)) {
      return(utils::read.csv(rv$result$run_index_path, stringsAsFactors = FALSE))
    }
    NULL
  })

  output$report_link <- shiny::renderUI({
    if (is.null(rv$result) || isTRUE(rv$result$dry_run)) {
      return(NULL)
    }
    report_path <- rv$result$report$html_path
    if (is.null(report_path) || is.na(report_path) || !file.exists(report_path)) {
      return(shiny::tags$p("No HTML report generated for this run."))
    }

    shiny::tags$p(
      shiny::tags$a(
        href = paste0("file://", normalizePath(report_path, winslash = "/", mustWork = TRUE)),
        target = "_blank",
        "Open HTML report"
      )
    )
  })
}

shiny::shinyApp(ui = ui, server = server)
