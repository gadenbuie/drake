drake_context("other features")

test_with_dir("debug_command()", {
  skip_on_cran()
  txt <- "    f(x + 2) + 2"
  txt2 <- "drake::debug_and_run(function() {\n    f(x + 2) + 2\n})"
  x <- parse(text = txt)[[1]]
  out1 <- debug_command(x)
  out2 <- debug_command(txt)
  txt3 <- safe_deparse(out1)
  expect_equal(out2, txt2)
  expect_equal(out2, txt3)
})

test_with_dir("build_target() does not need to access cache", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  config <- drake_config(drake_plan(x = 1), lock_envir = FALSE)
  meta <- drake_meta_(target = "x", config = config)
  config$cache <- NULL
  build <- build_target(target = "x", meta = meta, config = config)
  expect_equal(1, build$value)
  expect_error(
    drake_build(target = "x", config = config),
    regexp = "cannot find drake cache"
  )
})

test_with_dir("cache log files, gc, and make()", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  x <- drake_plan(a = 1)
  make(x, session_info = FALSE, garbage_collection = TRUE)
  expect_false(file.exists("drake_cache.csv"))
  make(x, session_info = FALSE)
  expect_false(file.exists("drake_cache.csv"))
  make(x, session_info = FALSE, cache_log_file = TRUE)
  expect_true(file.exists("drake_cache.csv"))
  make(x, session_info = FALSE, cache_log_file = "my.log")
  expect_true(file.exists("my.log"))
})

test_with_dir("drake_build works as expected", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  scenario <- get_testing_scenario()
  e <- eval(parse(text = scenario$envir))
  pl <- drake_plan(a = 1, b = a)
  con <- drake_config(
    plan = pl,
    session_info = FALSE,
    envir = e,
    lock_envir = TRUE
  )

  # can run before any make()
  o <- drake_build(
    target = "a", character_only = TRUE, config = con)
  x <- cached()
  expect_equal(x, "a")
  make(pl, envir = e)
  o <- drake_config(pl, envir = e)
  expect_equal(justbuilt(o), "b")

  # Replacing deps in environment
  con$eval$a <- 2
  o <- drake_build(b, config = con)
  expect_equal(o, 2)
  expect_equal(con$eval$a, 2)
  expect_equal(readd(a), 1)
  o <- drake_build(b, config = con, replace = FALSE)
  expect_equal(con$eval$a, 2)
  expect_equal(readd(a), 1)
  con$eval$a <- 3
  o <- drake_build(b, config = con, replace = TRUE)
  expect_equal(con$eval$a, 1)
  expect_equal(o, 1)

  # `replace` in loadd()
  e$b <- 1
  expect_equal(e$b, 1)
  e$b <- 5
  loadd(b, envir = e, replace = FALSE)
  expect_equal(e$b, 5)
  loadd(b, envir = e, replace = TRUE)
  expect_equal(e$b, 1)
  e$b <- 5
  loadd(b, envir = e)
  expect_equal(e$b, 1)
})

test_with_dir("colors and shapes", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  expect_is(color_of("target"), "character")
  expect_is(color_of("import"), "character")
  expect_is(color_of("not found"), "character")
  expect_is(color_of("not found"), "character")
  expect_equal(color_of("bluhlaksjdf"), color_of("other"))
  expect_is(shape_of("object"), "character")
  expect_is(shape_of("file"), "character")
  expect_is(shape_of("not found"), "character")
  expect_equal(shape_of("bluhlaksjdf"), shape_of("other"))
})

test_with_dir("shapes", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  expect_is(shape_of("target"), "character")
  expect_is(shape_of("import"), "character")
  expect_is(shape_of("not found"), "character")
  expect_is(shape_of("object"), "character")
  expect_is(color_of("file"), "character")
  expect_is(color_of("not found"), "character")
  expect_equal(color_of("bluhlaksjdf"), color_of("other"))
})

test_with_dir("make() with skip_targets", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  expect_silent(make(drake_plan(x = 1), skip_targets = TRUE,
    verbose = 0L, session_info = FALSE))
  expect_false("x" %in% cached())
})

