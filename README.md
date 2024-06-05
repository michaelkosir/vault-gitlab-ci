## Manual

```yaml
Tier: Free, Premium, Ultimate
Offering: GitLab.com, Self-managed, GitLab Dedicated
```


## Native Support
GitLab has selected [Vault by HashiCorp](https://www.vaultproject.io/) as the first supported provider, and [KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) as the first supported secrets engine. Use [ID tokens](https://docs.gitlab.com/ee/ci/yaml/index.html#id_tokens) to [authenticate with Vault](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication). The [Authenticating and Reading Secrets With HashiCorp Vault](https://docs.gitlab.com/ee/ci/examples/authenticating-with-hashicorp-vault/index.html) tutorial has more details about authenticating with ID tokens. You must [configure your Vault server](configure your Vault server) before you can [use Vault secrets in a CI job](use Vault secrets in a CI job).

```yaml
Tier: Premium, Ultimate
Offering: GitLab.com, Self-managed, GitLab Dedicated
```

<img src="https://docs.gitlab.com/ee/ci/img/gitlab_vault_workflow_v13_4.png">


## Vault Setup
```shell
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
  credential_type=assumed_role
  role_arns=$(terraform output -r role_arn)

# JWT Auth
export GITLAB_PROJECT_ID="..."

vault auth enable -path=gitlab jwt

vault write auth/jwt/config \
  oidc_discovery_url="https://gitlab.com" \
  bound_issuer="https://gitlab.com"

vault write auth/gitlab/role/demo - <<EOF
{
  "role_type": "jwt",
  "policies": ["example"],
  "token_ttl": 300,
  "token_max_ttl": 600,
  "user_claim": "project_id",
  "bound_claims": {
    "project_id": "$GITLAB_PROJECT_ID",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF


```