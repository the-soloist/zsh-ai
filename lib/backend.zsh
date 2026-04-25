_zsh_ai_strip_markdown() {
  command sed -n '/^```/{n; :loop; /^```/q; p; n; b loop}; /^```/!p'
}

_zsh_ai_load_api_profile() {
  local config_file="${ZSH_AI_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh-ai/config.json}"
  if [[ ! -f "$config_file" ]]; then
    echo "zsh-ai: config file not found: $config_file" >&2
    return 1
  fi

  local profile="${ZSH_AI_API_PROFILE:-$(jq -r '.default // empty' "$config_file")}"
  if [[ -z "$profile" ]]; then
    echo "zsh-ai: no profile specified and no default in config" >&2
    return 1
  fi

  local profile_data
  profile_data=$(jq -e ".profiles[\"$profile\"]" "$config_file" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "zsh-ai: profile '$profile' not found in config" >&2
    return 1
  fi

  # env vars override config values
  _ZSH_AI_API_FORMAT=$(echo "$profile_data" | jq -r '.api_format // "anthropic"')
  _ZSH_AI_API_URL="${ZSH_AI_API_URL:-$(echo "$profile_data" | jq -r '.url')}"
  _ZSH_AI_API_KEY="${ZSH_AI_API_KEY:-$(echo "$profile_data" | jq -r '.api_key')}"
  _ZSH_AI_API_MODEL="${ZSH_AI_API_MODEL:-$(echo "$profile_data" | jq -r '.model')}"
}

_zsh_ai_api_anthropic() {
  local prompt="$1" url="$2" key="$3" model="$4"
  local payload
  payload=$(jq -nc \
    --arg model "$model" \
    --arg content "$prompt" \
    '{model: $model, max_tokens: 1024, messages: [{role: "user", content: $content}]}')
  curl -sS "$url" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $key" \
    -H "anthropic-version: 2023-06-01" \
    -d "$payload" 2>/dev/null \
    | jq -r '.content[] | select(.type == "text") | .text'
}

_zsh_ai_api_openai() {
  local prompt="$1" url="$2" key="$3" model="$4"
  local payload
  payload=$(jq -nc \
    --arg model "$model" \
    --arg content "$prompt" \
    '{model: $model, messages: [{role: "user", content: $content}]}')
  curl -sS "$url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $key" \
    -d "$payload" 2>/dev/null \
    | jq -r '.choices[0].message.content'
}

_zsh_ai_query() {
  local prompt="$1"
  local backend="${ZSH_AI_BACKEND:-claude}"
  local model="${ZSH_AI_MODEL:-}"
  local px="${ZSH_AI_PROXY:-}"
  local result=""

  case "$backend" in
    claude)
      result=$(${px:+$px} claude -p --no-session-persistence \
        ${model:+--model "$model"} "$prompt" 2>/dev/null)
      ;;
    codex)
      result=$(${px:+$px} codex exec --ephemeral \
        ${model:+--model "$model"} "$prompt" 2>/dev/null)
      ;;
    opencode)
      result=$(${px:+$px} opencode run \
        ${model:+--model "$model"} "$prompt" 2>/dev/null)
      ;;
    api)
      _zsh_ai_load_api_profile || return 1
      case "$_ZSH_AI_API_FORMAT" in
        anthropic)
          result=$(_zsh_ai_api_anthropic "$prompt" "$_ZSH_AI_API_URL" "$_ZSH_AI_API_KEY" "$_ZSH_AI_API_MODEL")
          ;;
        openai)
          result=$(_zsh_ai_api_openai "$prompt" "$_ZSH_AI_API_URL" "$_ZSH_AI_API_KEY" "$_ZSH_AI_API_MODEL")
          ;;
        *)
          echo "zsh-ai: unknown api_format '$_ZSH_AI_API_FORMAT'" >&2
          return 1
          ;;
      esac
      ;;
    *)
      echo "zsh-ai: unknown backend '$backend'" >&2
      return 1
      ;;
  esac

  echo "$result" | _zsh_ai_strip_markdown
}
