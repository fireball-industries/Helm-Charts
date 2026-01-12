{{/*
Expand the name of the chart.
*/}}
{{- define "microvm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "microvm.fullname" -}}
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
{{- define "microvm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "microvm.labels" -}}
helm.sh/chart: {{ include "microvm.chart" . }}
{{ include "microvm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.vm.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "microvm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microvm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
kubevirt.io/vm: {{ .Values.global.vmName }}
{{- end }}

{{/*
VM resource requirements based on preset
*/}}
{{- define "microvm.resources" -}}
{{- if eq .Values.vm.resourcePreset "custom" }}
cpu: {{ .Values.vm.resources.cpu }}
memory: {{ .Values.vm.resources.memory }}
{{- else }}
{{- $preset := index .Values.presets .Values.vm.resourcePreset }}
cpu: {{ $preset.cpu }}
memory: {{ $preset.memory }}
{{- end }}
{{- end }}

{{/*
Cloud-init user data
*/}}
{{- define "microvm.cloudInitUserData" -}}
{{- if .Values.cloudInit.useBase64 }}
{{- .Values.cloudInit.userDataBase64 }}
{{- else }}
{{- .Values.cloudInit.userData | b64enc }}
{{- end }}
{{- end }}
