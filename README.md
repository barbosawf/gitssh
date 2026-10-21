# gitssh

Git, GitHub and SSH helpers for R when **more than one account or machine** is
involved. Split out of [`ufmmfu`](https://github.com/barbosawf/ufmmfu).

```r
# install.packages("pak")
pak::pak("barbosawf/gitssh")

library(gitssh)
git_tips()                # cheat sheet (HTML, buttons: pt-BR / English / Español)
git_tips(lang = "en", console = TRUE)   # same, as plain text in the console
```

## What it does

| Area | Functions |
|---|---|
| Setup & diagnostics | `get_ssh_home()`, `git_setup_ssh_config()`, `check_ssh_setup()`, `git_list_ssh_hosts()`, `git_test_ssh_alias()`, `check_cloud_sync_conflicts()`, `get_os_type()` |
| Remote protocol | `git_remote_urls()`, `git_status_check()`, `git_convert_to_ssh()`, `git_set_ssh_account()` |
| New project | `git_new_project()` (verifies `gh` **and** SSH identity before creating anything) |
| Cloning | `git_clone()` (any repo: yours or someone else's) |
| Daily loop | `git_pull_with_local_id()`, `git_push_with_local_id()` |
| Stash | `git_stash_save()`, `git_stash_list()`, `git_stash_pop()` |
| Danger zone | `git_pull_force_remote()`, `git_push_force_remote()` |

## Cloning third-party repositories (fixed vs. `ufmmfu`)

`git_clone()` used to turn *every* repository into `git@github.com:owner/repo.git`
and authenticate with your SSH setup. That fails for repositories you have no
key for, and for any machine whose bare `github.com` host has no identity (keys
are named per account, `Host github.com-<account>`). It now chooses the transport
with `protocol = "auto"`:

1. `ssh_alias` given, or a `git@host:...` URL → **SSH** as requested;
2. the owner has an alias here (`Host github.com-<owner>`) → **SSH** through it
   (your own, possibly private, repositories);
3. otherwise → **HTTPS**, which needs no key (public / third-party repositories).

```r
git_clone("tidyverse/dplyr")                              # HTTPS, no key
git_clone("my-account/private-repo")                      # SSH via github.com-my-account
git_clone("my-org/repo", ssh_alias = "github.com-work")   # explicit identity
git_clone("tidyverse/dplyr", protocol = "ssh")            # force a transport
```

Two related problems are handled as well:

* **`url.<base>.insteadOf` rules.** A global rule such as
  `url."git@github.com:".insteadOf = https://github.com/` silently rewrites every
  HTTPS URL to bare-host SSH, so even a plain `git clone https://...` fails
  without a default key. Third-party HTTPS clones and the pull/push/fetch helpers
  pin the exact URL (the longest `insteadOf` match wins), without touching your
  global config.
* **Auto HTTPS → SSH conversion** in `git_pull_with_local_id()`, `git_push_*()`
  and friends now only rewrites remotes whose owner has an SSH alias on this
  machine. Someone else's public remote stays on HTTPS.

`git_setup_ssh_config(..., default_account = "personal")` additionally gives the
bare `github.com` host a default key, for plain `git@github.com:` URLs.
