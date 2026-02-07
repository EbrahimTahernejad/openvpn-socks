#!/usr/bin/env bash

function spawn {
    if [[ -z ${PIDS+x} ]]; then PIDS=(); fi
    "$@" &
    PIDS+=($!)
}

function join {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            wait "${pid}"
        done
    fi
}

function on_kill {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            kill "${pid}" 2> /dev/null
        done
    fi
    kill "${ENTRYPOINT_PID}" 2> /dev/null
}

export ENTRYPOINT_PID="${BASHPID}"

trap "on_kill" EXIT
trap "on_kill" SIGINT

if [[ "${USE_DANTE}" == "true" ]]; then
    # Determine auth method based on credentials
    if [[ -n "${SOCKS5_USER}" && -n "${SOCKS5_PASS}" ]]; then
        SOCKS_METHOD="username"
        # Create user for dante authentication
        adduser -D -H -s /sbin/nologin "${SOCKS5_USER}" 2>/dev/null || true
        echo "${SOCKS5_USER}:${SOCKS5_PASS}" | chpasswd
    else
        SOCKS_METHOD="none"
    fi

    # Create dante configuration for tun0 interface
    cat > /etc/sockd.conf <<EOF
logoutput: stderr

internal: 0.0.0.0 port = 1080
external: tun0

socksmethod: ${SOCKS_METHOD}
clientmethod: none

user.privileged: root
user.unprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: error
}
EOF
    spawn sockd -f /etc/sockd.conf
else
    spawn socks5
fi

if [[ -n "${SOCKS5_UP}" ]]; then
    spawn "${SOCKS5_UP}" "$@"
elif [[ $# -gt 0 ]]; then
    "$@"
fi

if [[ $# -eq 0 || "${DAEMON_MODE}" == true ]]; then
    join
fi

