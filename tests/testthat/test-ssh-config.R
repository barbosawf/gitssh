test_that("git_setup_ssh_config writes aliases and the optional default host", {
  home <- tempfile("home-")
  dir.create(home)
  withr::defer(unlink(home, recursive = TRUE))
  local_mocked_bindings(get_ssh_home = function() home)

  accounts <- c(work = "w@example.com", personal = "p@example.com")

  expect_warning(
    suppressMessages(git_setup_ssh_config(accounts, bind_global = FALSE)),
    "private key files were not found"
  )
  cfg <- readLines(file.path(home, ".ssh", "config"))
  expect_true("Host github.com-work" %in% cfg)
  expect_true("Host github.com-personal" %in% cfg)
  expect_false("Host github.com" %in% cfg)

  suppressWarnings(suppressMessages(
    git_setup_ssh_config(accounts, bind_global = FALSE, default_account = "personal")
  ))
  cfg <- readLines(file.path(home, ".ssh", "config"))
  i <- which(cfg == "Host github.com")
  expect_length(i, 1)
  expect_match(cfg[i + 2], "id_rsa_personal$")

  expect_error(
    git_setup_ssh_config(accounts, bind_global = FALSE, default_account = "nope"),
    "must be one of"
  )
})

test_that("git_list_ssh_hosts reads the physical config by default", {
  home <- tempfile("home-")
  dir.create(file.path(home, ".ssh"), recursive = TRUE)
  withr::defer(unlink(home, recursive = TRUE))
  writeLines(c("Host *", "  UserKnownHostsFile x", "",
               "Host github.com-a github.com-b", "  HostName github.com"),
             file.path(home, ".ssh", "config"))
  local_mocked_bindings(get_ssh_home = function() home)
  expect_equal(git_list_ssh_hosts(), c("github.com-a", "github.com-b"))
})

test_that("git_system2 sets and restores env vars around the call", {
  home <- tempfile("home-")
  dir.create(file.path(home, ".ssh"), recursive = TRUE)
  file.create(file.path(home, ".ssh", "config"))
  withr::defer(unlink(home, recursive = TRUE))
  local_mocked_bindings(get_ssh_home = function() home)

  Sys.unsetenv(c("GIT_SSH_COMMAND", "GIT_TERMINAL_PROMPT"))
  seen <- NULL
  local_mocked_bindings(
    system2 = function(...) {
      seen <<- Sys.getenv(c("GIT_SSH_COMMAND", "GIT_TERMINAL_PROMPT"))
      0L
    },
    .package = "base"
  )
  git_system2("--version", extra_env = c(GIT_TERMINAL_PROMPT = "0"))
  expect_match(seen[["GIT_SSH_COMMAND"]], "^ssh -F ")
  expect_equal(seen[["GIT_TERMINAL_PROMPT"]], "0")
  expect_equal(Sys.getenv("GIT_SSH_COMMAND", unset = NA), NA_character_)
  expect_equal(Sys.getenv("GIT_TERMINAL_PROMPT", unset = NA), NA_character_)
})
