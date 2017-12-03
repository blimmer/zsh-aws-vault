#--------------------------------------------------------------------#
# Aliases                                                            #
#--------------------------------------------------------------------#
alias av='aws-vault'
alias ave='aws-vault exec'
alias avl='aws-vault login'
alias avs='aws-vault server'

#--------------------------------------------------------------------#
# Convenience Functions                                              #
#--------------------------------------------------------------------#
function avsh() {
  aws-vault exec $1 -- zsh
}

#--------------------------------------------------------------------#
# Prompt Customization                                               #
#--------------------------------------------------------------------#
function prompt_aws_vault_segment() {
  local PL_VAULT_CHAR

  () {
    PL_VAULT_CHAR=$'\u2601' # "the cloud"
  }

  if [[ -n $AWS_VAULT ]]; then
    echo -n "$PL_VAULT_CHAR $AWS_VAULT"
  fi
}