test_with_dir("warnings and messages are caught", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  expect_equal(nrow(progress()), 0)
  f <- function(x) {
    warning("my first warn")
    message("my first mess")
    warning("my second warn")
    message("my second mess")
    123
  }
  bad_plan <- drake_plan(x = f(), y = x)
  expect_warning(make(bad_plan, verbose = 1L, session_info = FALSE))
  x <- diagnose(x)
  expect_true(grepl("my first warn", x$warnings[1], fixed = TRUE))
  expect_true(grepl("my second warn", x$warnings[2], fixed = TRUE))
  expect_true(grepl("my first mess", x$messages[1], fixed = TRUE))
  expect_true(grepl("my second mess", x$messages[2], fixed = TRUE))
})

test_with_dir("missed() works with in-memory deps", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  # May have been loaded in a globalenv() testing scenario
  remove_these <- intersect(ls(envir = globalenv()), c("f", "g"))
  rm(list = remove_these, envir = globalenv())
  o <- dbug()
  expect_equal(character(0), missed(o))
  rm(list = c("f", "g"), envir = o$envir)
  expect_equal(sort(c("f", "g")), sort(missed(o)))
})

test_with_dir("missed() works with files", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  o <- dbug()
  expect_equal(character(0), missed(o))
  unlink("input.rds")
  expect_equal(display_keys(encode_path("input.rds")), missed(o))
})

test_with_dir(".onLoad() warns correctly and .onAttach() works", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  f <- ".RData"
  expect_false(file.exists(f))
  expect_silent(drake:::.onLoad())
  save.image()
  expect_true(file.exists(f))
  expect_warning(drake:::.onLoad())
  unlink(f, force = TRUE)
  set.seed(0)
  expect_silent(suppressPackageStartupMessages(drake:::.onAttach()))
})

test_with_dir("config_checks() via make()", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  config <- dbug()
  y <- data.frame(x = 1, y = 2)
  suppressWarnings(
    expect_error(
      make(y, envir = config$envir, session_info = FALSE, verbose = 0L)))
  y <- data.frame(target = character(0), command = character(0))
  suppressWarnings(
    expect_error(
      make(y, envir = config$envir,
           session_info = FALSE, verbose = 0L)))
  suppressWarnings(expect_error(
    make(
      config$plan,
      targets = character(0),
      envir = config$envir,
      session_info = FALSE,
      verbose = 0L
    ),
    regexp = "valid targets"
  ))
})

test_with_dir("targets can be partially specified", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  config <- dbug()
  config$targets <- "drake_target_1"
  testrun(config)
  expect_true(file.exists("intermediatefile.rds"))
  expect_error(readd(final))
  config$targets <- "final"
  testrun(config)
  expect_true(is.numeric(readd(final)))
})

test_with_dir("file_store quotes properly", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  expect_equal(file_store("x"), encode_path("x"))
})

test_with_dir("misc utils", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  expect_equal(pair_text("x", c("y", "z")), c("xy", "xz"))
  config <- list()
  expect_error(config_checks(config))
  expect_error(plan_checks(data.frame(x = 1, y = 2)), "columns")
  expect_error(targets_from_dots(123, NULL), regexp = "must contain names")
})

test_with_dir("make(..., skip_imports = TRUE) works", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  con <- dbug()
  plan <- dbug_plan()
  make(
    plan, parallelism = con$parallelism,
    envir = con$envir, jobs = con$jobs,
    skip_imports = TRUE,
    session_info = FALSE
  )
  con <- drake_config(
    plan, parallelism = con$parallelism,
    envir = con$envir, jobs = con$jobs,
    skip_imports = TRUE,
    session_info = FALSE
  )
  expect_equal(
    sort(cached(targets_only = FALSE)),
    sort(display_keys(
      c(encode_path("intermediatefile.rds"), plan$target)
    ))
  )

  # If the imports are already cached, the targets built with
  # skip_imports = TRUE should be up to date.
  make(plan, envir = con$envir, session_info = FALSE)
  clean(list = plan$target)
  make(
    plan, parallelism = con$parallelism,
    envir = con$envir, jobs = con$jobs,
    skip_imports = TRUE, session_info = FALSE
  )
  con <- drake_config(
    plan, parallelism = con$parallelism,
    envir = con$envir, jobs = con$jobs,
    skip_imports = TRUE, session_info = FALSE
  )
  out <- outdated(con)
  expect_equal(out, character(0))
})

test_with_dir("assert_pkg", {
  skip_on_cran()
  expect_error(assert_pkg("_$$$blabla"), regexp = "not installed")
  expect_error(
    assert_pkg("digest", version = "9999.9999.9999"),
    regexp = "must be version 9999.9999.9999 or greater"
  )
  expect_error(
    assert_pkg(
      "impossible",
      version = "9999.9999.9999",
      install = "installer::install"
    ),
    regexp = "with installer::install"
  )
})

