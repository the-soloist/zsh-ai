_ZSH_AI_LAST_EXIT_CODE=0

_zsh_ai_precmd() {
  _ZSH_AI_LAST_EXIT_CODE=$?
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zsh_ai_precmd

_zsh_ai_confirm() {
  local cmd="$1"
  local fix_retries=0
  local max_fix_retries=3

  while true; do
    echo "" >&2
    _zsh_ai_cmd_display "$cmd"
    _zsh_ai_warn_dangerous "$cmd"
    echo "" >&2

    local choice
    read "choice?Execute? ${_ZSH_AI_C_DIM}[Y]es / [E]dit / [R]evise / [C]ancel:${_ZSH_AI_C_RESET} "
    case "$choice" in
      y|Y|"")
        local output exit_code
        output=$(eval "$cmd" 2>&1)
        exit_code=$?
        [[ -n "$output" ]] && echo "$output" >&2

        if [[ $exit_code -ne 0 ]] && [[ "${ZSH_AI_AUTO_FIX:-true}" == "true" ]] && (( fix_retries < max_fix_retries )); then
          ((fix_retries++))
          _zsh_ai_warn "Command failed (exit $exit_code). Auto-fixing ($fix_retries/$max_fix_retries)..."
          local fix_prompt="You are a shell command fixer. The user's shell is zsh on macOS.
The following command failed with exit code $exit_code:

$cmd

Command output:
$output

Analyze the cause and provide the corrected command. Output ONLY the corrected command, no explanation, no markdown formatting."
          _zsh_ai_thinking "Fixing..."
          cmd=$(_zsh_ai_query "$fix_prompt")
          if [[ -z "$cmd" ]]; then
            _zsh_ai_err "No fix suggestion from AI backend."
            return $exit_code
          fi
          cmd=$(echo "$cmd" | _zsh_ai_sanitize)
          continue
        fi
        if [[ $exit_code -ne 0 ]] && (( fix_retries >= max_fix_retries )); then
          _zsh_ai_err "Auto-fix failed after $max_fix_retries attempts."
        fi
        return $exit_code
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
        cmd=$(echo "$cmd" | _zsh_ai_sanitize)
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

  cmd=$(echo "$cmd" | _zsh_ai_sanitize)
  _zsh_ai_confirm "$cmd"
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

  cmd=$(echo "$cmd" | _zsh_ai_sanitize)
  _zsh_ai_confirm "$cmd"
}
