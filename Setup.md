We can now install some required dependencies and then Vault itself:

sudo apt install python-certbot-apache
sudo apt install fail2ban links2
sudo apt install golang gox
sudo apt install sshpass

export VAULT_VERSION=1.5.3
curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS
grep "vault_${VAULT_VERSION}_linux_amd64.zip" vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c -

unzip -q vault_${VAULT_VERSION}_linux_amd64.zip
cp vault /usr/local/bin/

We can now configure and launch Vault using some development settings:

mkdir hvault
cat > config.hcl <<EOF
listener "tcp" {
    address     = "0.0.0.0:8200"
    tls_disable = true # don't do this in production - always use TLS in prod
}

storage "file" {
    path = "./hvault"
}

disable_mlock = true # don't do this in production either
# ^ setting this to true allows leaking of sensitive data to disk/swap
# we're doing it here to avoid running the process as root
# or modifying any system tunables
EOF

vault server -config=config.hcl

This will launch the server in the foreground, so we’ll want to connect to the Docker container in a new terminal:

docker exec -ti vault /bin/bash

Now we can configure Vault as a client and make sure we have a connection:

export VAULT_ADDR="http://127.0.0.1:8200"
echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
vault status

Finally, we can initialise Vault to make it ready to use:

vault operator init -key-shares=1 -key-threshold=1

# this will give you a vault token and an unseal key.  Use these now:

read -s -p "Initial Root Token: " vault_token
echo $vault_token > ~/.vault-token

vault operator unseal # provide 'Unseal Key 1:'

vault token lookup

Now we have Vault running, a client connected, and have made sure we have a valid token. The next step is to enable the secrets engine:

vault secrets enable -path=ssh-client ssh

We can then create a role which will allow us to ssh as the root user to any of our SSH servers (any IP address):

vault write ssh-client/roles/otp_key_role key_type=otp default_user=root cidr_list=0.0.0.0/0

With that in place, we now need to configure our SSH servers to use the vault-ssh-helper. First of all we need to download and configure the vault-ssh-helper tool itself:

curl -C - -k https://releases.hashicorp.com/vault-ssh-helper/0.1.4/vault-ssh-helper_0.1.4_linux_amd64.zip -o vault-ssh-helper.zip
unzip vault-ssh-helper.zip
mv vault-ssh-helper /usr/local/bin/

mkdir /etc/vault-ssh-helper.d
cat > /etc/vault-ssh-helper.d/config.hcl << EOL
vault_addr = "http://172.17.0.2:8200"
ssh_mount_point = "ssh-client"
ca_cert = "/etc/vault-ssh-helper.d/vault.crt"
tls_skip_verify = false
allowed_roles = "*"
EOL
vault-ssh-helper -dev -verify-only -config=/etc/vault-ssh-helper.d/config.hcl

Then we need to configure both PAM and SSHD to use vault-ssh-helper:

cat > /etc/pam.d/sshd << EOL
#%PAM-1.0
auth        required    pam_sepermit.so
#auth       substack    password-auth # COMMENT OUT FOR SSH-HELPER
auth        include     postlogin
auth        requisite   pam_exec.so quiet expose_authtok log=/var/log/vaultssh.log /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-ssh-helper.d/config.hcl
auth        optional    pam_unix.so not_set_pass use_first_pass nodelay
# Used with polkit to reauthorize users in remote sessions
-auth       optional    pam_reauthorize.so prepare
account     required    pam_nologin.so
account     include     password-auth
#password   include     password-auth # COMMENT OUT FOR SSH-HELPER
# pam_selinux.so close should be the first session rule
session     required    pam_selinux.so close
session     required    pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session     required    pam_selinux.so open env_params
session     required    pam_namespace.so
session     optional    pam_keyinit.so force revoke
session     include     password-auth
session     include     postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
EOL

vi /etc/ssh/sshd_config
# Set the following three options:
# ChallengeResponseAuthentication yes
# PasswordAuthentication no 
# UsePAM yes

And finally, because we are in a container without systemd access, we’ll cheat and run sshd ourselves rather than via systemd:

/usr/sbin/sshd-keygen
/usr/sbin/sshd -f /etc/ssh/sshd_config

We are now fully setup and ready to use ssh with vault. Let’s ask for access to 127.0.0.1, and then ssh in:

vault write ssh-client/creds/otp_key_role ip=127.0.0.1
vault ssh -role otp_key_role -mode otp -strict-host-key-checking=no -mount-point=ssh-client root@127.0.0.1
