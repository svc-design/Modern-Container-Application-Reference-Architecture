https://github.com/bitnami/charts/issues/6940

Describe the bug
Mixed Content: The page at 'https://keycloak.dev.trademaster.com.br/auth/admin/master/console/' was loaded over HTTPS, but requested an insecure script 'http://keycloak.dev.trademaster.com.br/auth/js/keycloak.js?version=7a4is'. This request has been blocked; the content must be served over HTTPS

extraEnvVars:
name: KEYCLOAK_PROXY
value: reencrypt
