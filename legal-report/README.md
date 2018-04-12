# SSF Legal Report

The `ssf_legal_report` is a Python script that generates a legal report of the [Symphony Software Foundation hosted projects](github.com/symphonyoss), to facilitate validation and compliance against the [SSF Legal Criteria](https://symphonyoss.atlassian.net/wiki/display/FM/Legal+Acceptance+Criteria?src=contextnavpagetreemode)

It identifies:
- Missing `LICENSE` or `NOTICE` files
- Apache Category B and X licenses by scanning projects line by line

In order to run the same validation also on transitive dependencies, the script allows to run system commands prior to the scanning (see `execute_commands:` below), so that projects can run platform-specific license reports and add files in the root project folder.

The default configuration provides support for Maven, Leiningen and Npm builds.

## Configuration
The report is configured with a YAML file (default is `./legal_report_config.yaml`) that allows you to configure:
- The github organisations, projects and (optionally) branches to scan
```
github_orgs:
  symphonyoss:
    contrib-toolbox:
    symphony-java-client:
      - master
      - develop
```
- Whether to preserve previous project checkouts or not; useful for testing, as it avoids to download the same project contents on every run (`preserve_downloads: true`)
- The report output format (`output_format: html`); if `html`, a `report.html` file will be created in the same folder where the command is executed; if `json`, a `reports/` folder will include a `.json` file for each project scanned where issues were found
- The reports output folder (`output: ./reports`)
- Folder where github projects are checked out (`github_checkout_folder: ./checkout`)
- OS commands executed before running the scan (`execute_commands:`, list)
- Check only master branch or all branches (`master_only: true`)
- Files to ignore (`excluded_files_list:`, list of regexp expressions)
- Apache Category B licenses (`category_b_licenses:`, list)
- Apache Category X licenses (`category_x_licenses:`, list)
- Strings that must be included in LICENSE file (`license_file_matches:`, list)

## Installation
In order to run the script, you need the following software installed:
- Python 2.7+ (`python`)
- [Python Pip](https://pip.pypa.io/en/stable/) (`which pip`)
- `pip install pyyaml`
- `git` (available on command-line)
- Apache Maven (`mvn -v`)
- Leiningen (`lein`)
- [NodeJs](https://nodejs.org/en/)
- `npm install -g license-report` (`which license-report`)

## Run
```
git clone git@github.com:symphonyoss/contrib-toolbox.git
cd contrib-toolbox/legal-report
cp legal_report_config.yaml.sample legal_report_config.yaml
python ssf_legal_report.py
```

## TODOs
- `os.popen` call could be reimplemented with proper libraries
- Improve function and file structure
- Bundle the app (work on `build.sh`)
- Improve code styling
