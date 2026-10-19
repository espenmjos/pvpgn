# pvpgn

Docker image for [PvPGN](https://github.com/pvpgn/pvpgn-server) **1.99.8**, a Battle.net server emulator. One image
contains all three daemons; choose which one runs with the container command:

| Command | Port      | Role |
|---------|-----------|------|
| `bnetd` | 6112 tcp/udp | Battle.net login, chat and game lists |
| `d2cs`  | 6113      | Diablo II closed realm character server |
| `d2dbs` | 6114      | Diablo II character database (used by D2GS) |

Built on Ubuntu 24.04 with Lua, MySQL and SQLite support. Daemons run as an unprivileged `pvpgn` user.

> **Want a complete Diablo II realm?** Use [espenmjos/d2gs](https://github.com/espenmjos/d2gs). Its compose file
> builds this image together with the D2GS game server and wires everything up.

## Quick start

```sh
git clone https://github.com/espenmjos/pvpgn.git
cd pvpgn
cp .env.example .env     # set PUBLIC_IP and D2GS_IPS
docker compose up -d --build
```

Config files end up in `./etc` and data (accounts, characters, ladders) in `./var`. On first start the default PvPGN
files are copied there. Existing files are never overwritten, so you can edit them freely and run
`docker compose restart`.

## Environment variables

These settings are written into the config files on every start. They are only applied when set, so if you prefer
to manage a setting by hand in the `.conf` files, leave the variable out.

| Variable            | Daemon        | Writes |
|---------------------|---------------|--------|
| `REALM_NAME`        | bnetd, d2cs   | `realm.conf`, `realmname` in `d2cs.conf` |
| `REALM_DESCRIPTION` | bnetd         | `realm.conf` |
| `D2CS_ADDR`         | bnetd         | d2cs address (`ip:port`) in `realm.conf`, sent to clients |
| `BNETD_ADDR`        | d2cs          | `bnetdaddr` in `d2cs.conf` |
| `D2GS_IPS`          | d2cs, d2dbs   | `gameservlist` in `d2cs.conf` and `d2dbs.conf` (comma separated) |
| `D2GS_PASSWORD`     | d2cs          | `d2gs_password` in `d2cs.conf` |
| `PUBLIC_IP`, `TRANSLATE`, `LAN_IP`, `LAN_NETWORK` | bnetd, d2cs | `address_translation.conf` (see below) |

### Address translation

When the servers run on a private Docker network, PvPGN would send container IPs to clients. Set `TRANSLATE` to the
internal `ip:port` addresses (space separated) and `PUBLIC_IP` to the address clients should get instead. With
`LAN_IP` + `LAN_NETWORK`, clients inside that network get `LAN_IP`. Example:

```sh
TRANSLATE="172.30.0.11:6113 172.30.0.20:4000"
PUBLIC_IP=203.0.113.10
LAN_IP=192.168.1.10
LAN_NETWORK=192.168.1.0/24
```

## Image details

- Build args: `PVPGN_VERSION` (git tag, default `1.99.8.0.0-rc1-PRO`), `WITH_LUA`, `WITH_MYSQL`, `WITH_SQLITE3`
- Volumes: `/usr/local/etc/pvpgn` (config), `/usr/local/var/pvpgn` (data)
- Any other command runs as-is, e.g. `docker compose run --rm bnetd bash`

## Links

- [PvPGN server](https://github.com/pvpgn/pvpgn-server)
- [D2GS installation guide](https://pvpgn.pro/d2gs_installation.html)
- [PvPGN gateway installer](https://github.com/pvpgn/battle.net-gateway-installer)
