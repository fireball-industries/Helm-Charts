{{/*
Expand the name of the chart.
*/}}
{{- define "timescaledb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "timescaledb.fullname" -}}
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
{{- define "timescaledb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "timescaledb.labels" -}}
helm.sh/chart: {{ include "timescaledb.chart" . }}
{{ include "timescaledb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "timescaledb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "timescaledb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "timescaledb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "timescaledb.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the password secret name
*/}}
{{- define "timescaledb.secretName" -}}
{{- printf "%s-secret" (include "timescaledb.fullname" .) }}
{{- end }}

{{/*
Get the ConfigMap name
*/}}
{{- define "timescaledb.configMapName" -}}
{{- printf "%s-config" (include "timescaledb.fullname" .) }}
{{- end }}

{{/*
Get the init scripts ConfigMap name
*/}}
{{- define "timescaledb.initScriptsConfigMapName" -}}
{{- printf "%s-init-scripts" (include "timescaledb.fullname" .) }}
{{- end }}

{{/*
Get the service name
*/}}
{{- define "timescaledb.serviceName" -}}
{{- include "timescaledb.fullname" . }}
{{- end }}

{{/*
Get the headless service name
*/}}
{{- define "timescaledb.headlessServiceName" -}}
{{- printf "%s-headless" (include "timescaledb.fullname" .) }}
{{- end }}

{{/*
Get the primary connection string
*/}}
{{- define "timescaledb.primaryConnectionString" -}}
{{- printf "postgresql://%s:$(POSTGRES_PASSWORD)@%s.%s.svc.cluster.local:%d/%s" .Values.postgresql.username (include "timescaledb.serviceName" .) .Release.Namespace (.Values.service.port | int) .Values.postgresql.database }}
{{- end }}

{{/*
Apply resource preset
This merges the selected preset with the default values
*/}}
{{- define "timescaledb.applyPreset" -}}
{{- $preset := .Values.preset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- $presetValues := index .Values.resourcePresets $preset -}}
{{- $_ := mergeOverwrite .Values $presetValues -}}
{{- end -}}
{{- end -}}

{{/*
Get resources based on preset or custom
*/}}
{{- define "timescaledb.resources" -}}
{{- $preset := .Values.preset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- $presetValues := index .Values.resourcePresets $preset -}}
{{- toYaml $presetValues.resources -}}
{{- else -}}
{{- toYaml .Values.resources -}}
{{- end -}}
{{- end -}}

{{/*
Get persistence size based on preset or custom
*/}}
{{- define "timescaledb.persistenceSize" -}}
{{- $preset := .Values.preset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- $presetValues := index .Values.resourcePresets $preset -}}
{{- $presetValues.persistence.size -}}
{{- else -}}
{{- .Values.persistence.size -}}
{{- end -}}
{{- end -}}

{{/*
Get WAL volume size based on preset or custom
*/}}
{{- define "timescaledb.walVolumeSize" -}}
{{- $preset := .Values.preset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- $presetValues := index .Values.resourcePresets $preset -}}
{{- $presetValues.walVolume.size -}}
{{- else -}}
{{- .Values.walVolume.size -}}
{{- end -}}
{{- end -}}

{{/*
Get PostgreSQL configuration based on preset or custom
*/}}
{{- define "timescaledb.postgresqlConfig" -}}
{{- $preset := .Values.preset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- $presetValues := index .Values.resourcePresets $preset -}}
{{- if $presetValues.postgresql -}}
{{- toYaml $presetValues.postgresql -}}
{{- else -}}
{{- toYaml .Values.postgresql -}}
{{- end -}}
{{- else -}}
{{- toYaml .Values.postgresql -}}
{{- end -}}
{{- end -}}

{{/*
Get TimescaleDB configuration based on preset or custom
*/}}
{{- define "timescaledb.timescaledbConfig" -}}
{{- $preset := .Values.preset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- $presetValues := index .Values.resourcePresets $preset -}}
{{- if $presetValues.timescaledb -}}
{{- toYaml $presetValues.timescaledb -}}
{{- else -}}
{{- toYaml .Values.timescaledb -}}
{{- end -}}
{{- else -}}
{{- toYaml .Values.timescaledb -}}
{{- end -}}
{{- end -}}

{{/*
Create PostgreSQL connection environment variables
*/}}
{{- define "timescaledb.connectionEnv" -}}
- name: POSTGRES_DB
  value: {{ .Values.postgresql.database | quote }}
- name: POSTGRES_USER
  value: {{ .Values.postgresql.username | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "timescaledb.secretName" . }}
      key: password
- name: PGDATA
  value: {{ .Values.persistence.mountPath }}/{{ .Values.persistence.subPath }}
{{- end -}}

{{/*
Pod annotations - merge user-defined with generated
*/}}
{{- define "timescaledb.podAnnotations" -}}
{{- $annotations := dict -}}
{{- if .Values.podAnnotations -}}
{{- $annotations = .Values.podAnnotations -}}
{{- end -}}
{{- if .Values.timescaledb.enabled -}}
{{- $_ := set $annotations "timescaledb.io/enabled" "true" -}}
{{- end -}}
{{- if .Values.monitoring.serviceMonitor.enabled -}}
{{- $_ := set $annotations "prometheus.io/scrape" "true" -}}
{{- $_ := set $annotations "prometheus.io/port" (toString .Values.sidecars.postgresExporter.port) -}}
{{- end -}}
{{- toYaml $annotations -}}
{{- end -}}

{{/*
Validate configuration
This helper performs validation and returns error messages if configuration is invalid
*/}}
{{- define "timescaledb.validateConfig" -}}
{{- if and (eq .Values.mode "ha") (lt (.Values.replicaCount | int) 2) -}}
{{- fail "HA mode requires at least 2 replicas" -}}
{{- end -}}
{{- if and .Values.walVolume.enabled (not .Values.persistence.enabled) -}}
{{- fail "WAL volume requires persistence to be enabled" -}}
{{- end -}}
{{- if and .Values.compliance.fda21CFRPart11.enabled (not .Values.tls.enabled) -}}
{{- fail "FDA 21 CFR Part 11 compliance requires TLS to be enabled" -}}
{{- end -}}
{{- end -}}

{{/*
Get PostgreSQL version from image tag
*/}}
{{- define "timescaledb.postgresVersion" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if contains "pg16" $tag -}}
16
{{- else if contains "pg15" $tag -}}
15
{{- else if contains "pg14" $tag -}}
14
{{- else if contains "pg13" $tag -}}
13
{{- else -}}
15
{{- end -}}
{{- end -}}

{{/*
Industrial humor comment generator
Because if you can't laugh at your SCADA system, what's the point?
*/}}
{{- define "timescaledb.industrialHumor" -}}
{{- $humor := list 
  "Your sensor data is safe from Excel now"
  "No more CSV files on network shares"
  "Proper time-series storage for once"
  "Because PLCs deserve better than spreadsheets"
  "Industrial IoT data, professionally stored"
  "SCADA historian that won't crash at shift change"
  "Time-series data management, millennial style"
  "Better than that Access database from 2003"
-}}
{{- index $humor (randInt 0 (len $humor)) -}}
{{- end -}}

{{/*
Storage class - use preset, values, or default
*/}}
{{- define "timescaledb.storageClass" -}}
{{- if .Values.global.storageClass -}}
{{- .Values.global.storageClass -}}
{{- else if .Values.persistence.storageClass -}}
{{- .Values.persistence.storageClass -}}
{{- end -}}
{{- end -}}
