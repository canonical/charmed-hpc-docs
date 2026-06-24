(contributing-to-docs)=
# Contributing to Charmed HPC's documentation

Contributions to Charmed HPC's documentation are welcomed and encouraged. Please read through the following guidelines to best prepare yourself for contributing. If you have questions, feel free to ask them in the the [Ubuntu High-Performance Computing Matrix chat](https://matrix.to/#/#hpc:ubuntu.com) or the [High-Performance Computing category on the Ubuntu Discourse](https://discourse.ubuntu.com/c/project/hpc/151).

(doc-structure)=
## Documentation structure

The documentation is written in the [MyST](https://mystmd.org/) flavor of the Markdown mark-up language and uses the [Diátaxis](https://diataxis.fr/) framework for content organization. The raw document files all hosted in the [Charmed HPC docs repository](https://github.com/canonical/charmed-hpc-docs) on GitHub and use the [Canonical Sphinx Stack](https://documentation.ubuntu.com/sphinx-stack/latest/) for theming, extensions, and rendering on [ReadtheDocs](https://about.readthedocs.com/). See Canonical's [MyST syntax guide](https://documentation.ubuntu.com/sphinx-stack/latest/reference/myst-syntax/) for formatting and preferred usage guidance.

## Prerequisites

There are a couple prerequisites to contributing to Charmed HPC's documentation:

* **GitHub Account:** The Charmed HPC project uses GitHub to host its documentation. You will need an active GitHub account to report issues and provide contributions. See [Creating an account on GitHub](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github) for more details.

* **Code of Conduct:** You must read and follow the Ubuntu [Code of Conduct](https://ubuntu.com/community/ethos/code-of-conduct) to contributed to Charmed HPC. Maintainers reserve the right to delete or remove any contributions that do not respect the Code of Conduct.

## Report an issue

To report an error in spelling, grammar, content, or documentation code functionality, [file an issue](https://github.com/canonical/charmed-hpc-docs/issues) in Charmed HPC's bug tracker on GitHub.

## Simple update

The easiest way to make a quick update, especially for those new to git and GitHub, is to use GitHub's [file editor](https://docs.github.com/en/repositories/working-with-files/managing-files/editing-files#editing-files-in-another-users-repository) through your web browser.

## Large contribution

For larger, more involved contributions, and those familiar with git and the command line, follow the [fork-and-branch](https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/) process. Be sure to familiarize yourself with the [Documentation structure](doc-structure) prior to any significant work.

## Test your contribution

To ensure that your contributions meet expectations and pass CI rules, check that they pass the repository's tests.

### Test locally

Install `npm` using the appropriate method for your operating system through one of the follow processes:
* Through your preferred package manager
* By following the [node version manager installation process](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm#using-a-node-version-manager-to-install-nodejs-and-npm)
* For Ubuntu and other snap-supported Linux distributions: `sudo snap install node --classic`

Then install commitlint:

```shell
npm install -D @commitlint/cli @commitlint/config-conventional
```

:::{admonition} Working directory
:class: warning

Make sure to run the commitlint installation command outside of the `docs` directory. The commitlint installation process installs a `node_modules` folder that should *not* become part of the `docs` repository.
:::

To run the tests:

| Command  | Usage |
|---------|-----|
| `make spelling`{l=shell} | Check for spelling errors; this command checks the HTML files in the `_build` directory. Fix any errors in the corresponding Markdown file |
| `make linkcheck`{l=shell} | Check for broken links |
| `make woke`{l=shell} | Check for non-inclusive language |
| `make pa11y`{l=shell} | Check for accessibility issues |
| `make vale`{l=shell} | Check for style guide compliance |
| `npx commitlint --from <start-ID> --to <end-ID> --verbose`{l=shell} | Check for commitlint compliance from git commit ID `<start-ID>` to commit ID `<end-ID>`|

For more information on setting up the tests locally, see [Run documentation checks](https://documentation.ubuntu.com/sphinx-stack/latest/how-to/run-documentation-checks/) within the Canonical Sphinx Stack documentation.

### Test through GitHub

If running the tests locally is not ideal, you may run them within GitHub. To do so, make sure any local changes have been pushed to your personal fork+branch and are visible from the web interface. Then, from the web interface for GitHub:

1. Go to the `Actions` tab.
2. Select the test of interest: `Automatic docs checks` or `docs test`
3. Select `Run workflow` within the workflows panel.
4. Select the relevant branch from the drop-down menu.
5. Select `Run workflow` within the drop-down.