# Variables
ENV ?= dev
DOCKER_TAG ?= latest
REPO_ROOT := $(shell git rev-parse --show-toplevel)

# Colors for terminal output
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

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

cleanup: ## [k8s] remove generated files and terraform artifacts
	@echo "${GREEN}Cleaning up generated files...${NC}"
	rm -f tofu/tfplan
	rm -rf tofu/.terraform
	rm -f tofu/terraform.tfstate
	rm -f tofu/terraform.tfstate.backup
	rm -f tofu/.terraform.lock.hcl
	@echo "${GREEN}Cleanup complete${NC}"
