local proxy="${ZSH_AI_PROXY:-}"
local bypass=""
if [[ "${ZSH_AI_BYPASS:-false}" == "true" ]]; then
  bypass="--dangerously-skip-permissions"
fi

_zsh_ai_mk_alias() {
  if [[ -n "$proxy" ]]; then
    alias "$1"="$proxy $2"
  else
    alias "$1"="$2"
  fi
}

# Default aliases
if [[ "$ZSH_AI_SKIP_DEFAULTS" != "true" ]]; then
  _zsh_ai_mk_alias claude       "claude ${bypass}"
  _zsh_ai_mk_alias claude-safe  "claude"
  _zsh_ai_mk_alias cl           "claude ${bypass}"
  _zsh_ai_mk_alias clr          "claude ${bypass} --resume"
  _zsh_ai_mk_alias clc          "claude ${bypass} --continue"

  _zsh_ai_mk_alias codex        "codex"
  _zsh_ai_mk_alias co           "codex"
  _zsh_ai_mk_alias cor          "codex resume"

  _zsh_ai_mk_alias opencode     "opencode"
  _zsh_ai_mk_alias oc           "opencode"
  _zsh_ai_mk_alias occ          "opencode --continue"
fi

# User custom aliases
if (( ${+ZSH_AI_ALIASES} )); then
  local name cmd
  for name cmd in "${(@kv)ZSH_AI_ALIASES}"; do
    _zsh_ai_mk_alias "$name" "$cmd"
  done
fi

unfunction _zsh_ai_mk_alias
