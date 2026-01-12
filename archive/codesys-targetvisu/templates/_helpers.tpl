{{/*
CODESYS TargetVisu Helm Chart - Template Helpers
Because even your templates need therapy after dealing with industrial automation.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "codesys-targetvisu.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "codesys-targetvisu.fullname" -}}
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
{{- define "codesys-targetvisu.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codesys-targetvisu.labels" -}}
helm.sh/chart: {{ include "codesys-targetvisu.chart" . }}
{{ include "codesys-targetvisu.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: hmi-visualization
app.kubernetes.io/part-of: industrial-automation
{{- end }}

{{/*
Selector labels
*/}}
{{- define "codesys-targetvisu.selectorLabels" -}}
app.kubernetes.io/name: {{ include "codesys-targetvisu.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "codesys-targetvisu.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "codesys-targetvisu.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "codesys-targetvisu.image" -}}
{{- $registry := .Values.targetvisu.image.registry | default "" -}}
{{- $repository := .Values.targetvisu.image.repository -}}
{{- $tag := .Values.targetvisu.image.tag | default .Chart.AppVersion -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Return the proper Docker Image Pull Secret Names
*/}}
{{- define "codesys-targetvisu.imagePullSecrets" -}}
{{- if .Values.targetvisu.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.targetvisu.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Get resource preset values
Returns the appropriate resource configuration based on the selected preset
*/}}
{{- define "codesys-targetvisu.resources" -}}
{{- $preset := .Values.resourcePreset | default "edge-standard" -}}
{{- if eq $preset "edge-minimal" }}
requests:
  cpu: {{ .Values.presets.edge-minimal.resources.requests.cpu | default "500m" }}
  memory: {{ .Values.presets.edge-minimal.resources.requests.memory | default "512Mi" }}
limits:
  cpu: {{ .Values.presets.edge-minimal.resources.limits.cpu | default "1000m" }}
  memory: {{ .Values.presets.edge-minimal.resources.limits.memory | default "1Gi" }}
{{- else if eq $preset "industrial" }}
requests:
  cpu: {{ .Values.presets.industrial.resources.requests.cpu | default "2000m" }}
  memory: {{ .Values.presets.industrial.resources.requests.memory | default "2Gi" }}
limits:
  cpu: {{ .Values.presets.industrial.resources.limits.cpu | default "4000m" }}
  memory: {{ .Values.presets.industrial.resources.limits.memory | default "4Gi" }}
{{- else }}
{{- /* edge-standard is default */ -}}
requests:
  cpu: {{ .Values.resources.requests.cpu | default "1000m" }}
  memory: {{ .Values.resources.requests.memory | default "1Gi" }}
limits:
  cpu: {{ .Values.resources.limits.cpu | default "2000m" }}
  memory: {{ .Values.resources.limits.memory | default "2Gi" }}
{{- end }}
{{- end }}

{{/*
Get storage size based on preset
*/}}
{{- define "codesys-targetvisu.storage.config.size" -}}
{{- $preset := .Values.resourcePreset | default "edge-standard" -}}
{{- if eq $preset "edge-minimal" }}
{{- .Values.presets.edge-minimal.storage.config.size | default "2Gi" }}
{{- else if eq $preset "industrial" }}
{{- .Values.presets.industrial.storage.config.size | default "10Gi" }}
{{- else }}
{{- .Values.storage.config.size | default "5Gi" }}
{{- end }}
{{- end }}

{{- define "codesys-targetvisu.storage.projects.size" -}}
{{- $preset := .Values.resourcePreset | default "edge-standard" -}}
{{- if eq $preset "edge-minimal" }}
{{- .Values.presets.edge-minimal.storage.projects.size | default "5Gi" }}
{{- else if eq $preset "industrial" }}
{{- .Values.presets.industrial.storage.projects.size | default "20Gi" }}
{{- else }}
{{- .Values.storage.projects.size | default "10Gi" }}
{{- end }}
{{- end }}

{{- define "codesys-targetvisu.storage.logs.size" -}}
{{- $preset := .Values.resourcePreset | default "edge-standard" -}}
{{- if eq $preset "edge-minimal" }}
{{- .Values.presets.edge-minimal.storage.logs.size | default "1Gi" }}
{{- else if eq $preset "industrial" }}
{{- .Values.presets.industrial.storage.logs.size | default "5Gi" }}
{{- else }}
{{- .Values.storage.logs.size | default "2Gi" }}
{{- end }}
{{- end }}

{{/*
Get max clients based on preset
*/}}
{{- define "codesys-targetvisu.maxClients" -}}
{{- $preset := .Values.resourcePreset | default "edge-standard" -}}
{{- if eq $preset "edge-minimal" }}
{{- .Values.presets.edge-minimal.targetvisu.web.maxClients | default "5" }}
{{- else if eq $preset "industrial" }}
{{- .Values.presets.industrial.targetvisu.web.maxClients | default "25" }}
{{- else }}
{{- .Values.targetvisu.web.maxClients | default "10" }}
{{- end }}
{{- end }}

{{/*
DNS policy - use ClusterFirstWithHostNet if hostNetwork is enabled
*/}}
{{- define "codesys-targetvisu.dnsPolicy" -}}
{{- if .Values.hostNetwork }}
{{- "ClusterFirstWithHostNet" }}
{{- else }}
{{- .Values.dnsPolicy | default "ClusterFirst" }}
{{- end }}
{{- end }}

{{/*
Get the license secret name
*/}}
{{- define "codesys-targetvisu.licenseSecretName" -}}
{{- if eq .Values.targetvisu.license.type "file" }}
{{- .Values.targetvisu.license.licenseSecret | default (printf "%s-license" (include "codesys-targetvisu.fullname" .)) }}
{{- else }}
{{- printf "%s-license" (include "codesys-targetvisu.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get protocol ports for service
*/}}
{{- define "codesys-targetvisu.protocolPorts" -}}
{{- if .Values.protocols.opcua.enabled }}
- name: opcua
  port: {{ .Values.protocols.opcua.port | default 4840 }}
  targetPort: opcua
  protocol: TCP
{{- end }}
{{- if .Values.protocols.modbusTcp.enabled }}
- name: modbus-tcp
  port: {{ .Values.protocols.modbusTcp.port | default 502 }}
  targetPort: modbus-tcp
  protocol: TCP
{{- end }}
{{- if .Values.protocols.ethernetIp.enabled }}
- name: ethernet-ip
  port: {{ .Values.protocols.ethernetIp.port | default 44818 }}
  targetPort: ethernet-ip
  protocol: TCP
{{- end }}
{{- if .Values.protocols.bacnet.enabled }}
- name: bacnet
  port: {{ .Values.protocols.bacnet.port | default 47808 }}
  targetPort: bacnet
  protocol: UDP
{{- end }}
{{- if .Values.gateway.enabled }}
- name: gateway
  port: {{ .Values.gateway.port | default 11740 }}
  targetPort: gateway
  protocol: TCP
{{- end }}
{{- end }}

{{/*
Get container environment variables
*/}}
{{- define "codesys-targetvisu.environment" -}}
- name: CODESYS_WEB_PORT
  value: {{ .Values.targetvisu.web.httpPort | default 8080 | quote }}
- name: CODESYS_HTTPS_PORT
  value: {{ .Values.targetvisu.web.httpsPort | default 8443 | quote }}
- name: CODESYS_WEBVISU_PORT
  value: {{ .Values.targetvisu.web.webVisuPort | default 8081 | quote }}
- name: CODESYS_MAX_CLIENTS
  value: {{ include "codesys-targetvisu.maxClients" . | quote }}
- name: CODESYS_LOG_LEVEL
  value: {{ .Values.targetvisu.runtime.logLevel | default "info" | quote }}
- name: CODESYS_LOG_FORMAT
  value: {{ .Values.targetvisu.runtime.logFormat | default "json" | quote }}
{{- if .Values.protocols.opcua.enabled }}
- name: OPCUA_ENABLED
  value: "true"
- name: OPCUA_PORT
  value: {{ .Values.protocols.opcua.port | default 4840 | quote }}
{{- end }}
{{- if .Values.protocols.modbusTcp.enabled }}
- name: MODBUS_TCP_ENABLED
  value: "true"
- name: MODBUS_TCP_PORT
  value: {{ .Values.protocols.modbusTcp.port | default 502 | quote }}
{{- end }}
{{- if .Values.plc.enabled }}
- name: PLC_ENABLED
  value: "true"
- name: PLC_CONNECTION_TYPE
  value: {{ .Values.plc.connection.type | default "local" | quote }}
{{- if eq .Values.plc.connection.type "remote" }}
- name: PLC_REMOTE_HOST
  value: {{ .Values.plc.connection.remote.host | quote }}
- name: PLC_REMOTE_PORT
  value: {{ .Values.plc.connection.remote.port | default 11740 | quote }}
{{- end }}
{{- end }}
{{- if .Values.monitoring.prometheus.enabled }}
- name: PROMETHEUS_ENABLED
  value: "true"
- name: PROMETHEUS_PORT
  value: {{ .Values.monitoring.prometheus.port | default 9100 | quote }}
{{- end }}
{{- end }}

{{/*
Validate configuration
Because somebody needs to tell you that Modbus on port 80 is a terrible idea
*/}}
{{- define "codesys-targetvisu.validateConfig" -}}
{{- if and .Values.protocols.profinet.enabled (not .Values.hostNetwork) }}
{{- fail "PROFINET requires hostNetwork: true (it's a layer 2 protocol, for crying out loud)" }}
{{- end }}
{{- if and (lt (int .Values.targetvisu.web.httpPort) 1024) (not .Values.security.podSecurityContext.runAsNonRoot) }}
{{- /* This is actually fine with NET_BIND_SERVICE capability */ -}}
{{- end }}
{{- if eq .Values.targetvisu.license.type "demo" }}
{{- /* Just a friendly reminder */ -}}
{{- end }}
{{- end }}

{{/*
Get the TLS secret name
*/}}
{{- define "codesys-targetvisu.tlsSecretName" -}}
{{- if .Values.security.tls.certSecret }}
{{- .Values.security.tls.certSecret }}
{{- else }}
{{- printf "%s-tls" (include "codesys-targetvisu.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the ingress TLS secret name
*/}}
{{- define "codesys-targetvisu.ingress.tlsSecretName" -}}
{{- if .Values.ingress.tls.secretName }}
{{- .Values.ingress.tls.secretName }}
{{- else }}
{{- printf "%s-ingress-tls" (include "codesys-targetvisu.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Common annotations for all resources
*/}}
{{- define "codesys-targetvisu.annotations" -}}
meta.helm.sh/release-name: {{ .Release.Name }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
fireball.industries/humor-level: "existential"
fireball.industries/coffee-required: "yes"
{{- end }}

{{/*
Get ConfigMap name for configuration files
*/}}
{{- define "codesys-targetvisu.configMapName" -}}
{{- printf "%s-config" (include "codesys-targetvisu.fullname" .) }}
{{- end }}

{{/*
Check if we're running on Raspberry Pi (arm64 edge deployment)
*/}}
{{- define "codesys-targetvisu.isRaspberryPi" -}}
{{- if and (eq .Values.resourcePreset "edge-minimal") (.Values.nodeSelector) }}
{{- if eq (index .Values.nodeSelector "kubernetes.io/arch") "arm64" }}
{{- true }}
{{- end }}
{{- end }}
{{- end }}
