#--------------------------------------------------------------------#
# Variables                                                          #
#--------------------------------------------------------------------#
AWS_VAULT_PL_DEFAULT_PROFILE=${AWS_VAULT_PL_DEFAULT_PROFILE:-default}
AWS_VAULT_PL_CHAR=${AWS_VAULT_PL_CHAR:-$'\u2601'} # "the cloud"
AWS_VAULT_PL_BROWSER=${AWS_VAULT_PL_BROWSER:-''}
AWS_VAULT_PL_BROWSER_LAUNCH_OPTS=${AWS_VAULT_PL_BROWSER_LAUNCH_OPTS:-''}
AWS_VAULT_PL_MFA=${AWS_VAULT_PL_MFA:-''}

#--------------------------------------------------------------------#
# Aliases                                                            #
#--------------------------------------------------------------------#
alias av='aws-vault'
alias avs='aws-vault server'
alias avl='aws-vault login'
alias avll='aws-vault login -s'
alias ave='aws-vault exec'

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
    case $browser in
      org.mozilla.firefox)
        # Ensure a profile is created (can run idempotently) and launch it as a disowned process
        /Applications/Firefox.app/Contents/MacOS/firefox --CreateProfile $1 2>/dev/null && \
        /Applications/Firefox.app/Contents/MacOS/firefox $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-remote -P $1 "${login_url}" 2>/dev/null &!
        ;;
      org.mozilla.firefoxdeveloperedition)
        /Applications/Firefox\ Developer\ Edition.app/Contents/MacOS/firefox --CreateProfile $1 2>/dev/null && \
        /Applications/Firefox\ Developer\ Edition.app/Contents/MacOS/firefox $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-remote -P $1 "${login_url}" 2>/dev/null &!
        ;;
      com.google.chrome)
        echo "${login_url}" | xargs -t nohup /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome %U $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --new-window --disk-cache-dir=$(mktemp -d /tmp/chrome.XXXXXX) --user-data-dir=$(mktemp -d /tmp/chrome.XXXXXX) > /dev/null 2>&1 &
        ;;
      com.microsoft.edgemac)
        echo "${login_url}" | xargs -t nohup /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge %U $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --new-window --disk-cache-dir=$(mktemp -d /tmp/msedge.XXXXXX) --user-data-dir=$(mktemp -d /tmp/msedge.XXXXXX) > /dev/null 2>&1 &
        ;;
      com.microsoft.edgemac.dev)
        echo "${login_url}" | xargs -t nohup /Applications/Microsoft\ Edge\ Dev.app/Contents/MacOS/Microsoft\ Edge\ Dev %U $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --new-window --disk-cache-dir=$(mktemp -d /tmp/msedgedev.XXXXXX) --user-data-dir=$(mktemp -d /tmp/msedgedev.XXXXXX) > /dev/null 2>&1 &
        ;;
      com.brave.Browser|com.brave.browser)
        echo "${login_url}" | xargs -t nohup /Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser %U $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --new-window --disk-cache-dir=$(mktemp -d /tmp/brave.XXXXXX) --user-data-dir=$(mktemp -d /tmp/brave.XXXXXX) > /dev/null 2>&1 &
        ;;
      com.vivaldi.browser)
        echo "${login_url}" | xargs -t nohup /Applications/Vivaldi.app/Contents/MacOS/Vivaldi %U $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --new-window --disk-cache-dir=$(mktemp -d /tmp/vivaldi.XXXXXX) --user-data-dir=$(mktemp -d /tmp/vivaldi.XXXXXX) > /dev/null 2>&1 &
        ;;
      *)
        # NOTE PRs welcome to add your browser
        echo "Sorry, I don't know how to launch your default browser ($browser) :-("
        ;;
    esac
  elif _using_linux ; then
    AVLI_TMP_PROFILE=$(mktemp --tmpdir -d avli.XXXXXX)
    case $browser in
      *"chrom"*|*"brave"*|*"vivaldi"*)
        (${browser} $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS --no-first-run --new-window --disk-cache-dir="${AVLI_TMP_PROFILE}" --user-data-dir="${AVLI_TMP_PROFILE}" "${login_url}" 2>/dev/null && rm -rf "${AVLI_TMP_PROFILE}") &!
        ;;
      *"firefox"*)
        (${browser} $AWS_VAULT_PL_BROWSER_LAUNCH_OPTS -profile "${AVLI_TMP_PROFILE}" -no-remote -new-instance "${login_url}" 2>/dev/null && rm -rf "${AVLI_TMP_PROFILE}") &!
        ;;
      *)
        rm -rf "${AVLI_TMP_PROFILE}"
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
