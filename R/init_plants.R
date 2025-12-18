#' Initialise plant grid and traits
#'
#' Lays out plants on a rectangular grid, assigns vegetation types, biomass
#' pools, and initial fluxes/transport parameters.
#'
#' @param veg_types Integer vector of vegetation types to include (0=C3 grass,
#'   1=C4 grass, 2=tree/shrub).
#' @return data.frame of plants with identifiers, coordinates, biomass pools,
#'   and state/flux columns used by the TTR model.
#' @examples
#' plants <- init_plants()
#' head(plants)
#' @export
init_plants <- function(veg_types = c(0, 1, 2)) {

  inter_plant_distance_x <- sqrt(CONSTANTS$PLOT_SIZE) / CONSTANTS$PLANTS_IN_X
  inter_plant_distance_y <- sqrt(CONSTANTS$PLOT_SIZE) / CONSTANTS$PLANTS_IN_Y

  x_coords <- (seq_len(CONSTANTS$PLANTS_IN_X) - 0.5) * inter_plant_distance_x
  y_coords <- (seq_len(CONSTANTS$PLANTS_IN_Y) - 0.5) * inter_plant_distance_y

  plant_grid <- expand.grid(xcor = x_coords, ycor = y_coords)
  plant_grid$plant_id <- seq_len(nrow(plant_grid))
  n_plants <- nrow(plant_grid)

  # Assign vegetation type
  plant_grid$veg_type <- replicate(n_plants, select_randomly(veg_types)) # type of vegetation (0, 1, 2 - C3 grass, C4 grass, tree)

  # Biomass in kg
  plant_grid$ms <- runif(n_plants,
                         min = CONSTANTS$PLANT_INITIAL_MASS_MIN,
                         max = CONSTANTS$PLANT_INITIAL_MASS_MAX) # shoot biomass [kg dry mass]
  plant_grid$mr <- plant_grid$ms # root biomass [kg dry mass]

# defence biomass [kg dry mass]

  init_C <- runif(n_plants, 0.05, 0.5) # initital C content
  init_N <- runif(n_plants, 0.01, 0.025) # initial N content

  plant_grid$cs <- plant_grid$ms * init_C # shoot C content [kg]
  plant_grid$cr <- plant_grid$mr * init_C  # root C content [kg]
  plant_grid$ns <- plant_grid$ms * init_N # shoot N content [kg]
  plant_grid$nr <- plant_grid$mr * init_N # root N content [kg]

  # Placeholder pools for defence C and N (not yet used by orchestrator)
  plant_grid$cd <- 0 # defence C content [kg]
  plant_grid$nd <- 0 # defence N content [kg]

  plant_grid$bleaf  <- ifelse(plant_grid$veg_type == 2, plant_grid$ms * 0.5, plant_grid$ms) # leaf biomass [kg dry mass]
  plant_grid$bstem  <- ifelse(plant_grid$veg_type == 2, plant_grid$ms * 0.5, 0) # stem biomass [kg dry mass]
  plant_grid$broot  <- plant_grid$mr # root biomass [kg dry mass]
  plant_grid$brepr  <- 0 # reproductive biomass [kg dry mass]
  plant_grid$bdef   <- plant_grid$ms * CONSTANTS$TOLERANCE # defence compartmental [structural] pool (like bleaf, bstem)
  plant_grid$md <- plant_grid$bdef # defence biomass [kg dry mass]
  plant_grid$height <- ifelse(plant_grid$veg_type == 2, 2.0, 1.0) # plant height [m] for trees and shrubs

  plant_grid$qroot  <- plant_grid$mr * 8 # root water content [kg]
  plant_grid$qshoot <- plant_grid$ms * 8 # shoot water content [kg]

  # Growth fluxes
  plant_grid$gs <- 0       # shoot growth [kg/day]
  plant_grid$gr <- 0       # root growth
  plant_grid$gd <- 0       # defence growth

  # Uptake fluxes
  plant_grid$uc <- 0       # C input (photosynthesis from leaves)
  plant_grid$un <- 0       # N input (root uptake)

  # Transport resistances (calculated from biomass)
  plant_grid$rsC <- 0 # differential equation for the transport flux of substrate C in shoot
  plant_grid$rrC <- 0 # differential equation for the transport flux of substrate C in root
  plant_grid$rdC <- 0 # differential equation for the transport flux of substrate C in defence
  plant_grid$rsN <- 0 # differential equation for the transport flux of substrate N in shoot
  plant_grid$rrN <- 0 # differential equation for the transport flux of substrate N in root
  plant_grid$rdN <- 0 # differential equation for the transport flux of substrate N in defence

  # Transport rates (based on concentration gradients & resistance)
  plant_grid$tauC  <- 0    # C from shoot to root
  plant_grid$tauN  <- 0    # N from root to shoot
  plant_grid$tauCd <- 0    # C to defence
  plant_grid$tauNd <- 0    # N to defence

  return(plant_grid)
}
