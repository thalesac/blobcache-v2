{{/*
Return the proper Blobcache image name
*/}}
{{- define "blobcache.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Blobcache image name for init containers
*/}}
{{- define "blobcache.initImage" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.initImage "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "blobcache.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.initImage) "global" .Values.global) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "blobcache.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (printf "%s" (include "common.names.fullname" .)) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "blobcache.ingress.certManagerRequest" -}}
{{ if or (hasKey . "cert-manager.io/cluster-issuer") (hasKey . "cert-manager.io/issuer") }}
    {{- true -}}
{{ end }}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "blobcache.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "blobcache.validateValues.authentication" .) -}}
{{- $messages := append $messages (include "blobcache.validateValues.redis" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Validate values of Blobcache - Authentication
*/}}
{{- define "blobcache.validateValues.authentication" -}}
{{- if and (not .Values.auth.token) (not .Values.existingSecret) -}}
blobcache: authentication
    You must provide an authentication token. Set either:
    - auth.token
    - existingSecret (pointing to a secret with 'token' key)
{{- end -}}
{{- end -}}

{{/*
Validate values of Blobcache - Redis dependency
*/}}
{{- define "blobcache.validateValues.redis" -}}
{{- if and .Values.redis.enabled (not .Values.externalRedis.host) (eq .Values.redis.architecture "replication") (not .Values.redis.auth.enabled) -}}
blobcache: redis
    When using Redis replication, you must enable authentication.
    Set redis.auth.enabled=true
{{- end -}}
{{- end -}}

{{/*
Return the Redis hostname
*/}}
{{- define "blobcache.redis.host" -}}
{{- if .Values.redis.enabled -}}
{{- if eq .Values.redis.architecture "replication" -}}
{{- printf "%s-redis-master" (include "common.names.fullname" .) -}}
{{- else -}}
{{- printf "%s-redis" (include "common.names.fullname" .) -}}
{{- end -}}
{{- else -}}
{{- .Values.externalRedis.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis port
*/}}
{{- define "blobcache.redis.port" -}}
{{- if .Values.redis.enabled -}}
{{- .Values.redis.master.service.ports.redis -}}
{{- else -}}
{{- .Values.externalRedis.port -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis password
*/}}
{{- define "blobcache.redis.password" -}}
{{- if .Values.redis.enabled -}}
{{- if .Values.redis.auth.enabled -}}
{{- .Values.redis.auth.password -}}
{{- end -}}
{{- else -}}
{{- .Values.externalRedis.password -}}
{{- end -}}
{{- end -}}

{{/*
Get the Redis credentials secret.
*/}}
{{- define "blobcache.redis.secretName" -}}
{{- if .Values.redis.enabled -}}
{{- if .Values.redis.auth.enabled -}}
{{- if .Values.redis.auth.existingSecret -}}
{{- .Values.redis.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-redis" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- if .Values.externalRedis.existingSecret -}}
{{- .Values.externalRedis.existingSecret -}}
{{- else -}}
{{- printf "%s-redis" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the Redis credentials secret key.
*/}}
{{- define "blobcache.redis.secretKey" -}}
{{- if .Values.redis.enabled -}}
{{- if .Values.redis.auth.enabled -}}
{{- if .Values.redis.auth.existingSecretPasswordKey -}}
{{- .Values.redis.auth.existingSecretPasswordKey -}}
{{- else -}}
redis-password
{{- end -}}
{{- end -}}
{{- else -}}
{{- .Values.externalRedis.existingSecretPasswordKey -}}
{{- end -}}
{{- end -}}

{{/*
Return the blobcache configuration configmap name
*/}}
{{- define "blobcache.configmapName" -}}
{{- if .Values.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "blobcache.createConfigmap" -}}
{{- if and (not .Values.existingConfigmap) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret with blobcache credentials
*/}}
{{- define "blobcache.secretName" -}}
{{- if .Values.existingSecret }}
    {{- printf "%s" (tpl .Values.existingSecret $) -}}
{{- else -}}
    {{- printf "%s" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created
*/}}
{{- define "blobcache.createSecret" -}}
{{- if and (not .Values.existingSecret) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return blobcache service port
*/}}
{{- define "blobcache.service.port" -}}
{{- .Values.service.ports.grpc -}}
{{- end -}}

{{/*
Return blobcache service target port
*/}}
{{- define "blobcache.service.targetPort" -}}
{{- if .Values.service.targetPort.grpc -}}
{{- .Values.service.targetPort.grpc -}}
{{- else -}}
{{- .Values.service.ports.grpc -}}
{{- end -}}
{{- end -}}
