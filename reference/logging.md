---
myst:
  html_meta:
    description: Reference for the logs of the services that make up a Charmed HPC deployment, covering log locations, read commands, verbosity, and retention for Slurm, filesystem, identity, container runtime, and Juju services.
---
(reference-log-locations)=
# Logging

This page lists the on-disk log locations and journald units for every service deployed as part
of Charmed HPC along with the command needed to read each one. Use it when troubleshooting a cluster from the controller node. Some of these logs are also sent to {term}`Loki` when COS is
integrated. For info on how to query them, see {ref}`reference-monitoring-loki-logs`.

Sections are grouped by the service that writes the logs. The charm that provides each service
is named alongside it.

(reference-log-locations-accessing)=
## Accessing logs

Read logs over SSH with `juju ssh`{l=shell} from the juju controller. Unit names throughout this page, such as `slurmctld/0`, are the default application
name and unit number. Substitute your own where your deployment differs:

:::{csv-table}
:header: >
: task, command, notes

Open a shell on a unit, `juju ssh <unit>`{l=shell}, "For example, `juju ssh slurmctld/0`{l=shell} opens a shell on the first `slurmctld` unit."
Read a log file without a shell, `juju ssh slurmctld/0 sudo cat /var/log/slurm/slurmctld.log`{l=shell}, Passes the read command to `juju ssh`{l=shell} rather than opening a shell.
Follow a log live, `juju ssh slurmctld/0 sudo tail -f /var/log/slurm/slurmctld.log`{l=shell}, Streams new lines as they are written.
List a unit's log directories, `juju ssh slurmctld/0 sudo ls -la /var/log/slurm /var/log/juju`{l=shell}, "Which directories exist depends on the services the unit runs, for example `/var/log/sssd` on an `sssd` unit. The sections below list them per service."
:::

:::{note}
Unless stated otherwise, every charm also writes a Juju unit log. See
{ref}`reference-log-locations-juju` for those locations, which apply to all charms on this page.
:::

(reference-log-locations-slurm)=
## Slurm workload manager

