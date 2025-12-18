#' Advance digestion by one hour
#'
#' Shifts gut content through hourly compartments, accumulates digestible
#' carbohydrate and protein energy, and accounts for metabolic water
#' production.
#'
#' @param herbivore Herbivore state list containing `MRT` and `digestion`
#'   vectors (`bleaf`, `bstem`, `bdef`, `dc_leaf`, `dc_stem`, `dp_leaf`,
#'   `dp_stem`, `dp_def`).
#' @return Updated `herbivore` list with intake and water fields increased.
#' @examples
#' # herbivore <- hourly_digestion_step(herbivore)
#' @export
hourly_digestion_step <- function(herbivore) {
  k <- as.integer(herbivore$MRT)  # digestion age index
  normalize_queue <- function(v, k) {
    v <- as.numeric(v)
    if (length(v) < k) v <- c(v, rep(0, k - length(v)))
    if (length(v) > k) v <- v[seq_len(k)]
    v[is.na(v)] <- 0
    v
  }

  # 1) release
  herbivore$digestion$bleaf   <- normalize_queue(herbivore$digestion$bleaf,   k)
  herbivore$digestion$bstem   <- normalize_queue(herbivore$digestion$bstem,   k)
  herbivore$digestion$bdef    <- normalize_queue(herbivore$digestion$bdef,    k)
  herbivore$digestion$dc_leaf <- normalize_queue(herbivore$digestion$dc_leaf, k)
  herbivore$digestion$dc_stem <- normalize_queue(herbivore$digestion$dc_stem, k)
  herbivore$digestion$dp_leaf <- normalize_queue(herbivore$digestion$dp_leaf, k)
  herbivore$digestion$dp_stem <- normalize_queue(herbivore$digestion$dp_stem, k)
  herbivore$digestion$dp_def  <- normalize_queue(herbivore$digestion$dp_def,  k)

  digested_carbs <- herbivore$digestion$dc_leaf[k] + herbivore$digestion$dc_stem[k]
  digested_prot  <- herbivore$digestion$dp_leaf[k] + herbivore$digestion$dp_stem[k] + herbivore$digestion$dp_def[k]

  herbivore$intake_digest_carbs_day   <- herbivore$intake_digest_carbs_day + digested_carbs
  herbivore$intake_digest_protein_day <- herbivore$intake_digest_protein_day + digested_prot
  herbivore$intake_NPE_day <- herbivore$intake_NPE_day + digested_carbs * CONSTANTS$CARB_TO_ENERGY
  herbivore$intake_PE_day  <- herbivore$intake_PE_day  + digested_prot  * CONSTANTS$PROTEIN_TO_ENERGY
  herbivore$metabolic_water_day <- herbivore$metabolic_water_day +
    CONSTANTS$CARB_TO_MW * digested_carbs + CONSTANTS$PROTEIN_TO_MW * digested_prot

  # 2) shift by one hour (drop the released slot k; prepend 0)
  shift_k <- function(v, k) c(0, normalize_queue(v, k)[seq_len(k - 1)])
  herbivore$digestion$bleaf   <- shift_k(herbivore$digestion$bleaf,   k)
  herbivore$digestion$bstem   <- shift_k(herbivore$digestion$bstem,   k)
  herbivore$digestion$bdef    <- shift_k(herbivore$digestion$bdef,    k)
  herbivore$digestion$dc_leaf <- shift_k(herbivore$digestion$dc_leaf, k)
  herbivore$digestion$dc_stem <- shift_k(herbivore$digestion$dc_stem, k)
  herbivore$digestion$dp_leaf <- shift_k(herbivore$digestion$dp_leaf, k)
  herbivore$digestion$dp_stem <- shift_k(herbivore$digestion$dp_stem, k)
  herbivore$digestion$dp_def  <- shift_k(herbivore$digestion$dp_def,  k)

  herbivore
}

set_herbivore_MRT <- function(h, MRT) {
  MRT <- as.integer(MRT)
  zeros <- function() numeric(MRT)
  h$MRT <- MRT
  h$digestion$bleaf   <- zeros()
  h$digestion$bstem   <- zeros()
  h$digestion$bdef    <- zeros()
  h$digestion$dc_leaf <- zeros()
  h$digestion$dc_stem <- zeros()
  h$digestion$dp_leaf <- zeros()
  h$digestion$dp_stem <- zeros()
  h$digestion$dp_def  <- zeros()
  h
}
