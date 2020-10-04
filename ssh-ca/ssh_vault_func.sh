ssh_vault () {
  export SSH_USER="$(whoami)"
  export SSH_SERVER="<ssh_host>"
  export VAULT_ADDR="http://<vault_dns>:8200"
  rm -f token ssh-ca.json .ssh/id_rsa_${SSH_USER}*
  ssh-keygen -t rsa -N "" -C "${SSH_USER}" -f .ssh/id_rsa_${SSH_USER}
  export public_key=$(cat .ssh/id_rsa_${SSH_USER}.pub)
  curl -s \
      --request POST \
      --data '{"password": "test"}' \
      ${VAULT_ADDR}/v1/auth/userpass/login/${SSH_USER} | jq -r .auth.client_token > token
  export VAULT_TOKEN=$(cat token)
  curl -s \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request POST \
    --data "{\"public_key\":\"${public_key}\",\"valid_principals\":\"${SSH_USER}\"}" \
    $VAULT_ADDR/v1/ssh-client-signer/sign/clientrole | jq -r .data.signed_key > .ssh/id_rsa_${SSH_USER}.signed.pub
  chmod 400 .ssh/id_rsa_${SSH_USER}*
  ssh -i .ssh/id_rsa_${SSH_USER}.signed.pub -i .ssh/id_rsa_${SSH_USER} ${SSH_USER}@${SSH_SERVER}
}
