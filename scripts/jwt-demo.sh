#!/bin/sh
echo "=============================================="
echo " Conjur JWT Authentication - End to End Demo"
echo " Pod: billing-test / ServiceAccount: billing-sa"
echo "=============================================="
echo ""
echo "[1] Reading pod service account token (mounted by Kubernetes, no human handling)..."
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
echo "    Token length: ${#TOKEN} chars"
SUB=$(echo $TOKEN | cut -d "." -f2 | base64 -d 2>/dev/null | grep -o "\"sub\":\"[^\"]*\"")
echo "    Identity claim: $SUB"
echo ""
echo "[2] Authenticating to Conjur with the JWT (no API key involved)..."
CONJUR_TOKEN=$(curl -sk -X POST "https://proxy/authn-jwt/k8s-cluster/myConjurAccount/authenticate" --data-urlencode "jwt=$TOKEN" | base64 | tr -d "\n")
if [ -z "$CONJUR_TOKEN" ]; then echo "    FAILED to authenticate"; exit 1; fi
echo "    Received Conjur access token (${#CONJUR_TOKEN} chars)"
echo ""
echo "[3] Fetching prod/billing-app/db/password from the vault..."
SECRET=$(curl -sk -H "Authorization: Token token=\"$CONJUR_TOKEN\"" "https://proxy/secrets/myConjurAccount/variable/prod%2Fbilling-app%2Fdb%2Fpassword")
echo "    Retrieved secret length: ${#SECRET} chars"
echo ""
echo "=============================================="
echo " SUCCESS: secret retrieved using pod identity"
echo " No API key, no .netrc, no stored credential."
echo "=============================================="
