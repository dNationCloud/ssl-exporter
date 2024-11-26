{{/*
#
# Copyright 2023 The dNation SSL Exporter authors. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
*/}}

{{- define "ssl-exporter-servicemonitor" }}
{{- $top := index . 0 }}
{{- $masternode := index . 1 }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  {{- if $masternode }}
  name: {{ include "ssl-exporter.fullname" $top }}-master
  {{- else }}
  name: {{ include "ssl-exporter.fullname" $top }}-worker
  {{- end }}
  labels:
 {{- include "ssl-exporter.labels" $top | nindent 4 }}
 {{- include "ssl-exporter.serviceMonitorLabels" $top | nindent 4 }}
spec:
  namespaceSelector:
    matchNames:
      - {{ $top.Release.Namespace }}
  selector:
    matchLabels:
      {{- if $masternode }}
      ssl-exporter/monitor-identifier: "{{ $top.Release.Name }}-master"
      {{- else }}
      ssl-exporter/monitor-identifier: "{{ $top.Release.Name  }}-worker"
      {{- end }}
  endpoints:
    # Kubernetes internal cerificates
    {{- range $top.Values.serviceMonitor.fileTargets }}
    - interval: {{ $top.Values.serviceMonitor.scrapeInterval }}
      port: metrics
      scrapeTimeout: {{ $top.Values.serviceMonitor.scrapeTimeout }}
      path: /probe
      params:
        module:
        - file
        target:
        - "{{ . }}"
      relabelings:
      - targetLabel: job
        replacement: ssl-kubernetes-files
        action: replace
    {{- end }}
  {{- if $masternode }}
    # Kubeconfig certificates
    {{- range $top.Values.serviceMonitor.kubeconfigTargets }}
    - interval: {{ $top.Values.serviceMonitor.scrapeInterval }}
      port: metrics
      scrapeTimeout: {{ $top.Values.serviceMonitor.scrapeTimeout }}
      path: /probe
      params:
        module:
        - kubeconfig
        target:
        - "{{ . }}"
      relabelings:
      - sourceLabels: [__param_target]
        targetLabel: target
        action: replace
      - targetLabel: job
        replacement: ssl-kubernetes-kubeconfig
        action: replace

    {{- end }}
  {{- else }}
    # External certificates
    {{- range $top.Values.serviceMonitor.externalTargets }}
    - interval: {{ $top.Values.serviceMonitor.scrapeInterval }}
      port: metrics
      scrapeTimeout: {{ $top.Values.serviceMonitor.scrapeTimeout }}
      path: /probe
      params:
        target:
          - "{{ . }}"
      relabelings:
      - targetLabel: job
        replacement: ssl-external-url
        action: replace
      metricRelabelings:
      - action: labeldrop
        regex: instance
      - action: labeldrop
        regex: pod
    {{- end }}
    # Certificates from kubernetes secrets
    {{- range $top.Values.serviceMonitor.secretTargets }}
    - interval: {{ $top.Values.serviceMonitor.scrapeInterval }}
      port: metrics
      scrapeTimeout: {{ $top.Values.serviceMonitor.scrapeTimeout }}
      path: /probe
      params:
        module:
          - kubernetes
        target:
          - "{{ . }}"
      relabelings:
      - targetLabel: job
        replacement: ssl-kubernetes-secrets
        action: replace
      metricRelabelings:
      - action: labeldrop
        regex: instance
      - action: labeldrop
        regex: pod
    {{- end }}
  {{- end }}
{{- end}}
