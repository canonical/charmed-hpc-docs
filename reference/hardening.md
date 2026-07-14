---
myst:
  html_meta:
    description: Security hardening guidelines for Charmed HPC, covering Slurm, cloud providers, Juju orchestration, monitoring, and Ubuntu OS security.
---

(reference-hardening)=
# Security hardening guidelines

Charmed HPC is designed for security out-of-the-box but this guide serves as a companion to help tailor security measures to your environment.

For an overview of Charmed HPC security features see:

- {ref}`cryptography`

(reference-hardening-slurm)=
## Slurm

Slurm is the underlying workload scheduler for Charmed HPC and particular care should be taken with user-facing components such as the `sackd` login nodes and the REST API.

By default, Charmed HPC does not enable SSH access to the login nodes, other than through the `juju ssh` command available to administrators. Administrators should follow best practices for securing SSH servers when opening the nodes up to their cluster users. A non-exhaustive list of potential options includes:

- Use of SSH keys for authentication
- Enforcing use of strong, modern ciphers
- Use of [Fail2ban](https://github.com/fail2ban/fail2ban) or equivalent tool to block brute-force attacks
- Limiting access to particular IP ranges

For REST API security guidance, see:

- [Slurm REST API - Security](https://slurm.schedmd.com/rest.html#security)

(reference-hardening-cloud)=
## Cloud

Charmed HPC can be deployed on a variety of backing clouds. Security documentation for common clouds can be found at:

:::{csv-table}
:header: >
: cloud, security guide

AWS, "[Security, Identity & Compliance](https://aws.amazon.com/architecture/security-identity-compliance/), [AWS security credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html)"
Azure, "[Security best practices and patterns](https://learn.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns), [Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/)"
Google Cloud, [Security documentation](https://cloud.google.com/docs/security)
MAAS, "[About MAAS security](https://canonical.com/maas/docs/about-maas-security), [How to enhance MAAS security](https://canonical.com/maas/docs/how-to-enhance-maas-security)"
:::

(reference-hardening-juju)=
## Juju

Juju is the underlying orchestration engine for managing the Charmed HPC Slurm charms throughout their lifecycle. For general Juju security considerations, see:

- [Juju security](https://documentation.ubuntu.com/juju/latest/explanation/juju-security/index.html)
- [Harden your Juju deployment](https://documentation.ubuntu.com/juju/latest/howto/manage-your-juju-deployment/harden-your-juju-deployment/)

### Cloud credentials

When initializing a backing cloud with Juju, it is essential that the credentials provided have suitable access rights and permissions. For guidance see:

- {ref}`howto-initialize-cloud-environment`
- Juju's [List of supported clouds](https://documentation.ubuntu.com/juju/latest/reference/cloud/list-of-supported-clouds/)

For cloud-specific resources, see:

:::{csv-table}
:header: >
: cloud, security guide

AWS, "[The Amazon EC2 cloud and Juju](https://canonical.com/juju/docs/juju-cli/latest/reference/cloud/list-of-supported-clouds/amazon-ec2), [Juju AWS Permissions](https://discourse.charmhub.io/t/juju-aws-permissions/5307)"
Azure, "[The Microsoft Azure cloud and Juju](https://documentation.ubuntu.com/juju/latest/reference/cloud/list-of-supported-clouds/the-microsoft-azure-cloud-and-juju/), [How to use Juju with Microsoft Azure ](https://discourse.charmhub.io/t/how-to-use-juju-with-microsoft-azure/15219)"
Google Cloud, [The Google GCE cloud and Juju](https://documentation.ubuntu.com/juju/latest/reference/cloud/list-of-supported-clouds/the-google-gce-cloud-and-juju/index.html)
MAAS, [The MAAS cloud and Juju](https://documentation.ubuntu.com/juju/latest/reference/cloud/list-of-supported-clouds/the-maas-cloud-and-juju/)
:::

(reference-hardening-monitoring)=
## Monitoring and auditing

Charmed HPC supports integration with the Canonical Observability Stack (COS) to provide system monitoring and logging, see:

- {ref}`howto-manage-integrate-with-cos`
- [Best practices for production deployments of COS Lite](https://charmhub.io/topics/canonical-observability-stack/reference/best-practices)

(reference-hardening-os)=
## Operating system

Charmed HPC runs on the Ubuntu operating system. For documentation on Ubuntu security and compliance, see:

- [Security Compliance & Certifications](https://ubuntu.com/security/certifications/docs)