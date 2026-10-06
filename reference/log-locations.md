---
myst:
  html_meta:
    description: Reference listing every relevant log location for the services that make up a Charmed HPC deployment, including Slurm, filesystem, identity, container runtime, and Juju logs.
---
(reference-log-locations)=
# Log locations

This page lists the on-disk log locations and journald units for every service deployed as part
of Charmed HPC, along with the command needed to read each one. Use it when troubleshooting a
cluster directly over SSH. For querying the same logs centrally once COS is integrated, see
{ref}`reference-monitoring-loki-logs`.

Log locations are grouped by the repository that provides the charm.

## Accessing logs

Every path on this page is a path on the machine running the unit, not on your workstation. Reach
it either by opening a shell on the machine:

:::{code-block} shell
juju ssh slurmctld/0
:::

Or by reading a single file without opening a shell:

:::{code-block} shell
juju ssh slurmctld/0 sudo cat /var/log/slurm/slurmctld.log
:::

To follow a log live:

:::{code-block} shell
juju ssh slurmctld/0 sudo tail -f /var/log/slurm/slurmctld.log
:::

Slurm daemon logs are owned by the `slurm` user and are not world-readable, so `sudo` is
required. To list which logs exist on a given machine:

:::{code-block} shell
juju ssh slurmctld/0 sudo ls -la /var/log/slurm /var/log/juju
:::

:::{note}
Unless stated otherwise, every charm also writes a Juju unit log. See
{ref}`reference-log-locations-juju` for those locations, which apply to all charms on this page.
:::

## Slurm workload manager

