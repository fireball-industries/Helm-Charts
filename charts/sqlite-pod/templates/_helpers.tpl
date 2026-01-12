{{/*
Expand the name of the chart.
*/}}
{{- define "sqlite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "sqlite.fullname" -}}
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
{{- define "sqlite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sqlite.labels" -}}
helm.sh/chart: {{ include "sqlite.chart" . }}
{{ include "sqlite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sqlite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sqlite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sqlite.serviceAccountName" -}}
{{- if .Values.advanced.serviceAccount.create }}
{{- default (include "sqlite.fullname" .) .Values.advanced.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.advanced.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate resource requests and limits
*/}}
{{- define "sqlite.resources" -}}
{{- $preset := .Values.resources.preset -}}
{{- if eq $preset "custom" -}}
{{- toYaml .Values.resources.custom }}
{{- else -}}
{{- $presetConfig := index .Values.resources.presets $preset -}}
{{- toYaml $presetConfig }}
{{- end }}
{{- end }}
