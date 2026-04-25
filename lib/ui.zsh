_ZSH_AI_C_RESET=$'\033[0m'
_ZSH_AI_C_CYAN=$'\033[36m'
_ZSH_AI_C_GREEN=$'\033[32m'
_ZSH_AI_C_YELLOW=$'\033[33m'
_ZSH_AI_C_RED=$'\033[31m'
_ZSH_AI_C_MAGENTA=$'\033[35m'
_ZSH_AI_C_DIM=$'\033[2m'
_ZSH_AI_C_BOLD=$'\033[1m'

_zsh_ai_thinking() {
  echo "${_ZSH_AI_C_BOLD}${_ZSH_AI_C_MAGENTA}$1${_ZSH_AI_C_RESET}" >&2
}

_zsh_ai_log() {
  echo "${_ZSH_AI_C_CYAN}$1${_ZSH_AI_C_RESET}" >&2
}

_zsh_ai_warn() {
  echo "${_ZSH_AI_C_YELLOW}$1${_ZSH_AI_C_RESET}" >&2
}

_zsh_ai_err() {
  echo "${_ZSH_AI_C_RED}$1${_ZSH_AI_C_RESET}" >&2
}

_zsh_ai_sanitize() {
  command sed $'s/\033\[[0-9;]*[a-zA-Z]//g; s/\r//g' | command tr -d $'\001-\010\013\014\016-\037'
}

_zsh_ai_cmd_display() {
  local cmd="$1"
  if [[ $(echo "$cmd" | wc -l) -gt 1 ]]; then
    _zsh_ai_log "(multi-line command)"
    echo "${_ZSH_AI_C_DIM}---${_ZSH_AI_C_RESET}" >&2
    echo "$cmd" | while IFS= read -r _line; do
      echo "${_ZSH_AI_C_GREEN}>${_ZSH_AI_C_RESET} ${_ZSH_AI_C_BOLD}$_line${_ZSH_AI_C_RESET}" >&2
    done
    echo "${_ZSH_AI_C_DIM}---${_ZSH_AI_C_RESET}" >&2
  else
    echo "${_ZSH_AI_C_GREEN}>${_ZSH_AI_C_RESET} ${_ZSH_AI_C_BOLD}$cmd${_ZSH_AI_C_RESET}" >&2
  fi
}

_zsh_ai_warn_dangerous() {
  local cmd="$1"
  local patterns='rm -rf|mkfs|dd if=|> /dev/|chmod -R 777|:(){ :|:& };:|shutdown|reboot|halt|kill -9 -1'
  if [[ "$cmd" =~ ($~patterns) ]]; then
    _zsh_ai_warn "WARNING: potentially destructive command detected"
    return 0
  fi
  return 1
}
