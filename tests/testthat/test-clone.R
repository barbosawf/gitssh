mock_aliases <- function(aliases = c("github.com-me", "github.com-org")) {
  testthat::local_mocked_bindings(
    git_list_ssh_hosts = function(...) aliases,
    .env = parent.frame()
  )
}

test_that("auto: third-party repos use HTTPS (the multi-account bug)", {
  mock_aliases()
  t <- .git_resolve_clone_target("tidyverse/dplyr")
  expect_equal(t$protocol, "https")
  expect_equal(t$url, "https://github.com/tidyverse/dplyr.git")
  expect_null(t$ssh_alias)
  expect_equal(t$name, "dplyr")

  t <- .git_resolve_clone_target("https://github.com/tidyverse/dplyr")
  expect_equal(t$protocol, "https")

  t <- .git_resolve_clone_target("https://gitlab.com/group/proj.git")
  expect_equal(t$url, "https://gitlab.com/group/proj.git")
})

test_that("auto: repos owned by one of your aliases go through that alias", {
  mock_aliases()
  t <- .git_resolve_clone_target("me/private-repo")
  expect_equal(t$protocol, "ssh")
  expect_equal(t$ssh_alias, "github.com-me")
  expect_equal(t$url, "git@github.com-me:me/private-repo.git")

  t <- .git_resolve_clone_target("https://github.com/org/private-repo.git")
  expect_equal(t$protocol, "ssh")
  expect_equal(t$url, "git@github.com-org:org/private-repo.git")
})

test_that("auto: an explicit alias or SSH URL always means SSH", {
  mock_aliases()
  t <- .git_resolve_clone_target("tidyverse/dplyr", ssh_alias = "github.com-org")
  expect_equal(t$protocol, "ssh")
  expect_equal(t$url, "git@github.com-org:tidyverse/dplyr.git")

  t <- .git_resolve_clone_target("git@github.com:tidyverse/dplyr.git")
  expect_equal(t$protocol, "ssh")
  expect_equal(t$url, "git@github.com:tidyverse/dplyr.git")
})

test_that("explicit protocols are respected", {
  mock_aliases()
  t <- .git_resolve_clone_target("tidyverse/dplyr", protocol = "ssh")
  expect_equal(t$url, "git@github.com:tidyverse/dplyr.git")

  t <- .git_resolve_clone_target("me/x", protocol = "ssh")
  expect_equal(t$url, "git@github.com-me:me/x.git")

  expect_message(
    t <- .git_resolve_clone_target("me/x", ssh_alias = "github.com-me",
                                   protocol = "https"),
    "ignored"
  )
  expect_equal(t$url, "https://github.com/me/x.git")
})

test_that("unusable repo identifiers are rejected", {
  mock_aliases()
  expect_error(.git_resolve_clone_target("justaname"), "Could not understand")
})

# git_clone's call to git, replaced by a fake that records its arguments and
# creates the destination as an empty repository.
mock_git_clone <- function(env = parent.frame()) {
  captured <- new.env()
  testthat::local_mocked_bindings(
    git_system2 = function(args, ..., extra_env = NULL) {
      captured$args <- args
      captured$extra_env <- extra_env
      dest <- args[length(args)]
      dir.create(dest, recursive = TRUE)
      system2("git", c("init", "-q", dest))
      0L
    },
    .env = env
  )
  captured
}

test_that("git_clone passes the resolved URL and a no-prompt env to git", {
  skip_if(nchar(Sys.which("git")) == 0, "git not available")
  local_git_global_config()
  mock_aliases()
  captured <- mock_git_clone()
  dest <- file.path(tempfile("clone-"), "dplyr")
  withr::defer(unlink(dirname(dest), recursive = TRUE))
  suppressMessages(git_clone("tidyverse/dplyr", dest_dir = dest, depth = 1))
  expect_equal(captured$args[1], "clone")
  expect_true("https://github.com/tidyverse/dplyr.git" %in% captured$args)
  expect_true(all(c("--depth", "1") %in% captured$args))
  expect_equal(captured$extra_env, c(GIT_TERMINAL_PROMPT = "0"))
})

test_that("git_clone defeats a global https->ssh insteadOf rule (the real-world bug)", {
  skip_if(nchar(Sys.which("git")) == 0, "git not available")
  local_git_global_config(rewrite_https_to_ssh)
  mock_aliases()
  captured <- mock_git_clone()
  dest <- file.path(tempfile("clone-"), "dplyr")
  withr::defer(unlink(dirname(dest), recursive = TRUE))

  url <- "https://github.com/tidyverse/dplyr.git"
  expect_true(.git_url_rewritten(url))
  suppressMessages(git_clone("tidyverse/dplyr", dest_dir = dest))

  # The exact URL is pinned for this one command...
  expect_equal(captured$args[1:2], c("-c", sprintf("url.%s.insteadOf=%s", url, url)))
  expect_equal(captured$args[3], "clone")
  # ...and for the cloned repository, so its later pulls stay on HTTPS too.
  pinned <- system2("git", c("-C", dest, "config", "--get",
                             sprintf("url.%s.insteadOf", url)), stdout = TRUE)
  expect_equal(pinned, url)
})

test_that("git_clone refuses to overwrite and reports failures with a hint", {
  skip_if(nchar(Sys.which("git")) == 0, "git not available")
  mock_aliases()
  existing <- tempfile("exists-")
  dir.create(existing)
  withr::defer(unlink(existing, recursive = TRUE))
  expect_error(suppressMessages(git_clone("a/b", dest_dir = existing)), "already exists")

  local_mocked_bindings(git_system2 = function(...) 128L)
  expect_error(
    suppressMessages(git_clone("a/b", dest_dir = file.path(tempdir(), "nope"))),
    "over HTTPS.*private repository"
  )
})
