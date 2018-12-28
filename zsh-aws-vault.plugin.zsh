#--------------------------------------------------------------------#
# Variables                                                          #
#--------------------------------------------------------------------#
AWS_VAULT_PL_DEFAULT_PROFILE=${AWS_VAULT_PL_DEFAULT_PROFILE:-default}
AWS_VAULT_PL_CHAR=${AWS_VAULT_PL_CHAR:-$'\u2601'} # "the cloud"
AWS_VAULT_PL_BROWSER=${AWS_VAULT_PL_BROWSER:-''}

#--------------------------------------------------------------------#
# Aliases                                                            #
#--------------------------------------------------------------------#
alias av='aws-vault'
alias ave='aws-vault exec'
alias avl='aws-vault login'
alias avs='aws-vault server'
alias avll='avl -s'

#--------------------------------------------------------------------#
# Convenience Functions                                              #
#--------------------------------------------------------------------#
function avsh() {
  aws-vault exec $1 -- zsh
}

function avli() {
  local login_url
  login_url="$(avll $1)"

  if [ $? -ne 0 ]; then
    echo "Could not login" >&2
    return 1
  fi

  if _using_osx ; then
    local browser="$(_find_browser)"

    case $browser in
      org.mozilla.firefox)
        # Ensure a profile is created (can run idempotently) and launch it as a disowned process
        /Applications/Firefox.app/Contents/MacOS/firefox --CreateProfile $1 2>/dev/null && \
        /Applications/Firefox.app/Contents/MacOS/firefox --no-remote -P $1 "${login_url}" 2>/dev/null &!
        ;;
      com.google.chrome)
        echo "${login_url}" | xargs /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --incognito --new-window
        ;;
      *)
        # NOTE PRs welcome to add your browser
        echo "Sorry, I don't know how to launch your default browser ($browser) :-("
        ;;
    esac

  else
    # NOTE this is untested - PRs welcome to improve it.
    echo "${login_url}" | xargs xdg-open
  fi
}

function avp() {
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

#--------------------------------------------------------------------#
# Utility Functions                                                  #
#--------------------------------------------------------------------#
function _using_osx() {
  [[ $(uname) == "Darwin" ]]
}

function _find_browser() {
  if [ -n "$AWS_VAULT_PL_BROWSER" ]; then
    echo "$AWS_VAULT_PL_BROWSER"
  fi
  if _using_osx ; then
    # https://stackoverflow.com/a/32465364/808678
    local prefs=~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
    plutil -convert xml1 $prefs
    grep 'https' -b3 $prefs | awk 'NR==2 {split($2, arr, "[><]"); print arr[3]}';
    plutil -convert binary1 $prefs
  else
    # TODO
  fi
}
