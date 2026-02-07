#!/usr/bin/env bash
set -e

export PATH=$PATH:/sbin:/usr/sbin:/bin:/usr/bin

log() {
  echo "[dns] $*" >&2
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

is_systemd() {
  [[ "$(ps -p 1 -o comm= 2>/dev/null)" == "systemd" ]]
}

collect_dns() {
  for optionname in ${!foreign_option_*}; do
    option="${!optionname}"
    set -- $option
    if [[ "$1" == "dhcp-option" ]]; then
      case "$2" in
        DNS)
          DNS_SERVERS+=("$3")
          ;;
        DOMAIN|DOMAIN-SEARCH)
          DNS_DOMAINS+=("$3")
          ;;
      esac
    fi
  done
}

DNS_SERVERS=()
DNS_DOMAINS=()

case "$script_type" in
  up)
    collect_dns

    # --- systemd-resolved path (preferred) ---
    if is_systemd && has_cmd resolvectl; then
      log "using systemd-resolved via resolvectl"
      [[ ${#DNS_SERVERS[@]} -gt 0 ]] && resolvectl dns "$dev" "${DNS_SERVERS[@]}"
      [[ ${#DNS_DOMAINS[@]} -gt 0 ]] && resolvectl domain "$dev" "${DNS_DOMAINS[@]}"
      exit 0
    fi

    # --- legacy resolvconf path ---
    if has_cmd resolvconf; then
      if resolvconf -l >/dev/null 2>&1; then
        log "using legacy resolvconf"
        {
          [[ ${#DNS_DOMAINS[@]} -gt 0 ]] && echo "search ${DNS_DOMAINS[*]}"
          for ns in "${DNS_SERVERS[@]}"; do
            echo "nameserver $ns"
          done
        } | resolvconf -x -a "${dev}.inet" || true
        exit 0
      fi
    fi

    log "no supported DNS backend found, skipping DNS"
    ;;
    
  down)
    if is_systemd && has_cmd resolvectl; then
      log "reverting systemd-resolved DNS"
      resolvectl revert "$dev" || true
      exit 0
    fi

    if has_cmd resolvconf; then
      resolvconf -d "${dev}.inet" || true
      exit 0
    fi
    ;;
esac

exit 0
