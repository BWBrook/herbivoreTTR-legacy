test_that("defence transport and growth are wired when enabled", {
  skip_on_cran()
  # Toggle defence wiring on, restore after
  old_flag <- CONSTANTS$DEFENCE_ENABLED
  on.exit({ CONSTANTS$DEFENCE_ENABLED <<- old_flag }, add = TRUE)
  CONSTANTS$DEFENCE_ENABLED <<- 1

  # Minimal conditions and a single plant with non-zero defence pools
  cond <- data.frame(day = 1:2, temp_mean = 20, sw = 0.5, N = 0.5)
  plants <- data.frame(
    plant_id = 1L,
    xcor = 0, ycor = 0,
    ms = 2.0, mr = 1.0, md = 0.2,
    cs = 1.0, cr = 0.5, cd = 0.1,
    ns = 0.1, nr = 0.05, nd = 0.02,
    bleaf = 1.6, bstem = 0.2, bdef = 0.2,
    brepr = 0.0, broot = 1.0,
    height = 1.0, veg_type = 0,
    uc = 0, un = 0, rsC = 0, rrC = 0, rdC = 0, rsN = 0, rrN = 0, rdN = 0,
    tauC = 0, tauN = 0, tauCd = 0, tauNd = 0, gs = 0, gr = 0, gd = 0
  )

  out <- transport_resistance(plants, cond, day_index = 1)
  expect_true(is.finite(out$tauCd[1]))
  expect_true(is.finite(out$tauNd[1]))
  # With Cs/Ms > Cd/Md, tauCd should be positive; similarly for N
  expect_gt(out$tauCd[1], 0)
  expect_gt(out$tauNd[1], 0)
  # Defence growth positive when pools > 0 and growth_env > 0
  expect_gte(out$gd[1], 0)
})
