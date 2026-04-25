# zsh-ai - AI CLI aliases and quick operations
#
# Alias configuration:
#   ZSH_AI_PROXY           - proxy command prefix (e.g., "proxychains4")
#   ZSH_AI_SKIP_DEFAULTS   - set to "true" to skip default aliases
#   ZSH_AI_BYPASS          - auto-inject --dangerously-skip-permissions (default: "false")
#   ZSH_AI_ALIASES         - associative array of extra/override aliases
#
# Quick operations configuration:
#   ZSH_AI_BACKEND         - "claude" (default) / "codex" / "opencode" / "api"
#   ZSH_AI_MODEL           - model name (optional, for CLI backends)
#   ZSH_AI_CONFIG           - API config file path (default: $ZDOTDIR/zsh-ai/config.json)
#   ZSH_AI_API_PROFILE      - API profile name (default: config's "default" field)
#   ZSH_AI_AUTO_FIX          - auto-fix failed commands in ask (default: "true")
#   ZSH_AI_API_URL/KEY/MODEL - override config profile values

local _zsh_ai_dir="${0:A:h}"

source "${_zsh_ai_dir}/lib/aliases.zsh"
source "${_zsh_ai_dir}/lib/ui.zsh"
source "${_zsh_ai_dir}/lib/backend.zsh"
source "${_zsh_ai_dir}/lib/commands.zsh"
source "${_zsh_ai_dir}/lib/agent.zsh"
