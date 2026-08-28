---
relatedlinks: "[Slurm&#32;FAQ&#32;-&#32;How&#32;can&#32;I&#32;dry&#32;up&#32;the&#32;workload&#32;for&#32;a&#32;maintenance&#32;period?](https://slurm.schedmd.com/faq.html#maint_time), [Slurm&#32;Workload&#32;Manager&#32;-&#32;Authentication&#32;Plugins](https://slurm.schedmd.com/authentication.html)"
myst:
  html_meta:
    description: Instructions on how to rotate the Slurm authentication key and the JWT authentication key of a Charmed HPC cluster using the slurmctld charm actions.
---

(howto-manage-rotate-slurm-keys)=
# Rotate authentication keys

{term}`Slurm` uses two separate keys to secure cluster communication: an authentication key for
Slurm remote procedure calls, and a JSON Web Token (JWT) key for REST API authentication. This
guide provides instructions on how you can use the {term}`slurmctld` charm to rotate each of them.

Both procedures are cluster-wide changes that require a maintenance window. For background on why
and how often keys should be rotated, see {ref}`explanation-key-rotation`.

(howto-manage-rotate-auth-key)=
## Rotate the Slurm authentication key

:::{admonition} Rotation downtime
:class: warning

**Key rotation requires cluster downtime**.

Authentication key rotation is a significant cluster-wide change and may cause interruption to the controller, compute nodes, accounting database and REST API.

Downtime varies depending on the node count of the cluster.
:::

Before beginning the rotation process, ensure the cluster in an appropriate
state for maintenance. Refer to the Slurm FAQ: ["How can I dry up the workload for a maintenance period?"](https://slurm.schedmd.com/faq.html#maint_time)

The `rotate-auth-key` action can be run on the slurmctld leader unit to start the asynchronous
process of rotating the authentication key for Slurm remote procedure calls:

:::{code-block} shell
juju run slurmctld/leader rotate-auth-key
:::

After the command returns, progress of the rotation can be monitored by viewing the status of the
`slurmctld` leader unit:

:::{terminal}
juju status

[...]
Unit             Workload  Agent      Machine  Public address  Ports           Message
slurmctld/0*     waiting   executing  2        10.200.245.185  6817,9092/tcp   (rotate-auth-key) Authentication key rotation in progress. Waiting for rotation to complete.
[...]
:::

Once the unit returns to `active` status, the key rotation has completed. A new key is in place and
the previous key has been deleted. The cluster can now be restored to full service.

(howto-manage-rotate-jwt-key)=
## Rotate the JWT authentication key

:::{admonition} Rotation downtime
:class: warning

**Key rotation requires accounting database API downtime**.

JWT key rotation will result in the accounting database being inaccessible via the Slurm REST API
until the rotation process completes.

The duration of the downtime depends on the time taken for the `slurmdbd` unit to process the
rotation event.
:::

Before beginning the rotation process, ensure the cluster is in an appropriate state where database API
downtime can be tolerated.

The `rotate-auth-key` action can be run on the slurmctld leader unit to start the asynchronous
process of rotating the JWT key for API authentication:

:::{code-block} shell
juju run slurmctld/leader rotate-jwt-key
:::

After the command returns, progress of the rotation can be monitored by viewing the `slurmdbd` unit
status log:

:::{terminal}
juju show-status-log slurmdbd/0

[...]
20 Apr 2026 12:55:00+01:00  juju-unit  executing  running secret-changed hook for secret:aapaln45l33kcv0so3i0
20 Apr 2026 12:55:01+01:00  juju-unit  idle
20 Apr 2026 12:58:02+01:00  workload   active
[...]
:::

Once the unit has been observed running the `secret-changed` hook and then returning to `active` status,
the key rotation has completed. A new key is in place and the previous key has been deleted. The
cluster is now restored to full service.

## Related topics

Explanation:

* {ref}`explanation-key-rotation`
* {ref}`cryptography`
