#!/usr/bin/env bash
set -euo pipefail

mkdir -p /run/sshd "${SSH_DIR:-/ssh}"
chmod 700 "${SSH_DIR:-/ssh}" || true

# === client keypair used to SSH to managed nodes ===
KEY="${SSH_DIR:-/ssh}/id_ed25519"
PUB="${KEY}.pub"
if [ ! -f "$KEY" ]; then
  echo "[entrypoint] Generating client keypair at $KEY"
  ssh-keygen -t ed25519 -C "ansible-container" -f "$KEY" -N "" >/dev/null
  chmod 600 "$KEY"; chmod 644 "$PUB"
fi

# Show pubkey so you can copy it to targets' authorized_keys
echo
echo "=== Container SSH public key (add to your managed nodes) ==="
cat "$PUB"
echo "============================================================"
echo

# Also allow this key to SSH into the container as 'ansible' (optional convenience)
install -d -m 700 -o ansible -g ansible ~ansible/.ssh
touch ~ansible/.ssh/authorized_keys
cat "$PUB" >> ~ansible/.ssh/authorized_keys || true
chown ansible:ansible ~ansible/.ssh/authorized_keys
chmod 600        ~ansible/.ssh/authorized_keys

# Host keys for sshd
ssh-keygen -A >/dev/null

echo "[entrypoint] Starting sshd (foreground)"
exec /usr/sbin/sshd -D -e
