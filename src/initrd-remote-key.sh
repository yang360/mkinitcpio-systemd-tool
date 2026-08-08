#!/usr/bin/busybox sh

# This file is part of https://github.com/random-archer/mkinitcpio-systemd-tool
# PATCHED 2026-08-08 (keyfetch-retry): retry the SSH fetch itself, not just the
# ping. ks01 answers ping before its sshd is up, so the stock script's single
# dbclient attempt can race a simultaneous power-on, write an empty keyfile,
# and park the boot at the passphrase prompt (2026-08-08 FSD drill, hv03).
# Success now requires dbclient exit 0 AND a non-empty keyfile.
# Re-applied on package ops by /etc/pacman.d/hooks/60-keyfetch-retry.hook.

source /etc/remotekey

for i in $(seq 1 ${REMOTE_KEY_TIMEOUT})
do
    if ping -c 1 -W 1 ${REMOTE_KEY_IP} &> /dev/null
    then
        if dbclient -y ${REMOTE_KEY_USER}@${REMOTE_KEY_IP} "cat ${REMOTE_KEY_FILE}" > /root/${REMOTE_KEY_FILE} \
            && [ -s /root/${REMOTE_KEY_FILE} ]
        then
            chmod 600 /root/${REMOTE_KEY_FILE}
            exit 0
        fi
        rm -f /root/${REMOTE_KEY_FILE}
    fi
    sleep 1
done

echo "Failed to get ${REMOTE_KEY_FILE}"
