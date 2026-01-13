{{/*
Expand the name of the chart.
*/}}
{{- define "ignition-edge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ignition-edge.fullname" -}}
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
{{- define "ignition-edge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ignition-edge.labels" -}}
helm.sh/chart: {{ include "ignition-edge.chart" . }}
{{ include "ignition-edge.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: industrial-automation
app.kubernetes.io/component: scada-gateway
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ignition-edge.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ignition-edge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ignition-edge.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ignition-edge.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get admin password from secret or generate new one
*/}}
{{- define "ignition-edge.adminPassword" -}}
{{- if .Values.gateway.admin.existingSecret }}
{{- .Values.gateway.admin.existingSecret }}
{{- else }}
{{- if .Values.gateway.admin.password }}
{{- .Values.gateway.admin.password }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Resource preset configurations
Because manually calculating CPU and RAM for every deployment is so 2010.
*/}}
{{- define "ignition-edge.resources" -}}
{{- $preset := .Values.global.preset | default "" }}
{{- if eq $preset "edge-panel" }}
requests:
  cpu: 1
  memory: 2Gi
limits:
  cpu: 2
  memory: 4Gi
{{- else if eq $preset "edge-gateway" }}
requests:
  cpu: 2
  memory: 4Gi
limits:
  cpu: 4
  memory: 8Gi
{{- else if eq $preset "edge-compute" }}
requests:
  cpu: 4
  memory: 8Gi
limits:
  cpu: 8
  memory: 16Gi
{{- else if eq $preset "standard" }}
requests:
  cpu: 4
  memory: 16Gi
limits:
  cpu: 8
  memory: 32Gi
{{- else if eq $preset "enterprise" }}
requests:
  cpu: 8
  memory: 32Gi
limits:
  cpu: 16
  memory: 64Gi
{{- else }}
{{- toYaml .Values.resources }}
{{- end }}
{{- end }}

{{/*
JVM heap size based on preset
*/}}
{{- define "ignition-edge.heapSize" -}}
{{- $preset := .Values.global.preset | default "" }}
{{- if eq $preset "edge-panel" }}
-Xms512m -Xmx1024m
{{- else if eq $preset "edge-gateway" }}
-Xms1g -Xmx2g
{{- else if eq $preset "edge-compute" }}
-Xms2g -Xmx4g
{{- else if eq $preset "standard" }}
-Xms4g -Xmx8g
{{- else if eq $preset "enterprise" }}
-Xms8g -Xmx16g
{{- else }}
-Xms{{ .Values.gateway.heap.initial }} -Xmx{{ .Values.gateway.heap.max }}
{{- end }}
{{- end }}

{{/*
Max designer connections based on preset and edition
*/}}
{{- define "ignition-edge.maxDesigners" -}}
{{- $preset := .Values.global.preset | default "" }}
{{- $edition := .Values.global.edition | default "gateway" }}
{{- if or (eq $edition "panel") (eq $edition "gateway") }}
0
{{- else if eq $preset "edge-compute" }}
5
{{- else if eq $preset "standard" }}
10
{{- else if eq $preset "enterprise" }}
25
{{- else }}
{{ .Values.gateway.connections.maxDesigners }}
{{- end }}
{{- end }}

{{/*
Max Vision client connections based on preset
*/}}
{{- define "ignition-edge.maxVisionClients" -}}
{{- $preset := .Values.global.preset | default "" }}
{{- if eq $preset "edge-panel" }}
5
{{- else if eq $preset "edge-gateway" }}
10
{{- else if eq $preset "edge-compute" }}
25
{{- else if eq $preset "standard" }}
50
{{- else if eq $preset "enterprise" }}
100
{{- else }}
{{ .Values.gateway.connections.maxVisionClients }}
{{- end }}
{{- end }}

{{/*
Storage size based on preset
*/}}
{{- define "ignition-edge.storageSize" -}}
{{- $preset := .Values.global.preset | default "" }}
{{- if eq $preset "edge-panel" }}
10Gi
{{- else if eq $preset "edge-gateway" }}
20Gi
{{- else if eq $preset "edge-compute" }}
50Gi
{{- else if eq $preset "standard" }}
100Gi
{{- else if eq $preset "enterprise" }}
200Gi
{{- else }}
{{ .Values.persistence.data.size }}
{{- end }}
{{- end }}

