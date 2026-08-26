(cryptography)=
# Cryptography and authentication

Charmed HPC uses and provides options for a couple different cryptography and authentication methods, namely SACK (Slurm Auth and Cred Kiosk), which is Slurm's internal authentication system, and JWT (JSON Web Tokens).

(sack)=
## Slurm credentials and SACK

[SACK (Slurm Auth and Cred Kiosk)](https://slurm.schedmd.com/authentication.html#sack) is Slurm's internal authentication
subsystem that manages creating and validating credentials.

This subsystem is used by the following Charmed HPC Slurm charms:

- [`slurmctld`](https://charmhub.io/slurmctld)
- [`slurmd`](https://charmhub.io/slurmd)
- [`slurmdbd`](https://charmhub.io/slurmdbd)
- [`slurmrestd`](https://charmhub.io/slurmrestd)
- [`sackd`](https://charmhub.io/sackd)

SACK requires sharing a cryptographically secure key between all the Slurm nodes in a cluster. To generate this key, the charms
use the [`secrets`](https://docs.python.org/3/library/secrets.html) library from the Python Standard Library, which uses either
[`getrandom(2)`](https://manpages.ubuntu.com/manpages/resolute/man2/getrandom.2.html) if available, and
[`/dev/urandom`](https://en.wikipedia.org/wiki//dev/random) otherwise.



(jwt)=
## JSON Web Tokens (JWT)

Some Slurm charms support [JSON Web Tokens](https://jwt.io/) as an alternative authentication method for a Slurm cluster.

This service is used by the Slurm charms:

- [`slurmctld`](https://charmhub.io/slurmctld)
- [`slurmrestd`](https://charmhub.io/slurmrestd)

A shared private encryption key is required to verify the signature of client tokens. The current method uses RSA with a length of 2048 bits, which is generated using the [`cryptography`](https://pypi.org/project/cryptography/) package for Python, from PyPI.

The [Slurm documentation](https://slurm.schedmd.com/jwt.html) contains more information about the topic.
