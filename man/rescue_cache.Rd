% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/api-clean.R
\name{rescue_cache}
\alias{rescue_cache}
\title{Try to repair a drake cache that is prone
to throwing \code{storr}-related errors.}
\usage{
rescue_cache(targets = NULL, path = NULL, search = NULL,
  verbose = 1L, force = FALSE, cache = drake::drake_cache(path =
  path, verbose = verbose), jobs = 1, garbage_collection = FALSE)
}
\arguments{
\item{targets}{Character vector, names of the targets to rescue.
As with many other drake utility functions, the word \code{target}
is defined generally in this case, encompassing imports
as well as true targets.
If \code{targets} is \code{NULL}, everything in the
cache is rescued.}

\item{path}{Character.
Set \code{path} to the path of a \code{storr::storr_rds()} cache
to retrieve a specific cache generated by \code{storr::storr_rds()}
or \code{drake::new_cache()}. If the \code{path} argument is \code{NULL},
\code{drake_cache()} searches up through parent directories
to find a folder called \code{.drake/}.}

\item{search}{Deprecated.}

\item{verbose}{Integer, control printing to the console/terminal.
\itemize{
\item \code{0}: print nothing.
\item \code{1}: print targets, retries, and failures.
\item \code{2}: also show a spinner when preprocessing tasks are underway.
}}

\item{force}{Deprecated.}

\item{cache}{A \code{storr} cache object.}

\item{jobs}{Number of jobs for light parallelism
(disabled on Windows).}

\item{garbage_collection}{Logical, whether to do garbage collection
as a final step. See \code{\link[=drake_gc]{drake_gc()}} and \code{\link[=clean]{clean()}}
for details.}
}
\value{
Nothing.
}
\description{
Sometimes, \code{storr} caches may have
dangling orphaned files that prevent you from loading or cleaning.
This function tries to remove those files so you can use the
cache normally again.
}
\examples{
\dontrun{
isolate_example("Quarantine side effects.", {
if (suppressWarnings(require("knitr"))) {
load_mtcars_example() # Get the code with drake_example("mtcars").
make(my_plan) # Run the project, build targets. This creates the cache.
# Remove dangling cache files that could cause errors.
rescue_cache(jobs = 2)
# Alternatively, just rescue targets 'small' and 'large'.
# Rescuing specific targets is usually faster.
rescue_cache(targets = c("small", "large"))
}
})
}
}
\seealso{
\code{\link[=drake_cache]{drake_cache()}}, \code{\link[=cached]{cached()}},
\code{\link[=drake_gc]{drake_gc()}}, \code{\link[=clean]{clean()}}
}
