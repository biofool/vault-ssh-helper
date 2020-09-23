sudo cp /etc/pam.d/sshd .
sudo tee //etc/pam.d/sshd<<EOSSHD
#@include common-auth
auth requisite pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl
auth optional pam_unix.so not_set_pass use_first_pass nodelay
EOSSHD
grep -v "@include common-auth" sshd |tee -a /etc/pam.d/sshd
