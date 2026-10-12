# Trusted Enterprise AI Development Platform

Every enterprise adopting AI-assisted development must answer three foundational questions — and each one maps to a platform capability that Red Hat delivers.

## Where Do We Run It?

**Red Hat Hybrid Cloud Platform.** Before AI models can serve developers, they need infrastructure that runs consistently everywhere: on-premises, at the edge, across multiple clouds. Red Hat OpenShift is an open, unified platform designed to build, manage, and scale applications — containers, virtual machines, and AI models — from a single control plane. It provides the enterprise Kubernetes foundation: identity, RBAC, networking, routing, scheduling, storage integration, monitoring, and GitOps patterns that make platform state reproducible and auditable.

The hybrid cloud platform is the first answer because it removes the location constraint. Organizations choose where workloads run based on data sovereignty, latency, cost, and regulation — not based on infrastructure limitations.

## How Do We Serve And Govern AI?

**Red Hat Private AI Platform.** Running AI models is not enough. Enterprises need to retain data sovereignty, control costs, enforce access policy, and operate at scale — without scattering credentials and endpoints across teams. Red Hat OpenShift AI is an enterprise-grade MLOps and GenAIOps platform that builds, tunes, and deploys AI models securely on-premises or across a hybrid cloud. It offers flexibility and consistency to build, deploy, and manage AI at scale across any hardware, addressing data constraints, privacy, security, and cost control.

Centered around open-source LLMs and AI agents, it lets companies serve private models inside the platform boundary while governing approved external models through a centralized Models-as-a-Service layer — one access point where platform teams control identity, API keys, subscriptions, rate limits, token limits, quotas, telemetry, and model lifecycle.

## How Do Developers Consume It?

**Red Hat Enterprise Application Platform.** An application platform is an integrated set of tools and services for developing, testing, deploying, and managing software through its entire lifecycle — not just one phase. It comprises everything developers need to build and run both applications and AI: infrastructure management for scalability, CI/CD pipelines with quality gates, monitoring, service mesh, APIs, GitOps, runtimes, security tooling, and developer portals that provide self-service access to all of it.

Red Hat delivers this through the Advanced Developer Suite: Developer Hub for the software catalog, OpenShift Dev Spaces for managed cloud workspaces, and OpenShift Pipelines for delivery with quality gates. The current workshop uses that layer as platform capability. The coding exercises that sit on top of it are not part of the published path.

## The Demo

The published workshop builds the platform and then scores a model before a team uses it. A writer can draft on a private model, through one governed gateway, and the platform team can keep a score for instruction following, safety, and speed.

The workshop does not claim regulatory compliance. It shows controls and boundaries that help architects design AI-enabled platforms for privacy-sensitive, sovereignty-sensitive, and regulated environments.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ENTERPRISE APPLICATION PLATFORM                                            │
│                                                                             │
│  Developer Hub · Dev Spaces · CI/CD Pipelines · Migration Toolkit           │
│  Golden-path templates · Quality gates · Software catalog · TechDocs        │
├─────────────────────────────────────────────────────────────────────────────┤
│  PRIVATE AI PLATFORM                                                        │
│                                                                             │
│  OpenShift AI · Model Serving (vLLM) · Model Registry · GenAI Studio        │
│  Models-as-a-Service · GPU Scheduling (Kueue) · Model Observability         │
│  AI Gateway · Usage Metrics · Token limits · API keys · Telemetry           │
├─────────────────────────────────────────────────────────────────────────────┤
│  HYBRID CLOUD PLATFORM                                                      │
│                                                                             │
│  Red Hat OpenShift · Kubernetes · Identity & RBAC · Networking & Routing    │
│  Storage (ODF) · Monitoring · GitOps (Argo CD) · GPU Infrastructure         │
│  Scheduling · Certificate Management · Node Management                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

The three layers work together as a single governed stack. Developers interact with the top layer — portals, workspaces, and AI coding assistants. Their prompts and code flow through the middle layer where models are served, access is governed, and usage is metered. Everything runs on the bottom layer where infrastructure, identity, networking, and state are managed consistently across hybrid cloud environments.

The central design choice: developers and their tools never connect directly to scattered model endpoints. They connect through Models-as-a-Service, where platform teams publish approved model choices and enforce access policy — one governed gateway for every AI consumer.

## What The Demo Shows

The published workshop is six stages. Stages 010–060 construct the platform declaratively — every resource reconciled from Git by Argo CD. Stage 060 scores a model that Stages 030 and 040 already serve.

| Stage | Intent |
|-------|--------|
| [010 - OpenShift AI Platform Foundation](stages/010-openshift-ai-platform-foundation/README.md) | Establish the AI control plane: operator, dashboard, model registry, identity, and observability |
| [020 - GPU Infrastructure for Private AI](stages/020-gpu-infrastructure-private-ai/README.md) | Provision GPU workers and quota-controlled scheduling for model workloads |
| [030 - Private Model Serving](stages/030-private-model-serving/README.md) | Serve private LLMs with vLLM inside the platform boundary |
| [040 - Governed Models-as-a-Service](stages/040-governed-models-as-a-service/README.md) | Expose private and external models through a governed MaaS gateway with API keys, rate limits, and telemetry |
| [050 - Advanced Application Platform](stages/050-advanced-app-platform/README.md) | Add the developer-facing layer: Developer Hub, Dev Spaces, Pipelines, quality gates, and provenance |
| [060 - Model Evaluation](stages/060-model-evaluation/README.md) | Score a served model with EvalHub before a team is allowed to use it |

## How Red Hat And Open Source Make It Work

