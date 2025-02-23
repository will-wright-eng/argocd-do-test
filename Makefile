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

argoinstall: ## [k8s] install ArgoCD in the cluster
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD pods to be ready..."
	kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s
	@echo "\nArgoCD admin password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argopass: ## [k8s] get ArgoCD admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argopf: argopass ## [k8s] access ArgoCD UI at http://localhost:8080
	@echo "Access ArgoCD UI at http://localhost:8080 (username admin)"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argoapply: ## [k8s] apply ArgoCD configuration
	kubectl apply -f argocd/projects/demo-project.yaml
	kubectl apply -f argocd/applications/api-app.yaml

deletepods: ## [k8s] delete all pods
	kubectl delete pods --all -n demo

#* Other
open: ## [other] open DO cluster in browser
	open https://cloud.digitalocean.com/kubernetes/clusters

registry-login: ## [do registry] login to DO container registry
	@bash scripts/registry-login.sh

registry-auth: ## [do registry] configure registry authentication
	@bash scripts/registry-auth.sh

cleanup: ## [k8s] remove generated files and terraform artifacts
	@echo "${GREEN}Cleaning up generated files...${NC}"
	rm -f tofu/tfplan
	rm -rf tofu/.terraform
	rm -f tofu/.terraform.lock.hcl
	@echo "${GREEN}Cleaning up Python artifacts...${NC}"
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	@echo "${GREEN}Cleanup complete${NC}"

#* ArgoCD management
ENVIRONMENT ?= dev

argo-init: ## [argocd] initialize ArgoCD applications
	@echo "Initializing ArgoCD applications..."
	kubectl apply -f argocd/applications/apps.yaml

argo-sync: ## [argocd] sync ArgoCD applications
	@echo "Syncing ArgoCD applications..."
	argocd app sync apps
	argocd app sync monitoring
	argocd app sync api

argo-status: ## [argocd] get ArgoCD applications status
	@echo "ArgoCD Applications Status:"
	kubectl get applications -n argocd
	@echo "\nPods Status:"
	kubectl get pods -n argocd

monitoring-init: ## [argocd] initialize monitoring stack
	@echo "Initializing monitoring stack..."
	cd monitoring && helm dependency update
	cd monitoring && helm dependency build

monitoring-status: ## [argocd] get monitoring stack status
	@echo "Monitoring Stack Status:"
	kubectl get pods -n monitoring
	@echo "\nServices:"
	kubectl get svc -n monitoring

monitoring-password: ## [argocd] get monitoring stack admin password
	@echo "Grafana admin password:"
	kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

grafana-ui: ## [argocd] port forward Grafana UI to http://localhost:3000
	@echo "Port forwarding Grafana UI to http://localhost:3000"
	kubectl port-forward svc/grafana -n monitoring 3000:80

prometheus-ui: ## [argocd] port forward Prometheus UI to http://localhost:9090
	@echo "Port forwarding Prometheus UI to http://localhost:9090"
	kubectl port-forward svc/prometheus-server -n monitoring 9090:80

clean: ## [argocd] remove ArgoCD applications and monitoring stack
	@echo "Cleaning up..."
	kubectl delete -f argocd/applications/apps.yaml || true
	kubectl delete namespace monitoring || true

#* Phase 1: Infrastructure Setup
infra-init: ## Initialize infrastructure
	@echo "${GREEN}Initializing infrastructure...${NC}"
	make init
	make apply
	make verify
	make registry-auth

#* Phase 2: Container Registry and Image
registry-setup: ## Setup registry and build/push image
	@echo "${GREEN}Setting up container registry and building image...${NC}"
	make registry-login
	make docker-build
	make docker-push

#* Phase 3: ArgoCD Installation
argocd-setup: ## Install and configure ArgoCD
	@echo "${GREEN}Setting up ArgoCD...${NC}"
	make argoinstall
	@echo "ArgoCD admin credentials:"
	make argopass
	make argoapply

#* Phase 4: Application Deployment
app-deploy: ## Deploy application via ArgoCD
	@echo "${GREEN}Deploying application...${NC}"
	make argo-init
	make argo-sync
	@echo "Waiting for applications to sync..."
	sleep 30
	make argo-status

#* Phase 5: Monitoring Setup
monitoring-setup: ## Setup monitoring stack
	@echo "${GREEN}Setting up monitoring stack...${NC}"
	make monitoring-init
	@echo "Waiting for monitoring stack to be ready..."
	sleep 30
	make monitoring-status
	@echo "Grafana admin credentials:"
	make monitoring-password

#* Complete Setup
full-setup: ## Complete setup from scratch
	@echo "${GREEN}Starting complete setup...${NC}"
	make infra-init
	make registry-setup
	make argocd-setup
	make app-deploy
	make monitoring-setup
	@echo "${GREEN}Setup complete! Access points:${NC}"
	@echo "ArgoCD UI: make argopf (http://localhost:8080)"
	@echo "Grafana: make grafana-ui (http://localhost:3000)"
	@echo "Prometheus: make prometheus-ui (http://localhost:9090)"

#* Cleanup and Teardown
full-cleanup: ## Complete cleanup of all resources
	@echo "${RED}Starting complete cleanup...${NC}"
	make clean
	make destroy
	make cleanup
	@echo "${GREEN}Cleanup complete${NC}"
