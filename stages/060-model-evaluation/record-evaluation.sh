#!/usr/bin/env bash
# Record guardrails and the latest EvalHub result on the Qwen3.6 model card.
# A pass is written only when a completed job for qwen3-6-27b includes a score.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib.sh"

load_env
check_oc_logged_in

MODEL_NAME="Qwen3.6-27B-FP8"
SERVED_NAME="qwen3-6-27b"
GUARDRAILS_PATH="/models-as-a-service/${SERVED_NAME}/guardrails/checks"

REGISTRY_HOST="$(oc get modelregistries.modelregistry.opendatahub.io demo-registry -n rhoai-model-registries -o jsonpath='{.status.hosts[0]}')"
[[ -n "$REGISTRY_HOST" ]] || { log_error "demo-registry has no route host"; exit 1; }
MR_BASE="https://${REGISTRY_HOST}/api/model_registry/v1alpha3"
EVAL_HOST="$(oc get route evalhub -n evalhub -o jsonpath='{.spec.host}')"
[[ -n "$EVAL_HOST" ]] || { log_error "EvalHub route is missing"; exit 1; }
TOKEN="$(oc whoami -t)"

mr_get() { curl -sk -H "Authorization: Bearer ${TOKEN}" "${MR_BASE}$1"; }

python3 - "$MR_BASE" "$TOKEN" "$MODEL_NAME" "$SERVED_NAME" "$GUARDRAILS_PATH" "https://${EVAL_HOST}" << 'PY'
import json, ssl, sys, urllib.request

ctx = ssl._create_unverified_context()

base, token, model_name, served_name, guard_path, eval_base = sys.argv[1:]

def get(url, headers):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, context=ctx) as resp:
        return json.load(resp)

def patch(url, headers, body):
    data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
    with urllib.request.urlopen(req, context=ctx) as resp:
        return resp.status

auth = {"Authorization": f"Bearer {token}"}
models = get(f"{base}/registered_models?pageSize=50", auth)
model = next((item for item in models.get("items", []) if item.get("name") == model_name), None)
if model is None:
    raise SystemExit(f"Registered model {model_name} was not found")

status = "awaiting-score"
job_id = ""
benchmark = ""
score = ""
try:
    jobs = get(f"{eval_base}/api/v1/evaluations/jobs?limit=50", {**auth, "X-Tenant": "evalhub"})
except Exception:
    jobs = {"items": []}

for job in jobs.get("items") or []:
    model_info = job.get("model") or {}
    if model_info.get("name") != served_name:
        continue
    if str(job.get("status") or job.get("state") or "").lower() != "completed":
        continue
    job_id = str(job.get("id") or job.get("job_id") or "")
    benchmarks = job.get("benchmarks") or []
    if benchmarks:
        benchmark = str(benchmarks[0].get("benchmark_id") or benchmarks[0].get("id") or "")
    result = job.get("result") or job.get("results") or {}
    raw_score = result.get("score") if isinstance(result, dict) else None
    if raw_score is None and isinstance(result, dict):
        metrics = result.get("metrics") or {}
        if isinstance(metrics, dict) and metrics:
            raw_score = next(iter(metrics.values()))
    if raw_score is not None and str(raw_score) != "":
        score = str(raw_score)
        status = "passed"
    break

def prop(value):
    return {"metadataType": "MetadataStringValue", "string_value": value}

current = model.get("customProperties") or {}
current["guardrails"] = prop("")
current["guardrails_path"] = prop(guard_path)
current["evaluation_status"] = prop(status)
if job_id:
    current["evaluation_job"] = prop(job_id)
if benchmark:
    current["evaluation_benchmark"] = prop(benchmark)
if score:
    current["evaluation_score"] = prop(score)

code = patch(
    f"{base}/registered_models/{model['id']}",
    {**auth, "Content-Type": "application/json"},
    {"customProperties": current},
)
if code != 200:
    raise SystemExit(f"Registry update failed with HTTP {code}")
print(f"Recorded {model_name}: evaluation_status={status}" + (f" score={score}" if score else " (no completed EvalHub score yet)"))
PY
unset TOKEN
log_success "Model card updated for ${MODEL_NAME}"
