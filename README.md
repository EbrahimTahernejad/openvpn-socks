# OpenVPN to SOCKS5 Proxy

Converts an OpenVPN connection into a SOCKS5 proxy server running in Docker, using [dante-server](https://www.inet.no/dante/). Based on [curve25519xsalsa20poly1305/docker-openvpn-socks5](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5).

## Features

- Connects to any OpenVPN server using your `.ovpn` config file
- Exposes a SOCKS5 proxy (dante-server) that routes traffic through the VPN tunnel
- Optional SOCKS5 authentication with username/password

## Quick Start

### 1. Add your OpenVPN config

Place your `.ovpn` configuration file in the `vpns/` directory:

```bash
mkdir -p vpns
cp /path/to/your/config.ovpn ./vpns/
```

### 2. Configure docker-compose.yml

```yaml
services:
  sl:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: sl
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    ports:
      - "8050:1080"
    volumes:
      - ./vpns/:/vpn:ro
    dns:
      - 1.1.1.1
      - 8.8.8.8
    environment:
      OPENVPN_CONFIG: /vpn/config.ovpn
      # SOCKS5_USER: user
      # SOCKS5_PASS: pass
```

### 3. Start the container

```bash
docker compose up -d
```

### 4. Test the proxy

```bash
curl -x socks5h://127.0.0.1:8050 https://ifconfig.co/json
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENVPN_CONFIG` | Path to the OpenVPN config file inside the container (required) | - |
| `SOCKS5_USER` | SOCKS5 authentication username (optional) | - |
| `SOCKS5_PASS` | SOCKS5 authentication password (optional) | - |
| `DAEMON_MODE` | Keep container running after CMD completes | `false` |
| `SOCKS5_UP` | Script to run after the SOCKS5 server starts | - |

### SOCKS5 Authentication

To enable SOCKS5 authentication, set both `SOCKS5_USER` and `SOCKS5_PASS`:

```yaml
environment:
  OPENVPN_CONFIG: /vpn/config.ovpn
  SOCKS5_USER: myuser
  SOCKS5_PASS: mypassword
```

Then connect with credentials:

```bash
curl -x socks5h://myuser:mypassword@127.0.0.1:8050 https://ifconfig.co/json
```

When neither variable is set, the proxy accepts connections without authentication.

### Build Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `MIRROR_URL` | Alpine APK mirror URL (useful behind restrictive networks) | `http://dl-4.alpinelinux.org/alpine/edge/testing` |

## Setting Up `/dev/net/tun`

The container requires access to the TUN device (`/dev/net/tun`) on the host. If it doesn't exist, the container will fail to start.

### Check if TUN is available

```bash
ls -l /dev/net/tun
```

### Create the TUN device (Linux)

If `/dev/net/tun` doesn't exist, create it:

```bash
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 666 /dev/net/tun
```

To make this persistent across reboots, add the above commands to `/etc/rc.local` or create a udev rule.

### Load the TUN kernel module

On some systems the `tun` kernel module isn't loaded by default:

```bash
sudo modprobe tun
```

To load it automatically on boot:

```bash
echo "tun" | sudo tee /etc/modules-load.d/tun.conf
```

### VPS / Cloud providers

Many VPS providers disable TUN/TAP by default. You may need to:

- **OpenVZ / LXC containers**: Enable TUN/TAP from your provider's control panel (often under "Settings" or "VPS Configuration"). This cannot be done from inside the container.
- **KVM / dedicated servers**: The `tun` module is usually available — just load it with `modprobe tun`.
- If neither option works, contact your hosting provider to enable TUN/TAP support.

### macOS (Docker Desktop)

Docker Desktop for macOS handles `/dev/net/tun` inside the Linux VM automatically. No extra setup is needed — the `devices` mapping in docker-compose will work out of the box.

## Running a Command Through the VPN

You can run a one-off command inside the container that uses the VPN connection:

```bash
docker compose run --rm sl curl https://ifconfig.co/json
```

## Troubleshooting

### Check VPN connection

```bash
docker compose logs -f
```

### Verify your external IP through the proxy

```bash
curl -x socks5h://127.0.0.1:8050 https://ifconfig.co/ip
```

### Test without authentication

If you're having auth issues, temporarily remove `SOCKS5_USER` and `SOCKS5_PASS` to test the connection without authentication.

### Container exits immediately

- Make sure `/dev/net/tun` exists on the host (see [Setting Up /dev/net/tun](#setting-up-devnettun))
- Verify your `.ovpn` file is valid and accessible at the mounted path
- Check logs with `docker compose logs`

## License

Based on work by [curve25519xsalsa20poly1305](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5).