Provided by [`slurm-charms`](https://github.com/canonical/slurm-charms).

The Slurm charms write service log paths into `slurm.conf` and `slurmdbd.conf` at deployment
time. All Slurm daemon logs live under `/var/log/slurm`.

:::{csv-table}
:header: >
: charm, location or command, notes

slurmctld, `sudo cat /var/log/slurm/slurmctld.log`{l=shell}, Set by the charm via the `SlurmctldLogFile` option.
slurmd, `sudo cat /var/log/slurm/slurmd.log`{l=shell}, Set by the charm via the `SlurmdLogFile` option. Written on each compute node.
slurmdbd, `sudo cat /var/log/slurm/slurmdbd.log`{l=shell}, Set by the charm via the `LogFile` option.
sackd, `sudo journalctl -u sackd`{l=shell}, No log file is configured by the charm. Output goes to journald.
slurmrestd, `sudo journalctl -u slurmrestd`{l=shell}, "No log file is configured. The charm runs the daemon with `-vv`, so output goes to journald."
:::

To confirm the active paths rather than trusting the defaults above, read them back from the
running configuration:

:::{code-block} shell
juju ssh slurmctld/0 sudo scontrol show config | grep -i logfile
:::

### Scheduler logging

Scheduler decision logging is disabled by default. Enable it with:

:::{code-block} shell
juju config slurmctld slurm-conf-parameters="SlurmSchedLogFile=/var/log/slurm/slurmsched.log SlurmSchedLogLevel=1"
:::

Then read it with:

:::{code-block} shell
juju ssh slurmctld/0 sudo cat /var/log/slurm/slurmsched.log
:::

### Job completion logging

Job completion records are not written to a file by default. Enable file-based completion
logging with:

:::{code-block} shell
juju config slurmctld slurm-conf-parameters="JobCompType=jobcomp/filetxt JobCompLoc=/var/log/slurm/jobcomp.log"
:::

Then read it with:

:::{code-block} shell
juju ssh slurmctld/0 sudo cat /var/log/slurm/jobcomp.log
:::

:::{caution}
The `slurm-conf-parameters` option replaces the whole override block rather than merging into it.
Read the current value with `juju config slurmctld slurm-conf-parameters`{l=shell} first and
include any existing entries in the new value.
:::

### Job accounting

Job accounting is not written to a log file. The charm sets
`AccountingStorageType=accounting_storage/slurmdbd`, so records go to the MySQL database by way
of `slurmdbd`. Query them with `sacct` from any unit with the Slurm client installed, such as a
`sackd` login node:

:::{code-block} shell
juju ssh sackd/0 sacct --allusers --starttime 2026-01-01 --format JobID,JobName,User,State,Elapsed,ExitCode
:::

To see everything recorded for one job:

:::{code-block} shell
juju ssh sackd/0 sacct -j 1234 --long
:::

### Slurm-Mail

Deployed on `slurmctld` only when an `smtp` integration is present.

:::{csv-table}
:header: >
: source, location or command

`slurm-spool-mail`, `sudo cat /var/log/slurm-mail/slurm-spool-mail.log`{l=shell}
`slurm-send-mail`, `sudo cat /var/log/slurm-mail/slurm-send-mail.log`{l=shell}
Configuration in effect, `sudo cat /etc/slurm-mail/slurm-mail.conf`{l=shell}
:::

Both log paths are defined in the charm's default Slurm-Mail configuration. For debug output, set
`verbose = true` under the relevant section of `/etc/slurm-mail/slurm-mail.conf`.

### Slurm accounting database

`slurmdbd` stores accounting data in a MySQL database provided by the `mysql` charm. Database
server logs are not part of the Slurm charms:

:::{csv-table}
:header: >
: source, location or command

`mysqld` error log, `sudo cat /var/log/mysql/error.log`{l=shell}
`mysqld` service status, `sudo journalctl -u mysql`{l=shell}
`mysql-router`, `sudo journalctl -u mysqlrouter`{l=shell}
:::

## Filesystems

Provided by [`filesystem-charms`](https://github.com/canonical/filesystem-charms).

### filesystem-client

The client charm configures [`autofs`](https://man7.org/linux/man-pages/man5/autofs.5.html) to
mount shares on demand. It does not run a daemon of its own, so mount failures appear in the
`autofs` journal and the kernel ring buffer rather than a dedicated log file.

:::{csv-table}
:header: >
: source, location or command, notes

`autofs` service, `sudo journalctl -u autofs`{l=shell}, Mount and unmount activity for all managed shares.
Kernel mount errors, `sudo dmesg -T | grep -iE 'nfs|ceph|lustre'`{l=shell}, "NFS, CephFS and Lustre mounts fail in the kernel, so errors surface here rather than in userspace logs."
Kernel log file, `sudo cat /var/log/kern.log`{l=shell}, Persistent copy of the above. Survives reboots.
Current mounts, `findmnt -t nfs,nfs4,ceph,lustre`{l=shell}, Confirms what is actually mounted versus what the charm intended.
LNet debug log, `sudo lctl dk`{l=shell}, "Lustre in-kernel debug buffer, only when `enable-lustre` is `true`."
:::

The charm writes two autofs files per unit. Read them to confirm what the charm believes should
be mounted:

:::{code-block} shell
juju ssh filesystem-client/0 sudo cat /etc/auto.master.d/filesystem-client-0.autofs
juju ssh filesystem-client/0 sudo cat /etc/auto.filesystem-client-0
:::

The filename is the Juju unit name with `/` replaced by `-`. Where you do not know the unit
number, list the directory rather than guessing:

:::{code-block} shell
juju ssh filesystem-client/0 sudo ls /etc/auto.master.d/
:::

### lustre-server

Lustre servers log through the kernel. There is no `/var/log/lustre` directory.

:::{csv-table}
:header: >
: source, location or command, notes

Lustre target activity, `sudo dmesg -T | grep -i lustre`{l=shell}, "MGS, MDT and OST activity is logged by the kernel."
Kernel log file, `sudo cat /var/log/kern.log`{l=shell}, Persistent copy of the above.
Lustre debug log, `sudo lctl dk /tmp/lustre-debug.log`{l=shell}, "Dumps the in-kernel debug buffer to a file, which is the most detailed source for Lustre faults."
Target status, `sudo lctl dl`{l=shell}, Lists configured devices and their state.
LNet state, `sudo lnetctl net show -v`{l=shell}, Current network state rather than a log. Use alongside `lctl dk`.
ZFS pool faults, `sudo zpool events -v`{l=shell}, The charm uses ZFS-backed targets.
ZFS pool health, `sudo zpool status -v`{l=shell}, Point-in-time health rather than a log.
ZFS kernel errors, `sudo dmesg -T | grep -i zfs`{l=shell}, Pool import and I/O errors.
:::

### Proxy charms

The `cephfs-server-proxy`, `lustre-server-proxy` and `nfs-server-proxy` charms are
integration-only. They relay connection details to `filesystem-client` and run no local
workload, so the Juju unit log is the only log they produce.

:::{csv-table}
:header: >
: charm, location or command

cephfs-server-proxy, `juju debug-log --replay --include cephfs-server-proxy`{l=shell}
lustre-server-proxy, `juju debug-log --replay --include lustre-server-proxy`{l=shell}
nfs-server-proxy, `juju debug-log --replay --include nfs-server-proxy`{l=shell}
:::

The backing servers these charms point at sit outside the Charmed HPC deployment, so their logs
are not covered here. To identify which host to investigate, read the proxy's configuration:

:::{code-block} shell
juju config nfs-server-proxy
juju config cephfs-server-proxy
juju config lustre-server-proxy
:::

## Identity and access

### sssd-operator

Provided by [`sssd-operator`](https://github.com/canonical/sssd-operator).

:::{csv-table}
:header: >
: source, location or command, notes

`sssd` service, `sudo journalctl -u sssd`{l=shell}, Service start and configuration errors.
Monitor process, `sudo cat /var/log/sssd/sssd.log`{l=shell}, Top-level SSSD process log.
NSS responder, `sudo cat /var/log/sssd/sssd_nss.log`{l=shell}, User and group lookup failures.
PAM responder, `sudo cat /var/log/sssd/sssd_pam.log`{l=shell}, Authentication failures.
LDAP child, `sudo cat /var/log/sssd/ldap_child.log`{l=shell}, LDAP bind and TLS handshake failures.
Domain backend, `sudo ls /var/log/sssd/`{l=shell}, "The per-domain log is named `sssd_<domain>.log`, where `<domain>` comes from the LDAP integration. List the directory to find it."
Login attempts, `sudo cat /var/log/auth.log`{l=shell}, PAM results for user logins.
Effective configuration, `sudo cat /etc/sssd/sssd.conf`{l=shell}, Charm-managed. Shows the configured domains.
Lookup test, `getent passwd <username>`{l=shell}, Confirms whether resolution works without reading logs.
:::

SSSD logs little at its default level. To diagnose LDAP binding or lookup failures, open
`/etc/sssd/sssd.conf`, add `debug_level = 6` under the `[sssd]` section and any
`[domain/<name>]` sections of interest, then restart the service:

:::{code-block} shell
juju ssh sssd/0 sudo systemctl restart sssd
:::

:::{caution}
The charm manages `/etc/sssd/sssd.conf`, so a manual edit is overwritten on the next
configuration change or integration event. Treat this as a temporary diagnostic measure.
:::

TLS trust problems usually trace back to certificates the charm installs per integration. List
them with:

:::{code-block} shell
juju ssh sssd/0 sudo ls -R /usr/local/share/ca-certificates/
:::

### openssh-operator

Provided by [`openssh-operator`](https://github.com/canonical/openssh-operator).

:::{csv-table}
:header: >
: source, location or command, notes

`ssh` service, `sudo journalctl -u ssh`{l=shell}, Daemon start and configuration parse errors.
Login attempts, `sudo cat /var/log/auth.log`{l=shell}, Accepted and failed logins including public key and password attempts.
Failed logins only, `sudo grep -iE 'failed|invalid' /var/log/auth.log`{l=shell}, Narrows `auth.log` to authentication failures.
Server drop-ins, `sudo ls /etc/ssh/sshd_config.d/`{l=shell}, "Charm-written files are prefixed `99-charmed-openssh-`."
Client drop-ins, `sudo ls /etc/ssh/ssh_config.d/`{l=shell}, Same naming convention.
Configuration test, `sudo sshd -t`{l=shell}, Validates the merged configuration. Run this first when the daemon will not start.
Effective configuration, `sudo sshd -T`{l=shell}, Prints the fully merged configuration including all drop-ins.
:::

## Container runtime

### apptainer-operator

Provided by [`apptainer-operator`](https://github.com/canonical/apptainer-operator).

Apptainer is not a daemon. It runs as the invoking user and writes diagnostics to stderr, so
container failures land in the job's output files rather than a system log.

:::{csv-table}
:header: >
: source, location or command, notes

Job output path, `scontrol show job 1234 | grep -E 'StdOut|StdErr|WorkDir'`{l=shell}, Resolves the actual output paths for a running or recently completed job. Run from a login node.
Job output path after completion, "`sacct -j 1234 --format JobID,WorkDir%80`{l=shell}", "`scontrol` drops job records after `MinJobAge`. Use `sacct` for older jobs, then look for `slurm-1234.out` in `WorkDir`."
Default output file, `cat <WorkDir>/slurm-1234.out`{l=shell}, "Where `sbatch` was called without `--output`, substituting the `WorkDir` found above."
Container launch failures, `sudo cat /var/log/slurm/slurmd.log`{l=shell}, "The `oci.conf` run commands are invoked by `slurmd`, so OCI runtime failures are recorded on the compute node."
Effective OCI configuration, `sudo cat /etc/slurm/oci.conf`{l=shell}, Written by the charm on the `slurmctld` leader. Check when `--container` jobs fail to launch.
Verbose runtime output, `apptainer --debug exec docker://ubuntu:24.04 echo ok`{l=shell}, Run interactively on a compute node to diagnose image or namespace problems.
Installed version, `apptainer --version`{l=shell}, Confirms the charm installed the runtime.
:::

(reference-log-locations-juju)=
## Juju logs

Every charm on this page is a Juju machine charm, so the following applies throughout.

### On each machine

:::{csv-table}
:header: >
: source, location or command, notes

Unit log, `sudo cat /var/log/juju/unit-slurmctld-0.log`{l=shell}, "Charm code output for a single unit. The first place to look when a unit is in `error` or `blocked`. Substitute your application name and unit number."
Machine agent log, `sudo cat /var/log/juju/machine-0.log`{l=shell}, "Machine agent activity, including charm deployment and container provisioning."
All logs on a machine, `sudo ls -la /var/log/juju/`{l=shell}, "Lists every unit and machine log present, including those of subordinate charms."
Subordinate unit log, `sudo cat /var/log/juju/unit-apptainer-0.log`{l=shell}, "Subordinates such as `apptainer`, `sssd` and `filesystem-client` write their own unit log on the principal's machine."
:::

Unit log filenames follow `unit-<application>-<unit-number>.log`, which is the Juju unit name
with `/` replaced by `-`. Where you do not know the exact name, list the directory rather than
guessing.

### Through the Juju CLI

Prefer these over reading files directly, since they aggregate across the model and need no SSH
access.

:::{csv-table}
:header: >
: command, purpose

`juju debug-log`{l=shell}, Live tail of all agent logs in the current model.
`juju debug-log --replay`{l=shell}, Full retained history rather than only new entries.
`juju debug-log --replay --include slurmctld/0`{l=shell}, Restrict output to a single unit.
`juju debug-log --replay --include slurmctld`{l=shell}, Restrict output to all units of one application.
`juju debug-log --replay --level ERROR`{l=shell}, "Filter by severity. Accepts `TRACE`, `DEBUG`, `INFO`, `WARNING` and `ERROR`."
`juju debug-log --replay --no-tail > model.log`{l=shell}, Capture the full history to a local file and exit rather than following.
`juju show-status-log slurmctld/0`{l=shell}, "Status transition history for a unit, which is useful for tracing when a unit entered `blocked`."
`juju status --format yaml`{l=shell}, Full status including the message each unit last set.
:::

### Raising charm log verbosity

Charmed HPC charms log at `INFO` by default. Many handlers emit configuration diffs and service
state at `DEBUG`:

:::{code-block} shell
juju model-config logging-config="<root>=WARNING;unit=DEBUG"
:::

Then replay the log to see the new detail:

:::{code-block} shell
juju debug-log --replay --include slurmctld --level DEBUG
:::

Revert when finished:

:::{code-block} shell
juju model-config --reset logging-config
:::

:::{caution}
`DEBUG` logging on `slurmctld` is verbose in large clusters, since several handlers log the full
Slurm configuration. Avoid leaving it enabled.
:::

### Juju controller logs

Controller-side problems, such as a unit that never starts or an integration that never
completes, are logged on the controller rather than the workload machine:

:::{code-block} shell
juju switch controller
juju debug-log --replay
:::

On the controller machine itself:

:::{code-block} shell
juju switch controller
juju ssh 0 sudo cat /var/log/juju/machine-0.log
:::

### Security events

The Slurm charms emit structured OWASP-format security events for authentication key lifecycle
operations, such as creating and rotating the Slurm auth and JWT keys. These are logged at
`DEBUG` with a `"type": "security"` field, so raise unit logging to `DEBUG` first, then filter:

:::{code-block} shell
juju model-config logging-config="<root>=WARNING;unit=DEBUG"
juju debug-log --replay --include slurmctld --level DEBUG | grep '"type": "security"'
:::

## Log retention

Juju rotates unit and machine logs on each machine automatically. The controller retains model
logs subject to the `max-logs-size` and `max-logs-age` controller configuration values, so
`juju debug-log --replay` may not reach as far back as the on-disk logs on a given machine. Check
the current limits with:

:::{code-block} shell
juju controller-config | grep -i max-logs
:::

Slurm daemon logs under `/var/log/slurm` are rotated by the `logrotate` configuration shipped
with the Slurm Debian packages. The charms do not override it. To see the policy in effect:

:::{code-block} shell
juju ssh slurmctld/0 "sudo ls /etc/logrotate.d/ && sudo grep -rl slurm /etc/logrotate.d/ | xargs sudo cat"
:::
