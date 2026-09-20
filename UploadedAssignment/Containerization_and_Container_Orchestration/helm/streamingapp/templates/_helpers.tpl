{{- define "streamingapp.name" -}}streamingapp{{- end }}
{{- define "streamingapp.labels" -}}
app.kubernetes.io/name: {{ include "streamingapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}
