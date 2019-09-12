# Contribution Toolbox

A collection of scripts and other tools used internally by the Symphony Software Foundation to automate [project lifecycle](https://symphonyoss.atlassian.net/wiki/display/FM/Project+Lifecycle) validations and transitions.

Available items:
- Project lifecycle badges, included in the [images/](images) folder; read more on our wiki about [lifecycle badges](https://symphonyoss.atlassian.net/wiki/display/FM/Incubating#Incubating-Badge)
- CI scripts:
  - [mvn-ssf-profiles.sh](scripts/mvn-ssf-profiles.sh) helps invoking Maven builds with per-branch build profiles; you can specify MVN_MASTER_PROFILES and MVN_ALLBRANCHES_PROFILES as comma-separated list of profiles to activate, based on the current SCM branch (`$SCM_BRANCH` in Travis CI)
  - [release-to-nuget.sh](scripts/release-to-nuget.sh) runs `nuget pack` only if the current branch (`$SCM_BRANCH` in Travis CI) is `master`
- Legal reports
  - [ssf_legal_report](legal-report/) is a Python script that generates a project report validating the [Foundation legal requirements](https://symphonyoss.atlassian.net/wiki/display/FM/Legal+Requirements)
- [validate-license-source.sh](validate-license-source.sh) is the deprecated version of `ssf_legal_report`

## Contributing

1. Fork it (<https://github.com/finos-fdx/contrib-toolbox/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Read our [contribution guidelines](.github/CONTRIBUTING.md) and [Community Code of Conduct](https://www.finos.org/code-of-conduct)
4. Commit your changes (`git commit -am 'Add some fooBar'`)
5. Push to the branch (`git push origin feature/fooBar`)
6. Create a new Pull Request

## License

The code in this repository is distributed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

Copyright 2016-2018 The Symphony Software Foundation
Copyright 2018-2019 FINOS

SPDX-License-Identifier: [Apache-2.0](https://spdx.org/licenses/Apache-2.0)
