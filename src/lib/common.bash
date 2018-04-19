_HOSTS_LIST=( )
_EXCLUDED_HOSTS_LIST=( )

function expand_ranges() {
  local OP="$1"
  local NAME="$2"
  local RANGE="$(echo "$NAME" | grep -o '\[[0-9]\{1,\}-[0-9]\{1,\}\]' | head -1)"
  if [ "$RANGE" != "" ]; then
    RANGE="${RANGE:1:-1}"
    PATTERN="\[${RANGE}\]"
    p_info "range detected: $RANGE"
    IFS='-' read L_LIMIT U_LIMIT <<< "$RANGE"
    for v in $(seq "$L_LIMIT" "$U_LIMIT"); do 
      HOST="${NAME/$PATTERN/$v}"
      hostlist "$OP" "$HOST"
    done
    return 0
  fi
  return 1
}

function hostlist() {
  local OP="$1"
  local HOSTS="$2"
  local HOST
  while read -d ',' HOST; do
    if [ "$HOST" != "" ]; then
      if ! expand_ranges "$OP" "$HOST"; then
        if [ "$OP" == "A" ]; then
          p_debug "adding $HOST"
          _HOSTS_LIST+=("$HOST")
        else
          p_debug "removing $HOST"
          _EXCLUDED_HOSTS_LIST+=("$HOST")
        fi
      fi
    fi
  done <<< "${HOSTS},"
}

SEPARATOR="$(cat /proc/sys/kernel/random/uuid)"

function runin() {
  # Run a command in a host (and redirect the output to a file (- means stdout))
  local HOST="$1"
  local REDIRECT="$2"
  shift
  shift
  local ESHELL="${SHELL:-sh}"
  local COMMAND=("$ESHELL" "-s")
  if [ "$REDIRECT" != "-" ]; then
    COMMAND+=(">$REDIRECT")
    COMMAND+=("2>&1")
  fi
  if [ "$SSHUSER" != "" ]; then
    HOST="${SSHUSER}@${HOST}"
  fi
  ssh $SSHOPTIONS "$HOST" "${COMMAND[@]}" <<$SEPARATOR
$@
$SEPARATOR
}

function readconfig() {
  local CONFIGFILE="$1"
  local OVERRIDEHOSTS="$2"

  # Read the config file (a simple bash file that will be sourced)
  if [ ! -e "$CONFIGFILE" ]; then
    p_warning "ignoring config file $CONFIGFILE because it does not exist"
  else
    if ! source "$CONFIGFILE"; then
      finalize 1 "could not read config from file $CONFIGFILE"
    fi

    if [ "$HOSTS" != "" ]; then
      if [ "$OVERRIDEHOSTS" != "true" ]; then
        hostlist A "$HOSTS"
      else
        p_info "overriding hosts from config file"
      fi
    fi
  fi
}

function excludehosts() {
  local EXCLUDE=
  # Exclude the hosts (if needed)
  _NEW_HOSTS_LIST=()
  for ((i=0; i<${#_HOSTS_LIST[@]}; i=i+1)); do
    EXCLUDE=false
    for ((j=0; j<${#_EXCLUDED_HOSTS_LIST[@]};j=j+1)); do
      if [ "${_HOSTS_LIST[$i]}" == "${_EXCLUDED_HOSTS_LIST[$j]}" ]; then
        EXCLUDE=true
        break
      fi
    done
    if [ "$EXCLUDE" == "false" ]; then
      _NEW_HOSTS_LIST+=("${_HOSTS_LIST[$i]}")
    fi
  done
  _HOSTS_LIST=("${_NEW_HOSTS_LIST[@]}")
}