#!/usr/bin/env bash
# prep.sh — CRD Question Lab Prep
set -euo pipefail

OUT_RES="$HOME/resources.yaml"
OUT_SUB="$HOME/subject.yaml"

rm -f "$OUT_RES" "$OUT_SUB"

kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: certificates.cert-manager.io
spec:
  group: cert-manager.io
  scope: Namespaced
  names:
    plural: certificates
    singular: certificate
    kind: Certificate
    shortNames:
      - cert
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                subject:
                  type: object
                  description: Subject configuration for the x509 certificate.
                  properties:
                    organizations:
                      type: array
                      items:
                        type: string
                    countries:
                      type: array
                      items:
                        type: string
                    localities:
                      type: array
                      items:
                        type: string
                    provinces:
                      type: array
                      items:
                        type: string
                    streetAddresses:
                      type: array
                      items:
                        type: string
                    postalCodes:
                      type: array
                      items:
                        type: string
                    serialNumber:
                      type: string
              required: []
EOF

kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: issuers.cert-manager.io
spec:
  group: cert-manager.io
  scope: Namespaced
  names:
    plural: issuers
    singular: issuer
    kind: Issuer
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
EOF

echo "✅ Prep complete."
echo "Solve the question by creating:"
echo "  - ~/resources.yaml"
echo "  - ~/subject.yaml"
