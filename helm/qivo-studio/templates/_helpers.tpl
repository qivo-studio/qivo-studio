{{- define "qivo.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{ else }}{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}{{ end }}
{{- end }}

{{- define "qivo.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{- define "qivo.selector" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "qivo.secretName" -}}
{{- .Values.existingSecret | default (printf "%s-env" (include "qivo.fullname" .)) }}
{{- end }}

{{- define "qivo.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/* a value kept across upgrades: given, else the one already in the Secret, else generated */}}
{{- define "qivo.kept" -}}
{{- $given := index . 0 }}{{- $existing := index . 1 }}{{- $key := index . 2 }}{{- $generated := index . 3 }}
{{- if $given }}{{ $given }}{{- else if and $existing (index $existing.data $key) }}{{ index $existing.data $key | b64dec }}{{- else }}{{ $generated }}{{- end }}
{{- end }}
