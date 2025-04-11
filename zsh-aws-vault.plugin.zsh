#--------------------------------------------------------------------#
# Variables                                                          #
#--------------------------------------------------------------------#
AWS_VAULT_PL_DEFAULT_PROFILE=${AWS_VAULT_PL_DEFAULT_PROFILE:-default}
AWS_VAULT_PL_CHAR=${AWS_VAULT_PL_CHAR:-$'\u2601'} # "the cloud"
AWS_VAULT_PL_BROWSER=${AWS_VAULT_PL_BROWSER:-''}
AWS_VAULT_PL_BROWSER_LAUNCH_OPTS=${AWS_VAULT_PL_BROWSER_LAUNCH_OPTS:-''}
AWS_VAULT_PL_MFA=${AWS_VAULT_PL_MFA:-''}
AWS_VAULT_PL_PERSIST_PROFILE=${AWS_VAULT_PL_PERSIST_PROFILE:-false}
AWS_VAULT_PL_PERSIST_PROFILE_PATH=${AWS_VAULT_PL_PERSIST_PROFILE_PATH:-"$HOME/.config/zsh-aws-vault/avli-profiles"}

#--------------------------------------------------------------------#
# Aliases                                                            #
#--------------------------------------------------------------------#
alias av='aws-vault'
alias avs='aws-vault server'
alias avl='aws-vault login'
alias avll='aws-vault login -s'
alias ave='aws-vault exec'
alias avr='eval $(AWS_VAULT=  aws-vault export --format=export-env $AWS_VAULT)'

#--------------------------------------------------------------------#
# Convenience Functions                                              #
#--------------------------------------------------------------------#
function avsh() {
  case ${AWS_VAULT_PL_MFA} in
    inline)
      aws-vault exec -t "$2" "$1" "${@:3}" -- zsh
      ;;
    yubikey)
      aws-vault exec --prompt ykman "$@" -- zsh
      ;;
    *)
      aws-vault exec "$@" -- zsh
      ;;
  esac
}

function avli() {
  function _using_osx() {
    [[ $(uname) == "Darwin" ]]
  }

  function _using_linux() {
    [[ $(uname) == "Linux" ]]
  }

  function _find_browser() {
    if [ -n "${AWS_VAULT_PL_BROWSER}" ]; then
      # use the browser bundle specified
      echo "${AWS_VAULT_PL_BROWSER}"
    elif [ -n "${BROWSER}" ]; then
        echo "${BROWSER}"
    elif _using_osx ; then
      # Detect the browser in launchservices
      # https://stackoverflow.com/a/32465364/808678
      local prefs=~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
      plutil -convert xml1 $prefs
      grep 'https' -b3 $prefs | awk 'NR==2 {split($2, arr, "[><]"); print arr[3]}';
      plutil -convert binary1 $prefs
    elif _using_linux ; then
      # This is bad but it's marginally better than hardcoding google-chrome
      xdg-settings get default-web-browser | cut -d'.' -f1
    else
      # TODO - other platforms
    fi
  }

  function _get_browser_profile_path() {
    local browser=$1
    local profile=$2
    local browser_profile_path=""

    if [ "$AWS_VAULT_PL_PERSIST_PROFILE" = "true" ]; then
      browser_profile_path="${AWS_VAULT_PL_PERSIST_PROFILE_PATH}/${browser}/${profile}"
      mkdir -p "${AWS_VAULT_PL_PERSIST_PROFILE_PATH}/${browser}"
    else
      browser_profile_path=$(mktemp --tmpdir -d $browser.$profile.XXXXXX)
    fi

    echo $browser_profile_path
  }

  function _maybe_clean_up_browser_profile() {
    local browser_profile_path=$1
    if [ "$AWS_VAULT_PL_PERSIST_PROFILE" = "false" ]; then
      rm -rf $browser_profile_path
    fi
  }

  local login_url
  case ${AWS_VAULT_PL_MFA} in
    inline)
      login_url="$(avll -t $2 $1 ${@:3})"
      ;;
    yubikey)
      login_url="$(avll --prompt ykman $@)"
      ;;
    *)
      login_url="$(avll $@)"
      ;;
  esac

  if [ $? -ne 0 ]; then
    echo "Could not login" >&2
    return 1
  fi

  local browser="$(_find_browser)"

  if _using_osx ; then
    local browser_profile_path=$(_get_browser_profile_path $browser $1)
    case $browser in
      org.mozilla.firefox)
        (
          nohup /Applications/Firefox.app/Contents/MacOS/firefox $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-remote --profile $browser_profile_path $login_url > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      org.mozilla.firefoxdeveloperedition)
        (
          nohup /Applications/Firefox\ Developer\ Edition.app/Contents/MacOS/firefox $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-remote --profile $browser_profile_path $login_url > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      com.google.chrome)
        (
          nohup /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "${login_url}" $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --disk-cache-dir="${browser_profile_path}" --user-data-dir="${browser_profile_path}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      com.microsoft.edgemac)
        (
          nohup /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "${login_url}" $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --disk-cache-dir="${browser_profile_path}" --user-data-dir="${browser_profile_path}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      com.microsoft.edgemac.dev)
        (
          nohup /Applications/Microsoft\ Edge\ Dev.app/Contents/MacOS/Microsoft\ Edge\ Dev "${login_url}" $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --disk-cache-dir="${browser_profile_path}" --user-data-dir="${browser_profile_path}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      com.brave.Browser|com.brave.browser)
        (
          nohup /Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser "${login_url}" $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --disk-cache-dir="${browser_profile_path}" --user-data-dir="${browser_profile_path}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      com.vivaldi.browser)
        (
          nohup /Applications/Vivaldi.app/Contents/MacOS/Vivaldi "${login_url}" $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --disk-cache-dir="${browser_profile_path}" --user-data-dir="${browser_profile_path}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      *)
        # NOTE PRs welcome to add your browser
        echo "Sorry, I don't know how to launch your default browser ($browser) :-("
        ;;
    esac
  elif _using_linux ; then
    local browser_profile_path=$(_get_browser_profile_path $browser $1)
    case $browser in
      *"chrom"*|*"brave"*|*"vivaldi"*)
        (
          nohup ${browser} $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --disk-cache-dir="${browser_profile_path}" --user-data-dir="${browser_profile_path}" "${login_url}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      *"firefox"*)
        (
          nohup ${browser} $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --profile "${browser_profile_path}" --no-remote --new-instance "${login_url}" > /dev/null 2>&1
          _maybe_clean_up_browser_profile "${browser_profile_path}"
        ) &!
        ;;
      *)
        rm -rf $browser_profile_path
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
