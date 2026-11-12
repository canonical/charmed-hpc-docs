terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.0"
    }
  }
}

data "juju_model" "slurm" {
  name  = "slurm"
  owner = "admin"
}


data "juju_application" "sackd" {
  model_uuid = data.juju_model.slurm.uuid
  name       = "sssd"
}

data "juju_application" "sssd" {
  model_uuid = data.juju_model.slurm.uuid
  name       = "sssd"
}

module "openssh" {
  source     = "git::https://github.com/canonical/ldap-integrator//terraform"
  model_uuid = data.juju_model.slurm.uuid

  base    = "ubuntu@26.04"
  channel = "10/stable"
}

resource "juju_application" "openssh_to_sackd" {
  model_uuid = data.juju_model.slurm.uuid

  application {
    name = module.openssh.application.name
  }

  application {
    name = data.juju_application.sackd.name
  }

}

resource "juju_application" "openssh_to_sssd" {
  model_uuid = data.juju_model.slurm.uuid

  application {
    name     = module.openssh.application.name
    endpoint = module.openssh.requires.ssh-config
  }

  application {
    name     = data.juju_application.sssd.name
    endpoint = "ssh-config"
  }
}
