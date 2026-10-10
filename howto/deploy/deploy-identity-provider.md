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

## Choosing an identity provider

:::{list-table}
:header-rows: 1
:widths: 50 50

* - Use case & requirements
  - Recommended provider
* - __Enterprise Identity__ : Your Charmed HPC cluster requires unified Single Sign-On (SSO), LDAP and SAML protocol bridging, Active Directory synchronization, and built-in administration console or first-party Terraform provider.
  - {ref}`Authentik <howto-deploy-deploy-identity-provider-authentik-and-sssd>`
* - __Existing Infrastructure__ : Your Charmed HPC cluster must integrate with an existing identity system such as central directory service.
  - {ref}`ldap-integrator <identity-ldap-integrator-and-sssd>`

:::

## Prerequisites

- An active [Slurm deployment](#howto-deploy-deploy-slurm) in your [`charmed-hpc` machine cloud](#howto-initialize-machine-cloud).
- The [Juju CLI client](https://canonical.com/juju/docs/juju-cli/3.6/reference/juju-cli/) installed on your machine.
- _Optional_: If you're using Terraform, then the [Juju Terraform provider](https://canonical.com/juju/docs/terraform-provider-juju/2.3/).

If you are going to deploy Authentik as the identity provider for your Charmed HPC cluster, 
additional prerequisites include:

- An initialized [`charmed-hpc-k8s` Kubernetes cloud](#howto-initialize-kubernetes-cloud).

## Deploy identity provider

(howto-deploy-deploy-identity-provider-authentik-and-sssd)=
### Deploy Authentik and SSSD

This section shows you how to use Authentik, an open source platform for unified user management,
as your Charmed HPC cluster's identity provider, and SSSD as the client for integrating your cluster's login
and compute nodes with an Authentik LDAP outpost.

:::{admonition} Unfamiliar with Authentik?
:class: note

If you're unfamiliar with operating Authentik, see the [Charmed Authentik tutorial](https://canonical-identity.readthedocs-hosted.com/authentik/tutorial/getting-started/)
guide for a high-level introduction to Authentik.
:::

#### Deploy Authentik

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, use `juju add-model`{l=shell} to create the `identity` model in your `charmed-hpc-k8s` Kubernetes cloud.

:::{code-block} shell
juju add-model identity charmed-hpc-k8s
:::

Now use `juju deploy`{l=shell} to deploy Authentik with:

* Postgres as Authentik's backing database.
* Traefik as Authentik's ingress provider.
* self-signed-certificates as Authentik's X.509 certificates provider.

:::{code-block} shell
juju deploy authentik-server --channel latest/stable --trust
juju deploy authentik-worker --channel latest/stable --trust
juju deploy authentik-ldap-outpost --channel latest/stable --trust
juju deploy postgresql-k8s --channel 14/stable --trust
juju deploy traefik-k8s --channel latest/stable --base ubuntu@26.04 --trust
juju deploy self-signed-certificates --channel latest/stable
:::

Next, use `juju integrate`{l=shell} to connect Authentik's services together, and integrate
Authentik with Postgres, Traefik, and self-signed-certificates:

:::{code-block} shell
juju integrate traefik-k8s:certificates self-signed-certificates:certificates
juju integrate authentik-server postgresql-k8s
juju integrate authentik-server traefik-k8s
juju integrate authentik-ldap-outpost traefik-k8s
juju integrate authentik-server authentik-worker
juju integrate authentik-server authentik-ldap-outpost
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ authentik_tf_file }}_ using 
`mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir authentik
touch authentik/main.tf
:::

Now open _{{ authentik_tf_file }}_ in a text editor and add the Juju Terraform provider to
your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/authentik.tf
:caption: {{ authentik_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, create the `identity` model on your `charmed-hpc-k8s` Kubernetes cloud:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/authentik.tf
:caption: {{ authentik_tf_file }}
:language: terraform
:lines: 10-16
:::

Now deploy Authentik with:

* Postgres as Authentik's backing database.
* Traefik as Authentik's ingress provider.
* self-signed-certificates as Authentik's X.509 certificates provider.

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/authentik.tf
:caption: {{ authentik_tf_file }}
:language: terraform
:lines: 18-53
:::

Next, connect Authentik's services together, and integrate Authentik with 
Postgres, Traefik, and self-signed-certificates:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/authentik.tf
:caption: {{ authentik_tf_file }}
:language: terraform
:lines: 55-125
:::

You can expand the dropdown below to see the full Terraform configuration file before applying it. 
Now use the `terraform`{l=shell} command to apply your configuration:

:::{code-block} shell
terraform -chdir=authentik init
terraform -chdir=authentik apply -auto-approve
:::

:::{dropdown} Full _{{ authentik_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/authentik.tf
:caption: {{ authentik_tf_file }}
:language: terraform
:linenos:
:::
:::

::::

:::::

Your Authentik deployment will become active within a few minutes. The output
of `juju status`{l=shell} will be similar to the following:

:::{terminal}
:scroll:

juju status

Model     Controller       Cloud/Region     Version  SLA          Timestamp
identity  charmed-hpc-k8s  charmed-hpc-k8s  3.6.28   unsupported  17:12:15-04:00

App                       Version   Status  Scale  Charm                     Channel        Rev  Address         Exposed  Message
authentik-ldap-outpost    2026.5.3  active      1  authentik-ldap-outpost    latest/stable   23  10.152.183.225  no
authentik-server          2026.5.3  active      1  authentik-server          latest/stable   30  10.152.183.164  no
authentik-worker          2026.5.3  active      1  authentik-worker          latest/stable    7  10.152.183.134  no
postgresql-k8s            14.24     active      1  postgresql-k8s            14/stable      960  10.152.183.88   no
self-signed-certificates            active      1  self-signed-certificates  1/stable       586  10.152.183.68   no
traefik-k8s               2.11.49   active      1  traefik-k8s               latest/stable  378  10.152.183.124  no       Serving at https://10.148.202.14

Unit                         Workload  Agent  Address     Ports  Message
authentik-ldap-outpost/0*    active    idle   10.1.0.222
authentik-server/0*          active    idle   10.1.0.210
authentik-worker/0*          active    idle   10.1.0.51
postgresql-k8s/0*            active    idle   10.1.0.223         Primary
self-signed-certificates/0*  active    idle   10.1.0.120
traefik-k8s/0*               active    idle   10.1.0.49          Serving at https://10.148.202.14
:::

You now need to deploy SSSD in your `slurm` model to enroll your cluster’s machines with the Authentik LDAP outpost.

#### Deploy SSSD

:::{include} /reuse/howto/setup/deploy-identity-provider/common/deploy-sssd.txt
:::

You now need to integrate SSSD with the Authentik LDAP outpost in your `identity` model so that
the SSSD application can activate and enroll your machines with Authentik.

#### Integrate SSSD with Authentik

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, create offers from Authentik and self-signed-certificates in your `identity` model using 
`juju offer`{l=shell}:

:::{code-block} shell
juju offer identity.authentik-ldap-outpost:ldaps ldaps
juju offer identity.self-signed-certificates:send-ca-cert send-ca-certs
:::

Next, use `juju consume`{l=shell} to consume offers from your `identity` model in your `slurm` model:

:::{code-block} shell
juju consume identity.ldaps
juju consume identity.send-ca-certs
:::

After that, use `juju integrate`{l=shell} to integrate SSSD with Authentik:

:::{code-block} shell
juju integrate sssd send-ca-cert
juju integrate sssd ldaps
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ integrate_sssd_with_authentik_tf_file }}_ 
using `mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir integrate-sssd-with-authentik
touch integrate-sssd-with-authentik/main.tf
:::

Now open _{{ integrate_sssd_with_authentik_tf_file }}_ in a text editor and add the Juju Terraform provider to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/integrate-sssd-with-authentik.tf
:caption: {{ integrate_sssd_with_authentik_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, declare data sources for the `identity` and `slurm` models, and the Authentik LDAP outpost,
self-signed-certificates, and SSSD applications:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/integrate-sssd-with-authentik.tf
:caption: {{ integrate_sssd_with_authentik_tf_file }}
:language: terraform
:lines: 10-33
:::

Now create offers from Authentik and self-signed-certificates in your `identity` model:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/integrate-sssd-with-authentik.tf
:caption: {{ integrate_sssd_with_authentik_tf_file }}
:language: terraform
:lines: 35-47
:::

After that, integrate SSSD with the Authentik and self-signed-certificates offer endpoints:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/integrate-sssd-with-authentik.tf
:caption: {{ integrate_sssd_with_authentik_tf_file }}
:language: terraform
:lines: 49-67
:::

You can expand the dropdown below to see the full Terraform configuration 
file before applying it. Now use the `terraform`{l=shell} command to apply your configuration:

:::{code-block} shell
terraform -chdir=integrate-sssd-with-authentik init
terraform -chdir=integrate-sssd-with-authentik apply -auto-approve
:::

:::{dropdown} Full _{{ integrate_sssd_with_authentik_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/authentik/integrate-sssd-with-authentik.tf
:caption: {{ integrate_sssd_with_authentik_tf_file }}
:language: terraform
:linenos:
:::
:::

::::

:::::

The SSSD application will become active within a few minutes. The output of `juju status`{l=shell}
will be similar to the following:

:::{terminal}
:scroll:

juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.28   unsupported  05:02:54-06:00

SAAS             Status  Store                   URL
ldaps            active  charmed-hpc-controller  admin/identity.ldaps
send-ca-certs    active  charmed-hpc-controller  admin/identity.send-ca-certs

App         Version          Status  Scale  Charm       Channel      Rev  Exposed  Message
mysql       8.0.44-0ubun...  active      1  mysql       8.0/stable   444  no
sackd       25.11.2          active      1  sackd       latest/edge   89  no
slurmctld   25.11.2          active      1  slurmctld   latest/edge  167  no       primary - UP
slurmd      25.11.2          active      1  slurmd      latest/edge  184  no
slurmdbd    25.11.2          active      1  slurmdbd    latest/edge  161  no
slurmrestd  25.11.2          active      1  slurmrestd  latest/edge  161  no
sssd        2.12.0           active      3  sssd        latest/edge   34  no

Unit           Workload  Agent  Machine  Public address  Ports           Message
mysql/0*       active    idle   5        10.124.231.61   3306,33060/tcp  Primary
sackd/0*       active    idle   0        10.124.231.201  6818/tcp
  sssd/1       active    idle            10.124.231.201
slurmctld/0*   active    idle   1        10.124.231.3    6817,9092/tcp   primary - UP
  sssd/0*      active    idle            10.124.231.3
slurmd/0*      active    idle   2        10.124.231.114  6818/tcp
  sssd/2       active    idle            10.124.231.114
slurmdbd/0*    active    idle   3        10.124.231.68   6819/tcp
slurmrestd/0*  active    idle   4        10.124.231.170  6820/tcp

Machine  State    Address         Inst id        Base          AZ  Message
0        started  10.124.231.201  juju-6004d5-0  ubuntu@26.04      Running
1        started  10.124.231.3    juju-6004d5-1  ubuntu@26.04      Running
2        started  10.124.231.114  juju-6004d5-2  ubuntu@26.04      Running
3        started  10.124.231.68   juju-6004d5-3  ubuntu@26.04      Running
4        started  10.124.231.170  juju-6004d5-4  ubuntu@26.04      Running
5        started  10.124.231.61   juju-6004d5-5  ubuntu@22.04      Running

:::

::::{admonition} LDAPS by default
:class: note

SSSD must be integrated with self-signed-certificates over the `send-ca-cert` endpoint
because Charmed Authentik uses LDAPS (TLS-encrypted LDAP) instead of LDAP by default.

SSSD will automatically default to use the LDAPS endpoint because the 
Authentik LDAP outpost advertises LDAPS as the preferred protocol type in the integration
data that it provides to SSSD.

To publicly expose an unencrypted LDAP endpoint from your Charmed Authentik deployment
for LDAP clients that do not support LDAPS, configure the Authentik LDAP outpost to
enable ingress for its LDAP endpoint:

:::{code-block} shell
juju config authentik-ldap-outpost expose_ldap_ingress=true
:::

::::

(identity-ldap-integrator-and-sssd)=
### Deploy ldap-integrator and SSSD

This section shows you how to use an external LDAP server as your Charmed HPC cluster's
identity provider, and SSSD as the client for integrating your cluster's login and compute
nodes with the external LDAP server.

The [ldap-integrator](https://charmhub.io/ldap-integrator) charm is used to proxy your
external LDAP server's configuration information to other charmed applications.

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
to read in your bind password from a secure file rather than provide
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

Next, use `juju consume`{l=shell} to consume the offer from your ldap-integrator
application in your `slurm` model:

:::{code-block} shell
juju consume identity.ldap
:::

After that, use `juju integrate`{l=shell} to integrate SSSD with ldap-integrator:

:::{code-block} shell
juju integrate ldap sssd
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ integrate_sssd_with_ldap_integrator_tf_file }}_
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

#### _Optional_: Enable TLS encryption between SSSD and the external LDAP server

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
Terraform configuration file before applying it. Now use the `terraform`{l=shell} command again to
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

## Enable SSH key-based authentication

Your deployed SSSD application can be integrated with a deployed 
[OpenSSH](https://charmhub.io/openssh) application to enable SSH key-based authentication 
for your cluster's users.

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, use `juju deploy`{l=shell} to deploy OpenSSH in your `slurm` model:

:::{code-block} shell
juju deploy openssh --channel 10/stable --base ubuntu@26.04
:::

Next, use `juju integrate`{l=shell} to integrate OpenSSH with SSSD and sackd:

:::{code-block} shell
juju integrate openssh sackd
juju integrate openssh:ssh-config sssd:ssh-config
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ openssh_tf_file }}_ using `mkdir`{l=shell}
and `touch`{l=shell}:

:::{code-block} shell
mkdir openssh
touch openssh/main.tf
:::

Now open _{{ openssh_tf_file }}_ in a text editor and add the Juju Terraform provider to
your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/openssh/openssh.tf
:caption: {{ openssh_tf_file }}
:language: terraform
:lines: 1-7
:::

Next, declare data sources for the `slurm` model, and the sackd and SSSD applications:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/openssh/openssh.tf
:caption: {{ openssh_tf_file }}
:language: terraform
:lines: 10-24
:::

Now deploy OpenSSH:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/openssh/openssh.tf
:caption: {{ openssh_tf_file }}
:language: terraform
:lines: 26-32
:::

After that, integrate OpenSSH with sackd and SSSD:

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/openssh/openssh.tf
:caption: {{ openssh_tf_file }}
:language: terraform
:lines: 34-59
:::

You can expand the dropdown below to see the full Terraform configuration file before
applying it. Now use the `terraform`{l=shell} command to apply your configuration:

:::{code-block} shell
terraform -chdir=openssh init
terraform -chdir=openssh apply -auto-approve
:::

:::{dropdown} Full _{{ openssh_tf_file }}_ Terraform configuration file

:::{literalinclude} /reuse/howto/setup/deploy-identity-provider/openssh/openssh.tf
:caption: {{ openssh_tf_file }}
:language: terraform
:linenos:
:::
:::

::::

:::::

The OpenSSH application will become active within a few minutes. The output of 
`juju status`{l=shell} will be similar to the following:

:::{terminal}
:scroll:

juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.28   unsupported  05:02:54-06:00

SAAS             Status  Store                   URL
ldaps            active  charmed-hpc-controller  admin/identity.ldaps
send-ca-certs    active  charmed-hpc-controller  admin/identity.send-ca-certs

App         Version          Status  Scale  Charm       Channel      Rev  Exposed  Message
openssh     10.2p1           active      1  openssh     10/stable      1  no
mysql       8.0.44-0ubun...  active      1  mysql       8.0/stable   444  no
sackd       25.11.2          active      1  sackd       latest/edge   89  no
slurmctld   25.11.2          active      1  slurmctld   latest/edge  167  no       primary - UP
slurmd      25.11.2          active      1  slurmd      latest/edge  184  no
slurmdbd    25.11.2          active      1  slurmdbd    latest/edge  161  no
slurmrestd  25.11.2          active      1  slurmrestd  latest/edge  161  no
sssd        2.12.0           active      3  sssd        latest/edge   34  no

Unit           Workload  Agent  Machine  Public address  Ports           Message
mysql/0*       active    idle   5        10.124.231.61   3306,33060/tcp  Primary
sackd/0*       active    idle   0        10.124.231.201  6818/tcp
  sssd/1       active    idle            10.124.231.201
  openssh/0*   active    idle            10.124.231.201  22/tcp
slurmctld/0*   active    idle   1        10.124.231.3    6817,9092/tcp   primary - UP
  sssd/0*      active    idle            10.124.231.3
slurmd/0*      active    idle   2        10.124.231.114  6818/tcp
  sssd/2       active    idle            10.124.231.114
slurmdbd/0*    active    idle   3        10.124.231.68   6819/tcp
slurmrestd/0*  active    idle   4        10.124.231.170  6820/tcp

Machine  State    Address         Inst id        Base          AZ  Message
0        started  10.124.231.201  juju-6004d5-0  ubuntu@26.04      Running
1        started  10.124.231.3    juju-6004d5-1  ubuntu@26.04      Running
2        started  10.124.231.114  juju-6004d5-2  ubuntu@26.04      Running
3        started  10.124.231.68   juju-6004d5-3  ubuntu@26.04      Running
4        started  10.124.231.170  juju-6004d5-4  ubuntu@26.04      Running
5        started  10.124.231.61   juju-6004d5-5  ubuntu@22.04      Running

:::

Your cluster's users can now use their public and private SSH key pairs to authenticate
when they log into your cluster's login node machines.

If you deployed Authentik as your cluster's identity provider, refer to the
{ref}`howto-manage-manage-users-and-groups-set-public-ssh-keys` section in the
{ref}`howto-manage-manage-users-and-groups` how-to for further information on how to
set a user's public SSH keys in Authentik.

## Next Steps

Now that your Charmed HPC cluster's identity provider is deployed, you can start exploring
the [Integrate](howto-integrate) section if you have also completed the 
{ref}`howto-deploy-deploy-shared-filesystem` how-to.

If you deployed Authentik as your cluster's identity provider, consult {ref}`howto-manage-manage-users-and-groups` 
for further information on how to manage the users and groups of your Charmed HPC cluster.

For more information on the charms deployed in this how-to guide and how they are managed,
consult the {ref}`reference-underlying-projects-and-dependencies` reference page.
