import os
import urllib2
import re
import glob
import yaml
import sys
import json

report_template_file = "{}/report-template.html".format(os.path.dirname(os.path.realpath(__file__)))

def loadConfig():
    if len(sys.argv) > 1:
        configFile = sys.argv[1]
    else:
        configFile = "legal_report_config.yaml"
    with open(configFile, 'r') as stream:
        try:
            config = yaml.load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    config['excluded_files_re'] = "" "(" + ")|(".join(config['excluded_files_list']) + ")"

    if 'output' in config:
        config['report_dir'] = os.path.abspath(config['output'])

    return config

def executeCommands(config):
    if 'execute_commands' in config:
        for command in config['execute_commands']:
            print "Executing command '{}'".format(command)
            os.popen(command)

def replaceInFile(filePath,placeholder,value):
    with open("report.html", "wt") as fout:
        with open(filePath, "rt") as fin:
            for line in fin:
                fout.write(line.replace(placeholder, value))

def checkGithubOrg(config):
    currentDir = os.getcwd()
    projects = {}
    if not os.path.isdir(config['github_checkout_folder']):
        os.makedirs(config['github_checkout_folder'])
    os.chdir(config['github_checkout_folder'])
    for github_org in config['github_orgs']:
        for project in config['github_orgs'][github_org]:
            if not config['github_orgs'][github_org][project]:
                config['github_orgs'][github_org][project] = {"master" : None}
            for branch in config['github_orgs'][github_org][project]:
                customUrl = None
                if config['github_orgs'][github_org][project][branch]:
                    customUrl = config['github_orgs'][github_org][project][branch]
                projectFolder = downloadProject(config,github_org,project,branch,customUrl)
                os.chdir(projectFolder)
                checkProject(projects,config,project,projectFolder,branch)
                os.chdir("..")

    os.chdir(currentDir)
    if 'output_format' in config and config['output_format'] == "html":
        myjson = json.dumps(flattenHash(projects))
        replaceInFile(report_template_file,"{{JSON_VAR}}",myjson)

def downloadProject(config,github_org,project,branch,customUrl):
    if customUrl:
        project_zip_url = customUrl.split('|')[0]
        project_zip_path = customUrl.split('|')[1]
    else:
        project_zip_url = "https://codeload.github.com/{}/{}/zip/{}".format(github_org,project,branch)
        project_zip_path = "{}-{}".format(project,branch)
    if 'preserve_downloads' in config and config['preserve_downloads'] == True and os.path.isdir(project_zip_path):
        return project_zip_path

    project_zip_archive = "{}.zip".format(project_zip_path)
    print "downloading '{}' into '{}'".format(project_zip_url,project_zip_archive)
    os.popen("curl -L {} > {}".format(project_zip_url,project_zip_archive))
    print "unzipping '{}' into '{}'".format(project_zip_url,project_zip_path)
    os.popen("unzip {}".format(project_zip_archive))
    return project_zip_path

def checkProject(projects,config,project_name,project_checkout_folder,branch):
    print "Scanning project {}".format(project_name)
    violations = {}
    checkNoticeFile(config,violations)
    checkLicenseFile(config,violations)
    executeCommands(config)
    walk(violations,config,".")
    if violations:
        if 'output' in config:
            if not os.path.isdir(config['report_dir']):
                os.makedirs(config['report_dir'])
            if 'output_format' in config and config['output_format'] == 'json':
                output_file = "{}/report-{}-{}.json".format(config['report_dir'],project_name,branch)
                print("Exporting project results on file {}".format(output_file))
                with open(output_file, 'w+') as outfile:
                    json.dump(flattenHash(violations), outfile)

        else:
            print("Printing out results for project '{}', branch '{}'".format(project_checkout_folder,branch))
            print(flattenHash(violations))
    else:
        print("No issues found on project '{}', branch '{}'".format(project_checkout_folder,branch))
    projects[project_name] = flattenHash(violations)

def checkFile(violations,config,root,name):
    filePath = root + "/" + name
    with open(filePath) as search:
        for line in search:
            line = line.rstrip()  # remove '\n' at end of line
            checkLine(violations,filePath,line,config['category_b_licenses'],'categoryB')
            checkLine(violations,filePath,line,config['category_x_licenses'],'categoryX')
    search.close()

def checkLine(violations,filePath, line,licenses,category):
    for license in licenses:
        if license in line:
            if not filePath in violations:
                violations[filePath] = []
            violation = createViolation("LGL-4","Third-party code license warning",license,category,line)
            violations[filePath].append(violation)

def walk(violations,config,folder):
    for root, dirs, files in os.walk(folder, topdown=False):
        for name in files:
            path = "{}/{}".format(root,name)
            if not re.match(config['excluded_files_re'], path):
                checkFile(violations,config,root,name)
        for name in dirs:
            path = "{}/{}".format(root,name)
            if not re.match(config['excluded_files_re'], path):
                walk(violations,config,name)

def flattenHash(input_raw):
    result = {}
    for key,value in input_raw.items():
        if value not in result.values():
            result[key] = value
    return result

def createViolation(id,description,license,license_category,line):
    violation = {}
    violation['id'] = id
    violation['description'] = description
    if license: violation['license'] = license
    if license_category: violation['license_category'] = license_category
    if line: violation['line'] = line
    return violation

def checkLicenseFile(config,violations):
    globs = glob.glob('LICENSE*') + glob.glob('license*')
    if not globs:
        if not 'LICENSE' in violations:
            violations['LICENSE'] = []
        violation = createViolation("LGL-1","Missing LICENSE file",None,None,None)
        violations['LICENSE'].append(violation)
    else:
        for match in config['license_file_matches']:
            if not match in open(globs[0]).read():
                if not 'LICENSE' in violations:
                    violations['LICENSE'] = []
                violation = createViolation("LGL-1","LICENSE file not matching '{}'".format(match),None,None,None)
                violations[globs[0]].append(violation)
                break

def checkNoticeFile(config,violations):
    globs = glob.glob('NOTICE*') + glob.glob('notice*')
    if not globs:
        if not 'NOTICE' in violations:
            violations['NOTICE'] = []
        violation = createViolation("LGL-2","Missing NOTICE file",None,None,None)
        violations['NOTICE'].append(violation)
