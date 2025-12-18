test_that("trap1 is bounded [0,1] and vectorized", {
  x <- c(-1, 0, 0.5, 1, 2)
  a <- 0
  b <- 1
  y <- trap1(x, a, b)
  expect_true(all(is.finite(y)))
  expect_true(all(y >= 0 & y <= 1))
  expect_equal(y, c(0, 0, 0.5, 1, 1), tolerance = 1e-12)
})

test_that("trap1 handles zero/negative width safely", {
  x <- c(0, 1)
  a <- 1
  b <- 1 # zero width
  y <- trap1(x, a, b)
  expect_true(all(is.finite(y)))
  expect_true(all(y >= 0 & y <= 1))
})

test_that("trap2 is bounded [0,1] and vectorized", {
  x <- seq(0, 10, length.out = 11)
  y <- trap2(x, 2, 4, 6, 8)
  expect_true(all(is.finite(y)))
  expect_true(all(y >= 0 & y <= 1))
  # plateau between [b,c]
  expect_true(all(trap2(4:6, 2, 4, 6, 8) == 1))
  # edges 0 outside [a,d]
  expect_true(all(trap2(c(-1, 0, 10, 11), 2, 4, 6, 8) == 0))
})

test_that("trap2 handles zero-width ramps safely", {
  # a==b and c==d
  x <- c(1, 2, 3)
  y <- trap2(x, 2, 2, 3, 3)
  expect_true(all(is.finite(y)))
  expect_true(all(y >= 0 & y <= 1))
})

test_that("monod is bounded and robust", {
  R <- c(-1, 0, 1, 10)
  k <- c(0, 0, 1, 10)
  y <- monod(R, k)
  expect_true(all(is.finite(y)))
  expect_true(all(y >= 0 & y <= 1))
  expect_equal(monod(1, 0), 1)
  expect_equal(monod(0, 0), 0)
})

test_that("calc_SWforcer uses trap1 and is bounded", {
  sw <- seq(0, 1, by = 0.1)
  y <- calc_SWforcer(sw, 0.2, 0.8)
  expect_true(all(is.finite(y)))
  expect_true(all(y >= 0 & y <= 1))
  expect_equal(y, trap1(sw, 0.2, 0.8))
})
