test_that(".git_parse_repo understands slugs, SSH and HTTPS forms", {
  p <- .git_parse_repo("tidyverse/dplyr")
  expect_equal(p$kind, "slug")
  expect_equal(p$host, "github.com")
  expect_equal(p$owner, "tidyverse")
  expect_equal(p$name, "dplyr")

  p <- .git_parse_repo("git@github.com-work:my-org/repo.git")
  expect_equal(p$kind, "ssh")
  expect_equal(p$host, "github.com-work")
  expect_equal(p$path, "my-org/repo")

  p <- .git_parse_repo("https://github.com/tidyverse/dplyr.git")
  expect_equal(p$kind, "https")
  expect_equal(p$path, "tidyverse/dplyr")

  p <- .git_parse_repo("https://user:token@gitlab.com/group/sub/repo/")
  expect_equal(p$host, "gitlab.com")
  expect_equal(p$owner, "group")
  expect_equal(p$name, "repo")
  expect_equal(p$path, "group/sub/repo")

  p <- .git_parse_repo("ssh://git@bitbucket.org/team/repo.git")
  expect_equal(p$kind, "ssh")
  expect_equal(p$host, "bitbucket.org")
  expect_equal(p$path, "team/repo")
})

test_that("git_build_https_url never needs an SSH alias", {
  expect_equal(git_build_https_url("tidyverse/dplyr"),
               "https://github.com/tidyverse/dplyr.git")
  expect_equal(git_build_https_url("git@github.com:tidyverse/dplyr.git"),
               "https://github.com/tidyverse/dplyr.git")
  expect_equal(git_build_https_url("owner/repo", host = "gitlab.com"),
               "https://gitlab.com/owner/repo.git")
})

test_that("git_build_ssh_url keeps the host of full URLs and honors aliases", {
  local_mocked_bindings(git_list_ssh_hosts = function(...) character(0))

  expect_equal(git_build_ssh_url("owner/repo"), "git@github.com:owner/repo.git")
  expect_equal(git_build_ssh_url("owner/repo", host = "gitlab.com"),
               "git@gitlab.com:owner/repo.git")
  # A GitLab HTTPS URL must stay on GitLab, not be rewritten to github.com.
  expect_equal(git_build_ssh_url("https://gitlab.com/owner/repo"),
               "git@gitlab.com:owner/repo.git")
  # An existing SSH alias in the URL is preserved when none is requested.
  expect_equal(git_build_ssh_url("git@github.com-work:owner/repo.git"),
               "git@github.com-work:owner/repo.git")
  # ...and replaced when one is.
  expect_equal(git_build_ssh_url("owner/repo", ssh_alias = "github.com-work"),
               "git@github.com-work:owner/repo.git")
  expect_equal(git_build_ssh_url("https://github.com/owner/repo.git",
                                 ssh_alias = "github.com-work"),
               "git@github.com-work:owner/repo.git")
})
