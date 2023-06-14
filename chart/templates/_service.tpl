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
{{- define "ssl-exporter-service" }}
{{- $top := index . 0 }}
{{- $masternode := index . 1 }}
apiVersion: v1
kind: Service
metadata:
  {{- if $masternode }}
  name: {{ include "ssl-exporter.fullname" $top }}-master
  {{- else }}
  name: {{ include "ssl-exporter.fullname" $top }}-worker
  {{- end }}
  labels:
    {{- if $top.Values.serviceMonitor.enabled }}
    {{- if $masternode }}
    ssl-exporter/monitor-identifier: "{{ $top.Release.Name }}-master"
    {{- else}}
    ssl-exporter/monitor-identifier: "{{ $top.Release.Name }}-worker"
    {{- end }}
    {{- end }}
    {{- include "ssl-exporter.labels" $top | nindent 4 }}
  {{- if $top.Values.serviceMonitor.enabled }}
  annotations:
    prometheus.io/port: "metrics"
    prometheus.io/scrape: "true"
    prometheus.io/path: ""
  {{- end }}
spec:
  type: {{ $top.Values.service.type }}
  ports:
    - port: {{ $top.Values.service.port }}
      targetPort: http
      protocol: TCP
      name: metrics
  selector:
    {{- include "ssl-exporter.selectorLabels" $top | nindent 4 }}
    {{- if $masternode }}
    ssl-exporter/service: "master"
    {{- else }}
    ssl-exporter/service: "worker"
        {{- end }}
{{- end }}
