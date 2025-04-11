# zsh-aws-vault

oh-my-zsh plugin for [aws-vault](https://github.com/99designs/aws-vault)

## Installation

### [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)

This plugin is intended to be used with oh-my-zsh

1. `cd ~/.oh-my-zsh/custom/plugins` (you may have to create the folder)
2. `git clone https://github.com/blimmer/zsh-aws-vault.git`
3. In your .zshrc, add `zsh-aws-vault` to your oh-my-zsh plugins:

```bash
plugins=(
  zsh-aws-vault
)
```

### [zgen](https://github.com/tarjoilija/zgen)

1. add `zgen load blimmer/zsh-aws-vault` to your '!saved/save' block
1. `zgen update`

## Upgrading

Some releases might have breaking changes to behaviors. Before upgrading, please review
[the Releases page](https://github.com/blimmer/zsh-aws-vault/releases) to understand the changes. This package follows
Semantic Versioning best-practices.

An upgrade guide for major versions is available in [UPGRADING.md](/UPGRADING.md).

## Features

This plugin provides a comprehensive set of tools for working with aws-vault:

- **Aliases** for common aws-vault commands:

  - `av` - aws-vault
  - `avs` - aws-vault server
  - `avl` - aws-vault login
  - `avll` - aws-vault login -s (prints the login URL to the screen without opening your browser)
  - `ave` - aws-vault exec

- **Convenience Functions**:

  - [`avsh`](#avsh) - Open a new shell with AWS credentials
  - [`avli`](#avli) - Login to AWS console in your default browser with profile isolation
  - [`avr`](#avr) - Refresh in-context `AWS_*` environment variables
  - `avp` - List all configured AWS profiles with their types (IAM Keys or Roles)

### `avli`

Login in an isolated browser profile.

> ℹ️ This function is currently only supported in MacOS and Linux.

This function will create a sandboxed browser profile after getting the temporary login URL for your AWS profile. This
allows opening multiple profiles simultaneously in different browser profiles. This differs from using incognito mode,
which shares the same profile across all incognito windows.

#### Specifying a Browser

You can specify a browser to use for `avli` by setting the `AWS_VAULT_PL_BROWSER` environment variable to the appropriate
browser.

In MacOS, we use the default browser set at the system level. On Linux, we use `xdg-settings` to find the default.

| Browser                   | `AWS_VAULT_PL_BROWSER` value (MacOS)  | `AWS_VAULT_PL_BROWSER` value (Linux) |
| ------------------------- | ------------------------------------- | ------------------------------------ |
| Firefox                   | `org.mozilla.firefox`                 |                                      |
| Firefox Developer Edition | `org.mozilla.firefoxdeveloperedition` |                                      |
| Chrome                    | `com.google.chrome`                   |                                      |
| Edge                      | `com.microsoft.edgemac`               |                                      |
| Edge Developer Edition    | `com.microsoft.edgemac.dev`           |                                      |
| Brave                     | `com.brave.Browser`                   |                                      |
| Vivaldi                   | `com.vivaldi.browser`                 |                                      |

#### Passing Additional Browser Launch Options

You can pass arbitrary parameters when launching your browser by setting the optional `AWS_VAULT_PL_BROWSER_LAUNCH_OPTS`
environment variable. For example, if you wanted to start new `avli` browser windows maximized, you can set
`AWS_VAULT_PL_BROWSER_LAUNCH_OPTS="--start-maximized"`. Refer to your browser documentation for possible options.

#### Reusing Sandboxed Profiles

By default, each time you run `avli`, a new, isolated browser profile is created. If you would like to reuse the same
browser profile between calls to `avli`, set the `AWS_VAULT_PL_PERSIST_PROFILE` environment variable to `true`.

This allows you to install extensions/addons, create bookmarks, retain history, etc. in the sandboxed browser.

### `avsh`

Create a shell for a given profile. For example, this command replaces the relevant `AWS_*` environment variables for
the `default` profile in a new shell session:

```bash
avsh default
```

This is a powerful tool that allows only placing AWS credentials in your shell session when needed.

### `avr`

Refresh your credentials without exiting the existing subshell. Requires `aws-vault` v7 or newer.

### Prompt Segment

This prompt segment echos out the current aws-vault profile you're logged into.
I use this for adding a segment into my custom
[agnoster theme](https://github.com/agnoster/agnoster-zsh-theme/blob/master/agnoster.zsh-theme).

For instance, this code:

```bash
prompt_aws_vault() {
  local vault_segment
  vault_segment="`prompt_aws_vault_segment`"
  [[ $vault_segment != '' ]] && prompt_segment cyan black "$vault_segment"
}
```

Produces this segment in my prompt:

![screenshot of agnoster theme with aws-vault segment](https://i.imgur.com/BLE0QXg.png)

The instructions to customize the prompt vary based on the [theme](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes) you
use. In some cases, you'll need to create a copy of the theme file and edit it to include the prompt segment. You can
check out my
[custom agnoster theme](https://github.com/blimmer/dotfiles/blob/fa46a6818dcd92c2b7c1a578b32166542c4febca/oh-my-zsh-custom/themes/agnoster.zsh-theme#L232)
to see how I updated the prompt.

#### Prompt Customization

You can customize the prompt segment behavior by overriding these variables:

| Variable Name                  | Default | Description                                                                 |
| ------------------------------ | ------- | --------------------------------------------------------------------------- |
| `AWS_VAULT_PL_CHAR`            | ☁       | The character to display when logged into an aws-vault profile              |
| `AWS_VAULT_PL_DEFAULT_PROFILE` | default | Only show the character when logged into this profile, not the profile name |

### Multi Factor Authentication (MFA)

You can override the default MFA prompt by adding the `AWS_VAULT_PL_MFA` environment variable.

| `AWS_VAULT_PL_MFA` value | Description                                                                                                                                                                 | Example                                                                                                    |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| inline                   | Enter your MFA token as an additional argument to the command.                                                                                                              | `avsh default 123456`<br>`avli default 123456`                                                             |
| yubikey                  | Generate an MFA token from your Yubikey. See the [docs](https://github.com/99designs/aws-vault/blob/master/USAGE.md#using-a-yubikey-as-a-virtual-mfa) for more information. | `avsh default`<br>`avsh default my-yubikey-profile`<br>`avli default`<br>`avli default my-yubikey-profile` |
