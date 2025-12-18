test_that("TTR constants exist and are numeric with units documented inline", {
  required <- c(
    "K_LITTER","K_M_LITTER","G_SHOOT","G_ROOT","G_DEFENCE",
    "K_C","K_N","K_M","PI_C","PI_N","Q_SCP","TR_C","TR_N",
    "FRACTION_C","FRACTION_N","PHENO_SWITCH","ACCEL_LEAF_LOSS",
    "INIT_SW","INIT_N","TEMP_GROWTH_1","TEMP_GROWTH_2","TEMP_GROWTH_3","TEMP_GROWTH_4",
    "TEMP_PHOTO_1","TEMP_PHOTO_2","TEMP_PHOTO_3","TEMP_PHOTO_4"
  )
  missing <- setdiff(required, names(CONSTANTS))
  expect_length(missing, 0)
  vals <- unlist(CONSTANTS[required], use.names = FALSE)
  expect_true(all(is.finite(as.numeric(vals))))
})
