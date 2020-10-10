#! /bin/dash
##  Variables
sudo ./newpackages.#!/bin/sh
sudo ./update-pamd.sh


export VAULT_ADDR=https://54.218.83.33:8200/
export VAULT_ADDR=https://vault.secureyourdata.org:8200/
export VAULT_ADDR=https://127.0.0.1:8200/
export SSHPASS=''
export GH_ORG=cabw
export VAULT_TOKEN='s.ziWMd5zIPi7DgFj6lsoj7ZoL'
vault secrets   enable --tls-skip-verify -path=ssh-client-signer ssh
vault write ssh-client-signer/config/ca generate_signing_key=true
vault read -field=public_key ssh-client-signer/config/ca > trusted-user-ca-keys.pem

vault secrets enable --tls-skip-verify -path=ssh-client ssh
#vault audit --tls-skip-verify enable syslog
vault audit --tls-skip-verify list
vault audit enable --tls-skip-verify file file_path="/var/tmp/audit.log"
vault write  --tls-skip-verify ssh-client-signer/config/ca generate_signing_key=true
vault read --tls-skip-verify -field=public_key ssh-client-signer/config/ca > trusted-user-ca-keys.pem
vault policy write --tls-skip-verify   user user-policy.hcl
vault auth enable --tls-skip-verify userpass
#  Modify authentication can be sourced from an existing identity source such as LDAP, Git etc.
vault write --tls-skip-verify auth/userpass/users/ubuntu password=test policies=user
vault write --tls-skip-verify auth/userpass/users/ec2-user password=test policies=user
vault write --tls-skip-verify auth/userpass/users/$(whoami) password=test policies=user

# Add role to Vault: Allow client to sign their public key using vault. Adjust TTL, allowed users here if needed.
#allow_user_certificates declares that this role will be for signing user certificates, instead of host certificates
#allowed_users: allows this role to sign for any users. If, for example, you wanted to create a role which allowed only keys for a particular service name (say you wanted only to sign keys for an ansible user if you were using Ansible)
#default_extensions sets the default certificate options when it signs the key. In this case, permit-pty allows the key to get a PTY on login, permitting interactive terminal sessions. For more information, consult the ssh-keygen
vault write --tls-skip-verify ssh-client-signer/roles/clientrole @signer-clientrole.json

#    SFTP the trusted-user-ca-keys.pem from step VAULT-02A
#    Then add the TrustedUserCAKeys directive to ssh_config file


sudo cp trusted-user-ca-keys.pem /etc/ssh/
echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" | sudo tee -a /etc/ssh/sshd_config
sudo service sshd restart
sudo service sshd status

#CLIENT-01 - OpenSSH Client Setup
#CLIENT-01A - Create key pair and sign with Vault:
#
#    Create key pair. Note that ssh_user must exist in on the server
export SSH_USER="ubuntu"
export SSH_SERVER="ssh-server"
export VAULT_ADDR="http://54.69.224.33:8200"
ssh-keygen -t rsa -N "" -C "${SSH_USER}" -f .ssh/id_rsa_${SSH_USER}
export public_key=$(cat .ssh/id_rsa_${SSH_USER}.pub)
echo ${public_key}

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
