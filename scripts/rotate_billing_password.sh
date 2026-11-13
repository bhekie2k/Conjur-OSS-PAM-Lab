#!/bin/bash
set -euo pipefail
source /home/bhekink/.rotation_env

CONJUR_URL="https://localhost:8443"
ACCOUNT="myConjurAccount"
CERT="/home/bhekink/conjur-quickstart/conjur-server.pem"
HOST_ID_ENC="host%2Fprod%2Fdb-admin%2Frotation-job-01"
LOGFILE="/home/bhekink/conjur-quickstart/rotation.log"

log() { echo "$(date -Iseconds) $1" >> "$LOGFILE"; }

log "rotation started"

# 1. Authenticate to Conjur as rotation-job-01
TOKEN=$(curl -s --cacert "$CERT" -d "$ROTATION_API_KEY" \
  "$CONJUR_URL/authn/$ACCOUNT/$HOST_ID_ENC/authenticate" | base64 | tr -d '\r\n')

# 2. Fetch the rotator DB credential from the vault
ROTATOR_PW=$(curl -s --cacert "$CERT" -H "Authorization: Token token=\"$TOKEN\"" \
  "$CONJUR_URL/secrets/$ACCOUNT/variable/prod%2Fdb-admin%2Frotator-password")

# 3. Generate a new random password
NEW_PW=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)

# 4. Change it on the database
PGPASSWORD="$ROTATOR_PW" psql -h localhost -p 8432 -U rotator -d billing \
  -c "ALTER ROLE billing_app WITH PASSWORD '$NEW_PW';" > /dev/null

log "database password changed"

# 5. Update the vault to match
curl -s --cacert "$CERT" -H "Authorization: Token token=\"$TOKEN\"" \
  -X POST --data "$NEW_PW" \
  "$CONJUR_URL/secrets/$ACCOUNT/variable/prod%2Fbilling-app%2Fdb%2Fpassword"

log "vault updated - rotation complete"
