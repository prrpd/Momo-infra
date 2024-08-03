{{/*
Custom common labels.
*/}}
{{- define "momo-store.labels" -}}
app: {{ .Values.name }}
app.kubernetes.io/name: momo-{{ .Values.name }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/version: "{{ .Chart.AppVersion }}"
app.kubernetes.io/managed-by: "{{ .Release.Service }}"
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
app.kubernetes.io/component: "{{ .Chart.Name }}"
app.kubernetes.io/part-of: momo-store
env: "{{ .Values.environment }}"
{{- end -}}