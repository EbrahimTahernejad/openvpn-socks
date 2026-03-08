FROM alpine:3.21

COPY socks5-entrypoint.sh /usr/local/bin/
COPY openvpn-up.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY update-resolv-conf.sh /etc/openvpn/update-resolv-conf

ARG MIRROR_URL=http://dl-4.alpinelinux.org/alpine/edge/testing

RUN echo "${MIRROR_URL}" > /etc/apk/repositories \
    && apk add --no-cache ca-certificates bash curl wget openvpn openresolv openrc dante-server \
    && chmod +x \
        /usr/local/bin/openvpn-up.sh \
        /usr/local/bin/entrypoint.sh \
        /etc/openvpn/update-resolv-conf \
        /usr/local/bin/socks5-entrypoint.sh

ENV         SOCKS_UP        ""
ENV         OPENVPN_UP      "/usr/local/bin/socks5-entrypoint.sh"
ENV         DAEMON_MODE     false
ENTRYPOINT  [ "entrypoint.sh" ]
