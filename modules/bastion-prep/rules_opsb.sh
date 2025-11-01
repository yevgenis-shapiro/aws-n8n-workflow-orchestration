  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itom-ingress-controller-svc-internal" TLS 30443 443
  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "omi-bbc" TCP 383 383
  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itom-opsbridge-des-nodeport" TCP 6060 30010

  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itom-di-receiver-svc" TCP 5050 30001
  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itom-di-data-access-svc" TCP 28443 30003
  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itom-di-administration-svc" TCP 18443 30004
  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itomdipulsar-proxy" TCP 6651 31051
  addListenerForService "$external_nlb" "$SUITE_NAMESPACE" "itomdipulsar-proxy" TCP 8443 31001
