_ZSH_AI_LAST_EXIT_CODE=0

_zsh_ai_precmd() {
  _ZSH_AI_LAST_EXIT_CODE=$?
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zsh_ai_precmd

# colors
_ZSH_AI_C_RESET=$'\033[0m'
_ZSH_AI_C_CYAN=$'\033[36m'
_ZSH_AI_C_GREEN=$'\033[32m'
_ZSH_AI_C_YELLOW=$'\033[33m'
_ZSH_AI_C_RED=$'\033[31m'
_ZSH_AI_C_MAGENTA=$'\033[35m'
_ZSH_AI_C_DIM=$'\033[2m'
_ZSH_AI_C_BOLD=$'\033[1m'

_zsh_ai_thinking() {
  echo "${_ZSH_AI_C_BOLD}${_ZSH_AI_C_MAGENTA}⟳ $1${_ZSH_AI_C_RESET}" >&2
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

_zsh_ai_confirm() {
  local cmd="$1"

  while true; do
    echo "" >&2
    _zsh_ai_cmd_display "$cmd"
    _zsh_ai_warn_dangerous "$cmd"
    echo "" >&2

    local choice
    read "choice?Execute? ${_ZSH_AI_C_DIM}[Y]es / [E]dit / [R]evise / [C]ancel:${_ZSH_AI_C_RESET} "
    case "$choice" in
      y|Y|"")
        eval "$cmd"
        return
        ;;
      e|E)
        print -z "$cmd"
        return
        ;;
      r|R)
        local feedback
        read "feedback?${_ZSH_AI_C_DIM}Revise:${_ZSH_AI_C_RESET} "
        if [[ -z "$feedback" ]]; then
          _zsh_ai_warn "No feedback provided."
          continue
        fi
        local prompt="You are a shell command generator. The user's shell is zsh on macOS.
The current command is:

$cmd

The user wants to modify it: $feedback

Output ONLY the revised command, no explanation, no markdown formatting."
        _zsh_ai_thinking "Revising..."
        cmd=$(_zsh_ai_query "$prompt")
        if [[ -z "$cmd" ]]; then
          _zsh_ai_err "No result from AI backend."
          return 1
        fi
        ;;
      *)
        _zsh_ai_log "Cancelled."
        return
        ;;
    esac
  done
}

ask() {
  local verbose=0
  local -a args
  for arg in "$@"; do
    case "$arg" in
      -v|--verbose) verbose=1 ;;
      *) args+=("$arg") ;;
    esac
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    _zsh_ai_warn "usage: ask [-v] <natural language description>"
    return 1
  fi

  local prompt="You are a shell command generator. The user's shell is zsh on macOS.
Generate a shell command for the following task. Output ONLY the command itself, no explanation, no markdown formatting.

Task: ${args[*]}"

  _zsh_ai_thinking "Thinking..."
  local cmd
  cmd=$(_zsh_ai_query "$prompt" "$verbose")
  if [[ -z "$cmd" ]]; then
    _zsh_ai_err "No result from AI backend."
    return 1
  fi

  _zsh_ai_confirm "$cmd"
}

