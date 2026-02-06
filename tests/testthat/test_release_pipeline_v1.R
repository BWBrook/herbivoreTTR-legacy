test_that("release candidate label helper uses rc suffix for semver versions", {
  expect_equal(release_candidate_label_v1("1.0.0"), "v1.0.0-rc1")
  expect_equal(release_candidate_label_v1("1.0.0.9000"), "v1.0.0.9000")
})

test_that("release expected scenario list contains required core slugs", {
  slugs <- release_expected_run_slugs_v1()
  expect_true(is.character(slugs))
  expect_true(length(slugs) > 0)
  expect_true("smoke_v0" %in% slugs)
  expect_true("experiment_a_presence_removal_v1" %in% slugs)
  expect_false(anyDuplicated(slugs) > 0)
})

test_that("changelog has a section for the current package version", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")

  changelog_path <- file.path(repo_root, "CHANGELOG.md")
  skip_if_not(file.exists(changelog_path), "CHANGELOG not available in this test context.")

  version <- resolve_package_version()
  expect_true(check_changelog_for_version_v1(version, changelog_path))
})
