#!/usr/bin/env bash
# deploy.sh - Stage 060: Model evaluation
# Creates the database password outside Git, then hands EvalHub to Argo CD.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
STAGE_NAME="060-model-evaluation"

if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT_DIR/.env"
  set +a
fi

if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
  echo "ERROR: RHOAI_EXPECTED_API_SERVER is not set." >&2
  exit 1
fi

ACTUAL_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ "$ACTUAL_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
  echo "ERROR: Active cluster ($ACTUAL_SERVER) does not match RHOAI_EXPECTED_API_SERVER." >&2
  exit 1
fi

echo "✓ Cluster guard passed: $ACTUAL_SERVER"
"$ROOT_DIR/scripts/require-node-sizing.sh"

NS="evalhub"
oc get namespace "$NS" >/dev/null 2>&1 || oc new-project "$NS" >/dev/null

if oc get secret evalhub-postgres -n "$NS" >/dev/null 2>&1 \
  && oc get secret evalhub-db-credentials -n "$NS" >/dev/null 2>&1; then
  echo "✓ EvalHub database secrets already exist"
else
  PW="${EVALHUB_DB_PASSWORD:-$(openssl rand -base64 24 | LC_ALL=C tr -dc 'A-Za-z0-9' | cut -c1-24)}"
  oc create secret generic evalhub-postgres \
    -n "$NS" \
    --from-literal=username=evalhub \
    --from-literal=password="$PW" \
    --from-literal=database=evalhub \
    --dry-run=client -o yaml | oc apply -f -
  oc create secret generic evalhub-db-credentials \
    -n "$NS" \
    --from-literal=db-url="postgres://evalhub:${PW}@postgresql.${NS}.svc.cluster.local:5432/evalhub" \
    --dry-run=client -o yaml | oc apply -f -
  unset PW
  echo "✓ EvalHub database secrets created (not stored in Git)"
fi

oc apply -f "$ROOT_DIR/gitops/argocd/app-of-apps/${STAGE_NAME}.yaml"
echo "✓ Argo CD Application ${STAGE_NAME} applied"
echo "  EvalHub becomes Ready after TrustyAI is Managed and PostgreSQL is up."
echo "  Run ./stages/${STAGE_NAME}/validate.sh"
