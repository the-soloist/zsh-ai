# zsh-ai - AI CLI aliases and quick operations
#
# Alias configuration:
#   ZSH_AI_PROXY           - proxy command prefix (e.g., "proxychains4")
#   ZSH_AI_SKIP_DEFAULTS   - set to "true" to skip default aliases
#   ZSH_AI_BYPASS          - auto-inject --dangerously-skip-permissions (default: "true")
#   ZSH_AI_ALIASES         - associative array of extra/override aliases
#
# Quick operations configuration:
#   ZSH_AI_BACKEND         - "claude" (default) / "codex" / "opencode" / "api"
#   ZSH_AI_MODEL           - model name (optional, backend-specific)
#   ZSH_AI_API_URL         - API endpoint (required when ZSH_AI_BACKEND="api")
#   ZSH_AI_API_KEY         - API key (required when ZSH_AI_BACKEND="api")
#   ZSH_AI_API_MODEL       - model for API calls (required when ZSH_AI_BACKEND="api")

local _zsh_ai_dir="${0:A:h}"

source "${_zsh_ai_dir}/lib/aliases.zsh"
source "${_zsh_ai_dir}/lib/backend.zsh"
source "${_zsh_ai_dir}/lib/commands.zsh"
