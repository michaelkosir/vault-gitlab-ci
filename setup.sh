#!/bin/bash

# Policy
vault policy write example - <<EOF
path "kv/data/prod/example" {
  capabilities = ["read"]
}
path "aws/sts/deploy" {
  capabilities = ["read"]
}
EOF

# KV Secrets
vault secrets enable -version=2 kv
vault kv put kv/prod/example apikey=$(uuidgen)

# AWS Secrets
vault secrets enable aws

vault write -f aws/config/root

vault write aws/roles/deploy \
  credential_type=assumed_role \
  role_arns="$AWS_ROLE_ARN"

# JWT Auth
vault auth enable -path=gitlab jwt

vault write auth/gitlab/config \
  oidc_discovery_url="https://gitlab.com" \
  bound_issuer="https://gitlab.com"

vault write auth/gitlab/role/demo - <<EOF
{
  "role_type": "jwt",
  "policies": ["example"],
  "token_ttl": 300,
  "token_max_ttl": 600,
  "user_claim": "project_path",
  "bound_audiences": ["https://vault.example.com"],
  "bound_claims": {
    "project_id": "$GITLAB_PROJECT_ID",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF

# then go to GitLab and update
# `.gitlab-ci.yml` with Vault Address
