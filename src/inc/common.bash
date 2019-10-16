_HOSTS_LIST=( )
_EXCLUDED_HOSTS_LIST=( )

function hostlist() {
  local OP="$1"
  local HOSTS="$2"
  local HOST HNAME
  while read -d ',' HOST; do
    if [ "$HOST" != "" ]; then
      local H_EXPANDED=()
      while read HNAME; do
        H_EXPANDED+=("$HNAME")
      done <<< "$(bashc.expand_ranges "$HOST")"
      p_debug "${H_EXPANDED[@]}"
      if [ "$OP" == "P" ]; then
        p_debug "pushing ${H_EXPANDED[@]}"
        _HOSTS_LIST=("${H_EXPANDED[@]}" "${_HOSTS_LIST[@]}")
      elif [ "$OP" == "A" ]; then
        p_debug "adding ${H_EXPANDED[@]}"
        _HOSTS_LIST+=("${H_EXPANDED[@]}")
      else
        p_debug "removing ${H_EXPANDED[@]}"
        _EXCLUDED_HOSTS_LIST+=("${H_EXPANDED[@]}")
      fi
    fi
  done <<< "${HOSTS},"
}

# Just for this run
_RUN_SEPARATOR="$(uuidgen)"

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
  ssh $SSHOPTIONS "$HOST" "${COMMAND[@]}" <<$_RUN_SEPARATOR
export BASHC_HOST=$HOST
export BASHC_COMMAND="$@"
$@
$_RUN_SEPARATOR
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