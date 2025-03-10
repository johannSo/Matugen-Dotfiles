# roundy.zsh - minimal path-aware zsh prompt (optimized)
# version: 1.0.1
# Core state
RR_TEXC=0
RR_STATUS=0
RR_TIME=""
RR_GIT=""
RR_DIR=""
RR_USR=""
# Default theme with cached symbols (using 255 for bright white + bold)
typeset -gA RT=(
  bg_ok 182    fg_ok 255  icon_ok "✓"    # Changed to 255 (bright white)
  bg_err 182   fg_err 255 icon_err "✗"   # Changed to 255 (bright white)
  bg_dir 240   fg_dir 255 icon_time " 󱑂" # Changed to 255 (bright white)
  bg_usr 240   fg_usr 255                # Changed to 255 (bright white)
  bg_git 4   fg_git 255                # Changed to 255 (bright white)
  bg_time 3  fg_time 255               # Changed to 255 (bright white)
)
# Options
: ${R_MODE:=dir-only}  # full, short, dir-only
: ${R_CODE:=0}         # show exit code in right prompt
: ${R_MIN:=2}          # show time for commands longer than 4s
: ${R_USR:=%n}         # username format
# Powerline chars (cached for performance)
R_LEFT=$'\uE0B6' R_RIGHT=$'\uE0B4'
# Cache for git queries
GIT_CACHE_TIMEOUT=5 # seconds
GIT_CACHE_TIME=0
GIT_CACHE_VALUE=""
GIT_CACHE_DIR=""
# Helpers - pre-compute some constants
SEG_FUNCTIONS_INITIALIZED=0
initialize_seg_functions() {
  [[ $SEG_FUNCTIONS_INITIALIZED -eq 1 ]] && return
  SEG_FUNCTIONS_INITIALIZED=1
  
  function seg() { echo "%F{$1}%K{${2:-default}}$R_RIGHT%B${3:-}" }  # Added %B for bold
  function seg_s() { echo " %k%F{$1}$R_LEFT%K{$1}%F{$2}%B${3:-}" }  # Added %B for bold
  function seg_e() { echo "%F{$1}%k$R_RIGHT%f%b" }                   # Added %b to end bold
  function status_color() { echo "%(?.${1}.%130(?.${1}.${2}))" }
}

get_time() {
  (( R_MIN && RR_TEXC )) || return
  local d=$(( EPOCHSECONDS - RR_TEXC ))
  (( d < R_MIN )) && return
  local t
  (( d >= 86400 )) && t+="$((d/86400))d " && d=$((d%86400))
  (( d >= 3600 )) && t+="$((d/3600))h " && d=$((d%3600))
  (( d >= 60 )) && t+="$((d/60))m " && d=$((d%60))
  t+="${d}s"
  RR_TEXC=0  # Reset execution time after showing
  echo "${RT[icon_time]} $t"
}

get_dir() {
  case "$R_MODE" in
    full)  echo ' %~';;
    short) echo ' %2~';;
    *)     echo ' %1~';;
  esac
}

get_usr() {
  echo " $R_USR"
}

get_git() {
  local current_dir=$(pwd)
  local current_time=$EPOCHSECONDS
  
  # Use cached value if still valid
  if [[ "$current_dir" == "$GIT_CACHE_DIR" && $(( current_time - GIT_CACHE_TIME )) -lt $GIT_CACHE_TIMEOUT ]]; then
    echo "$GIT_CACHE_VALUE"
    return
  fi
  
  # Quick check if .git exists before running git command
  [[ ! -d .git ]] && [[ ! "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] && return
  
  local branch
  branch=${$(git symbolic-ref HEAD 2>/dev/null)#refs/heads/}
  
  # Update cache
  GIT_CACHE_DIR="$current_dir"
  GIT_CACHE_TIME=$current_time
  
  if [[ -n $branch ]]; then
    GIT_CACHE_VALUE=" $branch"
    echo "$GIT_CACHE_VALUE"
  else
    GIT_CACHE_VALUE=""
    echo ""
  fi
}

# Right prompt segments (now showing directory)
r_dir() {
  initialize_seg_functions
  local s="$(seg_s ${RT[bg_dir]} ${RT[fg_dir]} $RR_DIR)"
  [[ -z $RR_GIT ]] && s+="$(seg_e ${RT[bg_dir]})"
  echo $s
}

r_git() {
  initialize_seg_functions
  [[ -z $RR_GIT ]] && return
  echo "$(seg ${RT[bg_dir]} ${RT[bg_git]} "%F{${RT[fg_git]}}$RR_GIT")$(seg_e ${RT[bg_git]})"
}

r_err() {
  initialize_seg_functions
  (( R_CODE && RR_STATUS != 0 && RR_STATUS != 130 )) || return
  local bg=${RR_GIT:+${RT[bg_git]}}
  bg=${bg:-${RT[bg_dir]}}
  echo " %F{${RT[bg_err]}}%k$R_LEFT%K{${RT[bg_err]}}%F{${RT[fg_err]}}%B%?%k%F{${RT[bg_err]}}$R_RIGHT"
}

# Left prompt segments (now showing username)
l_status() {
  initialize_seg_functions
  local bg=$(status_color ${RT[bg_ok]} ${RT[bg_err]})
  local fg=$(status_color ${RT[fg_ok]} ${RT[fg_err]})
  local icon=$(status_color ${RT[icon_ok]} ${RT[icon_err]})
  seg_s "$bg" "$fg" "$icon"
}

l_time() {
  initialize_seg_functions
  local bg=$(status_color ${RT[bg_ok]} ${RT[bg_err]})
  [[ -z $RR_TIME ]] && echo "$(seg "$bg" ${RT[bg_usr]})" && return
  echo "$(seg "$bg" ${RT[bg_time]} "%F{${RT[fg_time]}}$RR_TIME")$(seg ${RT[bg_time]} ${RT[bg_usr]})"
}

l_usr() {
  initialize_seg_functions
  echo "%F{${RT[fg_usr]}}$RR_USR$(seg_e ${RT[bg_usr]}) "
}

# Hooks and setup
preexec() {
  # Reset previous time state
  RR_TIME=""
  RR_TEXC=$EPOCHSECONDS
  # Set terminal title
  print -Pn "\e]0;${1}\a"
}

precmd() {
  RR_STATUS=$?
  RR_TIME=$(get_time)
  RR_GIT=$(get_git)
  RR_DIR=$(get_dir)
  RR_USR=$(get_usr)
  PROMPT="$(l_status)$(l_time)$(l_usr)"
  RPROMPT="$(r_dir)$(r_git)$(r_err)%f%b"  # Added %b to end bold in RPROMPT
  # Reset terminal title
  print -Pn "\e]0;%~\a"
}

# Plugin unload
roundy_unload() {
  add-zsh-hook -D preexec preexec
  add-zsh-hook -D precmd precmd
  unset -m 'RR_*' 'RT' 'R_*'
  unfunction -m 'roundy_*' 'seg*' 'status_color' 'get_*' '[lr]_*'
}

# Main
main() {
  emulate -L zsh
  setopt prompt_subst no_prompt_bang prompt_percent
  autoload -Uz add-zsh-hook
  (( $+EPOCHSECONDS )) || zmodload zsh/datetime
  PROMPT_EOL_MARK=$'\n%{\r%}'
  add-zsh-hook preexec preexec
  add-zsh-hook precmd precmd
}

main "$@"
