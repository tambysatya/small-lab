#!/usr/bin/env bash

source scripts/functions.sh

DOMAIN="local.fr"
CA_NAME="ca.$DOMAIN"


echo "Bootstraping CA" | boxes -d ansi
generate_step_ca $CA_NAME


echo "Bootstraping Provisioning TLS cert" | boxes -d ansi
generate_certificate $DOMAIN "vm-provisioning"

echo "Bootstraping age keys " | boxes -d ansi
generate_age_keypair "identity"
generate_age_keypair "storage"
generate_age_keypair "postgres"
generate_age_keypair "apps"

echo "Encrypting CA secrets and configuration" | boxes -d ansi
encrypt_CA "identity"




echo "Bootstraping tokens " | boxes -d ansi
blue "Keycloak (database password)"
generate_secret "keycloak-keycloak-db" 

blue "Garage (RPC secret, admin token and metrics token)"
generate_secret "garage-rpc" #rpc-secret
generate_secret "garage-admin" #admin token
generate_secret "garage-metrics" #metrics token

blue "Nextcloud (POSTGRES password, admin password and S3 keypair "
generate_secret "nextcloud-nextcloud-db" # postgres password
generate_secret "nextcloud-admin" # admin password
generate_s3_keypair "nextcloud" "nextcloud" # s3 API key

blue "LDAP admin password"
generate_secret "ldap-adminpass"
cat "secrets/plain/tokens/ldap-adminpass.key" | slappasswd -s -- -h "{SSHA}" > "secrets/plain/ldap-adminpass.ssha"

echo "Encrypting tokens" | boxes -d ansi
encrypt_secret "identity" "keycloak-keycloak-db"
encrypt_secret "postgres" "keycloak-keycloak-db"

encrypt_secret "storage" "garage-rpc"
encrypt_secret "storage" "garage-admin"
encrypt_secret "storage" "garage-metrics"

encrypt_secret "postgres" "nextcloud-nextcloud-db"
encrypt_secret "apps" "nextcloud-nextcloud-db"

encrypt_secret "apps" "nextcloud-admin"
encrypt_s3 "apps" "nextcloud"
encrypt_s3 "storage" "nextcloud-nextcloud"



echo "Bootstraping Encrypted TLS certificates" | boxes -d ansi
blue "Identity VM"
generate_encrypted_certificate $DOMAIN "identity" "auth" 
generate_encrypted_certificate $DOMAIN "identity" "openldap"

blue "Storage VM"
generate_encrypted_certificate $DOMAIN "storage" "s3"
generate_encrypted_certificate $DOMAIN "storage" "s3-admin"

blue "Postgres VM"
generate_encrypted_certificate $DOMAIN "postgres" "postgres"

blue "Apps VM"
generate_encrypted_certificate $DOMAIN "apps" "nextcloud"





