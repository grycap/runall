_MUTED_EXPRESSIONS=()

function p_mute() {
  _MUTED_EXPRESSIONS+=("${1// /[[:space:]]}")
}

function p_errfile() {
  local i
  local E
  for ((i=0;i<${#_MUTED_EXPRESSIONS[@]};i=i+1)); do
    E="${_MUTED_EXPRESSIONS[$i]}"
    if [[ "$1" =~ ^$E ]]; then
      return 0
    fi
  done

  if [ "$LOGFILE" == "" ]; then
    echo "$@" >&2
  else
    touch -f "$LOGFILE"
    if [ $? -eq 0 ]; then
      echo "$@" >> "$LOGFILE"
    fi
  fi
}

_COLORIZE_LOG=false

function p_error() {
  local CODE=0
  [ "$_COLORIZE_LOG" == "true" ] && CODE=$_P_COLOR_RED
  local O_STR="[`p_color_s $CODE ERROR`] $LOGGER $(date +%Y.%m.%d-%X) $@"
  p_errfile "$O_STR"
}

function p_warning() {
  local CODE=0
  [ "$_COLORIZE_LOG" == "true" ] && CODE=$_P_COLOR_YELLOW
  local O_STR="[`p_color_s $CODE WARNING`] $LOGGER $(date +%Y.%m.%d-%X) $@"
  p_errfile "$O_STR"
}

function p_info() {
  local L
  if [ "$VERBOSE" == "true" ]; then
    local TS="$(date +%Y.%m.%d-%X)"
    while read L; do
      p_errfile "[INFO] $LOGGER $TS $L"
    done <<< "$@"
  fi
}

function p_out() {
  if [ "$QUIET" != "true" ]; then
    while read L; do
      echo "$L"
    done <<< "$@"
  fi
}

function p_debug() {
  local L
  if [ "$DEBUG" == "true" ]; then
    local TS="$(date +%Y.%m.%d-%X)"
    while read L; do
      p_errfile "[DEBUG] $LOGGER $TS $L"
    done <<< "$@"
  fi
}

_P_COLOR_RED="\033[0;31m"
_P_COLOR_GREEN="\033[0;32m"
_P_COLOR_BROWN="\033[0;33m"
_P_COLOR_BLUE="\033[0;34m"
_P_COLOR_PURPLE="\033[0;35m"
_P_COLOR_CYAN="\033[0;36m"
_P_COLOR_LIGHT_GRAY="\033[0;37m"
_P_COLOR_DARK_GRAY="\033[0;38m"
_P_COLOR_YELLOW="\033[1;33m"
_P_COLOR_WHITE="\033[1;37m"

function p_color_s() {
  local CODE="$1"
  shift
  if [ "$CODE" == "" -o "$CODE" == "0" ]; then
    echo -n "$@"
  else
    echo -n -e "$CODE" 
    echo -n "$@"
    echo -n -e "\033[0;0m" 
  fi
}

function p_color() {
  local ECHONL=true
  while [ $# -gt 0 ]; do
    case "$1" in
      -n) ECHONL=false
          shift;;
      _P_COLOR_*) CODE=${!1}
          shift;;
      *) break;;
    esac
  done
  if [ "$CODE" == "" ]; then
    CODE=$_P_COLOR_RED
  fi

  if [ "$QUIET" != "true" ]; then
    while read L; do
      p_color_s $CODE "$L"
      [ "$ECHONL" == "true" ] && echo
    done <<< "$@"
  fi
}

function p_red() {
  p_color _P_COLOR_RED "$@"
}
function p_green() {
  p_color _P_COLOR_GREEN "$@"
}
function p_brown() {
  p_color _P_COLOR_BROWN "$@"
}
function p_blue() {
  p_color _P_COLOR_BLUE "$@"
}
function p_purple() {
  p_color _P_COLOR_PURPLE "$@"
}
function p_cyan() {
  p_color _P_COLOR_CYAN "$@"
}
function p_gray() {
  p_color _P_COLOR_LIGHT_GRAY "$@"
}
function p_yellow() {
  p_color _P_COLOR_YELLOW "$@"
}
function p_white() {
  p_color _P_COLOR_WHITE "$@"
}

function set_logger() {
  if [ "$1" != "" ]; then
    LOGGER="[$1]"
  else
    LOGGER=
  fi
}

_OLD_LOGGER=

function push_logger() {
  _OLD_LOGGER="$LOGGER"
  LOGGER="$LOGGER[$1]"
}

function pop_logger() {
  LOGGER="$_OLD_LOGGER"
}

function finalize() {
  # Finalizes the execution of the this script and shows an error (if provided)
  local ERR=$1
  shift
  local COMMENT=$@
  [ "$ERR" == "" ] && ERR=0
  if [ "$ERR" == "0" ]; then
    [ "$COMMENT" != "" ] && p_out "$COMMENT"
  else
    [ "$COMMENT" != "" ] && p_error "$COMMENT"
  fi
  exit $ERR
}