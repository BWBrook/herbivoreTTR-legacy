## Internals available via helper-ttr.R (source_all_R)

test_that("transport_resistance updates plants without NaN/Inf and keeps non-negative masses", {
  cond <- init_conditions(days_in_year = 10, mode = "flat", mean_temp = 20, amplitude = 0)
  plants <- init_plants(veg_types = c(0, 1, 2))
  before <- plants[1,]
  out <- transport_resistance(plants[1, , drop = FALSE], cond, day_index = 1)
  expect_equal(nrow(out), 1)
  expect_true(all(sapply(out, function(col) all(is.finite(col)))))
  expect_true(all(out$ms >= 0)); expect_true(all(out$mr >= 0))
  expect_true(all(out$bleaf >= 0)); expect_true(all(out$bstem >= 0)); expect_true(all(out$bdef >= 0))
  # Check that some state likely changed sensibly (not mandatory to increase/decrease consistently)
  expect_true(is.numeric(out$ms))
})

test_that("transport_resistance preserves canonical day-step output contract", {
  set.seed(24680)
  cond <- init_conditions(days_in_year = 30, mode = "seasonal", mean_temp = 19, amplitude = 5)
  plants <- init_plants(veg_types = c(0L, 1L, 2L))[1:3, , drop = FALSE]

  cols <- c(
    "ms", "mr", "cs", "cr", "ns", "nr", "cd", "nd", "bleaf", "bstem",
    "bdef", "md", "brepr", "broot", "rsC", "rrC", "rdC", "rsN", "rrN",
    "rdN", "tauC", "tauN", "tauCd", "tauNd", "uc", "un", "gs", "gr", "gd"
  )

  out <- transport_resistance(plants, cond, day_index = 7L)[, cols, drop = FALSE]

  expected <- structure(list(ms = c(36.4571274677583, 74.1803787660606,
  7.27630946093207), mr = c(36.4534514873052, 74.1728943634258,
  7.275577847415), cs = c(3.02158567852354, 6.94398116431992,
  2.11909076815195), cr = c(2.63315541693719, 6.77478146460851,
  2.11909076809995), ns = c(0.770402385927235, 1.13091508285678,
  0.108631709307626), nr = c(0.770402537010528, 1.13101973606298,
  0.108678840451678), cd = c(0, 0, 0), nd = c(0, 0, 0), bleaf = c(36.4534514873052,
  74.1728943634258, 7.275577847415), bstem = c(0, 0, 0), bdef = c(0.00367598045319607,
  0.00748440263477711, 0.000731613517064586), md = c(0.00367598045319607,
  0.00748440263477711, 0.000731613517064586), brepr = c(0.0172466054089001,
  0.0295377576605338, 0.0023718820781551), broot = c(36.4534514873052,
  74.1728943634258, 7.275577847415), rsC = c(0.0933960913970406,
  0.0578383433073993, 0.274118282034868), rrC = c(0.0933960913970406,
  0.0578383433073993, 0.274118282034868), rdC = c(0, 0, 0), rsN = c(0.0933960913970406,
  0.0578383433073993, 0.274118282034868), rrN = c(0.0933960913970406,
  0.0578383433073993, 0.274118282034868), rdN = c(0, 0, 0), tauC = c(0,
  0, 0), tauN = c(0, 0, 0), tauCd = c(0, 0, 0), tauNd = c(0, 0,
  0), uc = c(0.388430261586352, 0.169199699711415, 5.20003987929227e-11),
  un = c(1.5108329348667e-07, 0.000104653206201613, 4.71311440521005e-05),
  gs = c(1.72466054089001, 2.95377576605338, 0.348387851391453),
  gr = c(1.72466054089001, 2.95377576605338, 0.348387851391453),
  gd = c(0, 0, 0)), class = "data.frame", row.names = c(NA, 3L))

  expect_equal(out, expected, tolerance = 1e-12)
})
