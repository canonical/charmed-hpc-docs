(contributing-to-code)=
# Contributing to Charmed HPC's code

Charmed HPC is a open source project and welcomes community contributions. Please read through the following guidelines to best prepare yourself for making contributions. If you have questions, feel free to ask them in the [Ubuntu High-Performance Computing Matrix chat](https://matrix.to/#/#hpc:ubuntu.com) or the [High-Performance Computing category on the Ubuntu Discourse](https://discourse.ubuntu.com/c/project/hpc/151). 

## Report an issue

To report an issue or bug, file an issue in the appropriate repository's issue tracker; the full list of repositories is provided below. If you are unsure which repository the issue should belong to, share the issue in the [Ubuntu High-Performance Computing Matrix chat](https://matrix.to/#/#hpc:ubuntu.com) or the [High-Performance Computing category on the Ubuntu Discourse](https://discourse.ubuntu.com/c/project/hpc/151).


When reporting a bug, please:

* __Validate your issue__ &mdash; ensure that your issue is not being caused by either
a semantic or syntactic error in your environment.

* __Use the GitHub issue search__ &mdash; check if the issue you are encountering has
already been reported by someone else.

* __Check if the issue has already been fixed__ &mdash; try to reproduce your issue
using the latest revision of the repository.

* __Isolate the problem__ &mdash; the more pinpointed the issue, the easier it is to fix.

* __Provide context__ &mdash; your current environment, error reproduction in other environments, specific commands and actions to produce the error, and expected outcome.

## Enhancement proposals

While Charmed HPC's maintainers will often already have a plan for upcoming features, we welcome community ideas and potential improvements. The [Ubuntu High-Performance Computing Matrix chat](https://matrix.to/#/#hpc:ubuntu.com) or the [High-Performance Computing category on the Ubuntu Discourse](https://discourse.ubuntu.com/c/project/hpc/151) are good places for discussing open-ended questions, and more focused proposals can be created within a relevant repository's issue tracker.

## Pull requests

Good pull requests &mdash; patches, improvements, new features &mdash; are a huge help.

__Ask first__ before embarking on any significant pull request such as implementing new features, refactoring methods, or incorporating new libraries. Otherwise, you risk spending a lot of time working on a contribution that Charmed HPC's maintainers may be unable to include. For trivial changes and small contributions, you may feel free to open a pull request.

Adhering to the following process is the best way to have your contribution accepted:

1. [Fork](https://help.github.com/articles/fork-a-repo/) the project, clone your fork,
   and configure the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone https://github.com/<your-username>/<repository>.git

   # Navigate to the newly cloned directory
   cd <repository>

   # Assign the original repo to a remote called "upstream"
   git remote add upstream https://github.com/canonical/<repository>.git
   ```

2. If you cloned a while ago, pull the latest changes from the upstream repository:

   ```bash
   git checkout main
   git pull upstream main
   ```

3. Create a new topic branch (off the main project development branch) to
   contain your feature, change, or fix:

   ```bash
   git checkout -b <topic-branch-name>
   ```

4. Ensure that your changes pass all tests.

   The tests may differ for different repositories. See the corresponding repository's CONTRIBUTING file
    for details on the appropriate tests. 


5. Sign and commit and your changes in logical chunks to your topic branch, using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

   To set up GPG or SSH key signing with git, see 
   [GitHub's commit signature verification documentation](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
   
6. Locally rebase the upstream development branch into your topic branch:

   ```bash
   git pull --rebase upstream main
   ```

7. Push your topic branch up to your fork:

   ```bash
   git push origin <topic-branch-name>
   ```

8. [Open a Pull Request](https://help.github.com/articles/about-pull-requests/)
   with a clear title and description against the `main` branch. Your pull request should also be focused and not contain commits that are not related to what you are contributing.

9. Conditionally, open a corresponding Pull Request on the [`docs`](https://github.com/canonical/charmed-hpc-docs) repository, following the [canonical/charmed-hpc-docs CONTRIBUTING.md guidelines](https://github.com/canonical/charmed-hpc-docs/blob/main/CONTRIBUTING.md#pull-requests-and-contributing-process), if you are making user-facing changes.

## Charmed HPC GitHub Code Repositories

- [sssd-operator](https://github.com/canonical/sssd-operator)
- [apptainer-operator](https://github.com/canonical/apptainer-operator)
- [charmed-hpc-libs](https://github.com/canonical/charmed-hpc-libs)
- [slurmutils](https://github.com/canonical/slurmutils)
- [slurm-charms](https://github.com/canonical/slurm-charms)
- [filesystem-charms](https://github.com/canonical/filesystem-charms)
- [charmed-hpc-benchmarks](https://github.com/canonical/charmed-hpc-benchmarks)
- [charmed-hpc-terraform](https://github.com/canonical/charmed-hpc-terraform)
- [slurm-snap](https://github.com/canonical/slurm-snap)
- [ondemand-snap](https://github.com/canonical/ondemand-snap)
- [slurm-mail](https://github.com/canonical/slurm-mail)
- [mysql-proxy-operator](https://github.com/canonical/mysql-proxy-operator)
- [ood-portal-generator](https://github.com/canonical/ood-portal-generator)
- [sysprober](https://github.com/canonical/sysprober)

## Further resources

See the below resources for further guidance and useful references:

* [Charmed HPC's main GitHub CONTRIBUTING guidelines](https://github.com/canonical/hpc-team/blob/main/CONTRIBUTING.md)
* [Charmed HPC's documentation CONTRIBUTING guidelines](https://github.com/canonical/charmed-hpc-docs/blob/main/CONTRIBUTING.md)
* [Python code style guide](https://pep8.org/)
* [Juju documentation](https://documentation.ubuntu.com/juju)
* [Charmcraft documentation](https://canonical-charmcraft.readthedocs-hosted.com/stable/)
* [Ops framework documentation](https://ops.readthedocs.io/en/latest/) for Juju
* [Terraform/OpenTofu Provider for Juju documentation](https://documentation.ubuntu.com/terraform-provider-juju/latest/)
* [OpenTofu documentation](https://opentofu.org/docs/)
* [Slurm workload manager documentation](https://slurm.schedmd.com/documentation.html)
