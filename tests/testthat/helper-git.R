# Run the calling test with a hermetic global/system git config, so the
# results do not depend on the developer's own ~/.gitconfig. `lines` become
# the content of the global config (e.g. an insteadOf rewrite rule).
local_git_global_config <- function(lines = character(0), env = parent.frame()) {
  cfg <- tempfile("gitconfig-")
  writeLines(c("[user]", "  name = Test", "  email = test@example.com", lines), cfg)
  withr::defer(unlink(cfg), envir = env)
  withr::local_envvar(GIT_CONFIG_GLOBAL = cfg, GIT_CONFIG_NOSYSTEM = "1", .local_envir = env)
  invisible(cfg)
}

# The rule found in the wild that broke third-party clones: every GitHub
# HTTPS URL is silently rewritten to a bare-host SSH URL.
rewrite_https_to_ssh <- c('[url "git@github.com:"]', "  insteadOf = https://github.com/")