ask-agent() {
  local verbose=0
  local max_steps=20
  local -a args
  for arg in "$@"; do
    case "$arg" in
      -v|--verbose) verbose=1 ;;
      *) args+=("$arg") ;;
    esac
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    _zsh_ai_warn "usage: ask-agent [-v] <task description>"
    return 1
  fi

  local task="${args[*]}"
  local -a history
  local step=0
  local auto_approve=0

  _zsh_ai_log "Task: $task"

  while (( step < max_steps )); do
    ((step++))

    local context=""
    if [[ ${#history[@]} -gt 0 ]]; then
      context="Previous steps:
$(printf '%s\n' "${history[@]}")

"
    fi

    local prompt="You are a shell automation agent. The user's shell is zsh on macOS.
Your task: $task

${context}Based on the task and any previous results, decide what to do next.

Rules:
- If the task is complete, output exactly: [DONE]
- If the task cannot be completed, output exactly: [FAILED] reason
- Otherwise, output ONLY the next shell command to run, no explanation, no markdown formatting."

    echo "" >&2
    _zsh_ai_thinking "[Step $step] Thinking..."
    local cmd
    cmd=$(_zsh_ai_query "$prompt" "$verbose")

    if [[ -z "$cmd" ]]; then
      _zsh_ai_err "No result from AI backend."
      return 1
    fi

    if [[ "$cmd" == "[DONE]"* ]]; then
      echo "" >&2
      _zsh_ai_log "Task completed."
      return 0
    fi
    if [[ "$cmd" == "[FAILED]"* ]]; then
      echo "" >&2
      _zsh_ai_err "$cmd"
      return 1
    fi

    echo "" >&2
    _zsh_ai_cmd_display "$cmd"
    _zsh_ai_warn_dangerous "$cmd"
    echo "" >&2

    local output="" exit_code=0

    if (( auto_approve )); then
      output=$(eval "$cmd" 2>&1)
      exit_code=$?
      [[ -n "$output" ]] && echo "$output" >&2
    else
      local choice
      read "choice?${_ZSH_AI_C_DIM}[Y]es / [E]dit / [R]evise / [S]kip / [A]ll / [C]ancel:${_ZSH_AI_C_RESET} "

      case "$choice" in
        y|Y|"")
          output=$(eval "$cmd" 2>&1)
          exit_code=$?
          [[ -n "$output" ]] && echo "$output" >&2
          ;;
        e|E)
          local edited="$cmd"
          vared edited
          output=$(eval "$edited" 2>&1)
          exit_code=$?
          cmd="$edited"
          [[ -n "$output" ]] && echo "$output" >&2
          ;;
        r|R)
          local feedback
          read "feedback?${_ZSH_AI_C_DIM}Revise:${_ZSH_AI_C_RESET} "
          if [[ -n "$feedback" ]]; then
            history+=("[Step $step] AI suggested: $cmd | User feedback: $feedback")
          fi
          continue
          ;;
        s|S)
          history+=("[Step $step] Command: $cmd | Result: SKIPPED")
          continue
          ;;
        a|A)
          auto_approve=1
          output=$(eval "$cmd" 2>&1)
          exit_code=$?
          [[ -n "$output" ]] && echo "$output" >&2
          ;;
        *)
          _zsh_ai_log "Cancelled."
          return 0
          ;;
      esac
    fi

    local truncated="$output"
    if [[ $(echo "$output" | wc -l) -gt 50 ]]; then
      truncated="$(echo "$output" | head -20)
... (truncated) ...
$(echo "$output" | tail -20)"
    fi

    history+=("[Step $step] Command: $cmd | Exit: $exit_code | Output:
$truncated")
  done

  _zsh_ai_err "Reached max steps ($max_steps)."
  return 1
}

fix() {
  local verbose=0
  [[ "$1" == "-v" || "$1" == "--verbose" ]] && verbose=1

  local last_cmd=$(fc -ln -1 | command sed 's/^[[:space:]]*//')
  local exit_code=$_ZSH_AI_LAST_EXIT_CODE

  if [[ $exit_code -eq 0 ]]; then
    _zsh_ai_log "Last command succeeded (exit code 0), nothing to fix."
    return 0
  fi

  local prompt="You are a shell command fixer. The user's shell is zsh on macOS.
The following command failed with exit code $exit_code:

$last_cmd

Analyze the likely cause and provide the corrected command. Output ONLY the corrected command, no explanation, no markdown formatting."

  _zsh_ai_thinking "Analyzing: $last_cmd (exit $exit_code)..."
  local cmd
  cmd=$(_zsh_ai_query "$prompt" "$verbose")
  if [[ -z "$cmd" ]]; then
    _zsh_ai_err "No result from AI backend."
    return 1
  fi

  _zsh_ai_confirm "$cmd"
}
