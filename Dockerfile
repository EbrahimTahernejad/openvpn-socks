FROM golang:latest AS builder

WORKDIR /go/src/socks5
COPY server .
RUN go mod init && go mod tidy && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-s' -o ../socks5

# ------------------------------------------------

FROM alpine:latest

COPY socks5-entrypoint.sh /usr/local/bin/
COPY --from=builder /go/src/socks5/socks5 /usr/local/bin
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY openvpn-up.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY update-resolv-conf.sh /etc/openvpn/update-resolv-conf

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --no-cache bash curl wget openvpn openresolv openrc dante-server \
    && chmod +x \
        /usr/local/bin/openvpn-up.sh \
        /usr/local/bin/entrypoint.sh \
        /etc/openvpn/update-resolv-conf \
        /usr/local/bin/socks5-entrypoint.sh

ENV         SOCKS_UP        ""
ENV         OPENVPN_UP      "/usr/local/bin/socks5-entrypoint.sh"
ENV         DAEMON_MODE     false
ENTRYPOINT  [ "entrypoint.sh" ]
