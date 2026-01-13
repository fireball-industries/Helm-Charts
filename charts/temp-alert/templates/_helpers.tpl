{{/*
Expand the name of the chart.
*/}}
{{- define "alert-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "alert-manager.fullname" -}}
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
{{- define "alert-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "alert-manager.labels" -}}
helm.sh/chart: {{ include "alert-manager.chart" . }}
{{ include "alert-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: fireball-podstore
app.kubernetes.io/created-by: patrick-ryan
{{- end }}

{{/*
Selector labels
*/}}
{{- define "alert-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "alert-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "alert-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "alert-manager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "alert-manager.namespace" -}}
{{- if .Values.namespace.create }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Determine resource limits based on preset
*/}}
{{- define "alert-manager.resources" -}}
{{- if eq .Values.resources.preset "custom" }}
requests:
  cpu: {{ .Values.resources.custom.requests.cpu }}
  memory: {{ .Values.resources.custom.requests.memory }}
limits:
  cpu: {{ .Values.resources.custom.limits.cpu }}
  memory: {{ .Values.resources.custom.limits.memory }}
{{- else if eq .Values.resources.preset "small" }}
requests:
  cpu: {{ .Values.resources.presets.small.requests.cpu }}
  memory: {{ .Values.resources.presets.small.requests.memory }}
limits:
  cpu: {{ .Values.resources.presets.small.limits.cpu }}
  memory: {{ .Values.resources.presets.small.limits.memory }}
{{- else if eq .Values.resources.preset "large" }}
requests:
  cpu: {{ .Values.resources.presets.large.requests.cpu }}
  memory: {{ .Values.resources.presets.large.requests.memory }}
limits:
  cpu: {{ .Values.resources.presets.large.limits.cpu }}
  memory: {{ .Values.resources.presets.large.limits.memory }}
{{- else }}
requests:
  cpu: {{ .Values.resources.presets.medium.requests.cpu }}
  memory: {{ .Values.resources.presets.medium.requests.memory }}
limits:
  cpu: {{ .Values.resources.presets.medium.limits.cpu }}
  memory: {{ .Values.resources.presets.medium.limits.memory }}
{{- end }}
{{- end }}

{{/*
Create PVC name
*/}}
{{- define "alert-manager.pvcName" -}}
{{- printf "%s-storage" (include "alert-manager.fullname" .) }}
{{- end }}

{{/*
Create ConfigMap name
*/}}
{{- define "alert-manager.configMapName" -}}
{{- printf "%s-config" (include "alert-manager.fullname" .) }}
{{- end }}
