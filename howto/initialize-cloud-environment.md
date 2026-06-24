---
relatedlinks: "[Get&#032;started&#032;with&#032;Juju](https://documentation.ubuntu.com/juju/latest/user/tutorial/), [Juju&#032;(Application)](https://documentation.ubuntu.com/juju/latest/user/reference/application/), [Juju&#032;(Charm)](https://documentation.ubuntu.com/juju/latest/user/reference/charm/), [Juju&#032;(Cloud)](https://documentation.ubuntu.com/juju/latest/user/reference/cloud/), [Juju&#032;(Controller)](https://documentation.ubuntu.com/juju/latest/user/reference/controller/)"
---

(howto-initialize-cloud-environment)=
# How to initialize cloud environment

This how-to guide shows you how to initialize the cloud environment where you will
deploy your Charmed HPC cluster.

Charmed HPC uses a converged architecture where a machine cloud hosts compute plane
applications like the cluster's workload manager and filesystem, and a Kubernetes (K8s) cloud
hosts common control plane applications like identity management and observability services.
It is __strongly recommended__ that you pair your machine cloud with a complimenting Kubernetes cloud
to simplify the deployment and management of both clouds. For example, LXD should be paired
with Canonical Kubernetes, Azure paired with AKS, AWS paired with EKS, and so on.

:::{admonition} Cloud definition
:class: note

To Charmed HPC, a __cloud__ (or ___backing cloud___) is any entity that has an API that can
provide compute, networking, and optionally storage resources to applications deployed on them.
This includes public clouds such as Amazon Web Services, Google Compute Engine, Microsoft Azure
and Kubernetes as well as private OpenStack-based clouds. Charmed HPC can also make use of
environments, such as MAAS and LXD, which are not necessarily considered clouds, but can be treated
as a cloud.
:::

## Prerequisites

To initialize the cloud environment where you will deploy your Charmed HPC cluster,
you will need:

