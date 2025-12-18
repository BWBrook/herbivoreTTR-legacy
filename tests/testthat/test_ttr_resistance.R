test_that("resistances return finite, non-negative, vectorized outputs", {
  TR <- c(0.5, 1, 2)
  M <- c(0.1, 1, 10)
  Q <- c(1, 0.5, 0)
  # Expected base (without capping) for Q=1: TR / M
  expect_true(all(is.finite(calc_RsC(TR, M, 1))))
  expect_true(all(calc_RsC(TR, M, 1) >= 0))
  expect_true(all(is.finite(calc_RrC(TR, M, 1))))
  expect_true(all(is.finite(calc_RdC(TR, M, 1))))
  expect_true(all(is.finite(calc_RsN(TR, M, 1))))
  expect_true(all(is.finite(calc_RrN(TR, M, 1))))
  expect_true(all(is.finite(calc_RdN(TR, M, 1))))
})

test_that("resistances handle zero or negative mass without NaN/Inf", {
  TR <- 1
  Q <- 1
  M <- c(0, -1, NA, Inf)
  outC <- calc_RsC(TR, M, Q)
  outN <- calc_RsN(TR, M, Q)
  expect_true(all(is.finite(outC[is.finite(outC)])))
  expect_true(all(is.finite(outN[is.finite(outN)])))
  expect_true(all(outC[is.finite(outC)] >= 0))
  expect_true(all(outN[is.finite(outN)] >= 0))
})

test_that("resistances with Q=0 equal TR (bounded)", {
  TR <- c(0, 1, 2)
  M <- c(0.1, 1, 10)
  Q <- 0
  expect_equal(calc_RsC(TR, M, Q), pmax(TR, 0))
  expect_equal(calc_RsN(TR, M, Q), pmax(TR, 0))
})
