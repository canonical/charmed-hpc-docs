terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.0"
    }
  }
}

data "juju_model" "identity" {
  name  = "identity"
  owner = "admin"
}

data "juju_model" "slurm" {
  name  = "slurm"
  owner = "admin"
}

data "juju_application" "sssd" {
  model_uuid = data.juju_model.slurm.uuid
  name       = "sssd"
}

module "manual_tls_certificates" {
  source     = "git::https://github.com/canonical/manual-tls-certificates-operator//terraform"
  model_uuid = data.juju_model.identity.uuid

  config = {
    trusted-certificate-bundle = file("bundle.pem")
  }

  channel = "1/stable"
}

resource "juju_offer" "send_ldap_certs" {
  model_uuid       = data.juju_model.identity.uuid
  application_name = module.manual_tls_certificates.app_name
  endpoints        = ["trust_certificate"]
  name             = "send-ldap-certs"
}

resource "juju_integration" "sssd_to_send_ldap_certs" {
  model_uuid = data.juju_model.slurm.uuid

  application {
    name = data.juju_application.sssd.name
  }

  application {
    offer_url = juju_offer.send_ldap_certs.url
  }
}