Provided by [`slurm-charms`](https://github.com/canonical/slurm-charms).

At deployment time the `slurmctld` charm writes the service log paths into `slurm.conf` and
`slurmdbd` does the same in `slurmdbd.conf`. All Slurm daemon logs live under `/var/log/slurm`.
The Slurm packages create this directory rather than the charms. Its files are not world-readable
so read them with `sudo`:

:::{csv-table}
:header: >
: service, location or command, notes

slurmctld, `sudo cat /var/log/slurm/slurmctld.log`{l=shell}, Path set by the `slurmctld` charm via the `SlurmctldLogFile` option.
slurmd, `sudo cat /var/log/slurm/slurmd.log`{l=shell}, "Written on each compute node. The path is set via `SlurmdLogFile`, which the `slurmctld` charm writes into `slurm.conf`. The `slurmd` charm runs configless and takes the value from the controller."
slurmdbd, `sudo cat /var/log/slurm/slurmdbd.log`{l=shell}, Path set by the `slurmdbd` charm via the `LogFile` option.
sackd, `sudo journalctl -u sackd`{l=shell}, No log file is configured by the charm. Output goes to journald.
slurmrestd, `sudo journalctl -u slurmrestd`{l=shell}, "No log file is configured. The charm runs the daemon with `-vv`, so output goes to journald."
:::

:::{note}
`slurmctld` and `slurmdbd` run as the `slurm` user, but `slurmd` runs as `root`, so
`slurmd.log` is root-owned while the other two are owned by `slurm`. Ownership and permissions
come from the Slurm packages rather than the charms.
:::

To confirm the paths in effect, read them back from the running configuration:

:::{code-block} shell
juju ssh slurmctld/0 sudo scontrol show config | grep -i logfile
:::

None of the Slurm charms expose a dedicated option for log paths or verbosity. Set these
through the general-purpose `slurm-conf-parameters` option on `slurmctld` and
`slurmdbd-conf-parameters` on `slurmdbd`. Both options pass any `slurm.conf` or `slurmdbd.conf`
setting through to the daemon as seen in the sections below.

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

### Raising Slurm daemon verbosity

The Slurm daemons log at `info` by default. Raise a daemon's verbosity through the same override
option:

:::{code-block} shell
juju config slurmctld slurm-conf-parameters="SlurmctldDebug=debug2 SlurmdDebug=debug2"
:::

`slurmdbd` has its own override option:

:::{code-block} shell
juju config slurmdbd slurmdbd-conf-parameters="DebugLevel=debug2"
:::

:::{caution}
Both `slurm-conf-parameters` and `slurmdbd-conf-parameters` replace the whole override block
rather than merging into it. Read the current value first and include any existing entries in
the new value:

```shell
juju config slurmctld slurm-conf-parameters
juju config slurmdbd slurmdbd-conf-parameters
```

Both options are applied by the application leader only.
:::

### Job accounting

Job accounting is not written to a log file. When integrated with `slurmdbd`, the `slurmctld`
charm sets `AccountingStorageType=accounting_storage/slurmdbd` and `slurmdbd` stores the
records in a MySQL database provided by the `mysql` charm. For how to deploy `slurmdbd` with
MySQL, see {ref}`howto-deploy-deploy-slurm`.

Query recent records with `sacct` from any unit with the Slurm client installed, such as a
`sackd` login node:

:::{code-block} shell
juju ssh sackd/0 sacct --allusers --starttime now-1days --format JobID,JobName,User,State,Elapsed,ExitCode
:::

To see everything recorded for one job:

:::{code-block} shell
juju ssh sackd/0 sacct -j 1234 --long
:::

List the fields available to `--format` with `sacct --helpformat`{l=shell}. For the full set of
filters, output fields and job state codes, see the
[Slurm `sacct` documentation {octicon}`link-external`](https://slurm.schedmd.com/sacct.html).

:::{note}
Each `sacct` call sends a remote procedure call to `slurmdbd`. Slurm advises against running it
from loops or scripts since enough concurrent calls can degrade the daemon. See
[Performance {octicon}`link-external`](https://slurm.schedmd.com/sacct.html#SECTION_PERFORMANCE)
in the sacct documentation.
:::

If `sacct` shows no recent records, or the `slurmdbd` log reports database connection errors,
look at the database server next. The `mysql` charm runs MySQL from the `charmed-mysql` snap,
so its logs are under `/var/snap` rather than `/var/log/mysql`. These logs are not part of the
Slurm charms:

:::{csv-table}
:header: >
: source, location or command, notes

`mysqld` error log, `sudo cat /var/snap/charmed-mysql/common/var/log/mysql/error.log`{l=shell}, "Server startup, shutdown and runtime errors, including refused connections."
`mysqld` service output, `sudo snap logs charmed-mysql.mysqld`{l=shell}, Service restarts and failures.
Snap service state, `sudo snap services charmed-mysql`{l=shell}, Confirms whether `mysqld` is running and enabled.
:::

(reference-log-locations-slurm-mail)=
### Slurm-Mail

Deployed on `slurmctld` only when an `smtp` integration is present. For how to set up the
integration, see {ref}`howto-integrate-email-notifications`.

Slurm-Mail sends job emails in two steps. When a job needs a notification, `slurmctld` runs
`slurm-spool-mail`, which writes a spool file under `/var/spool/slurm-mail` instead of sending the
email directly, so `slurmctld` does not block on mail delivery. A cron job shipped in the
`slurm-mail` package runs `slurm-send-mail` once a minute to send the spooled emails over SMTP.

:::{csv-table}
:header: >
: source, location or command, notes

`slurm-spool-mail`, `sudo cat /var/log/slurm-mail/slurm-spool-mail.log`{l=shell}, One entry per spooled job notification.
`slurm-send-mail`, `sudo cat /var/log/slurm-mail/slurm-send-mail.log`{l=shell}, "SMTP delivery attempts and errors, including rejected or invalid addresses."
Spool directory, `sudo ls -la /var/spool/slurm-mail`{l=shell}, Files waiting to be sent. A growing backlog means `slurm-send-mail` is failing.
Configuration in effect, `sudo cat /etc/slurm-mail/slurm-mail.conf`{l=shell}, The file both commands read. The charm writes the SMTP settings from the `smtp` integration into it.
Cron schedule, `sudo cat /etc/cron.d/slurm-mail`{l=shell}, Shipped by the `slurm-mail` package. Runs `slurm-send-mail` every minute.
:::

Both log paths are set by the charm in `/etc/slurm-mail/slurm-mail.conf`. Verbosity is
per-command rather than global: each of the two tools reads the `verbose` key from its own
section. To get debug output from both, set `verbose = true` under both
`[slurm-spool-mail]` and `[slurm-send-mail]`.

:::{note}
The charm rewrites the SMTP keys in `[slurm-send-mail]` on every configuration change and
`smtp` integration event but leaves `verbose` alone. A manual change to it survives.
:::

(reference-log-locations-filesystems)=
## Filesystems

Provided by [`filesystem-charms`](https://github.com/canonical/filesystem-charms).

### filesystem-client

The client charm configures [`autofs`](https://man7.org/linux/man-pages/man5/autofs.5.html) to
mount shares on demand. It does not run a service of its own, so mount failures appear in the
`autofs` journal and the kernel ring buffer rather than a dedicated log file.

:::{csv-table}
:header: >
: source, location or command, notes

`autofs` service, `sudo journalctl -u autofs`{l=shell}, "Mount and unmount activity for all managed shares. The charm reloads or restarts this service when the generated map changes."
Kernel mount errors, `sudo dmesg -T | grep -iE 'nfs|ceph|lustre'`{l=shell}, "NFS, CephFS and Lustre mounts fail in the kernel, so errors surface here rather than in userspace logs."
Kernel log file, `sudo cat /var/log/kern.log`{l=shell}, Persistent copy of the above. Survives reboots.
LNet debug log, `sudo lctl dk`{l=shell}, "Lustre in-kernel debug buffer, only when `enable-lustre` is `true`."
Current mounts, "`findmnt -t autofs,nfs,nfs4,ceph,lustre`{l=shell}", "Confirms what is actually mounted versus what the charm intended. CephFS mounts report the kernel type `ceph`, and NFSv4 mounts report `nfs4`."
:::

The charm writes two `autofs` files per unit. Read them to confirm which mounts the charm
configured:

:::{code-block} shell
juju ssh filesystem-client/0 sudo cat /etc/auto.master.d/filesystem-client-0.autofs
juju ssh filesystem-client/0 sudo cat /etc/auto.filesystem-client-0
:::

Both filenames are built from the Juju unit name with `/` replaced by `-`. The master drop-in
adds a `.autofs` suffix and the map file adds an `auto.` prefix. The application name is part
of the unit name so a renamed application changes both paths. Both files are readable only by
root. If you do not know the exact names, list the directory to find them:

:::{code-block} shell
juju ssh filesystem-client/0 sudo ls /etc/auto.master.d/
:::

### lustre-server

Lustre servers log through the kernel. There is no `/var/log/lustre` directory. The charm
formats its targets on ZFS, so ZFS faults are a common root cause of Lustre errors.

:::{csv-table}
:header: >
: source, location or command, notes

Lustre target activity, `sudo dmesg -T | grep -i lustre`{l=shell}, "MGS, MDS and OSS activity is logged by the kernel."
Kernel log file, `sudo cat /var/log/kern.log`{l=shell}, Persistent copy of the above.
Lustre debug log, `sudo lctl dk /tmp/lustre-debug.log`{l=shell}, "Dumps the in-kernel debug buffer to a file, which is the most detailed source for Lustre faults."
Target status, `sudo lctl dl`{l=shell}, Lists configured devices and their state.
Mounted targets, `findmnt -t lustre`{l=shell}, "The combined MGT and MDT mounts at `/mnt/mgs_mdt`, and each OST at `/mnt/ost<index>`."
LNet state, `sudo lnetctl net show -v`{l=shell}, Current network state rather than a log. Use alongside `lctl dk`.
ZFS pool faults, `sudo zpool events -v`{l=shell}, The charm formats all targets with a ZFS backing filesystem.
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
juju config lustre-server-proxy
:::

:::{caution}
The `cephfs-server-proxy` charm holds a Cephx key in its `auth-info` option which
`juju config cephfs-server-proxy`{l=shell} prints in plain text. Read it only where that is
acceptable, or read the individual non-secret options instead:

```shell
juju config cephfs-server-proxy fsid
juju config cephfs-server-proxy sharepoint
juju config cephfs-server-proxy monitor-hosts
```
:::

(reference-log-locations-identity)=
## Identity and access

### SSSD

Provided by the `sssd` charm, from
[`sssd-operator`](https://github.com/canonical/sssd-operator). The charm installs SSSD from the
Ubuntu archive, so the standard package paths apply.

:::{csv-table}
:header: >
: source, location or command, notes

`sssd` service, `sudo journalctl -u sssd`{l=shell}, Service start and configuration errors.
Monitor process, `sudo cat /var/log/sssd/sssd.log`{l=shell}, Top-level SSSD process log.
NSS responder, `sudo cat /var/log/sssd/sssd_nss.log`{l=shell}, User and group lookup failures.
PAM responder, `sudo cat /var/log/sssd/sssd_pam.log`{l=shell}, Authentication failures.
LDAP child, `sudo cat /var/log/sssd/ldap_child.log`{l=shell}, LDAP bind and TLS handshake failures.
Domain backend, `sudo ls /var/log/sssd/`{l=shell}, "The per-domain log is named `sssd_<domain>.log`. The charm names the domain after the application providing the `ldap` integration, so with GLAuth deployed as `glauth` the file is `sssd_glauth.log`. List the directory to confirm."
Login attempts, `sudo cat /var/log/auth.log`{l=shell}, PAM results for user logins.
Effective configuration, `sudo cat /etc/sssd/sssd.conf`{l=shell}, Charm-managed. Shows the configured domains.
Lookup test, `getent passwd <username>`{l=shell}, Confirms whether resolution works without reading logs.
:::

SSSD logs little at its default level and the `sssd` charm exposes no configuration options at
all so there is no way to raise it through Juju. To diagnose LDAP binding or lookup failures,
open `/etc/sssd/sssd.conf` and add `debug_level = 6` under the `[sssd]` section and any
`[domain/<name>]` sections of interest. Then restart the service:

:::{code-block} shell
juju ssh sssd/0 sudo systemctl restart sssd
:::

:::{caution}
The charm rewrites `/etc/sssd/sssd.conf` on every `ldap` and `certificates` integration event,
so a manual edit is lost the next time one fires. Treat this as a temporary diagnostic measure.
:::

TLS trust problems usually trace back to certificates the charm installs per integration. The
charm writes them to `/usr/local/share/ca-certificates/<integration-id>/cert-<n>.crt`, where
`<integration-id>` is the numeric Juju integration ID. List them with:

:::{code-block} shell
juju ssh sssd/0 sudo ls -R /usr/local/share/ca-certificates/
:::

### OpenSSH

Provided by the `openssh` charm, from
[`openssh-operator`](https://github.com/canonical/openssh-operator).

:::{csv-table}
:header: >
: source, location or command, notes

`ssh` service, `sudo journalctl -u ssh`{l=shell}, Daemon start and configuration parse errors.
Login attempts, `sudo cat /var/log/auth.log`{l=shell}, Accepted and failed logins including public key and password attempts.
Failed logins only, `sudo grep -iE 'failed|invalid' /var/log/auth.log`{l=shell}, Narrows `auth.log` to authentication failures.
Charm-written drop-ins, `sudo ls /etc/ssh/ssh_config.d/`{l=shell}, "Every file the charm writes lives here and is named `99-charmed-openssh-<slug>.conf`. The charm leaves all other files in the directory untouched."
Configuration test, `sudo sshd -t`{l=shell}, Validates the merged configuration. Run this first when the daemon will not start.
Effective configuration, `sudo sshd -T`{l=shell}, Prints the fully merged configuration including all drop-ins.
:::

The charm writes one drop-in per setting it manages. `99-charmed-openssh-log-level.conf` and
`99-charmed-openssh-port.conf` come from charm configuration and each `ssh-config` integration
adds a `99-charmed-openssh-ssh-config-<integration-id>-<application>.conf` file. The charm
validates the merged configuration with `sshd -t` after applying integration data. If validation
fails, it removes the offending file and blocks the unit.

Unlike SSSD, the OpenSSH charm can raise daemon verbosity through Juju. Set the `log-level`
option to any `LogLevel` value accepted by `sshd_config`:

:::{code-block} shell
juju config openssh log-level=debug
:::

Then read the new detail from `auth.log` and the service journal:

:::{code-block} shell
juju ssh openssh/0 sudo journalctl -u ssh --since '5 min ago'
:::

Revert when finished:

:::{code-block} shell
juju config openssh --reset log-level
:::

:::{caution}
`debug` and above may record sensitive user data. Do not leave these levels enabled in
production.
:::

(reference-log-locations-container-runtime)=
## Container runtime

### Apptainer

Provided by the `apptainer` charm, from
[`apptainer-operator`](https://github.com/canonical/apptainer-operator).

Apptainer is not a daemon. It runs as the invoking user and writes diagnostics to stderr so
container failures land in the job's output files rather than a system log. The charm itself
does not create a service or log file and does not expose configuration options so its Juju unit log
is the only record of what it did.

:::{csv-table}
:header: >
: source, location or command, notes

Job output path, `scontrol show job 1234 | grep -E 'StdOut|StdErr|WorkDir'`{l=shell}, Resolves the actual output paths for a running or recently completed job. Run from a login node.
Job output path after completion, "`sacct -j 1234 --format JobID,WorkDir%80`{l=shell}", "`scontrol` drops job records after `MinJobAge`. Use `sacct` for older jobs, then look for `slurm-1234.out` in `WorkDir`. The `%80` suffix widens the column so long paths are not truncated. See the [`sacct` documentation {octicon}`link-external`](https://slurm.schedmd.com/sacct.html)."
Default output file, `cat <WorkDir>/slurm-1234.out`{l=shell}, "Where `sbatch` was called without `--output`, substituting the `WorkDir` found above."
Container launch failures, `sudo cat /var/log/slurm/slurmd.log`{l=shell}, "The `oci.conf` run commands are invoked by `slurmd`, so OCI runtime failures are recorded on the compute node."
Effective OCI configuration, `sudo cat /etc/slurm/oci.conf`{l=shell}, "Read this on a `slurmctld` unit. Check when `--container` jobs fail to launch."
Verbose runtime output, `apptainer --debug exec docker://ubuntu:24.04 echo ok`{l=shell}, Run interactively on a compute node to diagnose image or namespace problems. Global flags must precede the subcommand.
Installed version, `apptainer --version`{l=shell}, Confirms the charm installed the runtime.
:::

:::{note}
`/etc/slurm/oci.conf` is written by the `slurmctld` charm from configuration that the
`apptainer` leader unit publishes over the `oci-runtime` integration. If the file is missing or
stale, check the unit logs of both applications:

```shell
juju debug-log --replay --include apptainer --include slurmctld
```
:::

(reference-log-locations-juju)=
## Juju logs

Every charm on this page also writes a Juju unit log in addition to the workload logs above.
These record what the charm did: which handlers ran, the configuration it rendered and the
status each unit last reported. When a unit is in `error` or `blocked`, they usually hold the
explanation. Each machine holds one file per unit and per agent under `/var/log/juju` and the
controller retains the same logs for the whole model. For more, including how to forward these
logs to an external syslog server, see the
[upstream Juju documentation](https://documentation.ubuntu.com/juju/latest/howto/manage-logs/).

### On each machine

:::{csv-table}
:header: >
: source, location or command, notes

Unit log, `sudo cat /var/log/juju/unit-<application>-<unit-number>.log`{l=shell}, "Charm code output for a single unit. The first place to look when a unit is in `error` or `blocked`."
Subordinate unit log, `sudo cat /var/log/juju/unit-apptainer-0.log`{l=shell}, "Subordinates such as `apptainer`, `sssd`, `openssh` and `filesystem-client` write their own unit log on the principal's machine."
Machine agent log, `sudo cat /var/log/juju/machine-<machine-number>.log`{l=shell}, "Machine agent activity, including charm deployment and container provisioning."
All logs on a machine, `sudo ls -la /var/log/juju/`{l=shell}, "Lists every unit and machine log present, including those of subordinate charms and any rotated `.log.gz` backups."
:::

Unit log filenames follow `unit-<application>-<unit-number>.log`, which is the Juju unit name
with `/` replaced by `-`. If you do not know the exact name, list the directory to find it.

### Through the Juju CLI

Prefer these over reading files directly since they aggregate across the model and need no SSH
access.

:::{csv-table}
:header: >
: command, purpose

`juju debug-log`{l=shell}, "Live tail of all agent logs in the current model, starting from the last 10 lines."
`juju debug-log --replay`{l=shell}, Full retained history rather than only new entries.
`juju debug-log --replay --include <unit>`{l=shell}, Restrict output to a single unit.
`juju debug-log --replay --include <application>`{l=shell}, Restrict output to all units of one application.
`juju debug-log --replay --level ERROR`{l=shell}, "Show this severity and above. Accepts `TRACE`, `DEBUG`, `INFO`, `WARNING` and `ERROR`."
`juju debug-log --replay --no-tail > model.log`{l=shell}, Capture the full history to a local file and exit rather than following.
`juju show-status-log <unit>`{l=shell}, "Status transition history for a unit, useful for tracing when a unit entered `blocked`."
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
juju debug-log --replay --include <application> --level DEBUG
:::

Revert when finished:

:::{code-block} shell
juju model-config --reset logging-config
:::

:::{caution}
`DEBUG` logging on `slurmctld` is verbose in large clusters since several handlers log the full
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
operations, such as setting and removing the Slurm auth and JWT keys. The events carry an OWASP
severity in their own `level` field but every one of them is emitted at Python `DEBUG` level.
Raise unit logging to `DEBUG` first, then filter on the `type` field:

:::{code-block} shell
juju model-config logging-config="<root>=WARNING;unit=DEBUG"
juju debug-log --replay --level DEBUG | grep '"type": "security"'
:::

Each event is a single JSON object with `datetime`, `level`, `type`, `appid`, `event` and
`description` fields. The `event` field holds an OWASP event name and the key it applies to,
such as `authn_token_created:slurm-auth` or `authn_token_deleted:slurm-jwt`. A key rotation
appears as a `created` event followed later by a `deleted` event rather than a single rotation
event.

:::{note}
Key handling lives in code shared by all the Slurm charms so these events can appear on
`sackd`, `slurmd`, `slurmdbd` and `slurmrestd` as well as `slurmctld`. Omit `--include` when
searching or filter per application once you know where to look.
:::

(reference-log-locations-retention)=
## Log retention

Juju rotates its own unit and machine agent logs on each machine automatically and keeps a
number of compressed backups alongside the current file. The controller also retains model logs
subject to its own size and backup limits, so `juju debug-log --replay` may not reach as far
back as the on-disk logs on a given machine. Check the current limits with:

:::{code-block} shell
juju controller-config | grep -iE 'logfile-max|audit-log-max'
:::

This covers `agent-logfile-max-size` and `agent-logfile-max-backups` for the agent logs on each
machine, `model-logfile-max-size` and `model-logfile-max-backups` for the model logs the
controller keeps, and the `audit-log-max-*` keys for the controller audit log. These are
normally set at bootstrap with `juju bootstrap --config`. See the
[list of controller configuration keys](https://documentation.ubuntu.com/juju/latest/reference/configuration/list-of-controller-configuration-keys/)
for which can be changed afterwards.

The Slurm charms do not install or override any `logrotate` configuration, so rotation of
`/var/log/slurm` depends on what the Slurm packages ship. Slurm-Mail is the exception: its
package installs `/etc/logrotate.d/slurm-mail`, which rotates `/var/log/slurm-mail/*.log`
weekly and keeps five compressed backups. To see the policies in effect on any unit:

:::{code-block} shell
juju ssh <unit> "sudo ls /etc/logrotate.d/ && sudo grep -rl slurm /etc/logrotate.d/ | xargs sudo cat"
:::
