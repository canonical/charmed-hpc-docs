---
relatedlinks: "[Authentik&#32;documentation](https://docs.goauthentik.io), [Charmed&#32;Authentik&#32;documentation](https://canonical-identity.readthedocs-hosted.com/authentik/), [Authentik&#32;Terraform&#32;provider&#32;documentation](https://registry.terraform.io/providers/goauthentik/authentik/latest/docs)"
myst:
  html_meta:
    description: Manage the users and groups of a Charmed HPC cluster using the Authentik Terraform provider. Discover how to add, remove, and delete users and groups.
---

(howto-manage-manage-users-and-groups)=
# Manage users and groups

This guide provides examples of using the Authentik Terraform provider to manage the 
users and groups of a Charmed HPC cluster. 

## Prerequisites

To successfully use the Authentik Terraform provider to manage the users and groups of your
cluster, you will need to have:

- {ref}`Authentik deployed and integrated as your Charmed HPC cluster's identity provider. <howto-deploy-deploy-identity-provider-authentik-and-sssd>`
- [Terraform](https://developer.hashicorp.com/terraform/docs) installed on your machine.

Once you have satisfied the criteria above, you will need to enable the Authentik 
Terraform provider in your Terraform configuration.

## Configure the Authentik Terraform provider

First, declare the Authentik Terraform provider as a required provider in your Terraform
configuration file:

:::{code-block} terraform
terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2026.5.2"
    }
  }
}
:::

Next, use the Authentik server application's `get-bootstrap-admin-credentials` action to
retrieve an access token that the provider will use to authenticate with your Authentik deployment:

:::{code-block} shell
juju run authentik-server/leader get-bootstrap-admin-credentials
:::

The output of the `get-bootstrap-admin-credentials` action will look similar to the following:

:::{terminal}
:scroll:

juju run authentik-server/leader get-bootstrap-admin-credentials

bootstrap-token: foobar
password: supersecret
username: akadmin
warning: These are initial bootstrap credentials generated at deployment time. If
  the administrator password was subsequently changed via the web UI or recovery flows,
  the password returned here will be stale.
:::

Now, using the value of the `bootstrap-token` field, configure the provider to operate on 
your Authentik deployment. Note that you will need to use a different value for the `token`
parameter in your provider configuration if you either revoked the initial bootstrap token
or created a new access token for the `akadmin` user:

:::{code-block} terraform
provider "authentik" {
  url   = "<Public HTTPS address of your Authentik server application>"
  token = "foobar"
}
:::

::::{dropdown} Tip: Determining the public HTTPS address of your Authentik deployment

The Traefik application's `show-external-endpoints` action can be used to determine the
public HTTPS address of your Authentik deployment:

:::{terminal}
:scroll:

juju run traefik-k8s/leader show-external-endpoints

external-endpoints: '{"traefik-k8s": {"url": "https://10.148.202.14"}}'

:::

<br>

The output above shows that the public endpoint of your Traefik application is
`https://10.148.202.14` which means that this is also the public HTTPS address of 
your Authentik deployment.
::::

You can now use the Authentik Terraform provider to manage the users and groups of
your Charmed HPC cluster. Refer to the sections below for examples of common management
tasks such as adding new users and groups to the cluster.

::::{admonition} Accessing Authentik's API over HTTPS
:class: warning

The Authentik API uses HTTPS by default. This means that if you are using a private or
self-signed CA certificate, you will need to install the CA certificate on the machine
from which you will be applying your Terraform configuration.

For example, if your Authentik server application is integrated with the 
self-signed-certificates application, you can use the self-signed-certificates
application's `get-ca-certificate` action to pull the CA certificate used by your
Authentik deployment:

:::{code-block} shell
juju run self-signed-certificates/leader get-ca-certificate | \
  yq --raw-output '.["ca-certificate"]' | \
  tee /usr/local/share/ca-certificates/authentik.crt

sudo update-ca-certificates
:::

The commands above will pull the CA certificate that signs the TLS certificate used
by your Authentik deployment, save it to your machine's local CA certificate store,
and update your machine's trusted list of CA certificates. You can now communicate with
your Authentik deployment over HTTPS when applying your Terraform configuration.

If you do not want to communicate with your Authentik deployment over HTTPS, you can
configure the Authentik Terraform provider to use HTTP instead by setting the `insecure`
parameter to `true`:

:::{code-block} terraform
:emphasize-lines: 4

provider "authentik" {
  url      = "<Public HTTPS address of your Authentik server application>"
  token    = "foobar"
  insecure = true
}
:::
::::

## Add a new user

The `authentik_user` resource can be used to add new users. For example, to add the user
_Jane Doe_ to your cluster, do:

:::{code-block} terraform
resource "authentik_user" "janedoe" {
  username = "janedoe"
  name     = "Jane Doe"
}
:::

### Set a user's default shell

A user's default shell can be configured by setting the `loginShell` attribute in the `attributes`
parameter of the `authentik_user` resource. For example, to set the default shell of user 
_Jane Doe_ to `/bin/bash`{l=shell}, do:

:::{code-block} terraform
:emphasize-lines: 5-7

resource "authentik_user" "janedoe" {
  username   = "janedoe"
  name       = "Jane Doe"

  attributes = jsonencode({
    loginShell = "/bin/bash"
  })
}
:::

