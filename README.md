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