* Access to a [supported machine cloud](https://documentation.ubuntu.com/juju/latest/user/reference/cloud/list-of-supported-clouds/)
* Access to a [supported Kubernetes cloud](https://documentation.ubuntu.com/juju/latest/user/reference/cloud/list-of-supported-clouds/)
* The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine

(howto-initialize-machine-cloud)=
## Initialize machine cloud

Follow the instructions below to initialize the `charmed-hpc` machine cloud.

:::::{tab-set}

::::{tab-item} LXD
:sync: lxd

### Prerequisites for LXD

To use LXD as the machine cloud for your Charmed HPC cluster, you will need to have:

* [Installed LXD](https://documentation.ubuntu.com/lxd/en/stable-5.21/installing/)
* [Initialized LXD](https://documentation.ubuntu.com/lxd/en/stable-5.21/howto/initialize/)
* [Exposed LXD to the network](https://documentation.ubuntu.com/lxd/en/stable-5.21/howto/server_expose/)
* [Configured a server trust password](https://documentation.ubuntu.com/lxd/en/stable-5.21/server/#server-core:core.trust_password)

:::{admonition} New to LXD?
:class: note

If you're unfamiliar with operating an LXD server, see the [First steps with LXD](https://documentation.ubuntu.com/lxd/en/latest/tutorial/first_steps/)
tutorial for a high-level introduction to LXD.
:::

### Add LXD cloud to Juju

To make your LXD cloud known to Juju, first create the file _charmed-hpc-cloud.yaml_ and enter the following
content, substituting `<public address of lxd server>` with the public address of your LXD server:

:::{code-block} yaml
:caption: `charmed-hpc-cloud.yaml`
:linenos:

clouds:
  charmed-hpc:
    type: lxd
    description: "Machine cloud for Charmed HPC"
    auth-types: [certificate, interactive]
    endpoint: <public address of lxd server>
:::

Now, after creating _charmed-hpc-cloud.yaml_, use `juju add-cloud`{l=shell} to add
your LXD cloud to Juju:

:::{code-block} shell
juju add-cloud charmed-hpc --file ./charmed-hpc-cloud.yaml
:::

### Add LXD cloud credentials to Juju

Before you can start deploying applications on your LXD server, you must add credentials for contacting
your LXD server to Juju. Create the file _charmed-hpc-cloud-credentials.yaml_ and enter the following content, with
`<lxd server trust password>` substituted with your LXD server's configured trust password:

:::{code-block} yaml
:caption: `charmed-hpc-cloud-credentials.yaml`
:linenos:

credentials:
  charmed-hpc:
    accesskey:
      auth-type: interactive
      trust-password: <lxd server trust password>
:::

Now use `juju add-credential`{l=shell} to add the credentials for contacting your LXD server to Juju:

:::{code-block} shell
juju add-credential charmed-hpc --file ./charmed-hpc-cloud-credentials.yaml
:::

:::{admonition} Certificates
:class: note

Juju will use your LXD server's configured trust password to automatically retrieve your server's TLS certificates.
:::

### Bootstrap LXD cloud controller

With both your LXD server's endpoint and credentials added to Juju, use `juju bootstrap`{l=shell} to deploy
the cloud controller:

:::{code-block} shell
juju bootstrap charmed-hpc charmed-hpc-controller
:::

After a few minutes, your LXD cloud controller will become active. The output of `juju status`{l=shell}
command should be similar to the following:

:::{terminal}
juju status -m controller

Model       Controller              Cloud/Region         Version  SLA          Timestamp
controller  charmed-hpc-controller  charmed-hpc/default  3.6.2    unsupported  13:55:33-05:00

App         Version  Status  Scale  Charm            Channel     Rev  Exposed  Message
controller           active      1  juju-controller  3.6/stable  116  no

Unit           Workload  Agent  Machine  Public address  Ports  Message
controller/0*  active    idle   0        10.190.89.114

Machine  State    Address        Inst id        Base          AZ  Message
0        started  10.190.89.114  juju-3b4cde-0  ubuntu@24.04      Running
:::

::::

::::{tab-item} Azure
:sync: azure

To use Microsoft Azure as the machine cloud for your Charmed HPC cluster, you will need to have:

* [A valid Azure subscription ID](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id)
* [Installed the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Signed into the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively)
* [Adjusted quotas for suitable virtual machine (VM) families](https://learn.microsoft.com/en-us/azure/quotas/per-vm-quota-requests)

To decide on suitable VMs, it may be useful to refer to [Sizes for virtual machines in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/overview). A typical Charmed HPC deployment will use a mix of high-performance and GPU-accelerated compute VMs for cluster compute nodes, and general purpose VMs for other node types.

:::{admonition} Resource provider registration
:class: note

If the Azure Portal page for adjusting VM quota appears blank or contains the message "The selected provider is not registered for some of the selected subscriptions", confirm that [the *Microsoft.Compute* resource provider is registered](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types) for your subscription.
:::

### Add Azure cloud credentials to Juju

Azure supports a variety of authentication workflows with Juju. These instructions provide only a single example of creating a Service Principal to enable Juju to automatically create a Managed Identity. Refer to the [Juju documentation](https://documentation.ubuntu.com/juju/latest/user/reference/cloud/list-of-supported-clouds/the-microsoft-azure-cloud-and-juju/) for full details on authentication with Azure and **ensure you choose a method which meets requirements for security in your environment**.

To make your Azure credentials known to Juju, run:

:::{code-block} shell
juju add-credential azure
:::

This will start a script where you will be asked:

* `credential-name` — your choice of name that will help you identify the credential set, e.g. `my-az-credential`.
* `region` — a default region that is most convenient to deploy your controller and applications, e.g. `eastus`. Note that credentials are not region-specific.
* `auth type` — authentication type. Select `interactive`, the recommended way to authenticate to Azure using Juju.
* `subscription-id` — your Azure subscription ID, typical format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.
* `application_name` (optional) — any unique string to avoid collision with other users or applications. Leave blank to let the script decide.
* `role-definition-name` (optional) — any unique string to avoid collision with other users or applications. Leave blank to let the script decide.

You will be asked to authenticate the requests via your web browser with the following message:

:::{code-block} shell
To sign in, use a web browser to open the page https://microsoft.com/devicelogin
and enter the code <auth-code> to authenticate.
:::

In a web browser, open the [authentication page](https://microsoft.com/devicelogin), sign in as required, and enter the `<auth-code>` from the end of the authentication request shown in the terminal window. You will be asked to authenticate twice, to allow creation of two different resources in Azure.

Once the credentials have been added successfully, a message similar to the following will be displayed:

:::{code-block} shell
Credential "my-az-credential" added locally for cloud "azure".
:::

### Widen scope for credentials

To allow Juju to automatically create resources in Azure, further privileges should be granted to the credentials created above. Run, substituting `my-az-credential` with the name of your credential:

:::{terminal}
juju show-credentials azure my-az-credential
:::

which will show:

:::{terminal}
client-credentials:
  azure:
    my-az-credential:
      content:
        auth-type: service-principal-secret
        application-id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        application-object-id: <application-object-id>
        subscription-id: <subscription-id>
:::

Copy the value of `<application-object-id>` and run:

:::{code-block} shell
az role assignment create --assignee <application-object-id> --role Owner --scope /subscriptions/<subscription-id>
:::

This will grant the credential "full access to manage all resources". Refer to [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) for further details on the Owner role and other available roles.

### Bootstrap Azure cloud controller

With your credentials added, the Juju cloud environment can now be initialized or "bootstrapped". To bootstrap, first set the default region for deploying Azure instances, including the controller itself. Refer to [What are Azure regions?](https://learn.microsoft.com/en-us/azure/reliability/regions-overview) for an overview of available regions. To set the default region to East US:

:::{code-block} shell
juju default-region azure eastus
:::

Then deploy the cloud controller with the [`juju bootstrap`{l=shell}](https://documentation.ubuntu.com/juju/latest/user/reference/juju-cli/list-of-juju-cli-commands/bootstrap/) command, optionally providing your choice of memorable name for the controller (here `charmed-hpc-controller`):

:::{code-block} shell
juju bootstrap azure charmed-hpc-controller --constraints "instance-role=auto"
:::

After a few minutes, your Azure cloud controller will become active. The output of the `juju status`{l=shell} command should be similar to the following:

:::{terminal}
juju status -m controller

Model       Controller              Cloud/Region  Version  SLA          Timestamp
controller  charmed-hpc-controller  azure/eastus  3.6.3    unsupported  10:39:56Z

App         Version  Status  Scale  Charm            Channel     Rev  Exposed  Message
controller           active      1  juju-controller  3.6/stable  116  no

Unit           Workload  Agent  Machine  Public address  Ports  Message
controller/0*  active    idle   0        x.x.x.x

Machine  State    Address      Inst id        Base          AZ  Message
0        started  x.x.x.x      juju-e63b38-0  ubuntu@24.04
:::

::::

::::{tab-item} Amazon Web Services (AWS)
:sync: aws

To use AWS as the machine cloud for your Charmed HPC cluster, you will need to have:

* [Installed the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Authenticated into the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html)
* [Adjusted quotas for suitable EC2 instance types](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-quotas.html)

To decide on suitable instance types, it may be useful to refer to [Amazon EC2 Instance types](https://aws.amazon.com/ec2/instance-types/).
A typical Charmed HPC deployment will likely use a mix of HPC Optimized and Accelerated Computing instances for cluster compute
nodes, and general purpose instances for other node types.

### Create an AWS User

Juju requires an access key and a secret access key to authenticate against AWS, which allows it to create and manage
the controller instance.

First, create a new AWS user named `Juju`, and a new AWS group called `JujuGroup` for that user:

:::{code-block} shell
aws iam create-user --user-name Juju
aws iam create-group --group-name JujuGroup
aws iam add-user-to-group --user-name Juju --group-name JujuGroup
:::

Then, attach the required resource permissions to `JujuGroup`:

:::{code-block} shell
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name JujuGroup
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name JujuGroup
:::

:::{admonition} Juju permissions
:class: note

For simplicity's sake, these instructions configure the `Juju` user with full administrator access
to the EC2 and IAM resources. If you want to further restrict the permissions of the `Juju` user,
refer to [Define custom IAM permissions with customer managed policies][define-iam-policy].
Furthermore, [Refine permissions in AWS using last accessed information][perms] gives more information about how to
determine the correct subset of permissions for a managed policy.
:::

After creating the required user, generate the access key for the `Juju` user using the following command:

:::{code-block} shell
aws iam create-access-key --user-name Juju
:::

Take note of the secret access key and the access key ID, since those are the values required to authenticate
Juju.

[define-iam-policy]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html
[perms]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_last-accessed.html

### Add AWS cloud credentials to Juju

To make your AWS credentials known to Juju, run:

:::{code-block} shell
juju add-credential aws
:::

This will start a set of prompts where you will be asked:

* `credential-name` — Your choice of name that will help you identify the credential set, e.g. `my-aws-credential`.
* `region` — The region the credential is tied to e.g. `us-east-1`.
  Since AWS users are not tied to a specific AWS region, this can be left blank.
* `access-key` — The access key ID generated in the previous section, typically a 20-character alphanumeric string.
* `secret-key` — The secret access key generated in the previous section, typically an alphanumeric string with format `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/xxxxxxxx`.

:::{admonition} Characters not displayed
:class: warning

For security reasons, characters will NOT be displayed when entering the `secret-key` field. However, any input
(like the paste action) will still be captured by the script, even if it doesn't look like it.
:::

Once the credentials have been added successfully, a message similar to the following will be displayed:

:::{code-block} shell
Credential "my-aws-credential" added locally for cloud "aws".
:::

### Bootstrap AWS cloud controller

With your credentials added, the Juju cloud environment can now be initialized or "bootstrapped". To bootstrap, first set
the default region for deploying AWS instances, including the controller itself. Refer to [Regions, Availability Zones, and Local Zones][regions]
for an overview of available regions. To set the default region to US East (N. Virginia):

:::{code-block} shell
juju default-region aws us-east-1
:::

Then deploy the cloud controller with the [`juju bootstrap`{l=shell}][juju-bootstrap] command, optionally providing your
choice of memorable name for the controller (here `charmed-hpc-controller`):

:::{code-block} shell
juju bootstrap aws charmed-hpc-controller --bootstrap-constraints "instance-role=auto"
:::

After a few minutes, your AWS cloud controller will become active. The output of the `juju status`{l=shell} command should
be similar to the following:

:::{terminal}
juju status -m controller

Model       Controller              Cloud/Region   Version  SLA          Timestamp
controller  charmed-hpc-controller  aws/us-east-1  3.6.7    unsupported  17:33:14-06:00

App         Version  Status  Scale  Charm            Channel     Rev  Exposed  Message
controller           active      1  juju-controller  3.6/stable  116  yes

Unit           Workload  Agent  Machine  Public address  Ports      Message
controller/0*  active    idle   0        x.x.x.x         17022/tcp

Machine  State    Address      Inst id              Base          AZ          Message
0        started  x.x.x.x      i-1234e54321f987654  ubuntu@24.04  us-east-1a  running
:::

[regions]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html

::::

::::{tab-item} Google Cloud Platform (GCP)
:sync: gcp

:::{admonition} Juju isolation
:class: warning

Currently, Juju does not support any kind of isolation between Juju models and other resources created within
the same GCP project. This may make some processes more complex if you have special security requirements.
:::

To use GCP as the machine cloud for your Charmed HPC cluster, you will need to have:

* [Installed the gcloud CLI](https://cloud.google.com/sdk/docs/install)
* [Authenticated into the gcloud CLI](https://cloud.google.com/docs/authentication/gcloud)
* [Adjusted quotas for suitable Compute Engine machine families](https://cloud.google.com/compute/resource-usage#cpu_quota)

To decide on suitable instance types, it may be useful to refer to GCP's [Machine families resource and comparison guide][machines].
A typical Charmed HPC deployment will likely use a mix of Compute-optimized and Accelerator-optimized VMs
for cluster compute nodes, and General-purpose VMs for other node types.

[machines]: https://cloud.google.com/compute/docs/machine-resource

### Create a GCP Service Account

Juju requires a JSON file containing the Service Account key to authenticate Juju, which allows
it to create, remove, and manage machines.

First, create a new Service Account named `JujuService` in your GCP project, here `my-project`:

:::{code-block} shell
gcloud iam service-accounts create JujuService \
  --project="my-project" \
  --display-name="Juju Service Account"
:::

Then, attach the required IAM permissions to `JujuService`:

:::{code-block} shell
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:JujuService@my-project.iam.gserviceaccount.com" \
  --role="roles/compute.instanceAdmin.v1" \
  --role="roles/compute.securityAdmin"
:::

After creating the required Service Account, generate the Service Account key file for the `JujuService`
user using the following command:

:::{code-block} shell
gcloud iam service-accounts keys create ~/.local/share/juju/juju-sa-creds.json
:::

:::{admonition} Key file directory
:class: note

It is important that the key file is located in the directory path `~/.local/share/juju` for the
user that will manage the Juju CLI, since the tool does not have permissions to read files in other
directories.
:::

### Add GCP cloud credentials to Juju

To make your GCP credentials known to Juju, run:

:::{code-block} shell
juju add-credential google
:::

This will start a set of prompts where you will be asked:

* `credential-name` — Your choice of name that will help you identify the credential set. For example, `my-gcp-credential`.
* `region` — The region the credential is tied to. For example, `us-east-1`.
  Since GCP users are not tied to a specific GCP region, this can be left blank.
* `auth type` -- The method of authentication. You must input `jsonfile` here if you are following this how-to.
* `Path` -- The full path to the Service Account key file.

Once the credentials have been added successfully, a message similar to the following will be displayed:

:::{code-block} shell
Credential "my-gcp-credential" added locally for cloud "google".
:::

### Bootstrap GCP cloud controller

With your credentials added, the Juju cloud environment can now be initialized or "bootstrapped". To bootstrap, first set
the default region for deploying GCP instances, including the controller itself. Refer to
[Available regions and zones][gcp-regions] for an overview of available regions. To set the default region
to US East 1 (Moncks Corner, South Carolina):

:::{code-block} shell
juju default-region google us-east1
:::

:::{admonition} Zones and Regions
:class: note

Do not confuse Zones with Regions; Juju only requires a region and will pick a zone from that
region to deploy the machines on. Trying to provide a specific zone as the default region will
result in an error.
:::

Then deploy the cloud controller with the [`juju bootstrap`{l=shell}][juju-bootstrap] command, optionally providing your
choice of memorable name for the controller (here `charmed-hpc-controller`):

:::{code-block} shell
juju bootstrap google charmed-hpc-controller
:::

After a few minutes, your GCP cloud controller will become active. The output of the `juju status`{l=shell} command should
be similar to the following:

:::{terminal}
juju status -m controller

Model       Controller              Cloud/Region     Version  SLA          Timestamp
controller  charmed-hpc-controller  google/us-east1  3.6.8    unsupported  09:48:03-06:00

App         Version  Status  Scale  Charm            Channel     Rev  Exposed  Message
controller           active      1  juju-controller  3.6/stable  116  yes

Unit           Workload  Agent  Machine  Public address  Ports      Message
controller/0*  active    idle   0        x.x.x.x         17022/tcp

Machine  State    Address  Inst id        Base          AZ          Message
0        started  x.x.x.x  juju-806bc0-0  ubuntu@24.04  us-east1-b  RUNNING
:::

[gcp-regions]: https://cloud.google.com/compute/docs/regions-zones#available

::::

[juju-bootstrap]: https://documentation.ubuntu.com/juju/latest/user/reference/juju-cli/list-of-juju-cli-commands/bootstrap/

:::::

(howto-initialize-kubernetes-cloud)=
## Initialize Kubernetes cloud

After initializing the `charmed-hpc` machine cloud, follow the instructions below to initialize the
`charmed-hpc-k8s` Kubernetes cloud.

:::::{tab-set}

::::{tab-item} Canonical Kubernetes
:sync: lxd

### Prerequisites for Canonical Kubernetes

To use Canonical Kubernetes as the Kubernetes cloud for your Charmed HPC cluster,
you will need to have:

* [Initialized a machine cloud](#howto-initialize-machine-cloud)
* [Installed and bootstrapped Canonical Kubernetes](https://documentation.ubuntu.com/canonical-kubernetes/latest/snap/howto/install/snap/)
* [Enabled the default load balancer](https://documentation.ubuntu.com/canonical-kubernetes/latest/snap/howto/networking/default-loadbalancer/)

:::{admonition} New to Canonical Kubernetes?
:class: note

If you're unfamiliar with operating a Canonical Kubernetes cluster, see the
[Canonical Kubernetes tutorials](https://documentation.ubuntu.com/canonical-kubernetes/latest/snap/tutorial/)
for a high-level introduction to Canonical Kubernetes.
:::

### Add Canonical Kubernetes cloud to deployed controller

To make your Canonical Kubernetes cloud known to Juju and use the same controller as your
machine cloud, pipe the output of `k8s config`{l=shell} to `juju add-k8s`{l=shell} by running the
following command:

:::{code-block} shell
sudo k8s config | \
  juju add-k8s --controller charmed-hpc-controller charmed-hpc-k8s
:::

`juju add-k8s`{l=shell} will immediately add your Canonical Kubernetes cloud to the controller of your machine
cloud. The output of `juju clouds`{l=shell} should be similar to the following:

:::{terminal}
juju clouds --controller charmed-hpc-controller

Clouds available on the controller:
Cloud            Regions  Default  Type
charmed-hpc      1        default  lxd
charmed-hpc-k8s  1        default  k8s
:::

::::

::::{tab-item} Azure Kubernetes Service (AKS)
:sync: azure

### Prerequisites for Azure Kubernetes Service (AKS)

To use AKS as the Kubernetes cloud for your Charmed HPC cluster, you will need to have:

* [Initialized a machine cloud](#howto-initialize-machine-cloud)
* [Signed into the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively)
* [Adjusted quotas for suitable virtual machine (VM) families](https://learn.microsoft.com/en-us/azure/quotas/per-vm-quota-requests)

To decide on suitable VMs, it may be useful to refer to [Sizes for virtual machines in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/overview). VM sizes should be chosen to accommodate control plane applications like identity management and observability services.

### Create a new AKS cluster

Create a new [Azure Resource Group](https://learn.microsoft.com/en-us/cli/azure/manage-azure-groups-azure-cli) with your choice of name (here `aks`) in the same region as the machine cloud. For the East US region:

:::{code-block} shell
az group create --name aks --location eastus
:::

Bootstrap AKS in the new Azure Resource Group, using your choice of memorable name for the cluster instance (here `charmed-aks-cluster`) and adjusting node count and VM size to accommodate control plane applications and your requirements for availability:

:::{code-block} shell
az aks create -g aks -n charmed-aks-cluster --enable-managed-identity --node-count 1 --node-vm-size=Standard_D4s_v4 --generate-ssh-keys
:::

For further information on creating and sizing an AKS cluster, see the Azure guide: [Quickstart: Deploy an Azure Kubernetes Service (AKS) cluster using Azure CLI](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli).

### Add AKS cloud to deployed controller

To make your AKS cloud known to Juju and use the same controller as your machine cloud, first retrieve your AKS credentials:

:::{code-block} shell
az aks get-credentials --resource-group aks --name charmed-aks-cluster
:::

This will add your AKS credentials to the file `~/.kube/config`. Now, add the AKS cloud to the controller with the `juju add-k8s`{l=shell} command, providing the name of the existing controller, your choice of memorable name for the AKS cloud, and the name of the AKS cluster just added to the `~/.kube/config` file (here `charmed-hpc-controller`, `charmed-hpc-k8s`, and `charmed-aks-cluster` respectively):

:::{code-block} shell
juju add-k8s --controller charmed-hpc-controller charmed-hpc-k8s --cluster-name=charmed-aks-cluster
:::

With the AKS cloud added, the output of `juju clouds`{l=shell} for the controller should be similar to the following:

:::{terminal}
juju clouds --controller charmed-hpc-controller

Clouds available on the controller:
Cloud            Regions  Default  Type
azure            44       eastus   azure
charmed-hpc-k8s  1        eastus   k8s
:::

::::

::::{tab-item} Amazon Elastic Kubernetes Service (EKS)
:sync: aws

### Prerequisites for Amazon Elastic Kubernetes Service (EKS)

To use EKS as the Kubernetes cloud for your Charmed HPC cluster, you will need to have:

* [Initialized a machine cloud](#howto-initialize-machine-cloud)
* [Authenticated into the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html)
* [Installed the `eksctl` CLI](https://eksctl.io/installation/)

### Create a new EKS cluster

Bootstrap EKS using the `eksctl` command with your choice of memorable name for the cluster (here `charmed-eks-cluster`):

:::{code-block} shell
eksctl create cluster --name charmed-eks-cluster --ssh-access
:::

The previous command will use `~/.ssh/id_rsa.pub` as the default key path for SSH access to the nodes. You can also provide
the path to a local key or [create an AWS-managed key][aws-ssh-key], then provide it using the `--ssh-public-key` flag.

For further information on creating and sizing an EKS cluster, see [Get started with Amazon EKS – eksctl][eks-guide]
and [Creating and managing clusters][eksctl].

:::{admonition} SSO session name
:class: note

If you are getting the error `Error: failed to find SSO session section, Session name` when trying to create the
cluster, it could be caused by an incompatibility between `eksctl` and the AWS CLI v2; if the SSO session name
contains spaces, the AWS CLI will surround the name with apostrophes (') in the `sso-session` header, which the
`eksctl` CLI will fail to parse correctly. To fix this, you can either run `aws configure sso` and choose an SSO session
name that does not contain spaces, or manually edit the SSO session name in the `~/.aws/config` file.
:::

Running the `create cluster` command will write credentials for managing the EKS cluster in the `~/.kube/config` file.
However, it will write a longer cluster name than the one specified in the command to differentiate clusters created in
different AWS regions. To obtain the correct name of the cluster, you can run:

:::{code-block} shell
cat ~/.kube/config | grep 'name: charmed-eks-cluster'
:::

This should display something similar to:
:::{terminal}
cat ~/.kube/config | grep 'name: charmed-eks-cluster'

  name: charmed-eks-cluster.us-east-1.eksctl.io
:::

In this case, `charmed-eks-cluster.us-east-1.eksctl.io` is the name of the EKS cluster.

[aws-ssh-key]: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-keypairs.html#creating-a-key-pair
[eksctl]: https://eksctl.io/usage/creating-and-managing-clusters/
[eks-guide]: https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html

### Add EKS cloud to deployed controller

You can add the EKS cloud to the controller using the `/snap/juju/current/bin/juju add-k8s`{l=shell} command, providing
the name of the existing controller, your choice of memorable name for the EKS cloud, and the full name of the EKS cluster
just added to the `~/.kube/config` file (here `charmed-hpc-controller`, `charmed-hpc-k8s`, and
`charmed-eks-cluster.us-east-1.eksctl.io` respectively):

:::{code-block} shell
/snap/juju/current/bin/juju add-k8s charmed-hpc-k8s \
  --controller charmed-hpc-controller \
  --cluster-name=charmed-eks-cluster.us-east-1.eksctl.io
:::

:::{admonition} Juju client use
:class: warning

As mentioned in [Add a Kubernetes cloud](https://documentation.ubuntu.com/juju/3.6/howto/manage-clouds/#add-a-kubernetes-cloud),
for this step it is required that you use the 'raw' Juju client located in the snap directory (`/snap/juju/current/bin/juju`)
instead of the default client (`/snap/bin/juju`).
:::

With the EKS cloud added, the output of `juju clouds`{l=shell} for the controller should be similar to the following:

:::{terminal}
juju clouds --controller charmed-hpc-controller

Clouds available on the controller:
Cloud            Regions  Default    Type
aws              30       us-east-1  ec2
charmed-hpc-k8s  1        us-east-1  k8s
:::

::::

::::{tab-item} Google Kubernetes Engine (GKE)
:sync: gcp

### Prerequisites for Google Kubernetes Engine (GKE)

To use GKE as the Kubernetes cloud for your Charmed HPC cluster, you will need to have:

* [Initialized a machine cloud](#howto-initialize-machine-cloud)
* [Installed the `google-cloud-cli-gke-gcloud-auth-plugin` component](https://cloud.google.com/sdk/docs/components#additional_components)
* [Authenticated into the gcloud CLI](https://cloud.google.com/docs/authentication/gcloud)

### Set up default Service Account

:::{admonition} Account permissions
:class: note

For simplicity's sake, these instructions use the default Service Account to deploy and
manage the GKE cluster, but it is recommended that you
[use a least privileged account](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)
when deploying a cluster in a production environment.
:::

By default, GKE will use the default Service Account to deploy the cluster. To ensure you can run
system tasks like logging and monitoring on the Kubernetes cluster, you first need to ensure the
default Service Account has the `roles/container.defaultNodeServiceAccount` role. Assuming your
project ID is `my-project`, first get your project number:

:::{terminal}
gcloud projects describe my-project --format="value(projectNumber)"

12345678901
:::

Take note of the output (here `12345678901`) which should correspond to your project number,
and use that to grant the required role to the default Service Account:

:::{code-block} shell
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:12345678901-compute@developer.gserviceaccount.com" \
  --role="roles/container.defaultNodeServiceAccount"
:::

### Create a new GKE cluster

Bootstrap GKE using the `gcloud container clusters` command with your choice of memorable name for the
cluster (here `charmed-gke-cluster`):

:::{code-block} shell
gcloud container clusters create-auto charmed-gke-cluster \
  --project="my-project" \
  --location="us-east1"
:::

Then, get the credentials to access the cluster:

:::{code-block} shell
gcloud container clusters get-credentials CLUSTER_NAME \
    --project="my-project" \
    --location="us-east1"
:::

Running the `container clusters get-credentials` command will write the credentials into the `~/.kube/config` file.
However, it will write a longer cluster name than the one specified in the command to differentiate clusters
created in different GCP projects. To obtain the correct name of the cluster, you can run:

:::{code-block} shell
cat ~/.kube/config | grep 'name: .*charmed-gke-cluster'
:::

This should display something similar to:

:::{terminal}
cat ~/.kube/config | grep 'name: .*charmed-gke-cluster'

  name: gke_my-project_us-east1_charmed-gke-cluster
:::

In this case, `gke_my-project_us-east1_charmed-gke-cluster` is the name of the GKE cluster.

### Add GKE cloud to deployed controller

You can add the GKE cloud to the controller using the `/snap/juju/current/bin/juju add-k8s`{l=shell} command, providing
the name of the existing controller, your choice of memorable name for the GKE cloud, and the full name of the GKE cluster
just added to the `~/.kube/config` file (here `charmed-hpc-controller`, `charmed-hpc-k8s`, and
`gke_my-project_us-east1_charmed-gke-cluster` respectively):

:::{code-block} shell
/snap/juju/current/bin/juju add-k8s charmed-hpc-k8s \
  --controller charmed-hpc-controller \
  --cluster-name=gke_my-project_us-east1_charmed-gke-cluster
:::

:::{admonition} Juju client use
:class: warning

As mentioned in [Add a Kubernetes cloud](https://documentation.ubuntu.com/juju/3.6/howto/manage-clouds/#add-a-kubernetes-cloud),
for this step it is required that you use the 'raw' Juju client located in the snap directory (`/snap/juju/current/bin/juju`)
instead of the default client (`/snap/bin/juju`).
:::

With the GKE cloud added, the output of `juju clouds`{l=shell} for the controller should be similar to the following:

:::{terminal}
juju clouds --controller charmed-hpc-controller

Clouds available on the controller:
Cloud            Regions  Default    Type
google           30       us-east-1  gce
charmed-hpc-k8s  1        us-east-1  k8s
:::

::::

:::::

## Next steps

Now that both the `charmed-hpc` machine cloud and `charmed-hpc-k8s` Kubernetes cloud are initialized,
you can start deploying applications with Juju. Go to the {ref}`howto-deploy-deploy-slurm` guide
for how to deploy Slurm as the workload manager of your Charmed HPC cluster.

## Clean up

:::{admonition} Unused cloud resources
:class: warning

Always clean cloud resources that are no longer necessary! Abandoned resources are tricky to detect and can become expensive over time.
:::

Refer to {ref}`howto-cleanup-cloud-resources` for guidance on cleaning up resources in public clouds.
