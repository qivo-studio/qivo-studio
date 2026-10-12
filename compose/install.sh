#!/usr/bin/env bash
# QiVo Studio Enterprise: guided install with Docker Compose. Asks a few questions, writes .env, starts the stack.
#   ./install.sh            # in this folder (compose, or the release bundle's compose folder)
# Everything it asks can be changed later: in .env (then `docker compose up -d`) or in the app (Connections,
# Settings → Sandbox for probing). Passwords are typed without echo and only written to .env (mode 600).
set -euo pipefail
cd "$(dirname "$0")"

say() { printf '%s\n' "$*"; }
ask() {   # ask VAR "Question" [default]
  local def="${3:-}" reply
  read -r -p "$2${def:+ [$def]}: " reply || true
  printf -v "$1" '%s' "${reply:-$def}"
}
ask_secret() {   # ask_secret VAR "Question" [min length]
  local min="${3:-1}" reply
  while true; do
    read -r -s -p "$2: " reply || true; echo
    if [ "${#reply}" -ge "$min" ]; then printf -v "$1" '%s' "$reply"; return; fi
    say "  At least $min characters, please."
  done
}
yes_no() {   # yes_no "Question" default(y|n) -> status 0 for yes
  local def="$2" reply
  read -r -p "$1 [$([ "$def" = y ] && echo Y/n || echo y/N)]: " reply || true
  reply="${reply:-$def}"
  [[ "$reply" =~ ^[Yy] ]]
}
random() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-24}"; }

command -v docker >/dev/null || { say "Docker is not installed: https://docs.docker.com/engine/install/"; exit 1; }
docker compose version >/dev/null 2>&1 || { say "Docker Compose v2 is needed (docker compose ...)."; exit 1; }
if [ -e .env ] && ! yes_no ".env exists already. Replace it?" n; then say "Kept .env. Start with: docker compose up -d"; exit 0; fi

say ""
say "QiVo Studio Enterprise setup"
say "----------------------------"
say ""
say "The first administrator"
ask ADMIN_EMAIL "  Email"
ask_secret ADMIN_PASSWORD "  Password (at least 12 characters)" 12
ask ORGANISATION "  Organisation" "My organisation"
ask PORT "  Port for the web app" "8000"

ORACLE_DSN="" ORACLE_USER="" ORACLE_PASSWORD=""
say ""
say "An Oracle database to scan, read-only (you can also add connections later in the app)."
if yes_no "Add one now?" n; then
  ask ORACLE_DSN "  Easy Connect (host:port/service)"
  ask ORACLE_USER "  Read-only account" "LINEAGE"
  ask_secret ORACLE_PASSWORD "  Password"
fi

SANDBOX="no" SB_POOL="" SB_USER="" SB_PASSWORD="" SB_CDB="" SB_POOL_USER="" SB_POOL_PASSWORD="" SB_DATAFILES=""
say ""
say "A sandbox for probing (optional)."
say "  Lineage comes from the code alone; no sandbox is needed for it. A sandbox adds probing: dynamic SQL the code"
say "  cannot decide by itself is run in a copy of your schemas (structure, code, control-table rows; no business"
say "  data) and the SQL it builds is recorded. It must be an Oracle database you control, NOT production, set up"
say "  with the scripts in the sandbox folder (README.md there)."
if yes_no "Do you want a sandbox?" n; then
  SANDBOX="yes"
  ask SB_POOL "  Sandbox databases, comma-separated (host:port/service)"
  ask SB_USER "  Loader account" "sandbox_loader"
  ask_secret SB_PASSWORD "  Its password"
  if yes_no "  Rebuild each sandbox from a clean template after every job (recommended)?" y; then
    ask SB_CDB "    Container database (host:port/service of the CDB root)"
    ask SB_POOL_USER "    Pool account" "c##lineage_pool"
    ask_secret SB_POOL_PASSWORD "    Its password"
    ask SB_DATAFILES "    Where PDB datafiles live (a path, or omf)" "/opt/oracle/oradata/FREE"
  fi
else
  say "  No sandbox. You can plug one in later: Settings → Sandbox for probing."
fi

umask 077
cat > .env <<EOF
# Written by install.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ). Never commit this file. See .env.example for every setting.
POSTGRES_PASSWORD=$(random 32)
QIVO_ADMIN_EMAIL=$ADMIN_EMAIL
QIVO_ADMIN_PASSWORD=$ADMIN_PASSWORD
QIVO_ORGANISATION=$ORGANISATION
QIVO_PORT=$PORT
QIVO_PUBLIC_URL=http://localhost:$PORT
ORACLE_DSN=$ORACLE_DSN
ORACLE_LINEAGE_USER=$ORACLE_USER
ORACLE_LINEAGE_PASSWORD=$ORACLE_PASSWORD
QIVO_SANDBOX=$SANDBOX
SANDBOX_POOL=$SB_POOL
SANDBOX_DSN=${SB_POOL%%,*}
SANDBOX_LOADER_USER=$SB_USER
SANDBOX_LOADER_PASSWORD=$SB_PASSWORD
SANDBOX_CDB_DSN=$SB_CDB
SANDBOX_POOL_USER=$SB_POOL_USER
SANDBOX_POOL_PASSWORD=$SB_POOL_PASSWORD
SANDBOX_DATAFILES=$SB_DATAFILES
QIVO_WORKERS=1
LINEAGE_WORKERS=2
EOF
say ""
say "Wrote .env. Starting QiVo Studio (the first start takes a minute)..."
docker compose up -d --wait
if [ "$SANDBOX" = yes ]; then
  say ""
  say "Checking the sandbox..."
  docker compose exec -T app qivo sandbox-check || say "The sandbox is not ready yet: fix it, then run: docker compose exec app qivo sandbox-check"
fi
say ""
say "QiVo Studio is running: http://localhost:$PORT  (sign in as $ADMIN_EMAIL)"
