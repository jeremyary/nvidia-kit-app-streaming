# This project was developed with assistance from AI tools.
SHELL := /bin/bash

-include .env

NAMESPACE      ?= isaac-sim-streaming
CLUSTER_DOMAIN ?=
NGC_API_KEY    ?=
CLIENT_IMAGE   ?=
COTURN_PASSWORD := $(or $(COTURN_PASSWORD),$(shell oc get secret coturn-auth -n $(NAMESPACE) -o jsonpath='{.data.password}' 2>/dev/null | base64 -d),$(shell openssl rand -base64 24))
GPU_PRODUCT    ?= NVIDIA-L40S
GPU_RUNTIME_CLASS ?= nvidia
STREAM_WIDTH   ?= 1920
STREAM_HEIGHT  ?= 1080
STREAM_FPS     ?= 30

HELM_RELEASE   := isaac-sim-streaming
HELM_CHART     := helm/isaac-sim-streaming

.PHONY: help deploy undeploy status logs url build-client push-client gpu-info open restart template

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

deploy: ## Install Helm chart to OpenShift
	@if [ -z "$(CLUSTER_DOMAIN)" ]; then echo "ERROR: CLUSTER_DOMAIN is not set. See .env.example"; exit 1; fi
	@if [ -z "$(NGC_API_KEY)" ]; then echo "ERROR: NGC_API_KEY is not set. See .env.example"; exit 1; fi
	@if [ -z "$(CLIENT_IMAGE)" ]; then echo "ERROR: CLIENT_IMAGE is not set. See .env.example"; exit 1; fi
	@oc get namespace $(NAMESPACE) >/dev/null 2>&1 || oc create namespace $(NAMESPACE)
	@if ! oc get secret coturn-tls -n $(NAMESPACE) >/dev/null 2>&1; then \
		echo "Copying cluster wildcard cert to $(NAMESPACE)/coturn-tls..."; \
		src=$$(oc get secret -n openshift-ingress -l hive.openshift.io/managed=true \
			-o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
		if [ -z "$$src" ]; then echo "ERROR: Could not find managed wildcard cert in openshift-ingress"; exit 1; fi; \
		oc get secret "$$src" -n openshift-ingress -o json \
			| jq 'del(.metadata.namespace,.metadata.uid,.metadata.resourceVersion,.metadata.creationTimestamp,.metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"]) | .metadata.name = "coturn-tls"' \
			| oc apply -n $(NAMESPACE) -f -; \
	fi
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--set namespace=$(NAMESPACE) \
		--set clusterDomain=$(CLUSTER_DOMAIN) \
		--set ngc.apiKey=$(NGC_API_KEY) \
		--set client.image.repository=$(shell echo $(CLIENT_IMAGE) | rev | cut -d: -f2- | rev) \
		--set client.image.tag=$(shell echo $(CLIENT_IMAGE) | rev | cut -d: -f1 | rev) \
		--set coturn.password=$(COTURN_PASSWORD) \
		--set isaacSim.gpu.product=$(GPU_PRODUCT) \
		--set isaacSim.gpu.runtimeClassName=$(GPU_RUNTIME_CLASS) \
		--set stream.width=$(STREAM_WIDTH) \
		--set stream.height=$(STREAM_HEIGHT) \
		--set stream.fps=$(STREAM_FPS)

undeploy: ## Uninstall Helm chart
	helm uninstall $(HELM_RELEASE) 2>/dev/null || true
	@echo "NOTE: Namespace $(NAMESPACE) and PVCs are retained. Delete manually if needed."

status: ## Show pods, services, and routes
	@echo "=== Pods ==="
	@oc get pods -n $(NAMESPACE) -o wide 2>/dev/null || echo "(namespace not found)"
	@echo ""
	@echo "=== Services ==="
	@oc get svc -n $(NAMESPACE) 2>/dev/null || true
	@echo ""
	@echo "=== Routes ==="
	@oc get routes -n $(NAMESPACE) 2>/dev/null || true

logs: ## Tail Isaac Sim pod logs
	oc logs -f deploy/isaac-sim -n $(NAMESPACE)

url: ## Print the web client URL
	@echo "https://$(shell oc get route client -n $(NAMESPACE) -o jsonpath='{.spec.host}' 2>/dev/null || echo 'ROUTE_NOT_FOUND')"

build-client: ## Build web client container image
	@if [ -z "$(CLIENT_IMAGE)" ]; then echo "ERROR: CLIENT_IMAGE is not set."; exit 1; fi
	podman build -f client/Containerfile -t $(CLIENT_IMAGE) .

push-client: ## Push web client image to registry
	@if [ -z "$(CLIENT_IMAGE)" ]; then echo "ERROR: CLIENT_IMAGE is not set."; exit 1; fi
	podman push $(CLIENT_IMAGE)

gpu-info: ## Show GPU node labels and taints
	@echo "=== GPU Nodes ==="
	@oc get nodes -l nvidia.com/gpu.product -o custom-columns=\
	'NAME:.metadata.name,GPU:.metadata.labels.nvidia\.com/gpu\.product,MEMORY:.metadata.labels.nvidia\.com/gpu\.memory,TAINTS:.spec.taints[*].key' \
	2>/dev/null || echo "No GPU nodes found. Is the GPU Operator installed?"

open: ## Open web client URL in browser
	@xdg-open "$$($(MAKE) -s url)" 2>/dev/null || open "$$($(MAKE) -s url)" 2>/dev/null || echo "Open this URL: $$($(MAKE) -s url)"

restart: ## Restart Isaac Sim pod
	oc rollout restart deploy/isaac-sim -n $(NAMESPACE)

template: ## Render Helm templates (dry-run)
	helm template $(HELM_RELEASE) $(HELM_CHART) \
		--set namespace=$(NAMESPACE) \
		--set clusterDomain=$${CLUSTER_DOMAIN:-apps.example.com} \
		--set ngc.apiKey=test-key \
		--set client.image.repository=quay.io/test/client \
		--set client.image.tag=latest \
		--set coturn.password=test-password \
		--set isaacSim.gpu.product=$(GPU_PRODUCT) \
		--set isaacSim.gpu.runtimeClassName=$(GPU_RUNTIME_CLASS)
