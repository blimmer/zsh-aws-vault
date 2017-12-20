#--------------------------------------------------------------------#
# Variables                                                          #
#--------------------------------------------------------------------#
AWS_VAULT_PL_DEFAULT_PROFILE=${AWS_VAULT_PL_DEFAULT_PROFILE:-default}
AWS_VAULT_PL_CHAR=${AWS_VAULT_PL_CHAR:-$'\u2601'} # "the cloud"

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

function aws-login() {
    aws-vault login $1
}

function aws-login-incognito() {
    aws-get-login-link $1 | xargs /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --incognito --new-window
}

function aws-get-login-link() {
    aws-vault login -s $1
}

function aws-profiles() {
    local -a profiles
    local _profile_text _role
    if egrep -arn "^\[default\]" ~/.aws/config >/dev/null; then
        profiles+="default: IAM_Keys"
    fi
    for item in $(grep "\[profile " ~/.aws/config | sed -e 's/.*profile \([a-zA-Z0-9_-]*\).*/\1/' | sort); do
        _profile_text="$item: "
        _role=$(aws --profile $item configure get role_arn)
        if [ "$_role" != "" ]; then
            _profile_text+="ROLE($_role) "
        fi
        profiles+=$_profile_text
    done
    printf '%s\n' "${profiles[@]}" | column -t
}

#--------------------------------------------------------------------#
# Prompt Customization                                               #
#--------------------------------------------------------------------#
function prompt_aws_vault_segment() {
  if [[ -n $AWS_VAULT ]]; then
    if [ "$AWS_VAULT" = "$AWS_VAULT_PL_DEFAULT_PROFILE" ]; then
      echo -n "$AWS_VAULT_PL_CHAR"
    else
      echo -n "$AWS_VAULT_PL_CHAR $AWS_VAULT"
    fi
  fi
}
