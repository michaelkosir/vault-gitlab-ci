## Overview
CI/CD pipelines need to securely access secrets and other sensitive values and authenticate to external services and deploy applications, infrastructure, or other automated processes. HashiCorp Vault is a central system to store and access data, which enables CI/CD pipelines to programmatically push and pull secrets.

GitLab uses JSON Web Token (JWT) to authenticate with Vault to securely access secrets for CI/CD pipelines. Once authenticated, GitLab can pull static secrets from the KV secrets engine, or dynamic secrets from engines such as the AWS secrets engine.

### Diagram
<img src="https://docs.gitlab.com/ee/ci/img/gitlab_vault_workflow_v13_4.png">


## Gitlab CI
### Manual
```yaml
job:
  image: hashicorp/vault:1.16
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  script:
    - export VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=example jwt=$VAULT_ID_TOKEN)
    - export API_KEY=$(vault kv get -field=apikey kv/prod/example)
```

### Native Support
GitLab has selected [Vault by HashiCorp](https://www.vaultproject.io/) as the first supported provider, and [KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) as the first supported secrets engine. Use [ID tokens](https://docs.gitlab.com/ee/ci/yaml/index.html#id_tokens) to [authenticate with Vault](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication). The [Authenticating and Reading Secrets With HashiCorp Vault](https://docs.gitlab.com/ee/ci/examples/authenticating-with-hashicorp-vault/index.html) tutorial has more details about authenticating with ID tokens. You must [configure your Vault server](configure your Vault server) before you can [use Vault secrets in a CI job](use Vault secrets in a CI job).

```yaml
Tier: Premium, Ultimate
```

```yaml
job:
  image: alpine:3
  id_tokens:
    VAULT_ID_TOKEN:
      aud: "https://vault.example.com"
  secrets:
    API_KEY:
      file: false
      vault: prod/example/apikey@kv 
    AWS:
      file: false
      vault:
        engine:
          name: generic
          path: aws
        path: sts/deploy
        field: data
```

## Usage
### Infrastructure Setup
```shell
git clone https://gitlab.com/michaelkosir/vault-gitlab-ci.git
cd vault-gitlab-ci/tf
terraform apply
# update `.gitlab-ci.yml` with `vault_addr` output
```

### Vault Setup
```shell
export VAULT_ADDR=$(terraform output -raw vault_addr)
export VAULT_TOKEN="root"

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
  role_arns=$(terraform output -raw role_arn)

# JWT Auth
export GITLAB_PROJECT_ID="..."

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
  "user_claim": "project_id",
  "bound_audiences": ["https://vault.example.com"],
  "bound_claims": {
    "project_id": "$GITLAB_PROJECT_ID",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF

```
