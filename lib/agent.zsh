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

    cmd=$(echo "$cmd" | _zsh_ai_sanitize)

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
    local is_dangerous=1
    _zsh_ai_warn_dangerous "$cmd" && is_dangerous=0
    echo "" >&2

    local output="" exit_code=0

    if (( auto_approve )) && (( is_dangerous )); then
      output=$(eval "$cmd" 2>&1)
      exit_code=$?
      [[ -n "$output" ]] && echo "$output" >&2
    else
      if (( auto_approve )) && ! (( is_dangerous )); then
        _zsh_ai_warn "Auto-approve paused: dangerous command requires confirmation."
      fi
      local choice
      read "choice?${_ZSH_AI_C_DIM}[Y]es / [E]dit / [R]evise / [S]kip / [A]uto / [C]ancel:${_ZSH_AI_C_RESET} "

      case "$choice" in
        y|Y|"")
          output=$(eval "$cmd" 2>&1)
          exit_code=$?
          [[ -n "$output" ]] && echo "$output" >&2
          ;;
        e|E)
          local edited="$cmd"
          vared edited
          edited=$(echo "$edited" | _zsh_ai_sanitize)
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
