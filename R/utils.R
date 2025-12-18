# Supporting utility functions

#' Randomly select one element from a vector
#'
#' @param vec A non-empty vector to sample from.
#' @return A length-1 vector containing a single sampled element.
#' @export
select_randomly <- function(vec) sample(vec, 1, replace = FALSE)

#' Toroidal (wrap-around) Euclidean distance in a rectangular world
#'
#' Computes the shortest Euclidean distance between points accounting for
#' wrap-around on both axes (toroidal geometry). Useful for 2D plots where
#' edges connect (e.g., 100x100 m torus).
#'
#' @param x1,y1 Numeric scalars or vectors: origin coordinates (m).
#' @param x2,y2 Numeric scalars or vectors: target coordinates (m).
#' @param plot_width,plot_height Numeric scalars: plot dimensions (m).
#' @return Numeric vector of shortest toroidal distances (m).
#' @export
calc_toroidal_distance <- function(x1, y1, x2, y2, plot_width, plot_height) {
  dx <- pmin(abs(x1 - x2), plot_width - abs(x1 - x2))
  dy <- pmin(abs(y1 - y2), plot_height - abs(y1 - y2))
  sqrt(dx^2 + dy^2)
}

#' Sigmoid scaling function (skeleton)
#'
#' Generic sigmoid function; placeholder for growth allocation scaling.
#'
#' @param x,k,b Numeric parameters.
#' @return numeric scalar (stub returns NA_real_).
sf <- function(x, k, b) {
  # 1 / (1 + exp((x - k) * b))
  z <- (x - k) * b
  res <- 1 / (1 + exp(z))
  res[!is.finite(res)] <- 0
  pmax(pmin(res, 1), 0)
}
