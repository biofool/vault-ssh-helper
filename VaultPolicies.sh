#! dash
##  Viarables
export VAULT_ADDR=https://127.0.0.1:8200/
export VAULT_ADDR=https://54.218.83.33:8200/
export VAULT_ADDR=https://vault.secureyourdata.org:8200/

export GH_ORG=InsightVault
cd /etc/vault.d
sudo tee /etc/vault.d/admin-policy.hcl <<EOF
# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at `secret/` path

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}
EOF
python VaultPolicies.py
if [$? == 0]; then
  echo $ADMIN_TOKEN
else
  exit (1)

fi  #statements
vault token capabilities --tls-skip-verify $ADMIN_TOKEN sys/auth/approle
vault token capabilities --tls-skip-verify $ADMIN_TOKEN identity/entity

#Date:   Mon Sep 28 06:15:05 2020 +0000
vault policy write --tls-skip-verify developers developers.hcl
vault auth enable  --tls-skip-verify github
vault auth list  --tls-skip-verify -format=json | jq -r '.["github/"].accessor' > accessor.txt
vault write --tls-skip-verify auth/github/config organization=${GH_ORG}
 > developers.txt