:::{admonition} `/bin/sh`{l=shell} is the default shell
:class: note

`/bin/sh`{l=shell} is set as the default shell for a user if
the `loginShell` attribute is not returned in SSSD's LDAP search query for the user's information when the user logs into a machine.

Authentik does not set a default shell for newly created users, so you must
set `loginShell` in the user's custom attributes in Authentik 
if the user wants to have a default shell other than `/bin/sh`{l=shell}.
:::

(howto-manage-manage-users-and-groups-set-public-ssh-keys)=
### Set a user's public SSH keys

A user's public SSH keys can be configured by setting the `sshPublicKey` attribute in the `attributes`
parameter of the `authentik_user` resource. For example, to set the public SSH keys for user 
_Jane Doe_, do:

:::{code-block} terraform
:emphasize-lines: 5-10

resource "authentik_user" "janedoe" {
  username   = "janedoe"
  name       = "Jane Doe"

  attributes = jsonencode({
    sshPublicKey = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... jane@laptop",
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... jane@desktop"
    ]
  })
}
:::

A user's public SSH keys can also be read from a file:

:::{code-block} terraform
:emphasize-lines: 5-7

resource "authentik_user" "janedoe" {
  username   = "janedoe"
  name       = "Jane Doe"

  attributes = jsonencode({
    sshPublicKey = trimspace(file("${path.module}/keys/id_ed25519.pub"))
  })
}
:::

:::{admonition} `sshPublicKey` is required to enable SSH key-based authentication
:class: warning

The `sshPublicKey` attribute must be set in a user's custom attributes in Authentik
for SSH key-based authentication to work in your cluster. Authentik does not define
this attribute by default for newly created users. 
:::

## Add a new group

The `authentik_group` resource can be used to add new groups. For example, to add the group
_Scientists_ to your cluster, do:

:::{code-block} terraform
resource "authentik_group" "scientists" {
  name = "scientists"
}
:::

### Add a user to a group

Users can be added to a group by setting the `users` parameter. For example, to add the
existing user _Jane Doe_ to the _Scientists_ group, do:

:::{code-block} terraform
data "authentik_user" "janedoe" {
  username = "janedoe"
}

resource "authentik_group" "scientists" {
  name  = "scientists"
  users = [data.authentik_user.janedoe.id]
}
:::

If the _Scientists_ group is managed outside of your Terraform configuration - for example, if you
previously created the _Scientists_ group through Authentik's web UI - you can add users by
importing the group into your Terraform configuration:

:::{code-block} terraform
data "authentik_group" "existing" {
  name = "scientists"
}

data "authentik_user" "janedoe" {
  username = "janedoe"
}

import {
  to = authentik_group.scientists
  id = data.authentik_group.existing.id
}

resource "authentik_group" "scientists" {
  name = "Scientist"
  users = concat(
    [data.authentik_user.janedoe.id],
    [data.authentik_group.existing.users]
  )
}
:::

### Remove a user from a group

Users can be removed from a group by importing the group's information into your Terraform
configuration and filtering out the user to remove from the group's `users` field. For example,
to remove the user _Jane Doe_ from the _Scientists_ group, do:

:::{code-block} terraform
data "authentik_group" "existing" {
  name = "scientists"
}

data "authentik_user" "user_to_remove" {
  username = "janedoe"
}

import {
  to = authentik_group.scientists
  id = data.authentik_group.existing.id
}

resource "authentik_group" "scientists" {
  name = "scientists"

  users = [
    for user_id in data.authentik_group.existing.users :
    user_id if user_id != data.authentik_user.user_to_remove.id
  ]
}
:::

## Delete a user

A user can be deleted by importing their configuration into Terraform
and destroying the corresponding `authentik_user` resource. For example, to delete the
user _Jane Doe_, first declare a new `authentik_user` resource in your Terraform configuration:

:::{code-block} terraform
resource "authentik_user" "user_to_delete" {
  username = "janedoe"
}
:::

Next, use `terraform import`{l=shell} to import user _Jane Doe_'s information into your 
Terraform configuration state. Note that you will need to know the target user's UID number
in Authentik to successfully import them into your Terraform configuration state:

:::{code-block} shell
terraform import authentik_user.user_to_delete <uid>
:::

Now use `terraform destroy`{l=shell} to delete _Jane Doe_ from your cluster:

:::{code-block} shell
terraform destroy -auto-approve
:::

## Delete a group

A group can be deleted by importing its configuration into Terraform and destroying
the corresponding `authentik_group` resource. For example, to delete the group
_Scientists_, first declare a new `authentik_group` resource in your Terraform configuration:

:::{code-block} terraform
resource "authentik_group" "group_to_delete" {
  name = "scientists"
}
:::

Next, use `terraform import`{l=shell} to import the group _Scientists_' information into your
Terraform configuration state. Note that you will need to know the target group's UID number
in Authentik to successfully import the group into your Terraform configuration state:

:::{code-block} shell
terraform import authentik_group.group_to_delete <uid>
:::

Now use `terraform destroy`{l=shell} to delete _Scientists_ from your cluster:

:::{code-block} shell
terraform destroy -auto-approve
:::
