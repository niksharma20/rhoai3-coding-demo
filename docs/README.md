# Documentation Index

This directory holds operational and governance documentation for the Red Hat OpenShift AI coding demo. The root README and stage READMEs explain the learning path; these docs hold the runbooks, validation notes, and contribution rules that would make those READMEs too operational.

| Document | Purpose |
|----------|---------|
| [OPERATIONS.md](OPERATIONS.md) | Deployment order, bootstrap behavior, validation strategy, GitOps operations, day-2 notes, run verdicts, and cleanup guidance |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Symptom-based diagnostics and recovery commands |
| [PLATFORM_BASELINE.md](PLATFORM_BASELINE.md) | Fresh-environment platform baseline |
| [../BACKLOG.md](../BACKLOG.md) | Workarounds, known limitations, validation notes, and planned cleanup |

_This directory stays operational-only. Stage 090 v2 authoring is on `main`; live Argo 050 tracks `main`._

## Learning Path

The published workshop is the ordered path below. Stages 070–090 remain in the repository and are omitted from this path for now.

1. [Project README](../README.md)
2. [Stage 010: OpenShift AI Platform Foundation](../stages/010-openshift-ai-platform-foundation/README.md)
3. [Stage 020: GPU Infrastructure for Private AI](../stages/020-gpu-infrastructure-private-ai/README.md)
4. [Stage 030: Private Model Serving](../stages/030-private-model-serving/README.md)
5. [Stage 040: Governed Models-as-a-Service](../stages/040-governed-models-as-a-service/README.md)
6. [Stage 050: Advanced Application Platform](../stages/050-advanced-app-platform/README.md)
7. [Stage 060: Model Evaluation](../stages/060-model-evaluation/README.md)

## AI Collaboration Rules

Shared rules, skills, and agent definitions live under [`../.agents/`](../.agents/). They define project-wide AI agent behavior. Do not commit local rules, skills, credentials, personal paths, private cluster URLs, or personal preferences. See [CONTRIBUTING.md](../CONTRIBUTING.md) before changing shared agent behavior.

Claims in user-facing documentation must stay aligned with manifests, scripts, validation checks, and official product documentation.
