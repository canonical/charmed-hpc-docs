(explanation)=
# Explanation

Conceptual background on the design, security, and hardware considerations of Charmed HPC.

## Cluster architecture

Design decisions behind how a Charmed HPC cluster is structured and operated.

- {ref}`explanation-high-availability`
- {ref}`explanation-job-email-notifications`
- {ref}`explanation-lustre`

## Cryptography, authentication, and security

Security protocols and authentication mechanisms that protect communication between cluster components.

- {ref}`sack`
- {ref}`jwt`
- {ref}`explanation-key-rotation`

## Hardware

How specialized hardware is supported and managed in a Charmed HPC cluster.

- {ref}`explanation-gpus`
- {ref}`explanation-interconnects`
- {ref}`explanation-rebooting`

```{toctree}
:titlesonly:
:maxdepth: 1
:hidden:

Cryptography and Authentication <cryptography>
Email notifications for jobs <job-email-notifications>
GPUs <gpus>
High Availability <high-availability>
Interconnects <interconnects>
Instance auto-reboots <reboot-timing.md>
Key rotation <key-rotation>
Lustre <lustre>
```
