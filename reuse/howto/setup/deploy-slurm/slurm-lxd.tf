module "sackd" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/sackd/terraform"
  model_uuid  = juju_model.slurm.uuid
  constraints = "virt-type=virtual-machine"
}

module "slurmctld" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmctld/terraform"
  model_uuid  = juju_model.slurm.uuid
  constraints = "virt-type=virtual-machine"
}

module "slurmd" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmd/terraform"
  model_uuid  = juju_model.slurm.uuid
  constraints = "virt-type=virtual-machine"
}

module "slurmdbd" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmdbd/terraform"
  model_uuid  = juju_model.slurm.uuid
  constraints = "virt-type=virtual-machine"
}

module "slurmrestd" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmrestd/terraform"
  model_uuid  = juju_model.slurm.uuid
  constraints = "virt-type=virtual-machine"
}

module "mysql" {
  source          = "git::https://github.com/canonical/mysql-operators//machines/terraform"
  model  = juju_model.slurm.uuid
  constraints     = "virt-type=virtual-machine"
}
