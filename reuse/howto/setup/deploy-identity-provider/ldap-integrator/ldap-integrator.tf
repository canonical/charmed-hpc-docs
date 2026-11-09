terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.0"
    }
  }
}

resource "juju_model" "identity" {
  name = "identity"
  cloud {
    name = "charmed-hpc"
  }
}

resource "juju_secret" "external_ldap_password" {
  model_uuid = juju_model.identity.uuid
  name       = "external_ldap_password"
  value = {
    password = "test"
  }
}

module "ldap_integrator" {
  source     = "git::https://github.com/canonical/ldap-integrator//terraform"
  model_uuid = juju_model.identity.uuid

  config = {
    base_dn       = "cn=testing,cn=ubuntu,cn=com"
    bind_dn       = "cn=admin,dc=test,dc=ubuntu,dc=com"
    bind_password = juju_secret.external_ldap_password.secret_uri
    starttls      = false
    urls          = "ldap://10.214.237.229"
  }

  channel = "latest/edge"
}

resource "juju_access_secret" "grant_external_ldap_password_secret" {
  applications = [module.ldap_integrator.application.name]
  model_uuid   = juju_model.identity.uuid
  secret_id    = juju_secret.external_ldap_password.secret_id
}
