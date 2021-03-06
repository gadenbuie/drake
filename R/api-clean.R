#' @title Remove targets/imports from the cache.
#' @description Cleans up the work done by [make()].
#' @details
#' By default, `clean()` removes references to cached data.
#' To deep-clean the data to free up storage/memory, use
#' `clean(garbage_collection = TRUE)`. Garbage collection is slower,
#' but it purges data with no remaining references. To just do garbage
#' collection without cleaning, see [drake_gc()].
#' Also, for `clean()`, you must be in your project's working directory
#' or a subdirectory of it.
#' WARNING: This deletes ALL work done with [make()],
#' which includes
#' file targets as well as the entire drake cache. Only use `clean()`
#' if you're sure you won't lose anything important.
#' @section Safeguards:
#' If you run [clean()] with no arguments, `drake`'s response is to
#' remove all the targets etc. from the cache. To prevent you from
#' doing this accidentally in an interactive session, [clean()]
#' prompts you with a menu to confirm. The menu only appears
#' once per session. You can disable it with
#' `options(drake_clean_menu = FALSE)`.
#' @seealso [drake_gc()], [make()]
#' @export
#' @return Invisibly return `NULL`.
#'
#' @inheritParams cached
#'
#' @param ... Targets to remove from the cache: as names (symbols) or
#'   character strings. If the `tidyselect` package is installed,
#'   you can also supply `dplyr`-style `tidyselect`
#'   commands such as `starts_with()`, `ends_with()`, and `one_of()`.
#'
#' @param list Character vector naming targets to be removed from the
#'   cache. Similar to the `list` argument of [remove()].
#'
#' @param destroy Logical, whether to totally remove the drake cache.
#'   If `destroy` is `FALSE`, only the targets
#'   from `make()`
#'   are removed. If `TRUE`, the whole cache is removed, including
#'   session metadata, etc.
#'
#' @param jobs Number of jobs for light parallelism
#'   (disabled on Windows).
#'
#' @param force Logical, whether to try to clean the cache
#'   even though the project may not be back compatible with the
#'   current version of drake.
#'
#' @param garbage_collection Logical, whether to call
#'   `cache$gc()` to do garbage collection.
#'   If `TRUE`, cached data with no remaining references
#'   will be removed.
#'   This will slow down `clean()`, but the cache
#'   could take up far less space afterwards.
#'   See the `gc()` method for `storr` caches.
#'
#' @param purge Logical, whether to remove objects from
#'   metadata namespaces such as "meta", "build_times", and "errors".
#'
#' @examples
#' \dontrun{
#' isolate_example("Quarantine side effects.", {
#' if (suppressWarnings(require("knitr"))) {
#' load_mtcars_example() # Get the code with drake_example("mtcars").
#' make(my_plan) # Run the project, build the targets.
#' # List objects in the cache, excluding R objects
#' # imported from your workspace.
#' cached(no_imported_objects = TRUE)
#' # Remove 'summ_regression1_large' and 'small' from the cache.
#' clean(summ_regression1_large, small)
#' # Those objects should be gone.
#' cached(no_imported_objects = TRUE)
#' # Rebuild the missing targets.
#' make(my_plan)
#' # Remove all the targets and imports.
#' # On non-Windows machines, parallelize over at most 2 jobs.
#' clean(jobs = 2)
#' # Make the targets again.
#' make(my_plan)
#' # Garbage collection removes data whose references are no longer present.
#' # It is slow, but you should enable it if you want to reduce the
#' # size of the cache.
#' clean(garbage_collection = TRUE)
#' # All the targets and imports are gone.
#' cached()
#' # But there is still cached metadata.
#' build_times()
#' # To make even more room, use the "purge" flag.
#' clean(purge = TRUE)
#' build_times()
#' # Completely remove the entire cache (default: '.drake/' folder).
#' clean(destroy = TRUE)
#' }
#' })
#' }
clean <- function(
  ...,
  list = character(0),
  destroy = FALSE,
  path = NULL,
  search = NULL,
  cache = drake::drake_cache(path = path, verbose = verbose),
  verbose = 1L,
  jobs = 1,
  force = FALSE,
  garbage_collection = FALSE,
  purge = FALSE
) {
  deprecate_force(force)
  deprecate_search(search)
  if (is.null(cache)) {
    return(invisible())
  }
  targets <- c(as.character(match.call(expand.dots = FALSE)$...), list)
  if (requireNamespace("tidyselect", quietly = TRUE)) {
    targets <- drake_tidyselect_cache(
      ...,
      list = list,
      cache = cache,
      namespaces = target_namespaces_()
    )
  }
  if (!length(targets) && is.null(c(...))) {
    if (abort_full_clean(cache$driver$path)) {
      return(invisible()) # nocov
    }
    targets <- cache$list()
  }
  if (purge) {
    namespaces <- target_namespaces_(default = cache$default_namespace)
  } else {
    namespaces <- cleaned_namespaces_(default = cache$default_namespace)
  }
  lightly_parallelize(
    X = targets,
    FUN = clean_single_target,
    jobs = jobs,
    cache = cache,
    namespaces = namespaces
  )
  if (destroy) {
    cache$destroy()
  }
  if (garbage_collection) {
    cache$gc()
  }
  invisible()
}

