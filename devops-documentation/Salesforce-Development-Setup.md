# Salesforce Setup for Development
Before you can begin coding or customizing Salesforce, you must have a login to a Salesforce org (devhub or developer) and complete these software prerequisites. Then complete the steps in the Add Repository to VSC section. This page also lists very useful SFDX commands for:
- [Org Authentication](Salesforce-Development-Setup.md#Org-Authentication)
- [Create a Scratch Org](Salesforce-Development-Setup.md#Create-a-Scratch-Org)
- [Deploy Metadata to Org](Salesforce-Development-Setup.md#Deploy-Metadata-to-Org)
- [Retrieve Metadata from Org](Salesforce-Development-Setup.md#Retrieve-Metadata-from-Org)
- [Run Tests and Check Development Standards](Salesforce-Development-Setup.md#Run-Tests-and-Check-Development-Standards)


### Software Prerequisite
These software tools need to be installed on your computer.
1. [Salesforce CLI (sfdx) tool](https://developer.salesforce.com/tools/sfdxcli)
2. [Visual Studio Code + all the Salesforce extensions installed](https://developer.salesforce.com/tools/vscode/)
3. Access to a Git repository
4. Access to a Salesforce Dev Hub to build Scratch orgs or access to a Developer org.

If you are new to any of these tools, you should complete the [Set Up Your Workspace and Install Developer Tools](https://trailhead.salesforce.com/en/content/learn/trails/set-up-your-workspace-and-install-developer-tools) trail on Salesforce Trailhead.


### Add Repository to VSC
A lot of this process is documented in the [Salesforce VSC documentation](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models/). Below is a summary of the required steps. It assumes you already have a Git repository with the [Salesforce project directory](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_create_new.htm) structure.

1. Clone the Salesforce project Git repository to your local computer and open the directory in VSC. VSC also has a `Git Add Remote` command that lets you clone the repository in VSC - you just need the repository url.
2. The current branch you're working on is shown on the VSC status bar on the bottom left. Click on the branch name to change it or to create a new feature branch. Change the Git branch to dev if it's not already set.
3. In VSC open the command palette (ctrl + shift + p), start typing *Run SFDX: Authorize an Org* and select it. Select the right SF domain to login to (developer orgs are login.salesforce.com and sandboxes and scratch orgs are test.salesforce.com). On the next step, give the org an alias and then a browser window will open for you to login to Salesforce. Once you login, your VSC project will be connected to the Salesforce org.\
*Important Note:* If you have already authorized an org on your computer using sfdx, there is a place on the VSC status bar (at bottom) where you can select an org that's already been authenticated. You can select this for the project instead of authorizing again.
4. Once you've authorized an Org, right click on the manifest/package.xml file and select *SFDX: Deploy Source in Manifest to Org*. This will push all the metadata and code from the repository into your SF Org. You can also use the SFDX [Deploy Metadata to Org](Salesforce-Development-Setup.md#Deploy-Metadata-to-Org) command if you prefer using a CLI.


### SFDX Commands
Here's a list of useful and common SFDX (the Salesforce CLI tool) commands you'll use when developing and packaging in Salesforce. These commands need to run in the root directory of your Salesforce project. You can run these commands using the Terminal in VSC or a Windows cmd prompt. You can view all commands in the [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_top.htm) document for more details.


#### Org Authentication
Authenticate to a devhub org with an alias = devhub so SFDX is authorized to use it. The devhub authentication is used to build scratch orgs. You only need to authenticate to an org once.
```
sfdx auth:web:login --setalias devhub --setdefaultdevhubusername --instanceurl https://login.salesforce.com
```

Authenticate to a org with an alias = dev so SFDX is authorized to use it. You won't need to do this for scratch orgs - only permanent orgs. See instructions below on how to create a scratch org.
```
sfdx auth:web:login --setalias dev --setdefaultusername --instanceurl https://test.salesforce.com
```

Set a default username for SFDX if you didn't do this during the auth:web:login.
```
sfdx config:set defaultusername=dev
```

Set a default dev hub username for SFDX if you didn't do this during the auth:web:login.
```
sfdx config:set defaultdevhubusername=devhub
```

List all authorized orgs.
```
sfdx force:org:list
```

Open an authorized org in a browser.
```
sfdx force:org:open -u scratch
```

Logout of an org so SFDX can no longer use it.
```
sfdx auth:logout -u dev
```

#### Create a Scratch Org
Authenticate to a devhub org with an alias = devhub and sets it as the default devhub org. The devhub org authentication is used to create scratch orgs and build packages. You only need to login to the devhub org once - you will remain authorized to the devhub org until you run the `sfdx auth:logout` command.
```
sfdx auth:web:login --setalias devhub --setdefaultdevhubusername --instanceurl https://login.salesforce.com
```

Change the `adminEmail` in the script above to your email address so you'll receive Apex errors and package install emails. Also change the `username` value to include your email address with something unique at the end. This command builds a scratch org that lasts 30 days with a *scratch* alias and sets it as your default org.
```
sfdx force:org:create -f config/project-scratch-def.json --durationdays 30 --setalias scratch --setdefaultusername --targetdevhubusername devhub adminEmail=quentin.fish@ust.com username=quentin@ust.com.2021.10.31
```

Deploy all metadata defined in the manifest/package.xml to your Salesforce scratch org.
```
sfdx force:source:deploy -x manifest/package.xml -u scratch
```

Assign the a permission set named "PermSet" to your scratch org user.
```
sfdx force:user:permset:assign -n PermSet -u scratch
```

Open the Salesforce scratch org in a browser. You will not need to login since you are already authenticated in SFDX.
```
sfdx force:org:open -u scratch
```

Generate a password for the scratch user you just created. You only need to do this if you want to let someone else login to your scratch org from a browser.
```
sfdx force:user:password:generate -u scratch
```

Display the scratch org password you generated with the previous command. You only need to do this if you want to let someone else login to your scratch org from a browser.
```
sfdx force:user:display -u scratch
```


#### Delete a Scratch Org
Deletes a scratch org named *scratch*. We have a limited number of scratch orgs so make it a habit to delete ones you no longer need so we don't run out.
```
sfdx force:org:delete -u scratch
```


#### Deploy Metadata to Org
Deploy (push) all metadata and code from the Git branch on your local computer to your SF dev org. Only metadata defined in manifest/package.xml is deployed.
```
sfdx force:source:deploy -x manifest/package.xml -u scratch
```


#### Retrieve Metadata from Org
Retrieve (pull) all metadata and code defined in the manifest/package.xml from your SF dev org to your computer.
```
sfdx force:source:retrieve -x manifest/package.xml -u scratch
```


### Run Tests and Check Development Standards
Runs all unit tests in your dev org.
```
sfdx force:apex:test:run --testlevel RunLocalTests --codecoverage --resultformat human -u scratch
```

Lint all LWC and Aura components in the repository.
```
npm run lint
```

Run the Apex static source scanner on code in the repository. Requires the sfdx scanner plugin. You should create a [custom Apex PMD ruleset](https://github.com/pmd/pmd/blob/master/pmd-apex/src/main/resources/rulesets/apex/quickstart.xml) and store it in pmd/ruleset.xml to only run rules important to the project.
```
sfdx scanner:run --target=force-app/main/default --engine pmd --pmdconfig "pmd/ruleset.xml"
```


#### Other
Install the sfdx scanner plugin - https://forcedotcom.github.io/sfdx-scanner/en/getting-started/install/.
```
sfdx plugins:install @salesforce/sfdx-scanner
```

Display the API limits for the dev hub.
```
sfdx force:limits:api:display -u devhub
```

List the version of SFDX that you're using.
```
sfdx --version
```

List all the config settings for SFDX.
```
sfdx config:list
```

Update the SFDX CLI tool to the latest version.
```
sfdx update
```

Update the SFDX plugins to the latest version.
```
sfdx plugins:update
```


### Other Information
We use a *.gitattributes* file in our repo to handle line ending differences between Window and MacOS. More details are here - https://docs.github.com/en/github/using-git/configuring-git-to-handle-line-endings
