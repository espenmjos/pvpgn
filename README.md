<h1 align="center">pvpgn</h1>

<p align="center">
  <b>A Docker image for the PvPGN Battle.net server emulator.</b><br>
  bnetd, d2cs and d2dbs in one small Ubuntu 24.04 image, configured with environment variables.
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/espenmjos/pvpgn"></a>
  <img alt="PvPGN 1.99.8" src="https://img.shields.io/badge/PvPGN-1.99.8-blue">
  <img alt="Ubuntu 24.04" src="https://img.shields.io/badge/Ubuntu-24.04-e95420?logo=ubuntu&logoColor=white">
  <img alt="Docker Compose" src="https://img.shields.io/badge/docker-compose-2496ed?logo=docker&logoColor=white">
</p>

---

**pvpgn** packages [PvPGN](https://github.com/pvpgn/pvpgn-server) **1.99.8**, an open source Battle.net server
emulator. One image contains all three daemons, and the container command chooses which one runs:

| Command | Port | Role |
|---------|------|------|
| `bnetd` | 6112 TCP + UDP | Battle.net login, chat, channels and game lists |
| `d2cs` | 6113 TCP | Diablo II closed realm: character server |
| `d2dbs` | 6114 TCP | Diablo II closed realm: character database, used by D2GS |

> [!TIP]
> **Do you want a complete Diablo II realm?** Use [espenmjos/d2gs](https://github.com/espenmjos/d2gs). Its compose
> file builds this image together with the D2GS game server and connects everything for you.

## Features

- **One image, three daemons:** run `bnetd`, `d2cs` or `d2dbs` from the same image.
- **Small and up to date:** a multi-stage build on Ubuntu 24.04 gives a runtime image of about 175 MB.
- **Configured with environment variables:** realm, d2cs and D2GS settings are written to the config files on every
  start. Settings you don't set are left alone, so you can still edit the files by hand.
- **Address translation built in:** set `PUBLIC_IP` (and optionally `LAN_IP`), and clients get reachable addresses
  instead of private container IPs.
- **Safe defaults:** the daemons run as the unprivileged `pvpgn` user. Default files are only copied into empty
  volumes and existing files are never overwritten.
- **Lua, MySQL and SQLite** support is built in. Each one can be turned off with a build argument.

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Operations](#operations)
- [Image details](#image-details)
- [Project status](#project-status)
- [Credits and references](#credits-and-references)
- [License and legal](#license-and-legal)

## Requirements

- A Linux host with [Docker Engine](https://docs.docker.com/engine/install/) and the
  [Compose plugin](https://docs.docker.com/compose/install/linux/) (`docker compose`, v2)
- A few hundred MB of disk. The daemons use very little RAM and CPU (under 10 MB of RAM each when idle).
- One or more D2GS game servers if you want to play on the Diablo II closed realm, for example
  [espenmjos/d2gs](https://github.com/espenmjos/d2gs)

## Quick start

The compose file in this repository starts a Diablo II closed realm (`bnetd` + `d2cs` + `d2dbs`) without the game
server. Use it when your D2GS runs on another machine.

```sh
git clone https://github.com/espenmjos/pvpgn.git
cd pvpgn
cp .env.example .env     # set PUBLIC_IP and D2GS_IPS
docker compose up -d --build
docker compose logs -f
```

The config files are stored in `./etc`, and data (accounts, characters, ladders) in `./var`. The default PvPGN files
are copied there the first time the containers start.

### Ports

| Port | Protocol | Service | Expose to |
|------|----------|---------|-----------|
| 6112 | TCP + UDP | bnetd | Players |
| 6113 | TCP | d2cs | Players and D2GS |
| 6114 | TCP | d2dbs | D2GS only |

## Configuration

### Environment variables

The entrypoint writes these settings into the config files every time the container starts. A setting is only
applied when its variable is set. If you prefer to manage a setting by hand in the `.conf` files, leave the variable
out.

| Variable | Daemon | Writes to |
|----------|--------|-----------|
| `REALM_NAME` | bnetd, d2cs | `realm.conf`, and `realmname` in `d2cs.conf` |
| `REALM_DESCRIPTION` | bnetd | `realm.conf` |
| `D2CS_ADDR` | bnetd | The d2cs address (`ip:port`) in `realm.conf` |
| `BNETD_ADDR` | d2cs | `bnetdaddr` in `d2cs.conf` |
| `D2GS_IPS` | d2cs, d2dbs | `gameservlist` in `d2cs.conf` and `d2dbs.conf` (comma-separated) |
| `D2GS_PASSWORD` | d2cs | `d2gs_password` in `d2cs.conf` |
| `PUBLIC_IP`, `TRANSLATE`, `LAN_IP`, `LAN_NETWORK` | bnetd, d2cs | `address_translation.conf` (see below) |

### Address translation

On a private Docker network, PvPGN would send container IP addresses to clients, and clients can't reach those.
To fix this, set:

- `TRANSLATE` to the internal `ip:port` addresses to replace (separated by spaces)
- `PUBLIC_IP` to the address clients should get instead
- optionally `LAN_IP` and `LAN_NETWORK`, so clients inside that network get `LAN_IP`

```sh
TRANSLATE="172.30.0.11:6113 172.30.0.20:4000"
PUBLIC_IP=203.0.113.10
LAN_IP=192.168.1.10
LAN_NETWORK=192.168.1.0/24
```

`address_translation.conf` is generated from these variables, so any changes you make to that file by hand are
overwritten.

### Editing config files

You can edit the files in `./etc` directly. Then restart:

```sh
docker compose restart
```

## Operations

```sh
docker compose logs -f bnetd                     # logs from one daemon
docker compose run --rm bnetd bash               # shell with the volumes mounted
docker compose exec bnetd bnpass                 # create a PvPGN password hash
tar czf pvpgn-backup.tgz etc var                 # backup (best done with the realm stopped)
git pull && docker compose up -d --build         # update
```

## Image details

| | |
|---|---|
| Base image | `ubuntu:24.04` (multi-stage build) |
| PvPGN source | [pvpgn/pvpgn-server](https://github.com/pvpgn/pvpgn-server), tag `1.99.8.0.0-rc1-PRO` |
| Build arguments | `PVPGN_VERSION`, `WITH_LUA`, `WITH_MYSQL`, `WITH_SQLITE3` (all `true` by default) |
| Volumes | `/usr/local/etc/pvpgn` (config), `/usr/local/var/pvpgn` (data) |
| Exposed ports | `6112/tcp`, `6112/udp`, `6113/tcp`, `6114/tcp` |
| Default command | `bnetd` |
| User | The entrypoint starts as root to fix volume ownership, then runs the daemon as `pvpgn` |
| Tools included | `bnpass`, `bnchat`, `bnftp`, `bnstat`, `sha1hash` and the `bni*` utilities |

The container runs any command other than `bnetd`, `d2cs` or `d2dbs` unchanged, for example
`docker compose run --rm bnetd bash`.

## Project status

| Area | Status |
|------|--------|
| Diablo II closed realm with D2GS and a classic 1.14d client | ✅ Tested end to end through [d2gs](https://github.com/espenmjos/d2gs) |
| Diablo II: Lord of Destruction | ⚠️ Not tested yet |
| Other games supported by PvPGN (StarCraft, Warcraft II BNE, Warcraft III) | ⚠️ Should work with `bnetd` alone, but not tested |

Bug reports and pull requests are welcome.

## Credits and references

- [PvPGN server](https://github.com/pvpgn/pvpgn-server): the server this image packages
- [D2GS installation guide (pvpgn.pro)](https://pvpgn.pro/d2gs_installation.html)
- [PvPGN gateway installer](https://github.com/pvpgn/battle.net-gateway-installer): adds a server to the client's
  gateway list

## License and legal

The Dockerfile, scripts and compose files in this repository are released under the [MIT License](LICENSE). PvPGN
itself is licensed under the GPL; see [pvpgn/pvpgn-server](https://github.com/pvpgn/pvpgn-server).

This project is not affiliated with or endorsed by Blizzard Entertainment. Battle.net, Diablo, StarCraft and Warcraft
are trademarks of Blizzard Entertainment, Inc.