{{/*
Database connection string for PostgreSQL
*/}}
{{- define "ignition-edge.postgresqlUrl" -}}
{{- if .Values.databases.postgresql.enabled }}
jdbc:postgresql://{{ .Values.databases.postgresql.host }}:{{ .Values.databases.postgresql.port }}/{{ .Values.databases.postgresql.database }}
{{- end }}
{{- end }}

{{/*
Database connection string for TimescaleDB
*/}}
{{- define "ignition-edge.timescaledbUrl" -}}
{{- if .Values.databases.timescaledb.enabled }}
jdbc:postgresql://{{ .Values.databases.timescaledb.host }}:{{ .Values.databases.timescaledb.port }}/{{ .Values.databases.timescaledb.database }}
{{- end }}
{{- end }}

{{/*
OPC UA endpoint URL
*/}}
{{- define "ignition-edge.opcuaEndpoint" -}}
{{- if .Values.opcua.server.endpointUrl }}
{{ .Values.opcua.server.endpointUrl }}
{{- else }}
opc.tcp://{{ include "ignition-edge.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:{{ .Values.opcua.server.port }}
{{- end }}
{{- end }}

{{/*
MQTT broker URL for Engine
*/}}
{{- define "ignition-edge.mqttEngineUrl" -}}
{{- if .Values.mqtt.engine.broker.ssl }}
ssl://{{ .Values.mqtt.engine.broker.host }}:{{ .Values.mqtt.engine.broker.sslPort }}
{{- else }}
tcp://{{ .Values.mqtt.engine.broker.host }}:{{ .Values.mqtt.engine.broker.port }}
{{- end }}
{{- end }}

{{/*
MQTT broker URL for Transmission
*/}}
{{- define "ignition-edge.mqttTransmissionUrl" -}}
{{- if .Values.mqtt.transmission.broker.ssl }}
ssl://{{ .Values.mqtt.transmission.broker.host }}:{{ .Values.mqtt.transmission.broker.sslPort }}
{{- else }}
tcp://{{ .Values.mqtt.transmission.broker.host }}:{{ .Values.mqtt.transmission.broker.port }}
{{- end }}
{{- end }}

{{/*
Demo mode warning message
Because production without a license is like running scissors - exciting but dangerous.
*/}}
{{- define "ignition-edge.demoModeWarning" -}}
{{- if .Values.global.demoMode }}
⚠️  DEMO MODE ACTIVE - Gateway will restart every 2 hours!
   This is great for testing, terrible for production.
   Activate your license to stop the madness.
{{- end }}
{{- end }}

{{/*
Edition-specific module list
Because not every edge device needs the full buffet of SCADA goodness.
*/}}
{{- define "ignition-edge.editionModules" -}}
{{- $edition := .Values.global.edition | default "gateway" }}
{{- if eq $edition "panel" }}
- Vision
{{- else if eq $edition "gateway" }}
- OPC-UA
- MQTT-Engine
- MQTT-Transmission
- Tag-Historian
- Alarm-Notification
{{- else if eq $edition "compute" }}
- OPC-UA
- MQTT-Engine
- MQTT-Transmission
- MQTT-Chariot
- Tag-Historian
- Alarm-Notification
- Reporting
- Vision
- Perspective
{{- end }}
{{- end }}

{{/*
Get backup destination path
*/}}
{{- define "ignition-edge.backupPath" -}}
{{- if eq .Values.backup.destination.type "pvc" }}
/backups
{{- else if eq .Values.backup.destination.type "nfs" }}
{{ .Values.backup.destination.nfs.path }}
{{- else if eq .Values.backup.destination.type "s3" }}
s3://{{ .Values.backup.destination.s3.bucket }}/{{ include "ignition-edge.fullname" . }}
{{- end }}
{{- end }}

{{/*
Compliance mode configuration
Because the FDA doesn't care that "the PLC ate my audit log"
*/}}
{{- define "ignition-edge.complianceMode" -}}
{{- if .Values.security.compliance }}
21CFR-Part-11
{{- else }}
standard
{{- end }}
{{- end }}
