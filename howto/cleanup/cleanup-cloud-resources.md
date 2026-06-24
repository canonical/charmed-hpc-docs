(howto-cleanup-cloud-resources)=
# How to clean up cloud resources

This guide demonstrates how to clean up {ref}`a previously initialized cloud environment <howto-initialize-cloud-environment>`
and a deployed Charmed HPC cluster. This includes clean-up of both the machine cloud and the Kubernetes (K8s) cloud. All compute plane and
control plane applications hosted on these clouds will be destroyed.

:::{admonition} Data loss warning
:class: warning

Clean-up may result in **permanent data loss**. Ensure all data you wish to preserve has been migrated to a safe location before proceeding.

Always clean up public cloud resources that are no longer necessary! Abandoned resources are tricky to detect and can become expensive over time.
:::

:::::{tab-set}

::::{tab-item} Microsoft Azure & AKS
:sync: azure

To clean up Microsoft Azure and Azure Kubernetes Service (AKS) resources, it is assumed you have:

* Bootstrapped a Juju controller on Azure
* Added AKS to the controller
* [Signed into the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively)

### Clean up Azure resources

List all controllers that have been registered to the local client with:

:::{code-block} shell
juju controllers
:::

To destroy the Juju controller and remove the Azure instance:

:::{code-block} shell
juju destroy-controller <controller name> --destroy-all-models --destroy-storage --force
:::

List current AKS instances with:

:::{code-block} shell
az aks list
:::

This will give JSON-formatted output representing the current AKS instances. Look for the values of `"name"` and `"resourceGroup"` in the output:

:::{code-block} shell
[
  {
    "aadProfile": null,
    [...]
    "name": "charmed-aks-cluster",
    [...]
    "resourceGroup": "aks",
    [...]
    },
  }
]
:::

Here `charmed-aks-cluster` and `aks`. Now delete both the instance and its resource group with the following commands (substituting in your AKS instance name for `charmed-aks-cluster` and your resource group for `aks`):

:::{code-block} shell
az aks delete -n charmed-aks-cluster -g aks
az group delete -n aks
:::

Destroying the controller or AKS instance may take a long time depending on the complexity of the deployment. Should the destroy process exceed 15 minutes or otherwise be seemingly stuck, you can proceed to delete resources manually [via the Azure web portal](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resources-portal) or [via the `az` CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resources-cli).

To list any remaining Azure resources, use:

:::{code-block} shell
az resource list
:::

This command will return `[]` if no Azure resources remain. If there are `charmed-hpc` resources showing, repeat the above steps. If not, proceed to the steps for cleaning up your credentials below.

### Clean up credentials

List your Juju credentials with:

:::{terminal}
juju credentials

Client Credentials:
Cloud        Credentials
azure        <your credential name>
:::

Remove Azure CLI credentials from Juju:

:::{code-block} shell
juju remove-credential azure <your credential name>
:::

After deleting the credential, the interactive process may not clean up its Azure role resource and assignment. Check the full list of role definitions with:

:::{code-block} shell
az role definition list
:::

Look for role definitions with `"roleType": "CustomRole"`. If a custom `<Azure role definition name>` was not specified when initially adding the credential, the `"roleName"` will be similar to `"Juju Role Definition"` or `"juju-controller-role"`, followed by an ID, otherwise it will be the custom name provided. These definitions should be removed if Juju is no longer in use.

To remove a role definition, first its assignments must be removed. To check whether a role assignment is bound to `<Azure role definition name>` run:

:::{code-block} shell
az role assignment list --role <Azure role definition name>
:::

The assignment and then the definition itself can be removed with:

:::{code-block} shell
az role assignment delete --role <Azure role definition name>
az role definition delete --name <Azure role definition name>
:::

To finish cleaning up, log out from Azure CLI:

:::{code-block} shell
az logout
:::

::::

::::{tab-item} Amazon Web Services & EKS
:sync: aws

To clean up Amazon Web Services and Amazon Elastic Kubernetes Service (EKS) resources, it is assumed you have:

* Bootstrapped a Juju controller on AWS
* Added EKS to the controller
* [Authenticated into the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html)
* [Installed the `eksctl` CLI](https://eksctl.io/installation/)

### Clean up AWS resources

List all controllers that have been registered to the local client with:

:::{code-block} shell
juju controllers
:::

To destroy the Juju controller and remove the AWS instance:

:::{code-block} shell
juju destroy-controller <controller name> --destroy-all-models --destroy-storage --force
:::

List current EKS clusters with:

:::{code-block} shell
aws eks list-clusters
:::

This will give JSON-formatted output representing the currently active EKS clusters. Identify the cluster used by Juju in
the output:

:::{code-block} shell
{
    "clusters": [
        "charmed-eks-cluster"
    ]
}
:::

Here `charmed-eks-cluster`. Now delete the cluster using the following command (substituting in your EKS cluster name for `charmed-eks-cluster`):

:::{code-block} shell
eksctl delete cluster charmed-eks-cluster
:::

Destroying the controller or EKS cluster may take a long time depending on the complexity of the deployment. Should the destroy
process exceed 15 minutes or otherwise be seemingly stuck, you can proceed to delete resources manually
[via the AWS Management Console][aws-console] or [via the `aws` CLI][aws-cli].

[aws-console]: https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/what-is.html
[aws-cli]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-using.html

### Clean up credentials

List your Juju credentials with:

:::{terminal}
juju credentials

Client Credentials:
Cloud        Credentials
aws        <your credential name>
:::

Remove AWS credentials from Juju:

:::{code-block} shell
juju remove-credential aws <your credential name>
:::

After deleting the credential, the interactive process may not clean up its AWS user and group. Check the full list of users with:

:::{code-block} shell
aws iam list-users
:::

Then, refer to [Deleting an IAM user (AWS CLI)](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_remove.html#id_users_deleting_cli)
for instructions on how to delete a user.

Next, list all the groups in the account with:

:::{code-block} shell
aws iam list-groups
:::

Then, refer to [Delete an IAM group](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups_manage_delete.html) for instructions
on how to delete a group.

If you created a managed policy to restrict the Juju user permissions, list all custom policies with:

:::{code-block} shell
aws iam list-policies --scope Local
:::

Then, refer to [Delete IAM policies (AWS CLI)](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage-delete-cli.html) for
instructions on how to delete a custom policy.

Finally, if you are using SSO to authenticate the AWS CLI, you can log out from the AWS CLI using:

:::{code-block} shell
aws sso logout
:::

::::

::::{tab-item} Google Cloud Platform & GKE
:sync: gcp

To clean up Google Cloud Platform and Google Kubernetes Engine (GKE) resources, it is assumed you have:


* [Authenticated into the gcloud CLI](https://cloud.google.com/docs/authentication/gcloud)
* Bootstrapped a Juju controller on GCP
* Added a GKE cluster to the controller

### Clean up GCP resources

List all controllers that have been registered to the local client with:

:::{code-block} shell
juju controllers
:::

To destroy the Juju controller and remove the GCP instance:

:::{code-block} shell
juju destroy-controller <controller name> --destroy-all-models --destroy-storage --force
:::

List current GKE clusters with:

:::{code-block} shell
gcloud container clusters list --project="my-project"
:::

This will give a list of currently active GKE clusters in the project `my-project`. Identify the cluster
used by Juju in the output:

:::{code-block} shell
NAME                 LOCATION  MASTER_VERSION      MASTER_IP    MACHINE_TYPE  NODE_VERSION        NUM_NODES  STATUS
charmed-gke-cluster  us-east1  1.33.2-gke.1111000  x.x.x.x      e2-small      1.33.2-gke.1111000             RUNNING
:::

Here `charmed-gke-cluster`. Now delete the cluster using the following command (substituting in your GKE cluster name for `charmed-gke-cluster`):

:::{code-block} shell
gcloud container clusters delete charmed-gke-cluster \
  --project="my-project" \
  --region="us-east1"
:::

Destroying the controller or EKS cluster may take a long time depending on the complexity of the deployment. Should the destroy
process exceed 15 minutes or otherwise be seemingly stuck, you can proceed to delete resources manually
[via the Google Cloud Console][gcloud-console] or [via the `gcloud` CLI][gcloud-cli].

[gcloud-console]: https://console.cloud.google.com
[gcloud-cli]: https://cloud.google.com/sdk/gcloud

### Clean up credentials

List your Juju credentials with:

:::{terminal}
juju credentials

Client Credentials:
Cloud        Credentials
google       <your credential name>
:::

Remove AWS credentials from Juju:

:::{code-block} shell
juju remove-credential google <your credential name>
:::

After deleting the credential, the interactive process may not clean up its Service Account. Check the full list of accounts with:

:::{terminal}
gcloud iam service-accounts list --project="my-project"

Compute Engine default service account  12345678901-compute@developer.gserviceaccount.com  False
Juju Service Account                    JujuService@my-project.iam.gserviceaccount.com     False
:::

Then, delete the corresponding Service Account used by Juju (here, `Juju Service Account`) by its email:

:::{code-block} shell
gcloud iam service-accounts delete JujuService@my-project.iam.gserviceaccount.com \
  --project="my-project"
:::

Finally, if you want to log out of the gcloud CLI:

:::{code-block} shell
gcloud auth revoke my-user@my-email.com
:::

::::

:::::
