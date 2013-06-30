#!/bin/bash

export COROSYNC_MAIN_CONFIG_FILE=$(mktemp)

function cleanup()
{
  rm -f "$COROSYNC_MAIN_CONFIG_FILE"
}

trap cleanup EXIT

SERVER_ADDRESSES=" \
  2a01:7e00::f03c:91ff:fe93:4fb3 \
  2a02:270:2015:b00b:3e07:54ff:fe0c:3fd6 \
  2a02:270:2015:b00b:babe:cafe:face:beef \
  "

LOCAL_ADDRESSES=$(ip -o -6 addr show | awk '$3 = "inet6" { print $4 }' | cut -d/ -f1)
NODE_ID=100

for a in $SERVER_ADDRESSES
do
  for b in $LOCAL_ADDRESSES
  do
    if [ "$a" = "$b" ]
    then
      LOCAL_ADDRESS=$a
      break 2
    fi
  done
  NODE_ID=$((NODE_ID+1))
done

if [ -z "$LOCAL_ADDRESS" ]
then
  echo "Did not find any server address in local address list" 2>&1
  exit 1
fi

(cat <<EOF
totem {
        version: 2
        transport: udpu
        secauth: on
        nodeid: $NODE_ID
        interface {
                ringnumber: 0
                bindnetaddr: $LOCAL_ADDRESS
                mcastport: 5405
EOF

for SERVER in $SERVER_ADDRESSES
do
  cat <<EOF
                member {
                        memberaddr: $SERVER
                }
EOF
done

cat <<EOF
        }
}
logging {
        fileline: off
        to_stderr: yes
        to_logfile: no
        to_syslog: yes
        syslog_facility: daemon
        debug: off
        timestamp: on
        logger_subsys {
                subsys: AMF
                debug: off
        }
}
EOF
) > "$COROSYNC_MAIN_CONFIG_FILE"

export COROSYNC_TOTEM_AUTHKEY_FILE=/etc/bitraf1/keyring/corosync
export LD_LIBRARY_PATH="$PACKAGE_ROOT"/lib:"$PACKAGE_ROOT"/libexec

cat "$COROSYNC_MAIN_CONFIG_FILE"

"$PACKAGE_ROOT"/sbin/corosync -f
