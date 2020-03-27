#--------------------------------------------------------------------#
# Variables                                                          #
#--------------------------------------------------------------------#
AWS_VAULT_PL_DEFAULT_PROFILE=${AWS_VAULT_PL_DEFAULT_PROFILE:-default}
AWS_VAULT_PL_CHAR=${AWS_VAULT_PL_CHAR:-$'\u2601'} # "the cloud"
AWS_VAULT_PL_BROWSER=${AWS_VAULT_PL_BROWSER:-''}
<<<<<<< HEAD
AWS_VAULT_PL_MFA=${AWS_VAULT_PL_MFA:-''}
||||||| 2d11c48
=======
AWS_VAULT_PL_2FA=${AWS_VAULT_PL_2FA:-''}
>>>>>>> 92369cc8875627d23176f9fb8e500ebbb6bcfd3d

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
  case ${AWS_VAULT_PL_MFA} in
    inline)
      aws-vault exec -t $2 $1 -- zsh
      ;;
    yubikey)
      totp=${2:$1}
      aws-vault exec -t $(ykman oath code --single $totp) $1 -- zsh
      ;;
    *)
      aws-vault exec $1 -- zsh
      ;;
  esac
}

function avli() {
  local login_url
  case ${AWS_VAULT_PL_MFA} in
    inline)
      login_url="$(avll -t $2 $1)"
      ;;
    yubikey)
      totp=${2:-$1}
      login_url="$(avll -t $(ykman oath code --single $totp) $1)"
      ;;
    *)
      login_url="$(avll $1)"
      ;;
  esac

  if [ $? -ne 0 ]; then
    echo "Could not login" >&2
    return 1
  fi

  local browser="$(_find_browser)"

  if _using_osx ; then
    case $browser in
      org.mozilla.firefox)
        # Ensure a profile is created (can run idempotently) and launch it as a disowned process
        /Applications/Firefox.app/Contents/MacOS/firefox --CreateProfile $1 2>/dev/null && \
        /Applications/Firefox.app/Contents/MacOS/firefox --no-remote -P $1 "${login_url}" 2>/dev/null &!
        ;;
      com.google.chrome)
        echo "${login_url}" | xargs -t nohup /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome %U --no-first-run --new-window --disk-cache-dir=$(mktemp -d /tmp/chrome.XXXXXX) --user-data-dir=$(mktemp -d /tmp/chrome.XXXXXX) > /dev/null 2>&1 &
        ;;
      *)
        # NOTE PRs welcome to add your browser
        echo "Sorry, I don't know how to launch your default browser ($browser) :-("
        ;;
    esac
  elif _using_linux ; then
    case $browser in
      google-chrome)
        echo "${login_url}" | xargs -t nohup google-chrome %U --no-first-run --new-window --start-maximized --disk-cache-dir=$(mktemp -d /tmp/chrome.XXXXXX) --user-data-dir=$(mktemp -d /tmp/chrome.XXXXXX) > /dev/null 2>&1 &
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

function _using_linux() {
  [[ $(uname) == "Linux" ]]
}

function _find_browser() {
  if [ -n "$AWS_VAULT_PL_BROWSER" ]; then
    # use the browser bundle specified
    echo "$AWS_VAULT_PL_BROWSER"
  elif _using_osx ; then
    # Detect the browser in launchservices
    # https://stackoverflow.com/a/32465364/808678
    local prefs=~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
    plutil -convert xml1 $prefs
    grep 'https' -b3 $prefs | awk 'NR==2 {split($2, arr, "[><]"); print arr[3]}';
    plutil -convert binary1 $prefs
  elif _using_linux ; then
    # Always Chrome for now
    # NOTE PRs welcome to add your browser
    echo "google-chrome"
  else
    # TODO - other platforms
  fi
}
