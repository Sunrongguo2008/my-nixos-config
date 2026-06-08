#!/usr/bin/env bash
set -u

input=$(cat)

cwd=$(jq -r '.cwd // .workspace.current_dir // "?"' <<<"$input")
model_name=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
transcript=$(jq -r '.transcript_path // ""' <<<"$input")
cost_usd=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")

if [[ "$cwd" == "$HOME" ]]; then
  proj="~"
else
  proj="${cwd##*/}"
fi

branch=""
dirty=0
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
           || echo "")
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
fi

ctx_tokens=0
session_tokens=0
thinking_effort=""
if [[ -f "$transcript" ]]; then
  last_usage=$(tac "$transcript" 2>/dev/null \
          | jq -c -R 'fromjson? // empty | select(.message.usage) | .message.usage' 2>/dev/null \
          | head -n1)
  if [[ -n "$last_usage" ]]; then
    ctx_tokens=$(jq -r '(.input_tokens//0)+(.cache_read_input_tokens//0)+(.cache_creation_input_tokens//0)' <<<"$last_usage")
    thinking_effort=$(jq -r '.thinking_effort // ""' <<<"$last_usage")
  fi
  session_tokens=$(jq -c -R 'fromjson? // empty | select(.message.usage) | .message.usage | (.input_tokens//0)+(.output_tokens//0)+(.cache_read_input_tokens//0)+(.cache_creation_input_tokens//0)' "$transcript" 2>/dev/null \
                   | awk '{s+=$1} END{print s+0}')
fi

ctx_max=200000
[[ "$model_name" == *"1M"* ]] && ctx_max=1000000
ctx_pct=$(( ctx_tokens * 100 / ctx_max ))

fmt_k() {
  local n=$1
  if (( n >= 1000000 )); then
    awk -v n="$n" 'BEGIN{printf "%.2fM", n/1000000}'
  elif (( n >= 1000 )); then
    awk -v n="$n" 'BEGIN{printf "%.1fk", n/1000}'
  else
    echo "$n"
  fi
}
sess_tok=$(fmt_k "$session_tokens")

cost_fmt=$(awk -v c="$cost_usd" 'BEGIN{printf "$%.3f", c}')

C0=$'\e[0m'
DIR=$'\e[36m'
GC=$'\e[32m'
GD=$'\e[33m'
MOD=$'\e[35m'
TOK=$'\e[34m'
COSTC=$'\e[32m'
SEP=$'\e[90m'
EFFORT=$'\e[36m'
if   (( ctx_pct >= 80 )); then CTX=$'\e[31m'
elif (( ctx_pct >= 50 )); then CTX=$'\e[33m'
else                           CTX=$'\e[32m'
fi

git_seg=""
if [[ -n "$branch" ]]; then
  if (( dirty == 0 )); then
    git_seg="${SEP} | ${GC}${branch}${C0}"
  else
    git_seg="${SEP} | ${GD}${branch} ●${dirty}${C0}"
  fi
fi

effort_seg=""
if [[ -n "$thinking_effort" ]]; then
  effort_seg="${SEP} | ${EFFORT}${thinking_effort}${C0}"
fi

s_=" ${SEP}|${C0} "

printf "%s%s%s%s%s%s%s%s%s%s%s\n" \
  "${DIR}${proj}${C0}" "$git_seg" \
  "$s_" "${MOD}${model_name}${C0}" \
  "$s_" "${CTX}${ctx_pct}%${C0}" \
  "$s_" "${TOK}${sess_tok}${C0}" \
  "$s_" "${COSTC}${cost_fmt}${C0}" \
  "$effort_seg"
