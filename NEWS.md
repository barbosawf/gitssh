# gitssh (development version)

* Split out of `ufmmfu` (Git/GitHub/SSH helpers only).
* `git_clone()` works for public and third-party repositories: new
  `protocol = c("auto", "https", "ssh")`; `"auto"` uses SSH through the owner's
  alias for your own repositories and HTTPS for everyone else's. It no longer
  forces `git@github.com:` (which had no identity in multi-account setups), and
  keeps the host of full URLs (e.g. GitLab) instead of rewriting it to GitHub.
* HTTPS clones, pulls, pushes and fetches are immune to a global
  `url.<base>.insteadOf` rule that rewrites HTTPS to SSH (the exact URL is pinned).
* `git_pull_with_local_id()`, `git_push_with_local_id()`, `git_pull_force_remote()`
  and `git_push_force_remote()`: `auto_ssh` only converts remotes owned by one of
  your SSH aliases (or, for push only, when no alias exists at all).
* `git_remote_urls()` reports the raw configured URLs plus the effective ones
  after `insteadOf` rewriting (`rewritten`); `git_status_check()` mentions it.
* `git_setup_ssh_config(default_account=)` gives the bare `github.com` host a key.
* `git_list_ssh_hosts()` reads the physical `.ssh/config` by default;
  `git_set_ssh_account()` gains `host`; new `git_build_https_url()`;
  `git_system2()` gains `extra_env`.
* `git_tips()` is trilingual (pt-BR / English / Español, with buttons in the HTML
  page) and can print to the console (`console = TRUE`).
* Fixed missing help titles for `check_ssh_setup()` and `git_list_ssh_hosts()`.
