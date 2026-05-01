# Isaac Sim Browser Streaming on OpenShift

> [!NOTE]
> This project was developed with assistance from AI tools.

Stream NVIDIA Isaac Sim 6.0 to a web browser from an OpenShift cluster with GPU nodes.

## Architecture

Isaac Sim runs headless on a GPU node with WebRTC streaming enabled. A coturn TURN
relay bridges WebRTC media (UDP) through OpenShift's HTTP-only Routes. A lightweight
web client handles the browser-side WebRTC connection.

```
Browser (local machine)
  ├── HTTPS ──→ Edge Route ──────→ web-client (nginx)
  ├── WSS ────→ Edge Route ──────→ Isaac Sim (signaling)
  └── TURNS ──→ Passthrough Route → coturn (media relay)
                                       ↓ UDP (cluster-internal)
                                    Isaac Sim pod
```

## Prerequisites

- OpenShift cluster with an NVIDIA L40S (or compatible) GPU node
- NVIDIA GPU Operator installed (provides device plugin, NFD labels, runtime class)
- cert-manager with a `ClusterIssuer` (e.g., `letsencrypt`) for the coturn TLS certificate
- `oc` CLI authenticated with cluster-admin
- `helm` v3
- `podman` (for building the web client image)
- An [NGC API key](https://ngc.nvidia.com/setup) for pulling Isaac Sim container images
- A container registry (e.g., `quay.io`) for the web client image

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with your NGC API key, cluster domain, and registry

# 2. Build and push the web client
make build-client
make push-client

# 3. Verify GPU node is available
make gpu-info

# 4. Deploy
make deploy

# 5. Wait for Isaac Sim to start (5-10 min cold start)
make status

# 6. Open in browser
make open
```

## Makefile Targets

| Target | Description |
|---|---|
| `deploy` | Install Helm chart to OpenShift |
| `undeploy` | Uninstall Helm chart |
| `status` | Show pods, services, and routes |
| `logs` | Tail Isaac Sim pod logs |
| `url` | Print the web client URL |
| `build-client` | Build web client container image |
| `push-client` | Push web client image to registry |
| `gpu-info` | Show GPU node labels and taints |
| `open` | Open web client URL in browser |
| `restart` | Restart Isaac Sim pod |

## Configuration

All configuration is in `.env` (see `.env.example`). Key values:

| Variable | Description |
|---|---|
| `NAMESPACE` | OpenShift namespace for the deployment |
| `CLUSTER_DOMAIN` | Cluster apps domain (e.g., `apps.mycluster.example.com`) |
| `NGC_API_KEY` | NGC API key for pulling `nvcr.io` images |
| `CLIENT_IMAGE` | Full image reference for the web client |
| `COTURN_PASSWORD` | Password for the TURN relay (auto-generated if empty) |
| `GPU_PRODUCT` | GPU product label (default: `NVIDIA-L40S`) |
| `CERT_ISSUER` | cert-manager ClusterIssuer name (default: `letsencrypt`) |