Red Hat OpenShift provides the enterprise Kubernetes foundation: identity, RBAC, networking, routing, scheduling, storage integration, monitoring, and GitOps patterns. Red Hat OpenShift AI adds the AI control plane for model serving, GenAI Studio, model registry, and MaaS. Red Hat Advanced Developer Suite capabilities bring workspaces, modernization, portal discovery, and AI-assisted developer experiences into the same platform story.

Open-source models make the private path possible. Qwen runs on the platform through vLLM, so unpublished prompts stay inside the trust boundary. Approved external models, when used, still pass through the same MaaS gateway, where the platform team keeps the key, the limit, and the record of use.

Red Hat's role in this architecture is integration, lifecycle, support posture, and operational consistency — turning open-source building blocks into a governed enterprise platform.

## Running The Workshop

The READMEs explain the architecture. Use the commands below only in a prepared OpenShift environment.

**Environment sizing (required).** The full stack (RHOAI + ODF + GPU + MaaS + model serving) puts heavy, sustained load on the control plane. Provision `m6a.4xlarge`-class nodes (16 vCPU / 64 GiB) for the control plane *and* the CPU workers. The `m6a.xlarge` (4 vCPU / 16 GiB) control plane is **not** sufficient: kube-apiserver exhausts the node's CPU/memory and masters fail one after another. GPU nodes are sized by accelerator (e.g. `g6e.2xlarge`) and are exempt. Every stage's `deploy.sh` runs `scripts/require-node-sizing.sh` first and refuses to start on undersized nodes.

```bash
git clone https://github.com/niksharma20/rhoai3-coding-demo.git
cd rhoai3-coding-demo
```

**Environment configuration (required).** Before deploying any stage, copy the environment template and fill in the values for your target cluster. The `.env` file drives Git source references for Argo CD, cluster safety guards, demo persona credentials, external model API keys, and Stage 050 delivery-chain integrations (GitHub App, PAT, Quay robot account). Deploy scripts source this file automatically — deployment will fail or produce incomplete results without it.

```bash
cp env.example .env
# Edit .env — fill in RHOAI_EXPECTED_API_SERVER, credentials, and API keys
oc login --token=<token> --server=<api>
./scripts/validate-stage-flow.sh
```

**Deploy the platform stages in order.** Stage 010 bootstraps OpenShift GitOps itself (declarative overlays in `gitops/bootstrap/`) before handing the platform to Argo CD.

```bash
./stages/010-openshift-ai-platform-foundation/deploy.sh
./stages/020-gpu-infrastructure-private-ai/deploy.sh
./stages/030-private-model-serving/deploy.sh
./stages/040-governed-models-as-a-service/deploy.sh
./stages/050-advanced-app-platform/deploy.sh
./stages/060-model-evaluation/deploy.sh
```

For deployment detail, validation strategy, and recovery procedures, see:

- [Documentation Index](docs/README.md)
- [Operations Guide](docs/OPERATIONS.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Backlog and Workaround Register](BACKLOG.md)

## Repository Map

```text
rhoai3-coding-demo/
|-- README.md
|-- AGENTS.md                        # Entry point for AI coding agents working on this repo
|-- BACKLOG.md                       # Workarounds, limitations, and deferred work
|-- CONTRIBUTING.md
|-- env.example
|-- scripts/                         # Shared helpers, validation, recovery
|-- .agents/                         # Tool-neutral shared agent guidance: rules, skills, hooks, references
|-- gitops/
|   |-- bootstrap/                   # Declarative OpenShift GitOps bootstrap (stage 010)
|   |-- argocd/app-of-apps/          # Argo CD Applications for GitOps stages 010-060
|   `-- stages/                      # GitOps source for stage manifests
|-- stages/                          # Stage READMEs and per-stage deploy/validate scripts
`-- docs/                            # Operations, troubleshooting, TechDocs, and governance docs
```

## This Repository Practices What It Demonstrates

[`AGENTS.md`](AGENTS.md) is the agent entry point, and [`.agents/`](.agents/README.md) holds tool-neutral rules, doc-grounded skills for every Red Hat product in the demo, and safety hooks (including a cluster guard that blocks mutating `oc`/`kubectl` commands against unintended clusters). Tool-specific directories such as `.cursor/` contain only thin bridge files that point at the shared layer.

## Demo Personas

| User | Purpose |
|------|---------|
| `ai-admin` | Platform administrator persona for OpenShift AI, MTA, portal, and model administration |
| `ai-developer` | Developer persona consuming workspaces, models, and modernization workflows |
| `kubeadmin` | Cluster administrator for platform setup and recovery |

## Red Hat Products Demonstrated

| Red Hat product | Role in the workshop |
|-----------------|----------------------|
| [Red Hat OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) | Kubernetes application platform for identity, RBAC, networking, routing, scheduling, monitoring, and operations |
| [Red Hat OpenShift AI](https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai) | AI platform for model serving, GenAI Studio, model registry, and MaaS |
| [Red Hat Advanced Developer Suite](https://www.redhat.com/en/products/advanced-developer-suite) | Product family for the developer productivity layer represented by Dev Spaces, MTA, Developer Hub, and Developer Lightspeed |

## References

- [Red Hat AI](https://www.redhat.com/en/products/ai)
- [Red Hat OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift)
- [Red Hat OpenShift AI](https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai)
- [Red Hat OpenShift AI 3.5 documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/)
- [Red Hat OpenShift AI 3.5 MaaS documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/govern_llm_access_with_models-as-a-service/use-models-as-a-service_maas)
- [MaaS code assistant quickstart](https://docs.redhat.com/en/learn/ai-quickstarts/rh-maas-code-assistant)
- [Migration Toolkit for Applications 8.1 documentation](https://docs.redhat.com/en/documentation/migration_toolkit_for_applications/8.1/)
- [Red Hat Developer Hub 1.9 documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.9)
- [Red Hat OpenShift Dev Spaces documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/)
