{{/*
============================================================================
Helm Template Helpers
============================================================================
Fireball Industries - Patrick Ryan
"Making Kubernetes YAML slightly less painful since 2024"

These helper templates generate consistent names, labels, and selectors
across all Kubernetes resources in this chart.
============================================================================
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "home-assistant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "home-assistant.fullname" -}}
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
{{- define "home-assistant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "home-assistant.labels" -}}
helm.sh/chart: {{ include "home-assistant.chart" . }}
{{ include "home-assistant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: home-assistant
{{- end }}

{{/*
Selector labels
*/}}
{{- define "home-assistant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "home-assistant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "home-assistant.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "home-assistant.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
============================================================================
PostgreSQL Helper Templates
============================================================================
*/}}

{{/*
PostgreSQL fullname
*/}}
{{- define "home-assistant.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "home-assistant.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PostgreSQL service name
*/}}
{{- define "home-assistant.postgresql.serviceName" -}}
{{- printf "%s-postgresql" (include "home-assistant.fullname" .) }}
{{- end }}

{{/*
PostgreSQL secret name
*/}}
{{- define "home-assistant.postgresql.secretName" -}}
{{- if .Values.database.postgresql.auth.existingSecret }}
{{- .Values.database.postgresql.auth.existingSecret }}
{{- else }}
{{- printf "%s-postgresql" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Database connection URL for Home Assistant
Returns the appropriate database URL based on the database type
*/}}
{{- define "home-assistant.databaseUrl" -}}
{{- if eq .Values.database.type "postgresql" }}
{{- printf "postgresql://%s:%s@%s:5432/%s" .Values.database.postgresql.auth.username .Values.database.postgresql.auth.password (include "home-assistant.postgresql.serviceName" .) .Values.database.postgresql.auth.database }}
{{- else if eq .Values.database.type "external" }}
{{- if eq .Values.database.external.dbType "postgresql" }}
{{- printf "postgresql://%s:$(DB_PASSWORD)@%s:%d/%s" .Values.database.external.username .Values.database.external.host (.Values.database.external.port | int) .Values.database.external.database }}
{{- else if eq .Values.database.external.dbType "mysql" }}
{{- printf "mysql://%s:$(DB_PASSWORD)@%s:%d/%s" .Values.database.external.username .Values.database.external.host (.Values.database.external.port | int) .Values.database.external.database }}
{{- else if eq .Values.database.external.dbType "mariadb" }}
{{- printf "mysql://%s:$(DB_PASSWORD)@%s:%d/%s" .Values.database.external.username .Values.database.external.host (.Values.database.external.port | int) .Values.database.external.database }}
{{- end }}
{{- end }}
{{- end }}

{{/*
============================================================================
Add-on Helper Templates
============================================================================
*/}}

{{/*
MQTT service name
*/}}
{{- define "home-assistant.mqtt.serviceName" -}}
{{- if eq .Values.mqtt.deployment "sidecar" }}
{{- printf "localhost" }}
{{- else }}
{{- printf "%s-mqtt" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
MQTT secret name
*/}}
{{- define "home-assistant.mqtt.secretName" -}}
{{- if .Values.mqtt.config.existingSecret }}
{{- .Values.mqtt.config.existingSecret }}
{{- else }}
{{- printf "%s-mqtt" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Node-RED service name
*/}}
{{- define "home-assistant.nodered.serviceName" -}}
{{- if eq .Values.nodered.deployment "sidecar" }}
{{- printf "localhost" }}
{{- else }}
{{- printf "%s-nodered" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
ESPHome service name
*/}}
{{- define "home-assistant.esphome.serviceName" -}}
{{- if eq .Values.esphome.deployment "sidecar" }}
{{- printf "localhost" }}
{{- else }}
{{- printf "%s-esphome" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Zigbee2MQTT service name
*/}}
{{- define "home-assistant.zigbee2mqtt.serviceName" -}}
{{- if eq .Values.zigbee2mqtt.deployment "sidecar" }}
{{- printf "localhost" }}
{{- else }}
{{- printf "%s-zigbee2mqtt" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
============================================================================
PVC Helper Templates
============================================================================
*/}}

{{/*
Config PVC name
*/}}
{{- define "home-assistant.pvc.config" -}}
{{- if .Values.persistence.config.existingClaim }}
{{- .Values.persistence.config.existingClaim }}
{{- else }}
{{- printf "%s-config" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Media PVC name
*/}}
{{- define "home-assistant.pvc.media" -}}
{{- if .Values.persistence.media.existingClaim }}
{{- .Values.persistence.media.existingClaim }}
{{- else }}
{{- printf "%s-media" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Share PVC name
*/}}
{{- define "home-assistant.pvc.share" -}}
{{- if .Values.persistence.share.existingClaim }}
{{- .Values.persistence.share.existingClaim }}
{{- else }}
{{- printf "%s-share" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Backups PVC name
*/}}
{{- define "home-assistant.pvc.backups" -}}
{{- if .Values.persistence.backups.existingClaim }}
{{- .Values.persistence.backups.existingClaim }}
{{- else }}
{{- printf "%s-backups" (include "home-assistant.fullname" .) }}
{{- end }}
{{- end }}

{{/*
============================================================================
Image Pull Secrets
============================================================================
*/}}
{{- define "home-assistant.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
============================================================================
Resource Limits
============================================================================
Because someone has to prevent you from requesting 64GB for a lightbulb controller
*/}}
{{- define "home-assistant.resources" -}}
{{- if .Values.homeassistant.resources }}
resources:
  {{- if .Values.homeassistant.resources.requests }}
  requests:
    {{- if .Values.homeassistant.resources.requests.cpu }}
    cpu: {{ .Values.homeassistant.resources.requests.cpu }}
    {{- end }}
    {{- if .Values.homeassistant.resources.requests.memory }}
    memory: {{ .Values.homeassistant.resources.requests.memory }}
    {{- end }}
  {{- end }}
  {{- if .Values.homeassistant.resources.limits }}
  limits:
    {{- if .Values.homeassistant.resources.limits.cpu }}
    cpu: {{ .Values.homeassistant.resources.limits.cpu }}
    {{- end }}
    {{- if .Values.homeassistant.resources.limits.memory }}
    memory: {{ .Values.homeassistant.resources.limits.memory }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
