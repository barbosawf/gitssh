# .git_maybe_convert_to_ssh() must leave third-party HTTPS remotes alone but
# still fix the ones this machine has a key for.

local_repo <- function(remote_url, env = parent.frame()) {
  skip_if(nchar(Sys.which("git")) == 0, "git not available")
  local_git_global_config(env = env)
  dir <- tempfile("repo-")
  dir.create(dir)
  old <- setwd(dir)
  withr::defer({ setwd(old); unlink(dir, recursive = TRUE) }, envir = env)
  system2("git", c("init", "-q"))
  system2("git", c("remote", "add", "origin", remote_url))
  dir
}

current_url <- function() {
  system2("git", c("remote", "get-url", "origin"), stdout = TRUE)
}

test_that("a third-party HTTPS remote stays on HTTPS when pulling", {
  local_repo("https://github.com/tidyverse/dplyr.git")
  local_mocked_bindings(git_list_ssh_hosts = function(...) c("github.com-me"))
  expect_message(.git_maybe_convert_to_ssh(TRUE, "pull"), "keeping it on HTTPS")
  expect_equal(current_url(), "https://github.com/tidyverse/dplyr.git")
})

test_that("a remote owned by one of your aliases is converted via that alias", {
  local_repo("https://github.com/me/proj.git")
  local_mocked_bindings(
    git_list_ssh_hosts = function(...) c("github.com-me", "github.com-org"),
    git_test_ssh_alias = function(...) list(ok = TRUE, login = "me")
  )
  suppressMessages(.git_maybe_convert_to_ssh(TRUE, "pull"))
  expect_equal(current_url(), "git@github.com-me:me/proj.git")
})

test_that("with no aliases at all, only push converts (single-account setups)", {
  local_repo("https://github.com/someone/proj.git")
  local_mocked_bindings(git_list_ssh_hosts = function(...) character(0))
  expect_message(.git_maybe_convert_to_ssh(TRUE, "pull"), "keeping it on HTTPS")
  expect_equal(current_url(), "https://github.com/someone/proj.git")

  suppressMessages(.git_maybe_convert_to_ssh(TRUE, "push"))
  expect_equal(current_url(), "git@github.com:someone/proj.git")
})

test_that("auto_ssh = FALSE does nothing", {
  local_repo("https://github.com/me/proj.git")
  local_mocked_bindings(git_list_ssh_hosts = function(...) c("github.com-me"))
  expect_silent(.git_maybe_convert_to_ssh(FALSE, "push"))
  expect_equal(current_url(), "https://github.com/me/proj.git")
})

test_that("with a global https->ssh rewrite, git_remote_urls reports both views", {
  local_repo("https://github.com/tidyverse/dplyr.git")
  local_git_global_config(rewrite_https_to_ssh)
  urls <- git_remote_urls()
  expect_equal(urls$fetch_url, "https://github.com/tidyverse/dplyr.git")
  expect_true(urls$fetch_is_https)
  expect_equal(urls$effective_fetch_url, "git@github.com:tidyverse/dplyr.git")
  expect_true(urls$rewritten)
  suppressWarnings(expect_message(git_status_check(), "insteadOf"))
})

test_that("third-party remotes get pinned to HTTPS despite the rewrite rule", {
  local_repo("https://github.com/tidyverse/dplyr.git")
  local_git_global_config(rewrite_https_to_ssh)
  local_mocked_bindings(git_list_ssh_hosts = function(...) c("github.com-me"))
  url <- "https://github.com/tidyverse/dplyr.git"
  expect_equal(.git_remote_pin_args(), c("-c", sprintf("url.%s.insteadOf=%s", url, url)))
  # and the pinned URL really is what git would use
  expect_false(.git_url_rewritten(url) && !length(.git_remote_pin_args()))
})

test_that("your own remotes are not pinned: they are converted to the alias instead", {
  local_repo("https://github.com/me/proj.git")
  local_git_global_config(rewrite_https_to_ssh)
  local_mocked_bindings(
    git_list_ssh_hosts = function(...) c("github.com-me"),
    git_test_ssh_alias = function(...) list(ok = TRUE, login = "me")
  )
  expect_equal(.git_remote_pin_args(), character(0))
  suppressMessages(.git_maybe_convert_to_ssh(TRUE, "pull"))
  expect_equal(git_remote_urls()$fetch_url, "git@github.com-me:me/proj.git")
})

test_that("no rewrite rule means no pin args", {
  local_repo("https://github.com/tidyverse/dplyr.git")
  expect_equal(.git_remote_pin_args(), character(0))
})
