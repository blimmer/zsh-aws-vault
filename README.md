# zsh-aws-vault
oh-my-zsh plugin for [aws-vault](https://github.com/99designs/aws-vault)

## Installation

### [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)

This plugin is intended to be used with oh-my-zsh

1. `$ cd ~/.oh-my-zsh/custom/plugins` (you may have to create the folder)
2. `$ git clone git@github.com:blimmer/zsh-aws-vault.git`
3. In your .zshrc, add `zsh-aws-vault` to your oh-my-zsh plugins:

  ```bash
  plugins=(
    git
    ruby
    zsh-aws-vault
  )
  ```

### [zgen](https://github.com/tarjoilija/zgen)

1. add `zgen load blimmer/zsh-aws-vault` to your '!saved/save' block
1. `zgen update`

## Features

This plugin is pretty simple - it provides:
  - aliases
  - prompt segment

### Aliases

| Alias | Expression                                 |
|-------|--------------------------------------------|
| av    | aws-vault                                  |
| ave   | aws-vault exec                             |
| avl   | aws-vault login                            |
| avll  | aws-vault login -s                         |
| avli  | aws-vault login in private browsing window |
| avs   | aws-vault server                           |
| avsh  | aws-vault exec $1 -- zsh                   |
| avp   | list aws config / role ARNs                |

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

#### Prompt Customization
You can customize the prompt segment behavior by overriding these variables:

| Variable Name                  | Default | Description                                                                 |
|--------------------------------|---------|-----------------------------------------------------------------------------|
| `AWS_VAULT_PL_CHAR`            | ☁       | The character to display when logged into an aws-vault profile              |
| `AWS_VAULT_PL_DEFAULT_PROFILE` | default | Only show the character when logged into this profile, not the profile name |
