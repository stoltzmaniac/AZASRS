
#' Query account info table from database
#'
#' @param ... are for filtering the tables, can take values: category, portfolio, asset_class, sub_portfolio, previous_saa, sponsor, saa_benchmark, imp_benchmark, ticker, city
#' @return Returns a tibble of all of the data
#' @examples
#' get_account_info(asset_class == 'Equities', category == 'Large')
#' @export
get_account_info = function(...){

  args = rlang::enexprs(...)

  dat = account_info()

  if(length(args) > 0){
    dat = dat %>%
      dplyr::filter(!!! args)
  }

  return(dat %>% tibble::as_tibble())
}