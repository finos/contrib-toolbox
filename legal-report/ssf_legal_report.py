from legal_report_utils import loadConfig, checkGithubOrg

# Prerequisites:
# - Python 2.7+
# - git available on command-line
# - Apache Maven
# - Leiningen
# - npm install -g license-report

config = loadConfig()
checkGithubOrg(config)
