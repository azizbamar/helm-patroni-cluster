{{/*
Expand the name of the chart.
*/}}
{{- define "patroni-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "patroni-cluster.fullname" -}}
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
Create chart label
*/}}
{{- define "patroni-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "patroni-cluster.labels" -}}
helm.sh/chart: {{ include "patroni-cluster.chart" . }}
{{ include "patroni-cluster.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "patroni-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "patroni-cluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
etcd labels
*/}}
{{- define "patroni-cluster.etcdLabels" -}}
app.kubernetes.io/name: {{ include "patroni-cluster.name" . }}-etcd
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
etcd client endpoints string
*/}}
{{- define "patroni-cluster.etcdEndpoints" -}}
{{- $fullname := include "patroni-cluster.fullname" . -}}
{{- $ns := .Release.Namespace -}}
{{- $count := int .Values.etcd.replicaCount -}}
{{- $endpoints := list -}}
{{- range $i := until $count -}}
  {{- $endpoints = append $endpoints (printf "http://%s-etcd-%d.%s-etcd-headless.%s.svc.cluster.local:2379" $fullname $i $fullname $ns) -}}
{{- end -}}
{{ join "," $endpoints }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "patroni-cluster.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "patroni-cluster.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
