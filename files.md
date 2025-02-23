argocd/applications/apps.yaml

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: demo-project
  source:
    repoURL: https://github.com/your-repo/your-project.git
    targetRevision: HEAD
    path: argocd/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true

---
```

argocd/apps/Chart.yaml

```
apiVersion: v2
name: apps
description: Application definitions for ArgoCD
version: 0.1.0
type: application

---
```

argocd/apps/values.yaml

```
spec:
  source:
    repoURL: https://github.com/your-repo/your-project.git
    targetRevision: HEAD
environment: dev
monitoring:
  enabled: true
  namespace: monitoring
api:
  enabled: true
  namespace: demo
  replicas: 2
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"

---
```

argocd/apps/templates/api.yaml

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: api
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: demo-project
  source:
    repoURL: {{ .Values.spec.source.repoURL }}
    targetRevision: {{ .Values.spec.source.targetRevision }}
    path: k8s/overlays/{{ .Values.environment }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ .Values.api.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true

---
```

argocd/apps/templates/monitoring.yaml

```
{{- if .Values.monitoring.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: demo-project
  source:
    repoURL: {{ .Values.spec.source.repoURL }}
    targetRevision: {{ .Values.spec.source.targetRevision }}
    path: monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ .Values.monitoring.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
{{- end }}

---
```

monitoring/Chart.yaml

```
apiVersion: v2
name: monitoring
description: Monitoring stack for the demo project
version: 0.1.0
dependencies:
- name: prometheus
  version: 25.8.0
  repository: https://prometheus-community.github.io/helm-charts
- name: grafana
  version: 7.0.19
  repository: https://grafana.github.io/helm-charts
- name: loki
  version: 5.38.0
  repository: https://grafana.github.io/helm-charts
- name: promtail
  version: 6.15.3
  repository: https://grafana.github.io/helm-charts

---
```

monitoring/values.yaml

```
prometheus:
  server:
    persistentVolume:
      size: 10Gi
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
  alertmanager:
    persistentVolume:
      size: 5Gi
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"

grafana:
  persistence:
    enabled: true
    size: 5Gi
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-server.monitoring.svc.cluster.local
        access: proxy
        isDefault: true
      - name: Loki
        type: loki
        url: http://loki.monitoring.svc.cluster.local:3100
        access: proxy
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

loki:
  persistence:
    enabled: true
    size: 10Gi
  resources:
    requests:
      cpu: "200m"
      memory: "256Mi"
    limits:
      cpu: "400m"
      memory: "512Mi"

promtail:
  config:
    lokiAddress: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"

---
```

monitoring/templates/NOTES.txt

```
Thank you for installing {{ .Chart.Name }}.

Your release is named {{ .Release.Name }}.

To get the Grafana admin password run:

    kubectl get secret --namespace {{ .Release.Namespace }} grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

To access Grafana UI:

    kubectl port-forward svc/grafana -n {{ .Release.Namespace }} 3000:80

Then visit http://localhost:3000

To access Prometheus UI:

    kubectl port-forward svc/prometheus-server -n {{ .Release.Namespace }} 9090:80

Then visit http://localhost:9090
```
