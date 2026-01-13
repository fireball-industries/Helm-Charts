{{/*
Expand the name of the chart.
*/}}
{{- define "influxdb-pod.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "influxdb-pod.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "influxdb-pod.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "influxdb-pod.labels" -}}
helm.sh/chart: {{ include "influxdb-pod.chart" . }}
{{ include "influxdb-pod.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: fireball-industries
{{- end }}

{{/*
Selector labels
*/}}
{{- define "influxdb-pod.selectorLabels" -}}
app.kubernetes.io/name: {{ include "influxdb-pod.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "influxdb-pod.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "influxdb-pod.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
InfluxDB image
*/}}
{{- define "influxdb-pod.image" -}}
{{- printf "%s:%s" .Values.influxdb.image.repository .Values.influxdb.image.tag }}
{{- end }}

{{/*
Generate admin token
*/}}
{{- define "influxdb-pod.adminToken" -}}
{{- if .Values.influxdb.adminToken }}
{{- .Values.influxdb.adminToken }}
{{- else }}
{{- randAlphaNum 64 }}
{{- end }}
{{- end }}

{{/*
Generate admin password
*/}}
{{- define "influxdb-pod.adminPassword" -}}
{{- if .Values.influxdb.adminPassword }}
{{- .Values.influxdb.adminPassword }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}

{{/*
Resource preset configuration
*/}}
{{- define "influxdb-pod.resources" -}}
{{- if eq .Values.resourcePreset "edge" }}
limits:
  cpu: "500m"
  memory: "256Mi"
requests:
  cpu: "250m"
  memory: "256Mi"
{{- else if eq .Values.resourcePreset "small" }}
limits:
  cpu: "1"
  memory: "512Mi"
requests:
  cpu: "500m"
  memory: "512Mi"
{{- else if eq .Values.resourcePreset "medium" }}
limits:
  cpu: "2"
  memory: "2Gi"
requests:
  cpu: "1"
  memory: "2Gi"
{{- else if eq .Values.resourcePreset "large" }}
limits:
  cpu: "4"
  memory: "8Gi"
requests:
  cpu: "2"
  memory: "8Gi"
{{- else if eq .Values.resourcePreset "xlarge" }}
limits:
  cpu: "8"
  memory: "16Gi"
requests:
  cpu: "4"
  memory: "16Gi"
{{- else }}
{{- toYaml .Values.resources }}
{{- end }}
{{- end }}

{{/*
Storage size based on preset
*/}}
{{- define "influxdb-pod.storageSize" -}}
{{- if eq .Values.resourcePreset "edge" }}
5Gi
{{- else if eq .Values.resourcePreset "small" }}
10Gi
{{- else if eq .Values.resourcePreset "medium" }}
50Gi
{{- else if eq .Values.resourcePreset "large" }}
200Gi
{{- else if eq .Values.resourcePreset "xlarge" }}
500Gi
{{- else }}
{{- .Values.persistence.size }}
{{- end }}
{{- end }}

{{/*
InfluxDB URL
*/}}
{{- define "influxdb-pod.url" -}}
{{- if .Values.ingress.enabled }}
{{- $host := index .Values.ingress.hosts 0 }}
{{- if .Values.ingress.tls }}
https://{{ $host.host }}
{{- else }}
http://{{ $host.host }}
{{- end }}
{{- else }}
http://{{ include "influxdb-pod.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.port }}
{{- end }}
{{- end }}

{{/*
Pod security context
*/}}
{{- define "influxdb-pod.securityContext" -}}
runAsNonRoot: {{ .Values.security.runAsNonRoot }}
runAsUser: {{ .Values.security.runAsUser }}
runAsGroup: {{ .Values.security.runAsGroup }}
fsGroup: {{ .Values.security.fsGroup }}
{{- if eq .Values.security.podSecurityStandard "restricted" }}
seccompProfile:
  type: RuntimeDefault
{{- end }}
{{- end }}

{{/*
Container security context
*/}}
{{- define "influxdb-pod.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: {{ .Values.security.readOnlyRootFilesystem }}
capabilities:
  drop:
  {{- range .Values.security.capabilities.drop }}
  - {{ . }}
  {{- end }}
{{- if eq .Values.security.podSecurityStandard "restricted" }}
seccompProfile:
  type: RuntimeDefault
{{- end }}
{{- end }}

{{/*
Anti-affinity rules for HA
*/}}
{{- define "influxdb-pod.affinity" -}}
{{- if and (eq .Values.deploymentMode "ha") .Values.highAvailability.antiAffinity }}
podAntiAffinity:
  {{- if eq .Values.highAvailability.antiAffinity "hard" }}
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app.kubernetes.io/name
        operator: In
        values:
        - {{ include "influxdb-pod.name" . }}
      - key: app.kubernetes.io/instance
        operator: In
        values:
        - {{ .Release.Name }}
    topologyKey: kubernetes.io/hostname
  {{- else }}
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - {{ include "influxdb-pod.name" . }}
        - key: app.kubernetes.io/instance
          operator: In
          values:
          - {{ .Release.Name }}
      topologyKey: kubernetes.io/hostname
  {{- end }}
{{- end }}
{{- if .Values.affinity }}
{{- toYaml .Values.affinity }}
{{- end }}
{{- end }}
