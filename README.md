# zsh-aws-vault
oh-my-zsh plugin for aws-vault

## Features

This plugin is pretty simple - it provides:
  - aliases
  - prompt segment

### Aliases

| Alias | Expression               |
|-------|--------------------------|
| av    | aws-vault                |
| ave   | aws-vault exec           |
| avl   | aws-vault login          |
| avs   | aws-vault server         |
| avsh  | aws-vault exec $1 -- zsh |

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
