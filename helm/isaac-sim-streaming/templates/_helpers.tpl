{{/* This project was developed with assistance from AI tools. */}}

{{- define "isaac-sim-streaming.namespace" -}}
{{ .Values.namespace | default "isaac-sim-streaming" }}
{{- end -}}

{{- define "isaac-sim-streaming.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: isaac-sim-streaming
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "isaac-sim-streaming.signalingHost" -}}
{{- if .Values.clusterDomain -}}
signaling-{{ include "isaac-sim-streaming.namespace" . }}.{{ .Values.clusterDomain }}
{{- else -}}
""
{{- end -}}
{{- end -}}

{{- define "isaac-sim-streaming.clientHost" -}}
{{- if .Values.clusterDomain -}}
viewer-{{ include "isaac-sim-streaming.namespace" . }}.{{ .Values.clusterDomain }}
{{- else -}}
""
{{- end -}}
{{- end -}}

{{- define "isaac-sim-streaming.turnHost" -}}
{{- if .Values.clusterDomain -}}
turn-{{ include "isaac-sim-streaming.namespace" . }}.{{ .Values.clusterDomain }}
{{- else -}}
""
{{- end -}}
{{- end -}}

{{- define "isaac-sim-streaming.coturnRealm" -}}
{{ include "isaac-sim-streaming.namespace" . }}.{{ .Values.clusterDomain | default "cluster.local" }}
{{- end -}}
