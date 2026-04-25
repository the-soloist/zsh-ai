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

# Model (optional, for CLI backends)
export ZSH_AI_MODEL="haiku"
```

#### API Backend

When `ZSH_AI_BACKEND="api"`, configuration is loaded from a JSON config file:

```sh
# Config file path (default: $ZDOTDIR/zsh-ai/config.json)
# export ZSH_AI_CONFIG="$ZDOTDIR/zsh-ai/config.json"

# Select profile (default: config's "default" field)
# export ZSH_AI_API_PROFILE="anthropic"
```

Create the config file from the template:

```sh
export ZSH_AI_CONFIG=${ZDOTDIR:-~/.config/zsh}/zsh-ai/config.json
mkdir -p `dirname ${ZSH_AI_CONFIG}`
cp ${ZSH_CUSTOM}/plugins/zsh-ai/config.example.json ${ZSH_AI_CONFIG}
```

Config file supports multiple profiles with two API formats:

```json
{
  "default": "anthropic",
  "profiles": {
    "anthropic": {
      "api_format": "anthropic",
      "url": "https://api.anthropic.com/v1/messages",
      "api_key": "sk-ant-...",
      "model": "claude-sonnet-4-20250514"
    },
    "openai": {
      "api_format": "openai",
      "url": "https://api.openai.com/v1/chat/completions",
      "api_key": "sk-...",
      "model": "gpt-4o"
    }
  }
}
```

- `api_format: "anthropic"` — Anthropic API (x-api-key, content array response)
- `api_format: "openai"` — OpenAI-compatible API (Bearer token, choices array response). Works with OpenRouter, Ollama, etc.

Environment variables override config profile values when set:

```sh
# Override API endpoint
# export ZSH_AI_API_URL="https://api.anthropic.com/v1/messages"

# Override API key
# export ZSH_AI_API_KEY="sk-ant-..."

# Override model
# export ZSH_AI_API_MODEL="claude-sonnet-4-20250514"
```

### Commands

#### `ask <description>`

Translate natural language to a shell command, then confirm before executing.

```sh
ask "find all files larger than 100MB"
#   find . -type f -size +10M
# Execute? [y]es / [e]dit / [r]evise / [*]cancel:
```

- `y` — execute directly
- `e` — load command into the edit buffer for modification
- `r` — describe how to modify, AI will revise the command
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
