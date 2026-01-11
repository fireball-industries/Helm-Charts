{{/*
Expand the name of the chart.
*/}}
{{- define "node-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "node-exporter.fullname" -}}
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
{{- define "node-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "node-exporter.labels" -}}
helm.sh/chart: {{ include "node-exporter.chart" . }}
{{ include "node-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "node-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "node-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "node-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "node-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the namespace
*/}}
{{- define "node-exporter.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "node-exporter.rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" }}
{{- else }}
{{- print "rbac.authorization.k8s.io/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for policy.
*/}}
{{- define "node-exporter.psp.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1beta1/PodSecurityPolicy" }}
{{- print "policy/v1beta1" }}
{{- else }}
{{- print "extensions/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "node-exporter.networkPolicy.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1" }}
{{- print "networking.k8s.io/v1" }}
{{- else }}
{{- print "networking.k8s.io/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Get the collector arguments based on preset or custom configuration
*/}}
{{- define "node-exporter.collectors" -}}
{{- $preset := .Values.resourcePreset -}}
{{- $collectors := list -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
  {{- $collectors = (index .Values.resourcePresets $preset).collectors -}}
{{- else -}}
  {{- $collectors = .Values.collectors.enabled -}}
{{- end -}}
{{- range $collectors }}
- --collector.{{ . }}
{{- end }}
{{- if .Values.collectors.optional.systemd }}
- --collector.systemd
{{- end }}
{{- if .Values.collectors.optional.processes }}
- --collector.processes
{{- end }}
{{- if .Values.collectors.optional.textfile }}
- --collector.textfile
- --collector.textfile.directory={{ .Values.collectors.collectorArgs.textfile.directory }}
{{- end }}
{{- if .Values.collectors.optional.ntp }}
- --collector.ntp
{{- end }}
{{- if .Values.collectors.optional.tcpstat }}
- --collector.tcpstat
{{- end }}
{{- if .Values.collectors.optional.interrupts }}
- --collector.interrupts
{{- end }}
{{- if .Values.collectors.optional.thermal_zone }}
- --collector.thermal_zone
{{- end }}
{{- if .Values.collectors.optional.ethtool }}
- --collector.ethtool
{{- end }}
{{- if .Values.collectors.optional.wifi }}
- --collector.wifi
{{- end }}
{{- if .Values.collectors.optional.rapl }}
- --collector.rapl
{{- end }}
{{- if .Values.collectors.optional.supervisord }}
- --collector.supervisord
{{- end }}
{{- if .Values.collectors.collectorArgs.filesystem }}
{{- with .Values.collectors.collectorArgs.filesystem }}
{{- if .mountPointsExclude }}
- --collector.filesystem.mount-points-exclude={{ .mountPointsExclude }}
{{- else if (index . "mount-points-exclude") }}
- --collector.filesystem.mount-points-exclude={{ index . "mount-points-exclude" }}
{{- end }}
{{- if .fsTypesExclude }}
- --collector.filesystem.fs-types-exclude={{ .fsTypesExclude }}
{{- else if (index . "fs-types-exclude") }}
- --collector.filesystem.fs-types-exclude={{ index . "fs-types-exclude" }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.collectors.collectorArgs.netdev }}
{{- with .Values.collectors.collectorArgs.netdev }}
{{- if .deviceExclude }}
- --collector.netdev.device-exclude={{ .deviceExclude }}
{{- else if (index . "device-exclude") }}
- --collector.netdev.device-exclude={{ index . "device-exclude" }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.collectors.collectorArgs.netclass }}
{{- with .Values.collectors.collectorArgs.netclass }}
{{- if .ignoredDevices }}
- --collector.netclass.ignored-devices={{ .ignoredDevices }}
{{- else if (index . "ignored-devices") }}
- --collector.netclass.ignored-devices={{ index . "ignored-devices" }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.collectors.collectorArgs.diskstats }}
{{- with .Values.collectors.collectorArgs.diskstats }}
{{- if .deviceExclude }}
- --collector.diskstats.device-exclude={{ .deviceExclude }}
{{- else if (index . "device-exclude") }}
- --collector.diskstats.device-exclude={{ index . "device-exclude" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Get resources based on preset or custom configuration
*/}}
{{- define "node-exporter.resources" -}}
{{- $preset := .Values.resourcePreset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
{{- with (index .Values.resourcePresets $preset) }}
requests:
  cpu: {{ .requests.cpu }}
  memory: {{ .requests.memory }}
limits:
  cpu: {{ .limits.cpu }}
  memory: {{ .limits.memory }}
{{- end }}
{{- else -}}
{{- with .Values.resources }}
{{- toYaml . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "node-exporter.image" -}}
{{- $registry := .Values.image.registry -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.image.digest }}
{{- printf "%s/%s@%s" $registry $repository .Values.image.digest }}
{{- else }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}
{{- end }}

{{/*
Return init container image
*/}}
{{- define "node-exporter.initImage" -}}
{{- $registry := .Values.textfileCollector.initContainer.image.registry -}}
{{- $repository := .Values.textfileCollector.initContainer.image.repository -}}
{{- $tag := .Values.textfileCollector.initContainer.image.tag -}}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Compile all warnings into a single message
*/}}
{{- define "node-exporter.validateValues" -}}
{{- $messages := list -}}
{{- if and (ne .Values.deploymentMode "daemonset") (ne .Values.deploymentMode "deployment") (ne .Values.deploymentMode "statefulset") -}}
{{- $messages = append $messages "deploymentMode must be one of: daemonset, deployment, statefulset" -}}
{{- end -}}
{{- if not .Values.hostNetwork -}}
{{- $messages = append $messages "hostNetwork should be enabled for accurate node metrics" -}}
{{- end -}}
{{- if $messages -}}
{{- printf "\nVALIDATION WARNINGS:\n%s" (join "\n" $messages) | fail -}}
{{- end -}}
{{- end }}

{{/*
Count enabled collectors for NOTES.txt
*/}}
{{- define "node-exporter.collectorCount" -}}
{{- $count := 0 -}}
{{- $preset := .Values.resourcePreset -}}
{{- if and (ne $preset "custom") (hasKey .Values.resourcePresets $preset) -}}
  {{- $count = len (index .Values.resourcePresets $preset).collectors -}}
{{- else -}}
  {{- $count = len .Values.collectors.enabled -}}
{{- end -}}
{{- if .Values.collectors.optional.systemd }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.processes }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.textfile }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.ntp }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.tcpstat }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.interrupts }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.thermal_zone }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.ethtool }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.wifi }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.rapl }}{{ $count = add1 $count }}{{ end -}}
{{- if .Values.collectors.optional.supervisord }}{{ $count = add1 $count }}{{ end -}}
{{- $count -}}
{{- end }}
