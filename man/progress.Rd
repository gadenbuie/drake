% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/api-progress.R
\name{progress}
\alias{progress}
\title{Get the build progress of your targets
during a \code{\link[=make]{make()}}.}
\usage{
progress(..., list = character(0), no_imported_objects = NULL,
  path = NULL, search = NULL, cache = drake::drake_cache(path = path,
  verbose = verbose), verbose = 1L, jobs = 1, progress = NULL)
}
\arguments{
\item{...}{Objects to load from the cache, as names (unquoted)
or character strings (quoted). Similar to \code{...} in
\code{remove()} and \code{rm()}.}

\item{list}{Character vector naming objects to be loaded from the
cache. Similar to the \code{list} argument of \code{\link[=remove]{remove()}}.}

\item{no_imported_objects}{Logical, whether to only return information
about imported files and targets with commands (i.e. whether to ignore
imported objects that are not files).}

\item{path}{Path to a \code{drake} cache
(usually a hidden \code{.drake/} folder) or \code{NULL}.}

\item{search}{Deprecated.}

\item{cache}{drake cache. See \code{\link[=new_cache]{new_cache()}}.
If supplied, \code{path} is ignored.}

\item{verbose}{Integer, control printing to the console/terminal.
\itemize{
\item \code{0}: print nothing.
\item \code{1}: print targets, retries, and failures.
\item \code{2}: also show a spinner when preprocessing tasks are underway.
}}

\item{jobs}{Number of jobs/workers for parallel processing.}

\item{progress}{Character vector for filtering the build progress results.
Defaults to \code{NULL} (no filtering) to report progress of all objects.
Supported filters are \code{"done"}, \code{"running"}, \code{"failed"} and \code{"none"}.}
}
\value{
The build progress of each target reached by
the current \code{\link[=make]{make()}} so far.
}
\description{
Objects that drake imported, built, or attempted
to build are listed as \code{"done"} or \code{"running"}.
Skipped objects are not listed.
}
\examples{
\dontrun{
isolate_example("Quarantine side effects.", {
if (suppressWarnings(require("knitr"))) {
load_mtcars_example() # Get the code with drake_example("mtcars").
make(my_plan) # Run the project, build the targets.
# Watch the changing progress() as make() is running.
progress() # List all the targets reached so far.
progress(small, large) # Just see the progress of some targets.
progress(list = c("small", "large")) # Same as above.
progress(no_imported_objects = TRUE) # Ignore imported R objects.
}
})
}
}
\seealso{
\code{\link[=diagnose]{diagnose()}}, \code{\link[=drake_get_session_info]{drake_get_session_info()}},
\code{\link[=cached]{cached()}}, \code{\link[=readd]{readd()}}, \code{\link[=drake_plan]{drake_plan()}}, \code{\link[=make]{make()}}
}
