% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/database_globals.R
\name{AZASRS_DATABASE_CONNECTION}
\alias{AZASRS_DATABASE_CONNECTION}
\title{Opens a database connection}
\usage{
AZASRS_DATABASE_CONNECTION()
}
\description{
Uses AZASRS_DATABASE_LOCATION and should only be used with tbl_ functions. Allows for chaining of tbl_ functions to optimize SQL queries. Must close connection after usage. You must have .Renviron on your computer in the directory found by executing normalizePath('~/') in your console. Environment variables in there will allow you to connect to the database.
}
\examples{
con = AZASRS_DATABASE_CONNECTION()
data = tbl_pm_fund_nav_daily(con) \%>\%
       left_join(tbl_pm_fund_info(con), by = 'pm_fund_id') \%>\%
       as_tibble()
AZASRS_DATABASE_DISCONNECT(con)
}
