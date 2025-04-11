# Upgrading

## Pre-1.0 to 1.0

Release 1.0 contains a large rewrite of the `avli` command, which may cause breaking changes if you relied on existing,
inconsistent behavior.

### Breaking Changes

- By default, `avli` calls on Linux and Mac now remove the temporary profile directory when the browser closes. If you
  want to retain the profile between calls to `avli`, set the `AWS_VAULT_PL_PERSIST_PROFILE` environment variable to
  `true`.
- `avli` calls launching MacOS Firefox now creates profiles in the `/tmp` directory by default, instead of in the
  ApplicationSupport directory, as before. This means that, by default, Firefox `avli` profiles are completely transient
  by default. If you'd like to retain your browser profile between launches, set the `AWS_VAULT_PL_PERSIST_PROFILE`
  environment variable to `true`.
- `avli` calls using Chrome (and chrome-like browsers) no longer pass the `--new-window` flag by default. To retain the
  existing behavior, set the `AWS_VAULT_PL_BROWSER_LAUNCH_OPTS` to include `--new-window`.
- `avli` calls use `nohup` to ensure the browser is not terminated if the terminal window that launched it is closed.
- Utility functions `_using_osx()`, `_using_linux()`, and `_find_browser()` are no longer exported to your ZSH
  environment. These utility functions are internal and should not have been exposed in your ZSH environment. If you
  relied on having these functions available, view their definitions and export the functions manually from your
  `~/.zshrc` file.
