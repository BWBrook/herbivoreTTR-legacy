#' Thornley Transport Resistance orchestrator
#'
#' Performs a single-day TTR update for each plant row.
#'
#' @param plants data.frame of plant state. Expected columns include (lowercase):
#'   `ms`, `mr`, `cs`, `cr`, `ns`, `nr`, optional `md`, `cd`, `nd`, and flux/state
#'   columns such as `uc`, `un`, `rsC`, `rrC`, `rdC`, `rsN`, `rrN`, `rdN`,
#'   `tauC`, `tauN`, `tauCd`, `tauNd`, `gs`, `gr`, `gd`, `bleaf`, `bstem`, `bdef`,
#'   `brepr`, `broot`, `height`, `veg_type`.
#' @param conditions data.frame of daily environmental drivers with columns
#'   `temp_mean`, `sw`, `N`.
#' @param day_index integer index into `conditions`.
#' @return Updated plants data.frame after one day.
transport_resistance <- function(plants, conditions, day_index) {
  n <- nrow(plants)
  if (n == 0L) return(plants)
  plants_before <- plants

  # Fetch drivers
  di <- ((day_index - 1L) %% nrow(conditions)) + 1L
  temp <- conditions$temp_mean[di]
  sw   <- conditions$sw[di]
  N_avail <- conditions$N[di]

  # Forcing calculations
  SW_forced <- calc_SWforcer(sw, 0.15, 0.6)
  At_forced <- trap2(temp, CONSTANTS$TEMP_PHOTO_1, CONSTANTS$TEMP_PHOTO_2,
                     CONSTANTS$TEMP_PHOTO_3, CONSTANTS$TEMP_PHOTO_4)
  K_C_forced <- CONSTANTS$K_C * min(SW_forced, At_forced)
  growth_env <- min(trap2(temp, CONSTANTS$TEMP_GROWTH_1, CONSTANTS$TEMP_GROWTH_2,
                          CONSTANTS$TEMP_GROWTH_3, CONSTANTS$TEMP_GROWTH_4),
                    SW_forced)
  g_forced_shoot <- CONSTANTS$G_SHOOT   * growth_env
  g_forced_root  <- CONSTANTS$G_ROOT    * growth_env
  g_forced_def   <- CONSTANTS$G_DEFENCE * growth_env
  K_N_forced <- monod(N_avail, 0.1) * CONSTANTS$K_N

  # Helper for litter loss with guard
  litter_loss <- function(rate, mass) {
    if (!is.finite(mass) || mass <= 0) return(0)
    (rate * mass) / (1 + CONSTANTS$K_M_LITTER / mass)
  }

  for (i in seq_len(n)) {
    pr <- as.list(plants[i, , drop = FALSE])

    # Resistances (defence terms optional; keep zero unless present)
    plants$rsC[i] <- calc_RsC(CONSTANTS$TR_C, pr$ms, CONSTANTS$Q_SCP)
    plants$rrC[i] <- calc_RrC(CONSTANTS$TR_C, pr$mr, CONSTANTS$Q_SCP)
    plants$rsN[i] <- calc_RsN(CONSTANTS$TR_N, pr$ms, CONSTANTS$Q_SCP)
    plants$rrN[i] <- calc_RrN(CONSTANTS$TR_N, pr$mr, CONSTANTS$Q_SCP)
    if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) {
      md_val <- if (is.null(pr$md)) 0 else pr$md
      plants$rdC[i] <- calc_RdC(CONSTANTS$TR_C, md_val, CONSTANTS$Q_SCP)
      plants$rdN[i] <- calc_RdN(CONSTANTS$TR_N, md_val, CONSTANTS$Q_SCP)
    } else {
      plants$rdC[i] <- 0
      plants$rdN[i] <- 0
    }

    # Transport (defence disabled to mirror C++)
    pr$rsC <- plants$rsC[i]; pr$rrC <- plants$rrC[i]
    pr$rsN <- plants$rsN[i]; pr$rrN <- plants$rrN[i]
    plants$tauC[i] <- calc_tauC(pr)
    plants$tauN[i] <- calc_tauN(pr)
    if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) {
      pr$rdC <- plants$rdC[i]
      pr$rdN <- plants$rdN[i]
      plants$tauCd[i] <- calc_tauCd(pr)
      plants$tauNd[i] <- calc_tauNd(pr)
    } else {
      plants$tauCd[i] <- 0
      plants$tauNd[i] <- 0
    }

    # Uptake
    denom <- pr$bstem + pr$bleaf
    CLeaf <- if (!is.finite(denom) || denom <= 0) 0 else pr$cs * pr$bleaf / denom
    pr$cs <- pr$cs; pr$ms <- pr$ms
    plants$uc[i] <- calc_UC(pr, CLeaf, K_C_forced, CONSTANTS$K_M, CONSTANTS$PI_C)
    plants$un[i] <- calc_UN(pr, K_N_forced, CONSTANTS$K_M, CONSTANTS$PI_N)

    # Growth
    plants$gs[i] <- calc_Gs(pr, g_forced_shoot)
    plants$gr[i] <- calc_Gr(pr, g_forced_root)

    # Sanity stabiliser: remove once parameter fits confirmed
    cap <- 0.05  # ≤5% of current mass per day
    plants$gs[i] <- pmin(plants$gs[i], cap * pr$ms)
    plants$gr[i] <- pmin(plants$gr[i], cap * pr$mr)

    plants$gd[i] <- if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) calc_Gd(pr, g_forced_def) else 0

    # Litter losses
    loss_root <- CONSTANTS$K_LITTER
    loss_leaf <- CONSTANTS$K_LITTER * CONSTANTS$ACCEL_LEAF_LOSS
    if (temp > CONSTANTS$PHENO_SWITCH) loss_leaf <- CONSTANTS$K_LITTER
    loss_stem <- CONSTANTS$K_LITTER * 0.02
    loss_def  <- loss_leaf

    Mr_loss    <- litter_loss(loss_root, pr$mr)
    MLeaf_loss <- litter_loss(loss_leaf, pr$bleaf)
    MStem_loss <- litter_loss(loss_stem, pr$bstem)
    MDef_loss  <- litter_loss(loss_def,  pr$bdef)

    # ODE RHS updates for pools
    pr$uc <- plants$uc[i]; pr$un <- plants$un[i]
    pr$tauC <- plants$tauC[i]; pr$tauN <- plants$tauN[i]
    pr$tauCd <- plants$tauCd[i]; pr$tauNd <- plants$tauNd[i]
    pr$gs <- plants$gs[i]; pr$gr <- plants$gr[i]; pr$gd <- plants$gd[i]

    dCs <- calc_dCs_dt(pr, CONSTANTS$FRACTION_C)
    dCr <- calc_dCr_dt(pr, CONSTANTS$FRACTION_C)
    dNs <- calc_dNs_dt(pr, CONSTANTS$FRACTION_N)
    dNr <- calc_dNr_dt(pr, CONSTANTS$FRACTION_N)
    dCd <- if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) calc_dCd_dt(pr, CONSTANTS$FRACTION_C) else 0
    dNd <- if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) calc_dNd_dt(pr, CONSTANTS$FRACTION_N) else 0

    # Update structural masses
    ms_new <- pr$ms + plants$gs[i] - MLeaf_loss - MStem_loss
    mr_new <- pr$mr + plants$gr[i] - Mr_loss

    # Update C/N pools
    cs_new <- pr$cs + dCs
    cr_new <- pr$cr + dCr
    ns_new <- pr$ns + dNs
    nr_new <- pr$nr + dNr
    cd_new <- if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) pr$cd + dCd else 0
    nd_new <- if (isTRUE(CONSTANTS$DEFENCE_ENABLED)) pr$nd + dNd else 0

    # Allocation: reproduction and stems for trees (veg_type == 2)
    prop_to_repr <- trap1(pr$ms, 0.5, 10) * 0.01
    prop_to_stem <- 0
    if (!is.null(pr$veg_type) && pr$veg_type == 2) {
      lai_index <- if (!is.finite(pr$bstem) || pr$bstem <= 0) Inf else pr$bleaf / pr$bstem
      prop_to_stem <- 1 * trap1(lai_index, 0.25, 5.0) * (1.0 - prop_to_repr)
    }

    bleaf_new <- pr$bleaf + (1.0 - prop_to_stem) * plants$gs[i] - MLeaf_loss
    bstem_new <- pr$bstem + prop_to_stem * plants$gs[i] - MStem_loss
    prop_to_def <- CONSTANTS$TTR_DEFENCE_ALLOCATION_PROP
    bdef_new  <- pr$bdef + prop_to_def * plants$gs[i] - MDef_loss
    brepr_new <- 0 * pr$brepr + prop_to_repr * plants$gs[i]
    broot_new <- mr_new
    md_new <- bdef_new

    # Recalculate ms from components
    ms_new2 <- bleaf_new + bstem_new + bdef_new

    # Clamp to non-negative and assign back
    plants$ms[i]    <- pmax(ms_new2, 0)
    plants$mr[i]    <- pmax(mr_new, 0)
    plants$cs[i]    <- pmax(cs_new, 0)
    plants$cr[i]    <- pmax(cr_new, 0)
    plants$ns[i]    <- pmax(ns_new, 0)
    plants$nr[i]    <- pmax(nr_new, 0)
    plants$cd[i]    <- pmax(cd_new, 0)
    plants$nd[i]    <- pmax(nd_new, 0)
    plants$bleaf[i] <- pmax(bleaf_new, 0)
    plants$bstem[i] <- pmax(bstem_new, 0)
    plants$bdef[i]  <- pmax(bdef_new, 0)
    plants$md[i]    <- pmax(md_new, 0)
    plants$brepr[i] <- pmax(brepr_new, 0)
    plants$broot[i] <- pmax(broot_new, 0)
  }

  assert_ttr_guardrails(
    plants = plants,
    plants_previous = plants_before,
    day_of_simulation = day_index,
    phase = "ttr_daily"
  )

  plants
}
