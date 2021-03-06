% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-deprecate.R
\name{built}
\alias{built}
\title{Deprecated. List all the built targets (non-imports) in the cache.}
\usage{
built(path = getwd(), search = TRUE, cache = drake::get_cache(path =
  path, search = search, verbose = verbose), verbose = 1L, jobs = 1)
}
\arguments{
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
}
\value{
Character vector naming the built targets in the cache.
}
\description{
Deprecated on 2019-01-08.
}
\details{
Targets are listed in the workflow plan
data frame (see \code{\link[=drake_plan]{drake_plan()}}.
}
\seealso{
\code{\link[=cached]{cached()}}, \code{\link[=loadd]{loadd()}}
}
\keyword{internal}
