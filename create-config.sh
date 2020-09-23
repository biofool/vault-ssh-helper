sudo mkdir /etc/vault-helper
sudo tee -a /etc/vault-helper/config.hcl <<EOHCL
vault_addr = "https://vault.example.com:8200"
ssh_mount_point = "ssh"
namespace = "my_namespace"
ca_cert = "/etc/vault-ssh-helper.d/vault.crt"
tls_skip_verify = true
allowed_roles = "*"
EOHCL
