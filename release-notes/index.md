(release-notes)=
# Release notes

Release notes for Charmed HPC. As a single product composed of a portfolio of charms and supporting artifacts, the release notes summarise new features, bug and security fixes, and also contain the artifacts, upstream versions, and compatible third-party charm versions that were tested together for a given release, together with any breaking changes, deprecations, and known issues.

## Releases

- {ref}`release-notes-1-0-rc`

## Release policy and schedule

Releases are numbered `<major>.<minor>` and follow a six-month cycle with two scheduled release slots: one major release and one minor feature release, alternating approximately every three months. Minor patch releases are unschedule and cut as needed due to criticality. 

Both minor feature and minor patch releases increment the same minor version number, so the version alone does not distinguish them. Each release's notes will clearly state which kind it is.

### Ubuntu base support

Each Charmed HPC major release is built against the latest Ubuntu LTS release at the time it is cut, and all minor releases within that major release use the same base. A given Charmed HPC release supports a single Ubuntu base; running a release on any other base is not supported. Moving to a new Ubuntu base is a breaking change and only occurs in a new major release.

### Compatibility between releases

Within a major release, Charmed HPC components are **forward compatible**: a component from an older minor release can interact with and accept data from a newer minor release of the same major release. This includes the initial major release — for example, components from `1.0` can interoperate with components from `1.1` and later, although features introduced in a later release are not available to the older component. To use a new feature, every component that participates in it must be refreshed to the minor release that introduced it, or later.

Components from different major releases should not be used together.

### Mixed-version deployments

Only the set of versions listed in a single release's release notes is tested together. Mismatched component versions within the same major release are intended to work by virtue of the forward compatibility design, but are not guaranteed. If you encounter an issue with an unvalidated combination, you may submit an issue on GitHub; however, the common resolution will be to update to a supported component version set.

:::{toctree}
:titlesonly:
:maxdepth: 1
:hidden:

1.0-rc
:::
