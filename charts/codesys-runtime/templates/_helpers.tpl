{{/*
Expand the name of the chart.
*/}}
{{- define "codesys-runtime.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "codesys-runtime.fullname" -}}
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
{{- define "codesys-runtime.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codesys-runtime.labels" -}}
helm.sh/chart: {{ include "codesys-runtime.chart" . }}
{{ include "codesys-runtime.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: fireball-podstore
app.kubernetes.io/created-by: patrick-ryan
fireball.io/category: industrial-automation
{{- end }}

{{/*
Selector labels for runtime
*/}}
{{- define "codesys-runtime.selectorLabels" -}}
app.kubernetes.io/name: {{ include "codesys-runtime.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Runtime specific labels
*/}}
{{- define "codesys-runtime.runtime.labels" -}}
{{ include "codesys-runtime.labels" . }}
app.kubernetes.io/component: plc-runtime
{{- end }}

{{/*
Runtime selector labels
*/}}
{{- define "codesys-runtime.runtime.selectorLabels" -}}
{{ include "codesys-runtime.selectorLabels" . }}
app.kubernetes.io/component: plc-runtime
{{- end }}

{{/*
WebVisu specific labels
*/}}
{{- define "codesys-runtime.webvisu.labels" -}}
{{ include "codesys-runtime.labels" . }}
app.kubernetes.io/component: webvisu
{{- end }}

{{/*
WebVisu selector labels
*/}}
{{- define "codesys-runtime.webvisu.selectorLabels" -}}
{{ include "codesys-runtime.selectorLabels" . }}
app.kubernetes.io/component: webvisu
{{- end }}

{{/*
Create the name of the runtime service account
*/}}
{{- define "codesys-runtime.runtime.serviceAccountName" -}}
{{- if .Values.runtime.serviceAccount.create }}
{{- default (printf "%s-runtime" (include "codesys-runtime.fullname" .)) .Values.runtime.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.runtime.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the webvisu service account
*/}}
{{- define "codesys-runtime.webvisu.serviceAccountName" -}}
{{- if .Values.webvisu.serviceAccount.create }}
{{- default (printf "%s-webvisu" (include "codesys-runtime.fullname" .)) .Values.webvisu.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.webvisu.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "codesys-runtime.namespace" -}}
{{- if .Values.namespace.create }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Determine runtime resources based on preset
*/}}
{{- define "codesys-runtime.runtime.resources" -}}
{{- if eq .Values.runtime.resources.preset "custom" }}
requests:
  cpu: {{ .Values.runtime.resources.custom.requests.cpu }}
  memory: {{ .Values.runtime.resources.custom.requests.memory }}
limits:
  cpu: {{ .Values.runtime.resources.custom.limits.cpu }}
  memory: {{ .Values.runtime.resources.custom.limits.memory }}
{{- else if eq .Values.runtime.resources.preset "small" }}
requests:
  cpu: {{ .Values.runtime.resources.presets.small.requests.cpu }}
  memory: {{ .Values.runtime.resources.presets.small.requests.memory }}
limits:
  cpu: {{ .Values.runtime.resources.presets.small.limits.cpu }}
  memory: {{ .Values.runtime.resources.presets.small.limits.memory }}
{{- else if eq .Values.runtime.resources.preset "large" }}
requests:
  cpu: {{ .Values.runtime.resources.presets.large.requests.cpu }}
  memory: {{ .Values.runtime.resources.presets.large.requests.memory }}
limits:
  cpu: {{ .Values.runtime.resources.presets.large.limits.cpu }}
  memory: {{ .Values.runtime.resources.presets.large.limits.memory }}
{{- else }}
requests:
  cpu: {{ .Values.runtime.resources.presets.medium.requests.cpu }}
  memory: {{ .Values.runtime.resources.presets.medium.requests.memory }}
limits:
  cpu: {{ .Values.runtime.resources.presets.medium.limits.cpu }}
  memory: {{ .Values.runtime.resources.presets.medium.limits.memory }}
{{- end }}
{{- end }}

{{/*
Determine webvisu resources based on preset
*/}}
{{- define "codesys-runtime.webvisu.resources" -}}
{{- if eq .Values.webvisu.resources.preset "custom" }}
requests:
  cpu: {{ .Values.webvisu.resources.custom.requests.cpu }}
  memory: {{ .Values.webvisu.resources.custom.requests.memory }}
limits:
  cpu: {{ .Values.webvisu.resources.custom.limits.cpu }}
  memory: {{ .Values.webvisu.resources.custom.limits.memory }}
{{- else if eq .Values.webvisu.resources.preset "small" }}
requests:
  cpu: {{ .Values.webvisu.resources.presets.small.requests.cpu }}
  memory: {{ .Values.webvisu.resources.presets.small.requests.memory }}
limits:
  cpu: {{ .Values.webvisu.resources.presets.small.limits.cpu }}
  memory: {{ .Values.webvisu.resources.presets.small.limits.memory }}
{{- else if eq .Values.webvisu.resources.preset "large" }}
requests:
  cpu: {{ .Values.webvisu.resources.presets.large.requests.cpu }}
  memory: {{ .Values.webvisu.resources.presets.large.requests.memory }}
limits:
  cpu: {{ .Values.webvisu.resources.presets.large.limits.cpu }}
  memory: {{ .Values.webvisu.resources.presets.large.limits.memory }}
{{- else }}
requests:
  cpu: {{ .Values.webvisu.resources.presets.medium.requests.cpu }}
  memory: {{ .Values.webvisu.resources.presets.medium.requests.memory }}
limits:
  cpu: {{ .Values.webvisu.resources.presets.medium.limits.cpu }}
  memory: {{ .Values.webvisu.resources.presets.medium.limits.memory }}
{{- end }}
{{- end }}

{{/*
PVC name for runtime
*/}}
{{- define "codesys-runtime.runtime.pvcName" -}}
{{- printf "%s-runtime-storage" (include "codesys-runtime.fullname" .) }}
{{- end }}
