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

function avli() {
    # if OS X use `open` else maybe linux? use `xdg-open`
    local login_url="$(_aws_login_link $1)"
    if _using_osx ; then
        # TODO Known bugs here are that when you ifail a login it
        #      passes all the stdout to xargs and opens lots of tabs.
        # NOTE This opens the url in the default browser for os x
        echo "${login_url}" | xargs /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --incognito --new-window
        # TODO Augment this for firefox and safari too (OS X makes it
        #      near impossible to detect defaults. Closest I got was
        #      https://apple.stackexchange.com/questions/219582/default-browser-plist-location
        #      and
        #      https://www.google.com/search?q=os+x+defaults+read+detect+default+%22browser%22
    else
        # NOTE this hasn't been tested but should work the same
        xargs xdg-open
    fi
}

function _using_osx() {
    [[ $(uname) == "Darwin" ]]
}

function _aws_login_link() {
    avl -s $1
}

function av-profiles() {
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
