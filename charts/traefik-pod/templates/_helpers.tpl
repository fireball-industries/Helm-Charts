{{/*
Expand the name of the chart.
*/}}
{{- define "traefik.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "traefik.fullname" -}}
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
{{- define "traefik.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "traefik.labels" -}}
helm.sh/chart: {{ include "traefik.chart" . }}
{{ include "traefik.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "traefik.selectorLabels" -}}
app.kubernetes.io/name: {{ include "traefik.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "traefik.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "traefik.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resource requirements based on preset
*/}}
{{- define "traefik.resources" -}}
{{- if eq .Values.deployment.resourcePreset "custom" }}
{{- toYaml .Values.deployment.resources }}
{{- else }}
{{- $preset := index .Values.presets .Values.deployment.resourcePreset }}
{{- toYaml $preset }}
{{- end }}
{{- end }}

{{/*
Get replica count
*/}}
{{- define "traefik.replicas" -}}
{{- if .Values.ha.enabled }}
{{- .Values.ha.replicas }}
{{- else if eq .Values.deployment.kind "DaemonSet" }}
{{- /* DaemonSet doesn't use replicas */ -}}
{{- else }}
{{- .Values.deployment.replicas }}
{{- end }}
{{- end }}
