# zsh-ai

Oh-My-Zsh plugin for AI CLI aliases, quick operations, and configurable proxy.

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

### Claude

| Alias | Command |
|-------|---------|
| `claude` | `claude --dangerously-skip-permissions` |
| `claude-safe` | `claude` |
| `cl` | `claude --dangerously-skip-permissions` |
| `clr` | `claude --dangerously-skip-permissions --resume` |
| `clc` | `claude --dangerously-skip-permissions --continue` |

### Codex

| Alias | Command |
|-------|---------|
| `codex` | `codex` |
| `co` | `codex` |
| `cor` | `codex resume` |

### OpenCode

| Alias | Command |
|-------|---------|
| `opencode` | `opencode` |
| `oc` | `opencode` |
| `occ` | `opencode --continue` |

When `ZSH_AI_PROXY` is set, all commands are prefixed with the proxy command.

When `ZSH_AI_BYPASS` is set to `"false"`, `--dangerously-skip-permissions` is not injected.

## Quick Operations

### Configuration

```sh
# AI backend: "claude" (default) / "codex" / "opencode" / "api"
export ZSH_AI_BACKEND="claude"

# Model (optional, backend-specific)
export ZSH_AI_MODEL="sonnet"

# Native API mode (when ZSH_AI_BACKEND="api")
export ZSH_AI_API_URL="https://api.anthropic.com/v1/messages"
export ZSH_AI_API_KEY="sk-ant-..."
export ZSH_AI_API_MODEL="claude-sonnet-4-20250514"
```

### Commands

#### `ask <description>`

Translate natural language to a shell command, then confirm before executing.

```sh
ask "find all files larger than 100MB"
#   find . -type f -size +100M
# Execute? [y]es / [e]dit / [*]cancel:
```

- `y` — execute directly
- `e` — load command into the edit buffer for modification
- other — cancel

#### `fix`

Send the last failed command to AI for a corrected version.

```sh
$ grep -r "pattern" --incldue="*.py" .
grep: unrecognized option '--incldue=*.py'

$ fix
# Analyzing: grep -r "pattern" --incldue="*.py" . (exit 2)...
#   grep -r "pattern" --include="*.py" .
# Execute? [y]es / [e]dit / [*]cancel:
```

### Backend Details

| Backend | One-shot command | No persistence |
|---------|-----------------|----------------|
| `claude` | `claude -p --no-session-persistence` | `--no-session-persistence` |
| `codex` | `codex exec --ephemeral` | `--ephemeral` |
| `opencode` | `opencode run` | N/A |
| `api` | `curl` + native HTTP request | N/A |
