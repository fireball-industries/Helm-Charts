{{/*
Expand the name of the chart.
*/}}
{{- define "node-red.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "node-red.fullname" -}}
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
{{- define "node-red.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "node-red.labels" -}}
helm.sh/chart: {{ include "node-red.chart" . }}
{{ include "node-red.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "node-red.selectorLabels" -}}
app.kubernetes.io/name: {{ include "node-red.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: node-red
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "node-red.serviceAccountName" -}}
{{- if .Values.pod.serviceAccount.create }}
{{- default (include "node-red.fullname" .) .Values.pod.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.pod.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "node-red.namespace" -}}
{{- .Values.namespace.name | default .Release.Namespace }}
{{- end }}

{{/*
Get resource requests and limits based on preset
*/}}
{{- define "node-red.resources" -}}
{{- $preset := .Values.nodeRed.resources.preset }}
{{- if eq $preset "custom" }}
{{- toYaml .Values.nodeRed.resources.custom }}
{{- else }}
{{- $presets := .Values.nodeRed.resources.presets }}
{{- if hasKey $presets $preset }}
{{- toYaml (index $presets $preset) }}
{{- else }}
{{- toYaml $presets.medium }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Get admin password (auto-generate if not provided)
*/}}
{{- define "node-red.adminPassword" -}}
{{- if .Values.nodeRed.auth.password }}
{{- .Values.nodeRed.auth.password }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Generate bcrypt password hash for settings.js
Note: This is a placeholder - in real deployment, use pre-hashed password
*/}}
{{- define "node-red.passwordHash" -}}
{{- if .Values.nodeRed.auth.passwordHash }}
{{- .Values.nodeRed.auth.passwordHash }}
{{- else }}
{{- /* Default hash for "fireballs" - CHANGE IN PRODUCTION */ -}}
$2b$08$zZWtXTja0fB1pzD4sHCMyOCMYz2Z6dNbM6tl8sJogENOMcxWV9DN.
{{- end }}
{{- end }}

{{/*
PVC name
*/}}
{{- define "node-red.pvcName" -}}
{{- printf "%s-data" (include "node-red.fullname" .) }}
{{- end }}

{{/*
ConfigMap name for settings
*/}}
{{- define "node-red.settingsConfigMapName" -}}
{{- printf "%s-settings" (include "node-red.fullname" .) }}
{{- end }}

{{/*
Secret name for credentials
*/}}
{{- define "node-red.secretName" -}}
{{- printf "%s-auth" (include "node-red.fullname" .) }}
{{- end }}
