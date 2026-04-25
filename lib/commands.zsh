_ZSH_AI_LAST_EXIT_CODE=0

_zsh_ai_precmd() {
  _ZSH_AI_LAST_EXIT_CODE=$?
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zsh_ai_precmd

ask() {
  if [[ -z "$*" ]]; then
    echo "usage: ask <natural language description>" >&2
    return 1
  fi

  local prompt="You are a shell command generator. The user's shell is zsh on macOS.
Generate a shell command for the following task. Output ONLY the command itself, no explanation, no markdown formatting.

Task: $*"

  echo "Thinking..." >&2
  local cmd
  cmd=$(_zsh_ai_query "$prompt")
  if [[ -z "$cmd" ]]; then
    echo "No result from AI backend." >&2
    return 1
  fi

  echo "" >&2
  echo "  $cmd" >&2
  echo "" >&2

  local choice
  read "choice?Execute? [y]es / [e]dit / [*]cancel: "
  case "$choice" in
    y|Y)
      eval "$cmd"
      ;;
    e|E)
      print -z "$cmd"
      ;;
    *)
      echo "Cancelled." >&2
      ;;
  esac
}

fix() {
  local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
  local exit_code=$_ZSH_AI_LAST_EXIT_CODE

  if [[ $exit_code -eq 0 ]]; then
    echo "Last command succeeded (exit code 0), nothing to fix." >&2
    return 0
  fi

  local prompt="You are a shell command fixer. The user's shell is zsh on macOS.
The following command failed with exit code $exit_code:

$last_cmd

Analyze the likely cause and provide the corrected command. Output ONLY the corrected command, no explanation, no markdown formatting."

  echo "Analyzing: $last_cmd (exit $exit_code)..." >&2
  local cmd
  cmd=$(_zsh_ai_query "$prompt")
  if [[ -z "$cmd" ]]; then
    echo "No result from AI backend." >&2
    return 1
  fi

  echo "" >&2
  echo "  $cmd" >&2
  echo "" >&2

  local choice
  read "choice?Execute? [y]es / [e]dit / [*]cancel: "
  case "$choice" in
    y|Y)
      eval "$cmd"
      ;;
    e|E)
      print -z "$cmd"
      ;;
    *)
      echo "Cancelled." >&2
      ;;
  esac
}
