#!/bin/bash
# Seeds config/data volumes with defaults and applies settings from
# environment variables, then runs the requested PvPGN daemon.
set -euo pipefail

ETC=/usr/local/etc/pvpgn
VAR=/usr/local/var/pvpgn
DEFAULTS=/usr/local/share/pvpgn/defaults

DAEMON="${1:-bnetd}"
case "$DAEMON" in
  bnetd|d2cs|d2dbs) shift || true ;;
  *) exec "$@" ;;   # anything else: run it as-is (e.g. bash)
esac

# Started as root so bind-mounted directories can be fixed up; the daemon itself
# runs as the unprivileged pvpgn user.
if [ "$(id -u)" = 0 ]; then
  chown -R pvpgn:pvpgn "$ETC" "$VAR"
  exec setpriv --reuid=pvpgn --regid=pvpgn --init-groups "$0" "$DAEMON" "$@"
fi

# Several daemons usually share the same volumes; serialize setup.
exec 9>"$ETC/.entrypoint.lock"
flock 9

# First start: copy default files into empty volumes. Existing files are never overwritten.
cp -r --update=none "$DEFAULTS/etc/." "$ETC/"
cp -r --update=none "$DEFAULTS/var/." "$VAR/"

# set_conf FILE KEY VALUE - replace "key = value" line in a PvPGN conf file
set_conf() {
  local file="$1" key="$2" value="$3"
  if grep -qE "^[#[:space:]]*${key}[[:space:]]*=" "$file"; then
    sed -i -E "0,/^[#[:space:]]*${key}[[:space:]]*=.*/s||${key} = ${value}|" "$file"
  else
    echo "${key} = ${value}" >> "$file"
  fi
}

# Address translation: tell clients the host's IP instead of internal container IPs.
#   PUBLIC_IP          address clients use to reach the host
#   LAN_IP/LAN_NETWORK optional: clients inside LAN_NETWORK get LAN_IP instead
#   TRANSLATE          space separated "internal_ip:port" entries to translate
write_address_translation() {
  [ -n "${PUBLIC_IP:-}" ] && [ -n "${TRANSLATE:-}" ] || return 0
  {
    echo "# Generated from PUBLIC_IP/LAN_IP/LAN_NETWORK/TRANSLATE on container start - edits are overwritten"
    for addr in $TRANSLATE; do
      port="${addr##*:}"
      if [ -n "${LAN_IP:-}" ] && [ -n "${LAN_NETWORK:-}" ]; then
        printf '%s\t%s:%s\tNONE\t%s\n' "$addr" "$LAN_IP" "$port" "$LAN_NETWORK"
      fi
      printf '%s\t%s:%s\tNONE\tANY\n' "$addr" "$PUBLIC_IP" "$port"
    done
  } > "$ETC/address_translation.conf"
}

# Each daemon only touches its own files. Settings are only applied when the
# variable is set, so hand-edited config files keep working.
case "$DAEMON" in
  bnetd)
    if [ -n "${REALM_NAME:-}" ] && [ -n "${D2CS_ADDR:-}" ]; then
      printf '"%s"\t"%s"\t%s\n' "$REALM_NAME" "${REALM_DESCRIPTION:-PvPGN Closed Realm}" "$D2CS_ADDR" \
        > "$ETC/realm.conf"
    fi
    write_address_translation
    ;;
  d2cs)
    [ -n "${REALM_NAME:-}" ]    && set_conf "$ETC/d2cs.conf" realmname     "$REALM_NAME"
    [ -n "${BNETD_ADDR:-}" ]    && set_conf "$ETC/d2cs.conf" bnetdaddr     "$BNETD_ADDR"
    [ -n "${D2GS_IPS:-}" ]      && set_conf "$ETC/d2cs.conf" gameservlist  "$D2GS_IPS"
    [ -n "${D2GS_PASSWORD+x}" ] && set_conf "$ETC/d2cs.conf" d2gs_password "\"${D2GS_PASSWORD}\""
    write_address_translation
    ;;
  d2dbs)
    [ -n "${D2GS_IPS:-}" ]      && set_conf "$ETC/d2dbs.conf" gameservlist "$D2GS_IPS"
    ;;
esac

flock -u 9
exec 9>&-

exec "/usr/local/sbin/$DAEMON" -f "$@"
