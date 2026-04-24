# zsh-ai - AI CLI aliases with configurable proxy
#
# Configuration (set in .zshrc before plugins are loaded):
#   ZSH_AI_PROXY           - proxy command prefix (e.g., "proxychains4")
#   ZSH_AI_SKIP_DEFAULTS   - set to "true" to skip default aliases
#   ZSH_AI_BYPASS          - auto-inject --dangerously-skip-permissions (default: "true")
#   ZSH_AI_ALIASES         - associative array of extra/override aliases
#                            key = alias name, value = "command [args...]"

local proxy="${ZSH_AI_PROXY:-}"
local bypass=""
if [[ "${ZSH_AI_BYPASS:-true}" == "true" ]]; then
  bypass=" --dangerously-skip-permissions"
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
  _zsh_ai_mk_alias claude      "claude${bypass}"
  _zsh_ai_mk_alias clr          "claude${bypass} --resume"
  _zsh_ai_mk_alias clc          "claude${bypass} --continue"
  _zsh_ai_mk_alias claude-safe "claude"

  _zsh_ai_mk_alias codex       "codex"
  _zsh_ai_mk_alias cor          "codex resume"
fi

# User custom aliases (add or override)
if (( ${+ZSH_AI_ALIASES} )); then
  local name cmd
  for name cmd in "${(@kv)ZSH_AI_ALIASES}"; do
    _zsh_ai_mk_alias "$name" "$cmd"
  done
fi

unfunction _zsh_ai_mk_alias
