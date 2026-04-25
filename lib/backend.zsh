_zsh_ai_strip_markdown() {
  command sed -n '/^```/{n; :loop; /^```/q; p; n; b loop}; /^```/!p'
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
      local api_url="${ZSH_AI_API_URL:?ZSH_AI_API_URL is required when backend=api}"
      local api_key="${ZSH_AI_API_KEY:?ZSH_AI_API_KEY is required when backend=api}"
      local api_model="${ZSH_AI_API_MODEL:?ZSH_AI_API_MODEL is required when backend=api}"
      local payload
      payload=$(command python3 -c "
import json, sys
print(json.dumps({
    'model': sys.argv[1],
    'max_tokens': 1024,
    'messages': [{'role': 'user', 'content': sys.argv[2]}]
}, ensure_ascii=False))
" "$api_model" "$prompt")
      result=$(curl -sS "$api_url" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload" 2>/dev/null \
        | command python3 -c "
import json, sys
data = json.load(sys.stdin)
for block in data.get('content', []):
    if block.get('type') == 'text':
        print(block['text'])
")
      ;;
    *)
      echo "zsh-ai: unknown backend '$backend'" >&2
      return 1
      ;;
  esac

  echo "$result" | _zsh_ai_strip_markdown
}
