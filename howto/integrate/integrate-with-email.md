---
myst:
  html_meta:
    description: Instructions on how to integrate Charmed HPC with an SMTP mail server to enable Slurm job email notifications for cluster users.
---

(howto-integrate-email-notifications)=
# Integrate with a mail server for job notifications

This how-to guide demonstrates the steps necessary to integrate with an external Simple Mail
Transport Protocol (SMTP) server, also referred to as a mail server, to enable email notifications
of user job status changes on a Charmed HPC cluster.

## Prerequisites

* A [deployed Slurm cluster](howto-deploy-deploy-slurm).
* A pre-configured SMTP server.

:::{admonition} `slurmdbd` must be deployed
:class: warning

Your Slurm cluster __must__ have been deployed with a `slurmdbd` accounting database. If `slurmdbd`
is not available, attempts to integrate with an SMTP server will result in `slurmctld`
entering `Waiting` status until `slurmdbd` is integrated.
:::

## Deployment

Deploy the [`smtp-integrator` charm](https://charmhub.io/smtp-integrator) configured against the
SMTP server, then integrate with the cluster `slurmctld` controller on the `smtp` interface:

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

:::{code-block} shell
juju deploy smtp-integrator --config host=smtp.example.com --config port=587
juju integrate slurmctld smtp-integrator:smtp
:::

::::

::::{tab-item} Terraform
:sync: terraform

:::{code-block} terraform
:caption: `main.tf`
module "smtp_integrator" {
  source = "git::https://github.com/canonical/smtp-integrator-operator//terraform"
  model_uuid = juju_model.slurm.uuid
  config = {
    host = "smtp.example.com"
    port = 587
  }
}

resource "juju_integration" "smtp_integrator_to_slurmctld" {
  model_uuid = juju_model.slurm.uuid

  application {
    name     = module.slurmctld.app_name
    endpoint = module.slurmctld.requires.smtp
  }

  application {
    name     = module.smtp_integrator.app_name
    endpoint = module.smtp_integrator.provides.smtp
  }
}
:::

::::

:::::

Refer to the [`smtp-integrator` documentation](https://charmhub.io/smtp-integrator/configurations)
for all configuration options for connecting to an SMTP server.

Once integrated, users can include the [`--mail-type`](https://slurm.schedmd.com/sbatch.html#OPT_mail-type)
and [`--mail-user`](https://slurm.schedmd.com/sbatch.html#OPT_mail-user) SBATCH directives in their
job submissions and receive email notifications.

(howto-manage-customize-job-email-name)=
## Customize job notification sender name

This section requires that the Slurm cluster has been integrated with a mail server to enable job
notifications.

To customize the name that appears in the sign-off of email notifications sent by Slurm, set the
`slurmctld` configuration value `email-from-name`:

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

:::{code-block} shell
juju config slurmctld email-from-name="The my-cluster-name Admin Team"
:::

::::

::::{tab-item} Terraform
:sync: terraform

:::{code-block} terraform
:caption: `main.tf`
module "slurmctld" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmctld/terraform"
  model_uuid  = juju_model.slurm.uuid
  config = {
    email-from-name = "The my-cluster-name Admin Team"
  }
}
:::

::::

:::::

## Related topics

Explanation:

* {ref}`explanation-job-email-notifications`