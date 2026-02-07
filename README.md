# OpenVPN to SOCKS5 Proxy

Converts an OpenVPN connection to a SOCKS5 proxy server in Docker. Based on [curve25519xsalsa20poly1305/docker-openvpn-socks5](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5).

## Features

- Connects to any OpenVPN server using your `.ovpn` config file
- Exposes a SOCKS5 proxy that routes traffic through the VPN tunnel
- Optional SOCKS5 authentication with username/password
- Choice of SOCKS5 server: lightweight Go-based server or dante-server

## Quick Start

### 1. Add your OpenVPN config

Place your `.ovpn` configuration file in the `vpns/` directory:

```bash
cp /path/to/your/config.ovpn ./vpns/
```

### 2. Configure docker-compose.yml

```yaml
services:
  vpn-proxy:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: vpn-proxy
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    ports:
      - "1080:1080"
    volumes:
      - ./vpns/:/vpn:ro
    dns:
      - 1.1.1.1
      - 8.8.8.8
    environment:
      OPENVPN_CONFIG: /vpn/your-config.ovpn
```

### 3. Start the container

```bash
docker-compose up -d
```

### 4. Test the proxy

```bash
curl -x socks5h://127.0.0.1:1080 https://ifconfig.co/json
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENVPN_CONFIG` | Path to the OpenVPN config file (required) | - |
| `USE_DANTE` | Use dante-server instead of Go SOCKS5 server | `false` |
| `SOCKS5_USER` | SOCKS5 authentication username | - |
| `SOCKS5_PASS` | SOCKS5 authentication password | - |
| `DAEMON_MODE` | Keep container running after CMD completes | `false` |
| `OPENVPN_UP` | Script to run after VPN connects | `/usr/local/bin/socks5-entrypoint.sh` |
| `SOCKS5_UP` | Script to run after SOCKS5 server starts | - |

### Using dante-server with Authentication

To enable SOCKS5 authentication, use dante-server and set credentials:

```yaml
environment:
  OPENVPN_CONFIG: /vpn/your-config.ovpn
  USE_DANTE: "true"
  SOCKS5_USER: myuser
  SOCKS5_PASS: mypassword
```

Then connect with authentication:

```bash
curl -x socks5h://myuser:mypassword@127.0.0.1:1080 https://ifconfig.co/json
```

### Using the Go SOCKS5 Server

For a lightweight go server (udp may not work idk):

```yaml
environment:
  OPENVPN_CONFIG: /vpn/your-config.ovpn
  # USE_DANTE not set or false
```

## Running a Command Through the VPN

You can run a command inside the container that uses the VPN connection:

```bash
docker-compose run --rm vpn-proxy curl https://ifconfig.co/json
```

## Troubleshooting

### Check VPN connection

```bash
docker-compose logs -f
```

### Verify your external IP through the proxy

```bash
curl -x socks5h://127.0.0.1:1080 https://ifconfig.co/ip
```

### Test without authentication first

If you're having auth issues with dante, temporarily remove `SOCKS5_USER` and `SOCKS5_PASS` to test the connection without authentication.

## License

Based on work by [curve25519xsalsa20poly1305](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5).
