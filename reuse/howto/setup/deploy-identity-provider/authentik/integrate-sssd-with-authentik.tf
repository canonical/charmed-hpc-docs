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

data "juju_application" "authentik_ldap_outpost" {
  model_uuid = data.juju_model.identity.uuid
  name       = "authentik-ldap-outpost"
}

data "juju_application" "self_signed_certificates" {
  model_uuid = data.juju_model.identity.uuid
  name       = "self-signed-certificates"
}

data "juju_application" "sssd" {
  model_uuid = data.juju_model.slurm.uuid
  name       = "sssd"
}

resource "juju_offer" "ldaps" {
  model_uuid       = data.juju_model.identity.uuid
  application_name = data.juju_application.authentik_ldap_outpost.name
  endpoints        = ["ldap"]
  name             = "ldaps"
}

resource "juju_offer" "send_ca_cert" {
  model_uuid       = data.juju_model.identity.uuid
  application_name = data.juju_application.self_signed_certificates.name
  endpoints        = ["send-ca-cert"]
  name             = "send-ca-cert"
}

resource "juju_integration" "sssd_to_ldaps" {
  application {
    name = data.juju_application.sssd.name
  }

  application {
    offer_url = juju_offer.ldaps.url
  }
}

resource "juju_integration" "sssd_to_send_ca_cert" {
  application {
    name = data.juju_application.sssd.name
  }

  application {
    offer_url = juju_offer.send_ca_cert.url
  }
}
