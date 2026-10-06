ensure_service() {
    local scope="$1" unit="$2" state
    local ctl=(systemctl)
    local privileged=()
    if [[ "$scope" == user ]]; then
        ctl+=(--user)
    else
        privileged=(sudo)
    fi
    state="$("${ctl[@]}" is-enabled "$unit" 2>/dev/null || true)"
    case "$state" in
        enabled|static|indirect|generated|transient) ;;
        masked*) echo "Service $unit is masked; unmask it before setup." >&2; return 1 ;;
        not-found|"") echo "Service $unit is missing; install its package before setup." >&2; return 1 ;;
        *) "${privileged[@]}" "${ctl[@]}" enable "$unit" ;;
    esac
    if ! "${ctl[@]}" is-active --quiet "$unit"; then
        "${privileged[@]}" "${ctl[@]}" start "$unit"
    fi
}
