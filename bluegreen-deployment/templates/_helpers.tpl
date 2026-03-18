{{/*
Render a Kubernetes probe with exactly one handler type.
Priority: tcpSocket > httpGet > exec > grpc.
This avoids invalid specs when Helm deep-merges values from defaults and env files.
*/}}
{{- define "bluegreen.renderProbe" -}}
{{- $probe := . | default dict -}}
{{- $out := dict -}}

{{- if hasKey $probe "tcpSocket" -}}
{{- $_ := set $out "tcpSocket" (index $probe "tcpSocket") -}}
{{- else if hasKey $probe "httpGet" -}}
{{- $_ := set $out "httpGet" (index $probe "httpGet") -}}
{{- else if hasKey $probe "exec" -}}
{{- $_ := set $out "exec" (index $probe "exec") -}}
{{- else if hasKey $probe "grpc" -}}
{{- $_ := set $out "grpc" (index $probe "grpc") -}}
{{- end -}}

{{- if hasKey $probe "initialDelaySeconds" -}}
{{- $_ := set $out "initialDelaySeconds" (index $probe "initialDelaySeconds") -}}
{{- end -}}
{{- if hasKey $probe "periodSeconds" -}}
{{- $_ := set $out "periodSeconds" (index $probe "periodSeconds") -}}
{{- end -}}
{{- if hasKey $probe "timeoutSeconds" -}}
{{- $_ := set $out "timeoutSeconds" (index $probe "timeoutSeconds") -}}
{{- end -}}
{{- if hasKey $probe "successThreshold" -}}
{{- $_ := set $out "successThreshold" (index $probe "successThreshold") -}}
{{- end -}}
{{- if hasKey $probe "failureThreshold" -}}
{{- $_ := set $out "failureThreshold" (index $probe "failureThreshold") -}}
{{- end -}}
{{- if hasKey $probe "terminationGracePeriodSeconds" -}}
{{- $_ := set $out "terminationGracePeriodSeconds" (index $probe "terminationGracePeriodSeconds") -}}
{{- end -}}

{{- toYaml $out -}}
{{- end -}}

{{/*
Validate and return active version for blue/green selectors.
*/}}
{{- define "bluegreen.activeVersion" -}}
{{- $active := .Values.blueGreen.activeVersion | default "blue" -}}
{{- if and (ne $active "blue") (ne $active "green") -}}
{{- fail (printf "blueGreen.activeVersion must be 'blue' or 'green', got '%s'" $active) -}}
{{- end -}}
{{- $active -}}
{{- end -}}
