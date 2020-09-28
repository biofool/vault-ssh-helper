#! dash
##  Viarables
sudo ./newpackages.#!/bin/sh
sudo ./update-pamd.sh


export VAULT_ADDR=https://127.0.0.1:8200/
export VAULT_ADDR=https://54.218.83.33:8200/
export VAULT_ADDR=https://vault.secureyourdata.org:8200/

export GH_ORG=cabw
vault secrets enable --tls-skip-verify -path=ssh-client ssh
vault audit --tls-skip-verify enable syslog
vault audit --tls-skip-verify list
vault audit enable --tls-skip-verify file file_path="/var/tmp/audit.log"

# Create the role
vault write --tls-skip-verify ssh-client/roles/otp_key_role key_type=otp default_user=root cidr_list=0.0.0.0/0
vault write --tls-skip-verify ssh/roles/otp_key_role key_type=otp default_user=root cidr_list=0.0.0.0/0
# Create the credential
vault login --tls-skip-verify
vault write --tls-skip-verify ssh-client/creds/otp_key_role ip=127.0.0.1
vault ssh --tls-skip-verify  -role otp_key_role -mode otp -strict-host-key-checking=no -mount-point=ssh-client root@127.0.0.1
vault ssh --tls-skip-verify  -role otp_key_role -mode otp -strict-host-key-checking=no -mount-point=ssh-client ubuntu@127.0.0.1
vault token lookup --tls-skip-verify
https://www.vaultproject.io/docs/secrets/ssh/one-time-ssh-passwords.html
# Remove sshpass for testing
sudo tee /etc/vault-ssh-helper.d/config.hcl <<EOF
vault_addr = "https://127.0.0.1:8200"
tls_skip_verify = false
ssh_mount_point = "ssh"
allowed_roles = "*"
EOF
vault ssh  --tls-skip-verify -role otp_key_role -mode otp test@localhost
vault auth enable --tls-skip-verify github
vault write --tls-skip-verify auth/github/config organization=$GH_ORG
