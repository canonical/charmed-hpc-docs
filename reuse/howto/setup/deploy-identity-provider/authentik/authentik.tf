terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.0"
    }
  }
}

resource "juju_model" "identity" {
  name       = "identity"
  credential = "charmed-hpc-k8s"
  cloud {
    name = "charmed-hpc-k8s"
  }
}

module "authentik_server" {
  source     = "git::https://github.com/canonical/authentik-server-operator//terraform"
  model_uuid = juju_model.identity.uuid
  channel    = "latest/stable"
}

module "authentik_worker" {
  source     = "git::https://github.com/canonical/authentik-worker-operator//terraform"
  model_uuid = juju_model.identity.uuid
  channel    = "latest/stable"
}

module "authentik_ldap_outpost" {
  source     = "git::https://github.com/canonical/authentik-ldap-outpost-operator//terraform"
  model_uuid = juju_model.identity.uuid
  channel    = "latest/stable"
}

module "postgresql_k8s" {
  source     = "git::https://github.com/canonical/postgresql-k8s-operator//terraform"
  model_uuid = juju_model.identity.uuid
  channel    = "14/stable"
}

module "traefik_k8s" {
  source     = "git::https://github.com/canonical/traefik-k8s-operator//terraform"
  model_uuid = juju_model.identity.uuid
  channel    = "latest/stable"
  base       = "ubuntu@26.04"
}

module "self_signed_certificates" {
  source     = "git::https://github.com/canonical/self-signed-certificates-operator//terraform"
  model_uuid = juju_model.identity.uuid
  channel    = "latest/stable"
}

resource "juju_integration" "traefik_to_self_signed_certificates" {
  model_uuid = juju_model.identity.uuid

  application {
    name     = module.traefik_k8s.application.name
    endpoint = module.traefik_k8s.requires.certificates
  }

  application {
    name     = module.self_signed_certificates.application.name
    endpoint = module.self_signed_certificates.provides.certificates
  }
}

resource "juju_integration" "authentik_server_to_postgresql" {
  model_uuid = juju_model.identity.uuid

  application {
    name = module.postgresql_k8s.app_name
  }

  application {
    name = module.authentik_server.application.name
  }
}

resource "juju_integration" "authentik_server_to_traefik" {
  model_uuid = juju_model.identity.uuid

  application {
    name = module.authentik_server.application.name
  }

  application {
    name = module.traefik_k8s.application.name
  }
}

resource "juju_integration" "authentik_ldap_outpost_to_traefik" {
  application {
    name = module.authentik_ldap_outpost.application.name
  }

  application {
    name = module.traefik_k8s.application.name
  }
}

resource "juju_integration" "authentik_server_to_worker" {
  model_uuid = juju_model.identity.uuid

  application {
    name = module.authentik_server.application.name
  }

  application {
    name = module.authentik_worker.application.name
  }
}

resource "juju_integration" "authentik_server_to_ldap_outpost" {
  model_uuid = juju_model.identity.uuid

  application {
    name = module.authentik_server.application.name
  }

  application {
    name = module.authentik_ldap_outpost.application.name
  }
}
