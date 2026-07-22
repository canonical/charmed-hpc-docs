---
myst:
  html_meta:
    description: Instructions on how to use Juju to deploy and integrate an LDAP-based identity provider with SSSD to provide remote users to a Charmed HPC cluster.
---

(howto-deploy-deploy-identity-provider)=
# How to deploy an identity provider

An identity provider must be deployed and integrated with Charmed HPC to supply your cluster with
user and group information. This guide provides you with different options for how to set up an
identity provider for your Charmed HPC cluster.

Follow the instructions in the {ref}`identity-external-ldap-server-with-sssd`
section if you have an existing, external LDAP server that you want to use with your
Charmed HPC cluster.

Follow the instructions in the {ref}`identity-glauth-with-sssd` section if you are
experimenting with Charmed HPC or are deploying a small Charmed HPC cluster.

(identity-external-ldap-server-with-sssd)=
## External LDAP server with SSSD

This section shows you how to use an external LDAP server as your Charmed HPC cluster's
identity provider, and SSSD as the client for integrating your cluster's login and compute
nodes to the external LDAP server.

The [ldap-integrator](https://charmhub.io/ldap-integrator) charm is used to proxy your
external LDAP server's configuration information to other charmed applications.

### Prerequisites

- An active [Slurm deployment](#howto-deploy-deploy-slurm) in your [`charmed-hpc` machine cloud](#howto-initialize-machine-cloud).
- The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine.

### Deploy ldap-integrator and SSSD

You have two options for deploying ldap-integrator and SSSD:

1. Using the [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/reference/juju-cli/).
2. Using the [Juju Terraform client](https://canonical-terraform-provider-juju.readthedocs-hosted.com/latest/).

If you want to use Terraform to deploy ldap-integrator and SSSD, see the
[Manage `terraform-provider-juju`](https://canonical-terraform-provider-juju.readthedocs-hosted.com/latest/howto/manage-the-terraform-provider-for-juju/) how-to guide for additional
requirements.

#### Deploy ldap-integrator

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, use `juju add-model`{l=shell} to create the `identity` model on your
`charmed-hpc` machine cloud:

:::{code-block} shell
juju add-model identity charmed-hpc
:::

Now use `juju add-secret`{l=shell} to create a secret for your external LDAP server's bind password.
In this example, the external LDAP server's bind password is `"test"`:

:::{code-block} shell
secret_id=$(juju add-secret external_ldap_password password="test")
:::

Next, use `juju deploy`{l=shell} with the `--config`{l=shell} flag to deploy
ldap-integrator with your external LDAP server's configuration information. In this
example, the external LDAP server's:

- `base_dn` is `"cn=testing,cn=ubuntu,cn=com"`.
- `bind_dn` is `"cn=admin,dc=test,dc=ubuntu,dc=com"`.
- `bind_password` is `"test"`.
- `starttls` mode is disabled.
- `urls` are `"ldap://10.214.237.229"`.

For further customization, see [the full list of ldap-integrator's available configuration options](https://charmhub.io/ldap-integrator/configurations).

:::{code-block} shell
juju deploy ldap-integrator --channel "edge" \
  --config base_dn="cn=testing,cn=ubuntu,cn=com" \
  --config bind_dn="cn=admin,dc=test,dc=ubuntu,dc=com" \
  --config bind_password="${secret_id}" \
  --config starttls=false \
  --config urls="ldap://10.214.237.229"
:::

After that, use `juju grant-secret`{l=shell} to grant the ldap-integrator application
access to your external LDAP server's bind password:

:::{code-block} shell
juju grant-secret external_ldap_password ldap-integrator
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file
_{{ ldap_integrator_tf_file }}_ using `mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir ldap-integrator
touch ldap-integrator/main.tf
:::

Now open _{{ ldap_integrator_tf_file }}_ in a text editor and add the Juju Terraform provider
to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/ldap-integrator.tf
:caption: {{ ldap_integrator_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, create the `identity` model on your `charmed-hpc` machine cloud:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/ldap-integrator.tf
:caption: {{ ldap_integrator_tf_file }}
:language: terraform
:lines: 10-15
:::

Next, create the `external_ldap_password` secret in the `identity` model. In this example,
the external LDAP server's bind password is `"test"`:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/ldap-integrator.tf
:caption: {{ ldap_integrator_tf_file }}
:language: terraform
:lines: 17-23
:::

:::{admonition} Securely setting the external LDAP server's bind password in a Juju secret
:class: note

You can use Terraform's [built-in `file` function](https://developer.hashicorp.com/terraform/language/functions/file)
to read in your bind password from a secure file rather provide
it as plain text in the _{{ ldap_integrator_tf_file }}_ plan.
:::

Now deploy ldap-integrator. In this example, the external LDAP server's:

- `base_dn` is `"cn=testing,cn=ubuntu,cn=com"`.
- `bind_dn` is `"cn=admin,dc=test,dc=ubuntu,dc=com"`.
- `bind_password` is `"test"`.
- `starttls` mode is disabled.
- `urls` are `"ldap://10.214.237.229"`.

For further customization, see [the full list of ldap-integrator's available configuration options](https://charmhub.io/ldap-integrator/configurations).

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/ldap-integrator.tf
:caption: {{ ldap_integrator_tf_file }}
:language: terraform
:lines: 25-38
:::

Next, grant the ldap-integrator application access to the `external_ldap_password` secret:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/ldap-integrator.tf
:caption: {{ ldap_integrator_tf_file }}
:language: terraform
:lines: 40-44
:::

You can expand the dropdown below to see the full _{{ ldap_integrator_tf_file }}_
Terraform configuration file. Now use the `terraform`{l=shell} command to apply
your configuration:

:::{code-block} shell
terraform -chdir=ldap-integrator init
terraform -chdir=ldap-integrator apply -auto-approve
:::

:::{dropdown} Full _{{ ldap_integrator_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/ldap-integrator.tf
:caption: {{ ldap_integrator_tf_file }}
:language: terraform
:linenos:
:::
:::

::::

:::::

Your ldap-integrator application will become active within a few minutes. The output
of `juju status`{l=shell} will be similar to the following:

:::{terminal}
:scroll:

juju status

Model     Controller              Cloud/Region         Version  SLA          Timestamp
identity  charmed-hpc-controller  localhost/localhost  3.6.28   unsupported  12:52:02-06:00

App              Version  Status  Scale  Charm            Channel      Rev  Exposed  Message
ldap-integrator           active      1  ldap-integrator  latest/edge   38  no

Unit                Workload  Agent  Machine  Public address  Ports  Message
ldap-integrator/0*  active    idle   0        10.124.231.240

Machine  State    Address         Inst id        Base          AZ  Message
0        started  10.124.231.240  juju-be6f35-0  ubuntu@24.04      Running
:::

You now need to deploy SSSD in your `slurm` model to enroll your cluster's
machines with the external LDAP server.

#### Deploy SSSD

:::{include} /reuse/howto/setup/deploy-identity-provider/common/deploy-sssd.txt
:::

You now need to integrate SSSD with the ldap-integrator application in your `identity` model so that
the SSSD application can activate and enroll your machines with the external LDAP server.

#### Integrate SSSD with ldap-integrator

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, create an offer from the ldap-integrator application in your `identity` model
with `juju offer`{l=shell}:

:::{code-block} shell
juju offer identity.ldap-integrator:ldap ldap
:::

Next, use `juju consume` to consume the offer from your ldap-integrator
application in your `slurm` model:

:::{code-block} shell
juju consume identity.ldap
:::

After that, use `juju integrate` to integrate SSSD with ldap-integrator:

:::{code-block} shell
juju integrate ldap sssd
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform plan _{{ integrate_sssd_with_ldap_integrator_tf_file }}_
using `mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir integrate-sssd-with-ldap-integrator
touch integrate-sssd-with-ldap-integrator/main.tf
:::

Now open _{{ integrate_sssd_with_ldap_integrator_tf_file }}_ in a text editor and
add the Juju Terraform provider to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/integrate-sssd-with-ldap-integrator.tf
:caption: {{ integrate_sssd_with_ldap_integrator_tf_file }}
:language: terraform
:lines: 1-8
:::

After that, declare data sources for the `identity` and `slurm` models,
and the ldap-integrator and SSSD applications:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/integrate-sssd-with-ldap-integrator.tf
:caption: {{ integrate_sssd_with_ldap_integrator_tf_file }}
:language: terraform
:lines: 10-28
:::

Now create an offer from the ldap-integrator application in your `identity` model:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/integrate-sssd-with-ldap-integrator.tf
:caption: {{ integrate_sssd_with_ldap_integrator_tf_file }}
:language: terraform
:lines: 30-35
:::

Next, integrate SSSD with ldap-integrator:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/integrate-sssd-with-ldap-integrator.tf
:caption: {{ integrate_sssd_with_ldap_integrator_tf_file }}
:language: terraform
:lines: 37-47
:::

You can expand the dropdown below to see the full _{{ integrate_sssd_with_ldap_integrator_tf_file }}_ Terraform
configuration file. Now use the `terraform`{l=shell} command to apply your configuration.

:::{code-block} shell
terraform -chdir=integrate-sssd-with-ldap-integrator init
terraform -chdir=integrate-sssd-with-ldap-integrator apply -auto-approve
:::

:::{dropdown} Full _{{ integrate_sssd_with_ldap_integrator_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/integrate-sssd-with-ldap-integrator.tf
:caption: {{ integrate_sssd_with_ldap_integrator_tf_file }}
:language: terraform
:linenos:
:::
:::

::::

:::::

:::{include} /reuse/howto/setup/deploy-identity-provider/common/sssd-with-ldap-status.txt
:::

#### Optional: Enable TLS encryption between SSSD and the external LDAP server

The [manual-tls-certificates](https://charmhub.io/manual-tls-certificates) charm can
provide your SSSD application with your external LDAP server's TLS certificate.

:::{admonition} Before you begin
:class: note

The instructions in this section assume that your external LDAP server supports TLS and
that you have access to your LDAP server's TLS certificate.
:::

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, use `juju deploy`{l=shell} with the `--config`{l=shell} flag to deploy
manual-tls-certificates with your external LDAP server's TLS certificate. In this
example, the LDAP server's TLS certificate is stored in the file _bundle.pem_:

:::{code-block} shell
juju deploy manual-tls-certificates \
  --channel 1/stable \
  --model identity \
  --config trusted-certificate-bundle="$(cat bundle.pem)"
:::

:::{include} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/bundle-pem-tip.txt
:::

Next, create an offer from the manual-tls-certificates application in your `identity`
model with `juju offer`{l=shell}:

:::{code-block} shell
juju offer identity.manual-tls-certificates:trust_certificate send-ldap-certs
:::

Now use `juju consume`{l=shell} to consume the offer from your manual-tls-certificates
application in your `slurm` model:

:::{code-block} shell
juju consume identity.send-ldap-certs
:::

After that, use `juju integrate`{l=shell} to integrate SSSD with manual-tls-certificates:

:::{code-block} shell
juju integrate sssd send-ldap-certs
:::

Now use `juju config`{l=shell} to update the ldap-integrator application's configuration
to indicate that the external LDAP server supports TLS:

:::{code-block} shell
juju config ldap-integrator starttls=true
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, update the configuration of the ldap-integrator application in the
_{{ ldap_integrator_tf_file }}_ Terraform configuration file to indicate that
the external LDAP server supports TLS:

:::{code-block} terraform
:caption: {{ ldap_integrator_tf_file }}
:emphasize-lines: 9
module "ldap-integrator" {
  source = "git::https://github.com/canonical/ldap-integrator//terraform"
  model_uuid = juju_model.identity.uuid

  config = {
    base_dn = "cn=testing,cn=ubuntu,cn=com"
    bind_dn = "cn=admin,dc=test,dc=ubuntu,dc=com"
    bind_password = juju_secret.external_ldap_password.secret_uri
    starttls = true
    urls = "ldap://10.214.237.229"
  }

  channel = "latest/edge"
}
:::

Now create the Terraform configuration file _{{ manual_tls_certificates_tf_file }}_ using
`mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir manual-tls-certificates
touch manual-tls-certificates/main.tf
:::

Now open _{{ manual_tls_certificates_tf_file }}_ in a text editor and add the
Juju Terraform provider to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/manual-tls-certificates.tf
:caption: {{ manual_tls_certificates_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, declare data sources for the `identity` and `slurm` models, and the SSSD
application:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/manual-tls-certificates.tf
:caption: {{ manual_tls_certificates_tf_file }}
:language: terraform
:lines: 10-23
:::

Now deploy manual-tls-certificates in the `identity` model. In this
example, the LDAP server's TLS certificate is stored in the file _bundle.pem_:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/manual-tls-certificates.tf
:caption: {{ manual_tls_certificates_tf_file }}
:language: terraform
:lines: 25-32
:::

:::{include} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/bundle-pem-tip.txt
:::

Now create an offer from the manual-tls-certificates application in your `identity` model:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/manual-tls-certificates.tf
:caption: {{ manual_tls_certificates_tf_file }}
:language: terraform
:lines: 34-39
:::

After that, integrate SSSD with manual-tls-certificates:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/manual-tls-certificates.tf
:caption: {{ manual_tls_certificates_tf_file }}
:language: terraform
:lines: 41-51
:::

Now use the `terraform`{l=shell} command to update the configuration of your
ldap-integrator application:

:::{code-block} shell
terraform -chdir=ldap-integrator init
terraform -chdir=ldap-integrator apply -auto-approve
:::

You can expand the dropdown below to see the full _{{ manual_tls_certificates_tf_file }}_
Terraform plan before applying it. Now use the `terraform`{l=shell} command again to
deploy and integrate manual-tls-certificates.

:::{dropdown} Full _{{ manual_tls_certificates_tf_file }}_ Terraform configuration file

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/ldap-integrator/manual-tls-certificates.tf
:caption: {{ manual_tls_certificates_tf_file }}
:language: terraform
:linenos:
:::

:::{code-block} shell
terraform -chdir=manual-tls-certificates init
terraform -chdir=manual-tls-certificates apply -auto-approve
:::

::::

:::::

SSSD will reactivate within a few minutes. You will see that the offer
`send-ldap-certs` is now active in the output of `juju status`{l=shell}:

:::{include} /reuse/howto/setup/deploy-identity-provider/common/sssd-with-ldap-tls-status.txt
:start-line: 3
:::

### Next Steps

You can now use your external LDAP server as the identity provider for your Charmed HPC cluster.

You can also start exploring the [Integrate](howto-integrate) section if you have
completed the {ref}`howto-deploy-deploy-shared-filesystem` how-to.

(identity-glauth-with-sssd)=
## GLAuth with SSSD

This section shows you how to use GLAuth, a lightweight LDAP server, as your Charmed HPC
cluster's identity provider, and SSSD as the client for integrating your cluster's login
and compute nodes to the GLAuth server.

:::{admonition} Unfamiliar with GLAuth?
:class: note

If you're unfamiliar with operating GLAuth, see the [GLAuth quick start](https://glauth.github.io/docs/quickstart.html)
guide for a high-level introduction to GLAuth.
:::

:::{admonition} Using GLAuth in a production Charmed HPC cluster
:class: warning

GLAuth is a lightweight LDAP server that is intended to be used for development
or home use. You should only use GLAuth as the identity provider for your cluster
if you are experimenting with Charmed HPC or deploying a small cluster.

You should deploy a dedicated LDAP server and follow the instructions in the
{ref}`identity-external-ldap-server-with-sssd` section instead if you are
looking to deploy a production-grade Charmed HPC cluster instead.
:::

### Prerequisites

- An active [Slurm deployment](#howto-deploy-deploy-slurm) in your [`charmed-hpc` machine cloud](#howto-initialize-machine-cloud).
- An initialized [`charmed-hpc-k8s` Kubernetes cloud](#howto-initialize-kubernetes-cloud).
- The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine.

### Deploy GLAuth and SSSD

You have two options for deploying GLAuth and SSSD:

1. Using the [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/reference/juju-cli/).
2. Using the [Juju Terraform client](https://canonical-terraform-provider-juju.readthedocs-hosted.com/latest/).

If you want to use Terraform to deploy GLAuth and SSSD, see the
[Manage `terraform-provider-juju`](https://canonical-terraform-provider-juju.readthedocs-hosted.com/latest/howto/manage-the-terraform-provider-for-juju/) how-to guide for additional
requirements.

#### Deploy GLAuth

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, use `juju add-model`{l=shell} to create the `identity` model in your
`charmed-hpc-k8s` Kubernetes cloud:

:::{code-block} shell
juju add-model identity charmed-hpc-k8s
:::

Now use `juju deploy`{l=shell} to deploy GLAuth with:

- Postgres as GLAuth's back-end database.
- Traefik as GLAuth's ingress provider.
- self-signed-certificates as GLAuth's X.509 certificates provider.

:::{code-block} shell
juju deploy glauth-k8s --channel "edge" \
  --config anonymousdse_enabled=true \
  --trust
juju deploy postgresql-k8s --channel "14/stable" --trust
juju deploy self-signed-certificates
juju deploy traefik-k8s --trust
:::

:::{include} /reuse/howto/setup/deploy-identity-provider/glauth/anonymous-dse-note.txt
:::

Next, use `juju integrate` to integrate GLAuth with Postgres, Traefik, and
self-signed-certificates:

:::{code-block} shell
juju integrate glauth-k8s postgresql-k8s
juju integrate glauth-k8s self-signed-certificates
juju integrate glauth-k8s:ingress traefik-k8s
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ glauth_tf_file }}_
using `mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir glauth
touch glauth/main.tf
:::

Now open _{{ glauth_tf_file }}_ in a text editor and add the Juju Terraform provider
to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/glauth.tf
:caption: {{ glauth_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, create the `identity` model on your `charmed-hpc-k8s` Kubernetes cloud:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/glauth.tf
:caption: {{ glauth_tf_file }}
:language: terraform
:lines: 10-16
:::

Now deploy GLAuth with:

- Postgres as GLAuth's back-end database.
- Traefik as GLAuth's Kubernetes ingress provider.
- self-signed-certificates as GLAuth's X.509 certificates provider.

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/glauth.tf
:caption: {{ glauth_tf_file }}
:language: terraform
:lines: 18-43
:::

:::{include} /reuse/howto/setup/deploy-identity-provider/glauth/anonymous-dse-note.txt
:::

Next, integrate GLAuth with Postgres, Traefik, and self-signed-certificates:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/glauth.tf
:caption: {{ glauth_tf_file }}
:language: terraform
:lines: 45-80
:::

You can expand the dropdown below to see the full _{{ glauth_tf_file }}_
Terraform configuration file before applying it. Now use the `terraform`{l=shell}
command to apply your configuration:

:::{code-block} shell
terraform -chdir=glauth init
terraform -chdir=glauth apply -auto-approve
:::

:::{dropdown} Full _{{ glauth_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/glauth.tf
:caption: {{ glauth_tf_file }}
:language: terraform
:linenos:
:::
:::

::::

:::::

Your GLAuth deployment will become active within a few minutes. The output
of `juju status`{l=shell} will be similar to the following:

:::{terminal}
:scroll:

juju status

Model     Controller              Cloud/Region             Version  SLA          Timestamp
identity  charmed-hpc-controller  charmed-hpc-k8s/default  3.6.4    unsupported  14:24:50-04:00

App                       Version  Status  Scale  Charm                     Channel        Rev  Address         Exposed  Message
glauth-k8s                         active      1  glauth-k8s                latest/edge     52  10.152.183.159  no
postgresql-k8s            14.15    active      1  postgresql-k8s            14/stable      495  10.152.183.236  no
self-signed-certificates           active      1  self-signed-certificates  latest/stable  264  10.152.183.57   no
traefik-k8s               2.11.0   active      1  traefik-k8s               latest/stable  232  10.152.183.122  no       Serving at 10.175.90.230

Unit                         Workload  Agent  Address     Ports  Message
glauth-k8s/0*                active    idle   10.1.0.165
postgresql-k8s/0*            active    idle   10.1.0.45          Primary
self-signed-certificates/0*  active    idle   10.1.0.128
traefik-k8s/0*               active    idle   10.1.0.73          Serving at 10.175.90.230
:::

You now need to deploy SSSD in your slurm model to enroll your cluster’s machines with the GLAuth server.

#### Deploy SSSD

:::{include} /reuse/howto/setup/deploy-identity-provider/common/deploy-sssd.txt
:::

You now need to integrate SSSD with the GLAuth application in your `identity` model so that
the SSSD application can activate and enroll your machines with the GLAuth server.

#### Integrate SSSD with GLAuth

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, create offers for GLAuth in your `identity` model using `juju offer`{l=shell}:

:::{code-block} shell
juju offer identity.glauth-k8s:ldap ldap
juju offer identity.glauth-k8s:send-ca-cert send-ldap-certs
:::

Next, use `juju consume`{l=shell} to consume offers from your GLAuth application
in your `slurm` model:

:::{code-block} shell
juju consume identity.ldap
juju consume identity.send-ldap-certs
:::

After that, use `juju integrate`{l=shell} to integrate SSSD with GLAuth:

:::{code-block} shell
juju integrate sssd ldap
juju integrate sssd send-ldap-certs
:::

:::{include} /reuse/howto/setup/deploy-identity-provider/common/sssd-with-ldap-tls-status.txt
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ integrate_sssd_with_glauth_tf_file }}_
using `mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir integrate-sssd-with-glauth
touch integrate-sssd-with-glauth/main.tf
:::

Now open _{{ integrate_sssd_with_glauth_tf_file }}_ in a text editor and add the Juju Terraform provider
to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/integrate-sssd-with-glauth.tf
:caption: {{ integrate_sssd_with_glauth_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, declare data sources for the `identity` and `slurm` models, and the GLAuth and SSSD
applications:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/integrate-sssd-with-glauth.tf
:caption: {{ integrate_sssd_with_glauth_tf_file }}
:language: terraform
:lines: 10-28
:::

Now create offers from the GLAuth application in your `identity` model:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/integrate-sssd-with-glauth.tf
:caption: {{ integrate_sssd_with_glauth_tf_file }}
:language: terraform
:lines: 30-42
:::

After that, integrate SSSD with GLAuth:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/integrate-sssd-with-glauth.tf
:caption: {{ integrate_sssd_with_glauth_tf_file }}
:language: terraform
:lines: 44-66
:::

You can expand the dropdown below to see the full _{{ integrate_sssd_with_glauth_tf_file }}_
Terraform configuration file before applying it. Now use the `terraform`{l=shell} command to
apply your configuration:

:::{code-block} shell
terraform -chdir=integrate-sssd-with-glauth init
terraform -chdir=integrate-sssd-with-glauth apply -auto-approve
:::

:::{dropdown} Full _{{ integrate_sssd_with_glauth_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/glauth/integrate-sssd-with-glauth.tf
:caption: {{ integrate_sssd_with_glauth_tf_file }}
:language: terraform
:::
:::

:::{include} /reuse/howto/setup/deploy-identity-provider/common/sssd-with-ldap-tls-status.txt
:::

::::

:::::

### Next Steps

You can now use GLAuth as the identity provider for your Charmed HPC cluster.

Explore [GLAuth's Database documentation](https://glauth.github.io/docs/databases.html) for more information
on how to use SQL queries to manage your cluster's users and groups in your Postgres database.

You can also start exploring the [Integrate](howto-integrate) section if you have
completed the {ref}`howto-deploy-deploy-shared-filesystem` how-to.
