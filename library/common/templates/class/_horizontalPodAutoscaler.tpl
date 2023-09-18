{{/*
This template serves as a blueprint for horizontal pod autoscaler objects that are created
using the common library.
*/}}
{{- define "tc.v1.common.class.hpa" -}}
  {{- $targetName := include "tc.v1.common.lib.chart.names.fullname" . -}}
  {{- $fullName := include "tc.v1.common.lib.chart.names.fullname" . -}}
  {{- $hpaName := $fullName -}}
  {{- $values := .Values.hpa -}}

  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.hpa -}}
      {{- $values = . -}}
    {{- end -}}
  {{- end -}}
  {{- $hpaLabels := $values.labels -}}
  {{- $hpaAnnotations := $values.annotations -}}

  {{- if and (hasKey $values "nameOverride") $values.nameOverride -}}
    {{- $hpaName = printf "%v-%v" $hpaName $values.nameOverride -}}
  {{- end }}
---
apiVersion: {{ include "tc.v1.common.capabilities.hpa.apiVersion" $ }}
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $hpaName }}
  namespace: {{ $.Values.namespace | default $.Values.global.namespace | default $.Release.Namespace }}
  {{- $labels := (mustMerge ($hpaLabels | default dict) (include "tc.v1.common.lib.metadata.allLabels" $ | fromYaml)) -}}
  {{- with (include "tc.v1.common.lib.metadata.render" (dict "rootCtx" $ "labels" $labels) | trim) }}
  labels:
    {{- . | nindent 4 }}
  {{- end -}}
  {{- $annotations := (mustMerge ($hpaAnnotations | default dict) (include "tc.v1.common.lib.metadata.allAnnotations" $ | fromYaml)) -}}
  {{- with (include "tc.v1.common.lib.metadata.render" (dict "rootCtx" $ "annotations" $annotations) | trim) }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: {{ $values.targetKind | default "Deployment" }}
    name: {{ $values.target | default $targetName }}
  minReplicas: {{ $values.minReplicas | default 1 }}
  maxReplicas: {{ $values.maxReplicas | default 3 }}
  metrics:
    {{- if $values.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $values.targetCPUUtilizationPercentage }}
    {{- end -}}
    {{- if $values.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: AverageValue
          averageValue: {{ $values.targetMemoryUtilizationPercentage }}
    {{- end -}}
{{- end -}}
