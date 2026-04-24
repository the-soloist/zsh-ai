# zsh-ai

Oh-My-Zsh plugin for AI CLI aliases with configurable proxy and permission bypass.

## Install

Clone to oh-my-zsh custom plugins directory:

```sh
git clone https://github.com/the-soloist/zsh-ai.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```

Add `zsh-ai` to plugins in `.zshrc`:

```sh
plugins=(... zsh-ai)
```

## Configuration

Set before plugins are loaded in `.zshrc`:

```sh
# Proxy command prefix (optional)
export ZSH_AI_PROXY="proxychains4"

# Auto-inject --dangerously-skip-permissions for claude (default: "true")
export ZSH_AI_BYPASS="true"

# Skip all default aliases (default: unset)
# export ZSH_AI_SKIP_DEFAULTS="true"

# Custom aliases (optional, add or override defaults)
# typeset -gA ZSH_AI_ALIASES=(
#   aider  "aider"
#   gemini "gemini"
# )
```

## Default Aliases

| Alias | Command |
|-------|---------|
| `claude` | `claude --dangerously-skip-permissions` |
| `cr` | `claude --dangerously-skip-permissions --resume` |
| `cc` | `claude --dangerously-skip-permissions --continue` |
| `claude-safe` | `claude` |
| `codex` | `codex` |
| `or` | `codex resume` |

When `ZSH_AI_PROXY` is set (e.g., `px`), all commands are prefixed with the proxy command.

When `ZSH_AI_BYPASS` is set to `"false"`, `--dangerously-skip-permissions` is not injected.
