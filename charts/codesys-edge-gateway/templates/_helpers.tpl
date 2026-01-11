{{/*
Expand the name of the chart.
*/}}
{{- define "codesys-edge-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "codesys-edge-gateway.fullname" -}}
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
{{- define "codesys-edge-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codesys-edge-gateway.labels" -}}
helm.sh/chart: {{ include "codesys-edge-gateway.chart" . }}
{{ include "codesys-edge-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "codesys-edge-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "codesys-edge-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "codesys-edge-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "codesys-edge-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image name with tag
*/}}
{{- define "codesys-edge-gateway.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s-%s" .Values.image.repository $tag .Values.image.architecture }}
{{- end }}

{{/*
Get the secret name for Automation Server credentials
*/}}
{{- define "codesys-edge-gateway.secretName" -}}
{{- if .Values.gateway.automationServer.existingSecret }}
{{- .Values.gateway.automationServer.existingSecret }}
{{- else }}
{{- include "codesys-edge-gateway.fullname" . }}-auth
{{- end }}
{{- end }}

{{/*
Get the PVC name
*/}}
{{- define "codesys-edge-gateway.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- include "codesys-edge-gateway.fullname" . }}-data
{{- end }}
{{- end }}

{{/*
Get the ConfigMap name
*/}}
{{- define "codesys-edge-gateway.configMapName" -}}
{{- include "codesys-edge-gateway.fullname" . }}-config
{{- end }}