test_with_dir("packages are loaded and prework is run", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  skip_if_not_installed("abind")
  on.exit(options(test_drake_option_12345 = NULL))

  options(test_drake_option_12345 = "unset")
  expect_equal(getOption("test_drake_option_12345"), "unset")
  config <- dbug()
  try(detach("package:abind", unload = TRUE), silent = TRUE) # nolint
  expect_error(abind(1))

  # Load packages with the 'packages' argument
  config$packages <- "abind"
  config$prework <- "options(test_drake_option_12345 = 'set')"
  config$plan <- drake_plan(
    x = getOption("test_drake_option_12345"),
    y = c(deparse(body(abind)), x)
  )
  config$targets <- config$plan$target
  expect_false(any(c("x", "y") %in% config$cache$list()))
  testrun(config)
  expect_true(all(c("x", "y") %in% config$cache$list()))
  expect_equal(readd(x), "set")
  expect_true(length(readd(y)) > 0)
  clean()

  # load packages the usual way
  options(test_drake_option_12345 = "unset")
  expect_equal(getOption("test_drake_option_12345"), "unset")
  try(detach("package:abind", unload = TRUE), silent = TRUE) # nolint
  expect_error(abind(1))
  library(abind) # nolint
  config$packages <- NULL
  expect_false(any(c("x", "y") %in% config$cache$list()))

  # drake may be loaded with devtools::load_all() but not
  # installed.
  scenario <- get_testing_scenario()
  suppressWarnings(
    make(
      plan = config$plan,
      targets = config$targets,
      envir = config$envir,
      verbose = 0L,
      parallelism = scenario$parallelism,
      jobs = scenario$jobs,
      prework = config$prework,
      command = config$command,
      session_info = FALSE
    )
  )
  expect_true(all(c("x", "y") %in% config$cache$list()))
  expect_equal(readd(x), "set")
  expect_true(length(readd(y)) > 0)
})

test_with_dir("prework can be an expression", {
  on.exit(options(test_drake_option_12345 = NULL))
  options(test_drake_option_12345 = "unset")
  expect_equal(getOption("test_drake_option_12345"), "unset")
  config <- dbug()
  config$plan <- drake_plan(x = getOption("test_drake_option_12345"))
  config$targets <- config$plan$target
  config$prework <- quote(options(test_drake_option_12345 = "set"))
  testrun(config)
  expect_equal(readd(x), "set")
})

test_with_dir("prework can be an expression", {
  on.exit(
    options(test_drake_option_12345 = NULL, test_drake_option_6789 = NULL)
  )
  options(test_drake_option_12345 = "unset", test_drake_option_6789 = "unset")
  expect_equal(getOption("test_drake_option_12345"), "unset")
  expect_equal(getOption("test_drake_option_6789"), "unset")
  config <- dbug()
  config$plan <- drake_plan(
    x = getOption("test_drake_option_12345"),
    y = getOption("test_drake_option_6789")
  )
  config$targets <- config$plan$target
  config$prework <- list(
    quote(options(test_drake_option_12345 = "set")),
    quote(options(test_drake_option_6789 = "set"))
  )
  testrun(config)
  expect_equal(readd(x), "set")
  expect_equal(readd(y), "set")
})

test_with_dir("parallelism can be a scheduler function", {
  plan <- drake_plan(x = file.create("x"))
  build_ <- function(target, config){
    tidy_expr <- eval(
      expr = config$layout[[target]]$command_build,
      envir = config$eval
    )
    eval(expr = tidy_expr, envir = config$eval)
  }
  loop_ <- function(config) {
    targets <- igraph::topo_sort(config$graph)$name
    for (target in targets) {
      log_msg(target, config = config, newline = TRUE)
      config$eval[[target]] <- build_(
        target = target,
        config = config
      )
    }
    invisible()
  }
  config <- drake_config(plan, parallelism = loop_)
  expect_warning(
    make(config = config),
    regexp = "Use at your own risk"
  )
  expect_true(file.exists("x"))
  expect_false(config$cache$exists("x"))
})

test_with_dir("running()", {
  skip_on_cran()
  plan <- drake_plan(a = 1)
  cache <- storr::storr_environment()
  make(plan, session_info = FALSE, cache = cache)
  expect_equal(running(cache = cache), character(0))
  cache$set(key = "a", value = "running", namespace = "progress")
  expect_equal(running(cache = cache), "a")
})
