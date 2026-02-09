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
#' @param use_compiled_kernel Logical; when `TRUE`, optional compiled helper
#'   kernels are used where available. Falls back to pure R automatically.
#' @return Updated plants data.frame after one day.
transport_resistance <- function(plants, conditions, day_index, use_compiled_kernel = FALSE) {
  n <- nrow(plants)
  if (n == 0L) return(plants)
  plants_before <- plants

  # Fetch drivers
  di <- ((day_index - 1L) %% nrow(conditions)) + 1L
  temp <- conditions$temp_mean[di]
  sw <- conditions$sw[di]
  N_avail <- conditions$N[di]

  # Forcing calculations
  SW_forced <- calc_SWforcer(sw, 0.15, 0.6)
  At_forced <- trap2(
    temp,
    CONSTANTS$TEMP_PHOTO_1,
    CONSTANTS$TEMP_PHOTO_2,
    CONSTANTS$TEMP_PHOTO_3,
    CONSTANTS$TEMP_PHOTO_4
  )
  K_C_forced <- CONSTANTS$K_C * min(SW_forced, At_forced)
  growth_env <- min(
    trap2(
      temp,
      CONSTANTS$TEMP_GROWTH_1,
      CONSTANTS$TEMP_GROWTH_2,
      CONSTANTS$TEMP_GROWTH_3,
      CONSTANTS$TEMP_GROWTH_4
    ),
    SW_forced
  )
  g_forced_shoot <- CONSTANTS$G_SHOOT * growth_env
  g_forced_root <- CONSTANTS$G_ROOT * growth_env
  g_forced_def <- CONSTANTS$G_DEFENCE * growth_env
  K_N_forced <- monod(N_avail, 0.1) * CONSTANTS$K_N

  # Helper for litter loss with guard
  litter_loss <- function(rate, mass) {
    if (!is.finite(mass) || mass <= 0) return(0)
    (rate * mass) / (1 + CONSTANTS$K_M_LITTER / mass)
  }

  defence_enabled <- isTRUE(CONSTANTS$DEFENCE_ENABLED)

  column_or_default <- function(name, default = 0) {
    if (name %in% names(plants)) {
      as.numeric(plants[[name]])
    } else {
      rep(default, n)
    }
  }

  # Copy state columns into vectors and mutate there to avoid repeated
  # data.frame subassignment overhead in the hot loop.
  ms <- column_or_default("ms")
  mr <- column_or_default("mr")
  cs <- column_or_default("cs")
  cr <- column_or_default("cr")
  ns <- column_or_default("ns")
  nr <- column_or_default("nr")
  md <- column_or_default("md")
  cd <- column_or_default("cd")
  nd <- column_or_default("nd")
  bleaf <- column_or_default("bleaf")
  bstem <- column_or_default("bstem")
  bdef <- column_or_default("bdef")
  brepr <- column_or_default("brepr")
  broot <- column_or_default("broot")
  veg_type <- if ("veg_type" %in% names(plants)) as.integer(plants$veg_type) else rep(0L, n)

  resistance_kernel <- compute_ttr_resistances_kernel_v1(
    ms = ms,
    mr = mr,
    tr_c = CONSTANTS$TR_C,
    tr_n = CONSTANTS$TR_N,
    q_scp = CONSTANTS$Q_SCP,
    q_snp = CONSTANTS$Q_SCP,
    use_compiled = use_compiled_kernel
  )
  rsC <- as.numeric(resistance_kernel$rsC)
  rrC <- as.numeric(resistance_kernel$rrC)
  rsN <- as.numeric(resistance_kernel$rsN)
  rrN <- as.numeric(resistance_kernel$rrN)
  rdC <- column_or_default("rdC")
  rdN <- column_or_default("rdN")
  tauC <- column_or_default("tauC")
  tauN <- column_or_default("tauN")
  tauCd <- column_or_default("tauCd")
  tauNd <- column_or_default("tauNd")
  uc <- column_or_default("uc")
  un <- column_or_default("un")
  gs <- column_or_default("gs")
  gr <- column_or_default("gr")
  gd <- column_or_default("gd")

  cap <- 0.05 # <=5% of current mass per day

  for (i in seq_len(n)) {
    ms_i <- ms[[i]]
    mr_i <- mr[[i]]
    cs_i <- cs[[i]]
    cr_i <- cr[[i]]
    ns_i <- ns[[i]]
    nr_i <- nr[[i]]
    md_i <- md[[i]]
    cd_i <- cd[[i]]
    nd_i <- nd[[i]]
    bleaf_i <- bleaf[[i]]
    bstem_i <- bstem[[i]]
    bdef_i <- bdef[[i]]
    brepr_i <- brepr[[i]]

    # Resistances
    rsC_i <- rsC[[i]]
    rrC_i <- rrC[[i]]
    rsN_i <- rsN[[i]]
    rrN_i <- rrN[[i]]
    if (defence_enabled) {
      rdC_i <- calc_RdC(CONSTANTS$TR_C, md_i, CONSTANTS$Q_SCP)
      rdN_i <- calc_RdN(CONSTANTS$TR_N, md_i, CONSTANTS$Q_SCP)
    } else {
      rdC_i <- 0
      rdN_i <- 0
    }

    # Transport
    tauC_i <- calc_tauC(list(ms = ms_i, mr = mr_i, cs = cs_i, cr = cr_i, rsC = rsC_i, rrC = rrC_i))
    tauN_i <- calc_tauN(list(ms = ms_i, mr = mr_i, ns = ns_i, nr = nr_i, rsN = rsN_i, rrN = rrN_i))
    if (defence_enabled) {
      tauCd_i <- calc_tauCd(list(ms = ms_i, md = md_i, cs = cs_i, cd = cd_i, rsC = rsC_i, rdC = rdC_i))
      tauNd_i <- calc_tauNd(list(mr = mr_i, md = md_i, nr = nr_i, nd = nd_i, rdN = rdN_i, rrN = rrN_i))
    } else {
      tauCd_i <- 0
      tauNd_i <- 0
    }

    # Uptake
    denom <- bstem_i + bleaf_i
    CLeaf <- if (!is.finite(denom) || denom <= 0) 0 else cs_i * bleaf_i / denom
    uc_i <- calc_UC(list(ms = ms_i, cs = cs_i), CLeaf, K_C_forced, CONSTANTS$K_M, CONSTANTS$PI_C)
    un_i <- calc_UN(list(mr = mr_i, nr = nr_i), K_N_forced, CONSTANTS$K_M, CONSTANTS$PI_N)

    # Growth
    gs_i <- calc_Gs(list(ms = ms_i, cs = cs_i, ns = ns_i), g_forced_shoot)
    gr_i <- calc_Gr(list(mr = mr_i, cr = cr_i, nr = nr_i), g_forced_root)
    gs_i <- pmin(gs_i, cap * ms_i)
    gr_i <- pmin(gr_i, cap * mr_i)
    gd_i <- if (defence_enabled) calc_Gd(list(md = md_i, cd = cd_i, nd = nd_i), g_forced_def) else 0

    # Litter losses
    loss_root <- CONSTANTS$K_LITTER
    loss_leaf <- CONSTANTS$K_LITTER * CONSTANTS$ACCEL_LEAF_LOSS
    if (temp > CONSTANTS$PHENO_SWITCH) loss_leaf <- CONSTANTS$K_LITTER
    loss_stem <- CONSTANTS$K_LITTER * 0.02
    loss_def <- loss_leaf

    Mr_loss <- litter_loss(loss_root, mr_i)
    MLeaf_loss <- litter_loss(loss_leaf, bleaf_i)
    MStem_loss <- litter_loss(loss_stem, bstem_i)
    MDef_loss <- litter_loss(loss_def, bdef_i)

    # ODE RHS updates for pools
    dCs <- calc_dCs_dt(list(uc = uc_i, gs = gs_i, tauC = tauC_i, tauCd = tauCd_i), CONSTANTS$FRACTION_C)
    dCr <- calc_dCr_dt(list(tauC = tauC_i, gr = gr_i), CONSTANTS$FRACTION_C)
    dNs <- calc_dNs_dt(list(tauN = tauN_i, gs = gs_i), CONSTANTS$FRACTION_N)
    dNr <- calc_dNr_dt(list(un = un_i, gr = gr_i, tauN = tauN_i, tauNd = tauNd_i), CONSTANTS$FRACTION_N)
    dCd <- if (defence_enabled) calc_dCd_dt(list(tauCd = tauCd_i, gd = gd_i), CONSTANTS$FRACTION_C) else 0
    dNd <- if (defence_enabled) calc_dNd_dt(list(tauNd = tauNd_i, gd = gd_i), CONSTANTS$FRACTION_N) else 0

    # Update structural masses
    mr_new <- mr_i + gr_i - Mr_loss

    # Update C/N pools
    cs_new <- cs_i + dCs
    cr_new <- cr_i + dCr
    ns_new <- ns_i + dNs
    nr_new <- nr_i + dNr
    cd_new <- if (defence_enabled) cd_i + dCd else 0
    nd_new <- if (defence_enabled) nd_i + dNd else 0

    # Allocation: reproduction and stems for trees (veg_type == 2)
    prop_to_repr <- trap1(ms_i, 0.5, 10) * 0.01
    prop_to_stem <- 0
    if (!is.na(veg_type[[i]]) && veg_type[[i]] == 2L) {
      lai_index <- if (!is.finite(bstem_i) || bstem_i <= 0) Inf else bleaf_i / bstem_i
      prop_to_stem <- trap1(lai_index, 0.25, 5.0) * (1.0 - prop_to_repr)
    }

    bleaf_new <- bleaf_i + (1.0 - prop_to_stem) * gs_i - MLeaf_loss
    bstem_new <- bstem_i + prop_to_stem * gs_i - MStem_loss
    prop_to_def <- CONSTANTS$TTR_DEFENCE_ALLOCATION_PROP
    bdef_new <- bdef_i + prop_to_def * gs_i - MDef_loss
    brepr_new <- 0 * brepr_i + prop_to_repr * gs_i
    broot_new <- mr_new
    md_new <- bdef_new

    # Recalculate shoot mass from components
    ms_new <- bleaf_new + bstem_new + bdef_new

    # Clamp to non-negative and assign back to vectors
    rsC[[i]] <- rsC_i
    rrC[[i]] <- rrC_i
    rdC[[i]] <- rdC_i
    rsN[[i]] <- rsN_i
    rrN[[i]] <- rrN_i
    rdN[[i]] <- rdN_i
    tauC[[i]] <- tauC_i
    tauN[[i]] <- tauN_i
    tauCd[[i]] <- tauCd_i
    tauNd[[i]] <- tauNd_i
    uc[[i]] <- uc_i
    un[[i]] <- un_i
    gs[[i]] <- gs_i
    gr[[i]] <- gr_i
    gd[[i]] <- gd_i

    ms[[i]] <- pmax(ms_new, 0)
    mr[[i]] <- pmax(mr_new, 0)
    cs[[i]] <- pmax(cs_new, 0)
    cr[[i]] <- pmax(cr_new, 0)
    ns[[i]] <- pmax(ns_new, 0)
    nr[[i]] <- pmax(nr_new, 0)
    cd[[i]] <- pmax(cd_new, 0)
    nd[[i]] <- pmax(nd_new, 0)
    bleaf[[i]] <- pmax(bleaf_new, 0)
    bstem[[i]] <- pmax(bstem_new, 0)
    bdef[[i]] <- pmax(bdef_new, 0)
    md[[i]] <- pmax(md_new, 0)
    brepr[[i]] <- pmax(brepr_new, 0)
    broot[[i]] <- pmax(broot_new, 0)
  }

  plants$rsC <- rsC
  plants$rrC <- rrC
  plants$rdC <- rdC
  plants$rsN <- rsN
  plants$rrN <- rrN
  plants$rdN <- rdN
  plants$tauC <- tauC
  plants$tauN <- tauN
  plants$tauCd <- tauCd
  plants$tauNd <- tauNd
  plants$uc <- uc
  plants$un <- un
  plants$gs <- gs
  plants$gr <- gr
  plants$gd <- gd
  plants$ms <- ms
  plants$mr <- mr
  plants$cs <- cs
  plants$cr <- cr
  plants$ns <- ns
  plants$nr <- nr
  plants$cd <- cd
  plants$nd <- nd
  plants$bleaf <- bleaf
  plants$bstem <- bstem
  plants$bdef <- bdef
  plants$md <- md
  plants$brepr <- brepr
  plants$broot <- broot

  assert_ttr_guardrails(
    plants = plants,
    plants_previous = plants_before,
    day_of_simulation = day_index,
    phase = "ttr_daily"
  )

  plants
}
