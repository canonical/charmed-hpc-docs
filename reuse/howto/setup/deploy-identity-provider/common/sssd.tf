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
  name       = "sackd"
}

data "juju_application" "slurmctld" {
  model_uuid = data.juju_model.slurm.uuid
  name       = "slurmctld"
}

data "juju_application" "slurmd" {
  model_uuid = data.juju_model.slurm.uuid
  name       = "slurmd"
}

module "sssd" {
  source     = "git::https://github.com/canonical/sssd-operator//terraform"
  model_uuid = data.juju_model.slurm.uuid
}

resource "juju_integration" "sssd_to_sackd" {
  model_uuid = data.juju_model.slurm.uuid

  application {
    name = module.sssd.application.name
  }

  application {
    name = data.juju_application.sackd.name
  }
}

resource "juju_integration" "sssd_to_slurmctld" {
  model_uuid = data.juju_model.slurm.uuid

  application {
    name = module.sssd.application.name
  }

  application {
    name = data.juju_application.slurmctld.name
  }
}

resource "juju_integration" "sssd_to_slurmd" {
  model_uuid = data.juju_model.slurm.uuid

  application {
    name = module.sssd.application.name
  }

  application {
    name = data.juju_application.slurmd.name
  }
}
