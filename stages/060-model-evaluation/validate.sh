#!/usr/bin/env bash
# validate.sh - Stage 060: Model evaluation
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT_DIR/.env"
  set +a
fi

if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
  echo "ERROR: RHOAI_EXPECTED_API_SERVER is not set. Set it in .env." >&2
  exit 1
fi
ACTUAL_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ "$ACTUAL_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
  echo "ERROR: Active cluster ($ACTUAL_SERVER) does not match guard." >&2
  exit 1
fi

check() {
  local label="$1"
  local result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "✓ $label"
    (( PASS++ )) || true
  else
    echo "✗ $label  ($result)"
    (( FAIL++ )) || true
  fi
}

NS="evalhub"
STATE=$(oc get dsc default-dsc -o jsonpath='{.spec.components.trustyai.managementState}' 2>/dev/null || true)
[[ "$STATE" == "Managed" ]] && R="pass" || R="trustyai=${STATE:-missing}"
check "DataScienceCluster TrustyAI is Managed" "$R"

if oc get crd evalhubs.trustyai.opendatahub.io >/dev/null 2>&1; then
  check "EvalHub CRD is installed" "pass"
else
  check "EvalHub CRD is installed" "missing"
fi

PHASE=$(oc get evalhub evalhub -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
READY=$(oc get evalhub evalhub -n "$NS" -o jsonpath='{.status.ready}' 2>/dev/null || true)
[[ "$PHASE" == "Ready" && "$READY" == "True" ]] && R="pass" || R="phase=${PHASE:-missing} ready=${READY:-missing}"
check "EvalHub is Ready" "$R"

PROVIDERS=$(oc get evalhub evalhub -n "$NS" -o jsonpath='{.status.activeProviders}' 2>/dev/null || true)
[[ "$PROVIDERS" == *"lm-evaluation-harness"* && "$PROVIDERS" == *"ragas"* ]] && R="pass" || R="providers=${PROVIDERS:-empty}"
check "EvalHub loaded benchmark and RAGAS providers" "$R"

PODS=$(oc get pods -n "$NS" -l app=eval-hub --no-headers 2>/dev/null || true)
[[ "$PODS" == *"2/2"* && "$PODS" == *"Running"* ]] && R="pass" || R="${PODS:-no pod}"
check "EvalHub pod is running" "$R"

HOST=$(oc get route evalhub -n "$NS" -o jsonpath='{.spec.host}' 2>/dev/null || true)
if [[ -n "$HOST" ]]; then
  HEALTH=$(curl -ksS --max-time 20 "https://${HOST}/api/v1/health" || true)
  [[ "$HEALTH" == *"healthy"* ]] && R="pass" || R="health=${HEALTH:-empty}"
  check "EvalHub health endpoint" "$R"
else
  check "EvalHub health endpoint" "route missing"
fi

ADMIN=$(oc get rolebinding rhods-admins-evalhub -n "$NS" --no-headers 2>/dev/null || true)
[[ -n "$ADMIN" ]] && R="pass" || R="missing"
check "rhods-admins can submit evaluations" "$R"

DB=$(oc get secret evalhub-db-credentials -n "$NS" --no-headers 2>/dev/null || true)
[[ -n "$DB" ]] && R="pass" || R="missing"
check "EvalHub database secret exists" "$R"

PHASE=$(oc get nemoguardrails maas-guardrails -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
[[ "$PHASE" == "Ready" ]] && R="pass" || R="phase=${PHASE:-missing}"
check "NeMo guardrails are Ready" "$R"

ROUTE=$(oc get httproute maas-guardrails -n "$NS" -o jsonpath='{.spec.rules[0].matches[0].path.value}' 2>/dev/null || true)
[[ "$ROUTE" == "/models-as-a-service/qwen3-6-27b/guardrails" ]] && R="pass" || R="path=${ROUTE:-missing}"
check "Guardrail check is on the MaaS gateway" "$R"

echo
echo "Validation: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
