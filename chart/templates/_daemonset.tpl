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
{{- define "ssl-exporter-daemonset" }}
{{- $top := index . 0 }}
{{- $masternode := index . 1 }}
apiVersion: apps/v1
kind: DaemonSet
metadata:
  {{- if $masternode }}
  name: {{ include "ssl-exporter.fullname" $top }}-master
  {{- else }}
  name: {{ include "ssl-exporter.fullname" $top }}-worker
  {{- end }}
  labels:
    {{- include "ssl-exporter.labels" $top | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "ssl-exporter.selectorLabels" $top | nindent 6 }}
  template:
    metadata:
      {{- with $top.Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "ssl-exporter.selectorLabels" $top | nindent 8 }}
        {{- if $masternode }}
        ssl-exporter/service: "master"
        {{- else }}
        ssl-exporter/service: "worker"
        {{- end }}
    spec:
      {{- with $top.Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "ssl-exporter.serviceAccountName" $top }}
      securityContext:
        {{- toYaml $top.Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ $top.Chart.Name }}
          securityContext:
            {{- toYaml $top.Values.securityContext | nindent 12 }}
          image: "{{ $top.Values.image.repository }}:{{ $top.Values.image.tag | default $top.Chart.AppVersion }}"
          imagePullPolicy: {{ $top.Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ $top.Values.service.port }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml $top.Values.resources | nindent 12 }}
          volumeMounts:
            - name: config
              mountPath: "/etc/ssl-exporter"
            {{- if $masternode }}
            - name: host-kubeconfig
              mountPath: {{ $top.Values.kubeconfigMountPath }}
            {{- end }}
            - name: host-k8s-certs
              mountPath: {{ $top.Values.certMountPath }}
          args:
            - --config.file=/etc/ssl-exporter/ssl_exporter.yaml
    {{- if $masternode }}
      nodeSelector:
        {{ include "ssl-exporter.nodeSelectorMaster"  $top | nindent 8}}
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
    {{- else }}
      {{- with $top.Values.nodeSelectorWorker }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $top.Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $top.Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    {{- end }}
      volumes:
        - name: config
          configMap:
            name: {{ include "ssl-exporter.configMapName" $top }}
        {{- if $masternode }}
        - name: host-kubeconfig
          hostPath:
            path: {{ $top.Values.kubeconfigMountPath }}
        {{- end }}
        - name: host-k8s-certs
          hostPath:
            path: {{ $top.Values.certMountPath }}
{{- end }}
