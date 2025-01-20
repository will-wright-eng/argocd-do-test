# Variables
ENV ?= dev
DOCKER_TAG ?= latest
REPO_ROOT := $(shell git rev-parse --show-toplevel)

# Colors for terminal output
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

# Registry configuration
REGISTRY := registry.digitalocean.com
REGISTRY_NAME := $(shell cd tofu && tofu output -raw registry_name 2>/dev/null || echo "demo-registry")
IMAGE_NAME ?= demo-api
IMAGE_TAG ?= latest
FULL_IMAGE_NAME := $(REGISTRY)/$(REGISTRY_NAME)/$(IMAGE_NAME):$(IMAGE_TAG)

# Local development settings
API_PORT ?= 8080
LOCAL_IMAGE_NAME := demo-api-local

#* Setup
.PHONY: $(shell sed -n -e '/^$$/ { n ; /^[^ .\#][^ ]*:/ { s/:.*$$// ; p ; } ; }' $(MAKEFILE_LIST))
.DEFAULT_GOAL := help

help: ## list make commands
	@echo ${MAKEFILE_LIST}
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Infrastructure commands
init: ## [tofu] initialize terraform
	@bash scripts/init.sh

apply: ## [tofu] apply terraform
	@bash scripts/apply.sh

destroy: ## [tofu] destroy terraform
	@bash scripts/destroy.sh

#* Docker commands
docker-build: ## [docker] build docker image
	@echo "Building image: $(FULL_IMAGE_NAME)"
	docker build -t $(FULL_IMAGE_NAME) api/

docker-push: registry-login docker-build ## [docker] push docker image
	@echo "Pushing image: $(FULL_IMAGE_NAME)"
	docker push $(FULL_IMAGE_NAME)

# Local API testing commands
local: ## [docker] test api locally
	docker compose -f docker-compose.yml up --build --remove-orphans

kill: ## [docker] kill local docker image
	docker compose -f docker-compose.yml down

health:
	curl -s http://localhost:$(API_PORT)/health | jq || echo "Failed to connect to API"

#* Kubernetes commands
verify: ## [k8s] verify cluster
	@bash scripts/verify-cluster.sh

cluster-info: ## [k8s] get cluster info
	@echo "Cluster Info:"
	@kubectl cluster-info
	@echo "\nNode Status:"
	@kubectl get nodes
	@echo "\nSystem Pods:"
	@kubectl get pods -n kube-system

argo-install: ## [k8s] install ArgoCD in the cluster
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD pods to be ready..."
	kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s
	@echo "\nArgoCD admin password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argo-pass: ## [k8s] get ArgoCD admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argo-pf: ## [k8s] access ArgoCD UI at http://localhost:8080
	@echo "Access ArgoCD UI at http://localhost:8080"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argo-apply: ## [k8s] apply ArgoCD configuration
	kubectl apply -f argocd/projects/demo-project.yaml
	kubectl apply -f argocd/applications/api-app.yaml

delete-pods: ## [k8s] delete all pods
	kubectl delete pods --all -n demo

#* Other
registry-login: ## [do registry] login to DO container registry
	@bash scripts/registry-login.sh

registry-auth: ## [do registry] configure registry authentication
	@bash scripts/registry-auth.sh

cleanup: ## [k8s] remove generated files and terraform artifacts
	@echo "${GREEN}Cleaning up generated files...${NC}"
	rm -f tofu/tfplan
	rm -rf tofu/.terraform
	rm -f tofu/terraform.tfstate
	rm -f tofu/terraform.tfstate.backup
	rm -f tofu/.terraform.lock.hcl
	@echo "${GREEN}Cleanup complete${NC}"
