{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "prometheus.fullname" -}}
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
{{- define "prometheus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "prometheus.labels" -}}
helm.sh/chart: {{ include "prometheus.chart" . }}
{{ include "prometheus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: prometheus
{{- end }}

{{/*
Selector labels
*/}}
{{- define "prometheus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "prometheus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "prometheus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "prometheus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the appropriate resource values based on preset
*/}}
{{- define "prometheus.resources" -}}
{{- if eq .Values.resourcePreset "custom" }}
{{- toYaml .Values.resources }}
{{- else }}
{{- $preset := index .Values.presets .Values.resourcePreset }}
limits:
  cpu: {{ $preset.limits.cpu }}
  memory: {{ $preset.limits.memory }}
requests:
  cpu: {{ $preset.requests.cpu }}
  memory: {{ $preset.requests.memory }}
{{- end }}
{{- end }}

{{/*
Get storage size based on preset
*/}}
{{- define "prometheus.storageSize" -}}
{{- if eq .Values.resourcePreset "custom" }}
{{- .Values.persistence.size }}
{{- else }}
{{- $preset := index .Values.presets .Values.resourcePreset }}
{{- $preset.storage }}
{{- end }}
{{- end }}

{{/*
Get retention time based on preset
*/}}
{{- define "prometheus.retentionTime" -}}
{{- if eq .Values.resourcePreset "custom" }}
{{- .Values.retention.time }}
{{- else }}
{{- $preset := index .Values.presets .Values.resourcePreset }}
{{- default .Values.retention.time $preset.retentionTime }}
{{- end }}
{{- end }}

{{/*
Get retention size based on preset
*/}}
{{- define "prometheus.retentionSize" -}}
{{- if eq .Values.resourcePreset "custom" }}
{{- .Values.retention.size }}
{{- else }}
{{- $preset := index .Values.presets .Values.resourcePreset }}
{{- default .Values.retention.size $preset.retentionSize }}
{{- end }}
{{- end }}

{{/*
Anti-affinity rules for HA
*/}}
{{- define "prometheus.antiAffinity" -}}
{{- if eq .Values.deploymentMode "ha" }}
{{- if eq .Values.highAvailability.antiAffinity "hard" }}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          {{- include "prometheus.selectorLabels" . | nindent 10 }}
      topologyKey: kubernetes.io/hostname
{{- else if eq .Values.highAvailability.antiAffinity "soft" }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            {{- include "prometheus.selectorLabels" . | nindent 12 }}
        topologyKey: kubernetes.io/hostname
{{- end }}
{{- end }}
{{- end }}

{{/*
Prometheus config file name
*/}}
{{- define "prometheus.configName" -}}
{{ include "prometheus.fullname" . }}-config
{{- end }}

{{/*
Prometheus rules configmap name
*/}}
{{- define "prometheus.rulesName" -}}
{{ include "prometheus.fullname" . }}-rules
{{- end }}