clean_single_target <- function(
  target,
  cache,
  namespaces,
  graph,
  layout
) {
  files <- character(0)
  if (cache$exists(target, namespace = "meta")) {
    files <- cache$get(key = target, namespace = "meta")$file_out
  }
  for (namespace in namespaces) {
    for (key in c(target, files)) {
      try(cache$del(key = key, namespace = namespace))
    }
  }
  if (length(files)) {
    unlink(decode_path(files), recursive = TRUE)
  }
}

#' @title Do garbage collection on the drake cache.
#' @description The cache is a key-value store.
#' By default, the [clean()] function removes
#' values, but not keys.
#' Garbage collection removes the remaining dangling files.
#' @seealso [clean()]
#' @export
#' @return`NULL`
#' @inheritParams cached
#' @param force Logical, whether to load the cache
#'   despite any back compatibility issues with the
#'   running version of drake.
#' @examples
#' \dontrun{
#' isolate_example("Quarantine side effects.", {
#' if (suppressWarnings(require("knitr"))) {
#' load_mtcars_example() # Get the code with drake_example("mtcars").
#' make(my_plan) # Run the project, build the targets.
#' # At this point, check the size of the '.drake/' cache folder.
#' # Clean without garbage collection.
#' clean(garbage_collection = FALSE)
#' # The '.drake/' cache folder is still about the same size.
#' drake_gc() # Do garbage collection on the cache.
#' # The '.drake/' cache folder should have gotten much smaller.
#' }
#' })
#' }
drake_gc <- function(
  path = NULL,
  search = NULL,
  verbose = 1L,
  cache = drake::drake_cache(path = path, verbose = verbose),
  force = FALSE
) {
  deprecate_search(search)
  if (!is.null(cache)) {
    cache$gc()
    rm_bad_cache_filenames(cache)
  }
  invisible()
}

rm_bad_cache_filenames <- function(cache) {
  if (keys_are_mangled(cache)) {
    files <- list.files(path = cache$driver$path, recursive = TRUE)
    keep <- grepl(pattern = "^[-_./\\0-9a-zA-Z]*$", x = files)
    unlink(files[!keep], recursive = TRUE)
  }
}

#' @title Try to repair a drake cache that is prone
#'   to throwing `storr`-related errors.
#' @description Sometimes, `storr` caches may have
#' dangling orphaned files that prevent you from loading or cleaning.
#' This function tries to remove those files so you can use the
#' cache normally again.
#' @return Nothing.
#' @export
#' @seealso [drake_cache()], [cached()],
#'   [drake_gc()], [clean()]
#' @inheritParams drake_cache
#' @param targets Character vector, names of the targets to rescue.
#'   As with many other drake utility functions, the word `target`
#'   is defined generally in this case, encompassing imports
#'   as well as true targets.
#'   If `targets` is `NULL`, everything in the
#'   cache is rescued.
#' @param cache A `storr` cache object.
#' @param jobs Number of jobs for light parallelism
#'   (disabled on Windows).
#' @param garbage_collection Logical, whether to do garbage collection
#'   as a final step. See [drake_gc()] and [clean()]
#'   for details.
#' @param search Deprecated.
#' @param force Deprecated.
#' @examples
#' \dontrun{
#' isolate_example("Quarantine side effects.", {
#' if (suppressWarnings(require("knitr"))) {
#' load_mtcars_example() # Get the code with drake_example("mtcars").
#' make(my_plan) # Run the project, build targets. This creates the cache.
#' # Remove dangling cache files that could cause errors.
#' rescue_cache(jobs = 2)
#' # Alternatively, just rescue targets 'small' and 'large'.
#' # Rescuing specific targets is usually faster.
#' rescue_cache(targets = c("small", "large"))
#' }
#' })
#' }
rescue_cache <- function(
  targets = NULL,
  path = NULL,
  search = NULL,
  verbose = 1L,
  force = FALSE,
  cache = drake::drake_cache(path = path, verbose = verbose),
  jobs = 1,
  garbage_collection = FALSE
) {
  deprecate_search(search)
  deprecate_force(force)
  if (is.null(cache)) {
    return(invisible())
  }
  for (namespace in cache$list_namespaces()) {
    X <- cache$list(namespace = namespace)
    if (!is.null(targets)) {
      X <- intersect(X, targets)
    }
    lightly_parallelize(
      X = X,
      FUN = rescue_del,
      jobs = jobs,
      cache = cache,
      namespace = namespace
    )
  }
  if (garbage_collection) {
    cache$gc()
  }
  invisible()
}

rescue_del <- function(key, cache, namespace) {
  tryCatch(
    touch_storr_object(key = key, cache = cache, namespace = namespace),
    error = function(e) {
      cache$del(key = key, namespace = namespace)
    }
  )
  invisible(NULL)
}

touch_storr_object <- function(key, cache, namespace) {
  envir <- environment()
  hash <- cache$get_hash(key = key, namespace = namespace)
  value <- cache$driver$get_object(hash = hash)
  remove(value, envir = envir)
  invisible(NULL)
}

abort_full_clean <- function(path) {
  menu_enabled <- .pkg_envir[["drake_clean_menu"]] %||%
    getOption("drake_clean_menu") %||%
    TRUE
  if (!(interactive() && menu_enabled)) {
    return(FALSE)
  }
  # nocov start
  title <- paste0(
    "Really delete everything in the drake cache at ",
    shQuote(path),
    "? (Prompt shown once per session.)",
    sep = "\n"
  )
  response <- utils::menu(choices = c("yes", "no"), title = title)
  .pkg_envir[["drake_clean_menu"]] <- FALSE
  !identical(as.integer(response), 1L)
  # nocov end
}
