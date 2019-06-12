#' @export
calc_tvpi = function(distributions, contributions, nav){
  dat = sum(distributions + nav) / sum(abs(contributions))
  return(dat)
}

#' @export
calc_dpi = function(distributions, contributions){
  dat = sum(abs(distributions)) / sum(abs(contributions))
  return(dat)
}

#' @export
calc_appreciation = function(nav, cash_flow){
  dat = sum(nav) - sum(cash_flow)
  return(dat)
}

#' @export
calc_pme = function(distributions, contributions, fv_index_factors, nav){
  total_fv_distributions = sum((distributions * fv_index_factors) + nav)
  total_fv_contributions = sum(contributions * fv_index_factors)
  pme = total_fv_distributions / total_fv_contributions
  return(pme)
}


#' @export
calc_tvpi_df = function(cash_flow, nav, grouping_var = pm_fund_id){

  grouping_var = dplyr::enquo(grouping_var)

  dat_nav = nav %>%
    group_by(pm_fund_id) %>%
    filter(effective_date == max(effective_date))
  dat = cash_flow %>%
    dplyr::filter(effective_date <= max(dat_nav$effective_date)) %>%
    dplyr::group_by(!! grouping_var) %>%
    summarize(contributions = sum(contributions), distributions = sum(distributions)) %>%
    dplyr::left_join(dat_nav, by = glue::glue('{grouping_var}_id')) %>%
    dplyr::group_by(!! grouping_var) %>%
    dplyr::summarize(tvpi = calc_tvpi(distributions, contributions, nav) )
  return(dat)
  }


#' @export
calc_lastinvec_df = function(cash_flow, grouping_var = pm_fund_id){

  grouping_var = dplyr::enquo(grouping_var)

  dat = cash_flow %>%
    dplyr::group_by(!! grouping_var) %>%
    dplyr::summarize(lastinvec = asrsMethods::irr.z(cash_flow, gips=TRUE))
  return(dat)
}


#' @export
calc_dpi_df = function(cash_flow, grouping_var = pm_fund_id){

  grouping_var = dplyr::enquo(grouping_var)

  dat = cash_flow %>%
    dplyr::mutate(distributions = dplyr::if_else(cash_flow > 0, abs(cash_flow), 0),
           contributions = dplyr::if_else(cash_flow < 0, abs(cash_flow), 0)) %>%
    dplyr::group_by(!! grouping_var) %>%
    dplyr::summarize(dpi = sum(distributions) / sum(contributions))
  return(dat)
}


#' @export
calc_appreciation_df = function(cash_flow, nav, valdate, grouping_var = pm_fund_id){

  grouping_var = dplyr::enquo(grouping_var)

  dat_nav = nav %>%
    dplyr::filter(effective_date == valdate)

  dat_cf = cash_flow %>%
    dplyr::filter(effective_date >= valdate) %>%
    dplyr::group_by(!! grouping_var) %>%
    dplyr::summarize(cash_flow = sum(cash_flow))

  dat = dat_cf %>%
    dplyr::left_join(dat_nav, by = glue::glue('{grouping_var}_id')) %>%
    dplyr::mutate(appreciation = nav - cash_flow)

  return(dat)
}


#' @export
calc_benchmark_daily_index_df = function(benchmark_daily_index){
  latest_benchmark_daily_index = benchmark_daily_index %>%
    dplyr::group_by(benchmark_id) %>%
    dplyr::summarize(effective_date = max(effective_date)) %>%
    dplyr::left_join(benchmark_daily_index, by = c('benchmark_id', 'effective_date')) %>%
    dplyr::rename(latest_daily_index = index_value) %>%
    dplyr::select(benchmark_id, latest_daily_index)

  final_benchmark_daily_index = benchmark_daily_index %>%
    dplyr::left_join(latest_benchmark_daily_index, by = 'benchmark_id') %>%
    dplyr::mutate(final_daily_index = latest_daily_index / index_value)

  return(final_benchmark_daily_index)
}


#' @export
calc_pme_df = function(cash_flow, nav, benchmark_daily_index, valdate, pmfi){

  nav_filtered = nav %>%
    dplyr::mutate(effective_date = as.Date(effective_date, format = '%Y-%m-%d')) %>%
    dplyr::filter(effective_date == valdate) %>%
    dplyr::group_by(pm_fund_id) %>%
    dplyr::summarize(nav = max(nav))

  cash_flow_mod = cash_flow %>%
    dplyr::mutate(distributions = dplyr::if_else(cash_flow > 0, abs(cash_flow), 0),
           contributions = dplyr::if_else(cash_flow < 0, abs(cash_flow), 0)) %>%
    dplyr::mutate(effective_date = as.Date(effective_date, format = '%Y-%m-%d')) %>%
    dplyr::left_join(pmfi, by = 'pm_fund_id') %>%
    dplyr::left_join(bench_index, by = c('benchmark_id'='benchmark_id', 'effective_date'='effective_date'))

  pme = cash_flow_mod %>%
    dplyr::group_by(pm_fund_id) %>%
    dplyr::summarize(dist_no_nav = sum(distributions*final_daily_index),
              contrib = sum(contributions*final_daily_index)) %>%
    dplyr::left_join(nav_filtered, by = 'pm_fund_id') %>%
    dplyr::mutate(pme = (dist_no_nav + nav)/contrib)

  return(pme)
}
