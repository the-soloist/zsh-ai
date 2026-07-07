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

## Environment Variables

All variables are set in `.zshrc` before plugins are loaded.

### Aliases

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_AI_PROXY` | `""` | Proxy command prefix (e.g., `proxychains4`, `proxychains4 -q`) |
| `ZSH_AI_PERMISSION` | `"default"` | Claude permission mode injected into claude aliases: `default` / `auto` / `bypass` |
| `ZSH_AI_SKIP_DEFAULTS` | unset | Set to `"true"` to skip all default aliases |
| `ZSH_AI_ALIASES` | unset | Associative array of extra/override aliases |

`ZSH_AI_PERMISSION` controls the flag injected into the `claude`, `cl`, `clr`, `clc` aliases:

| Value | Injected flag | Behavior |
|-------|---------------|----------|
| `default` | *(none)* | Standard step-by-step permission prompts |
| `auto` | `--permission-mode auto` | Auto-approve low-risk operations, still prompt for risky ones |
| `bypass` | `--dangerously-skip-permissions` | Skip all permission prompts |

### Quick Operations

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_AI_BACKEND` | `"claude"` | AI backend: `claude` / `codex` / `opencode` / `api` |
| `ZSH_AI_MODEL` | `""` | Model name for CLI backends (e.g., `haiku`, `sonnet`) |
| `ZSH_AI_AUTO_FIX` | `"true"` | Auto-fix failed commands in `ask` |

### API Backend

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_AI_CONFIG` | `$ZDOTDIR/zsh-ai/config.json` | API config file path |
| `ZSH_AI_API_PROFILE` | config's `default` field | API profile name |
| `ZSH_AI_API_URL` | from profile | Override API endpoint |
| `ZSH_AI_API_KEY` | from profile | Override API key |
| `ZSH_AI_API_MODEL` | from profile | Override model |

## Configuration Example

```sh
# @ zsh-ai
export ZSH_AI_PROXY="proxychains4"
export ZSH_AI_PERMISSION="bypass"
export ZSH_AI_BACKEND="claude"
export ZSH_AI_MODEL="haiku"

# Custom aliases (optional)
# typeset -gA ZSH_AI_ALIASES=(
#   aider  "aider"
#   gemini "gemini"
# )
```

## Default Aliases

### Claude

`<perm>` below is the flag injected by `ZSH_AI_PERMISSION` (empty for `default`).

| Alias | Command |
|-------|---------|
| `claude` | `claude <perm>` |
| `claude-safe` | `claude` |
| `cl` | `claude <perm>` |
| `clr` | `claude <perm> --resume` |
| `clc` | `claude <perm> --continue` |

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

Claude aliases inject a permission flag based on `ZSH_AI_PERMISSION` (`default` → none, `auto` → `--permission-mode auto`, `bypass` → `--dangerously-skip-permissions`). `claude-safe` always runs without any flag.

## Quick Operations

### `ask <description>`

Translate natural language to a shell command, then confirm before executing. If the command fails, auto-fix is triggered (controlled by `ZSH_AI_AUTO_FIX`).

```sh
ask "find all files larger than 100MB"
# > find . -type f -size +100M
# Execute? [Y]es / [E]dit / [R]evise / [C]ancel:
```

- `Y` — execute directly (auto-fix if failed)
- `E` — load command into the edit buffer for modification
- `R` — describe how to modify, AI will revise the command
- `C` — cancel

Use `-v` for verbose AI output.

### `ask-agent <task>`

Multi-step agent loop. AI generates commands based on previous results until the task is complete.

```sh
ask-agent "find all python files with TODO comments and list them"
# Task: find all python files with TODO comments and list them
#
# [Step 1] Thinking...
# > find . -name "*.py" -exec grep -l "TODO" {} +
# [Y]es / [E]dit / [R]evise / [S]kip / [A]uto / [C]ancel: y
# ./src/main.py
# ./lib/utils.py
#
# [Step 2] Thinking...
# Task completed.
```

- `Y` — execute command, feed output to AI for next step
- `E` — edit command inline before executing
- `R` — describe revision, AI regenerates without executing
- `S` — skip this step, continue to next
- `A` — auto-approve all subsequent commands (pauses on dangerous commands)
- `C` — cancel

Max 20 steps per session. Use `-v` for verbose AI output.

### `fix`

Send the last failed command to AI for a corrected version.

```sh
$ grep -r "pattern" --incldue="*.py" .
grep: unrecognized option '--incldue=*.py'

$ fix
# Analyzing: grep -r "pattern" --incldue="*.py" . (exit 2)...
# > grep -r "pattern" --include="*.py" .
# Execute? [Y]es / [E]dit / [R]evise / [C]ancel:
```

Use `-v` for verbose AI output.

## API Backend Setup

When `ZSH_AI_BACKEND="api"`, configuration is loaded from a JSON config file.

Create the config file from the template:

```sh
export ZSH_AI_CONFIG=${ZDOTDIR:-~/.config/zsh}/zsh-ai/config.json
mkdir -p $(dirname ${ZSH_AI_CONFIG})
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

## Backend Details

| Backend | One-shot command | No persistence |
|---------|-----------------|----------------|
| `claude` | `claude -p --no-session-persistence` | `--no-session-persistence` |
| `codex` | `codex exec --ephemeral` | `--ephemeral` |
| `opencode` | `opencode run` | N/A |
| `api` | `curl` + native HTTP request | N/A |
