# Salesforce Setup for Development
Before you can begin coding or customizing Salesforce, you must have a login to a Salesforce org (devhub or developer) and complete these software prerequisites. Then complete the steps in the Add Repository to VSC section.

### Software Prerequisite
These software tools need to be installed on your computer.
1. [Salesforce CLI (sfdx) tool](https://developer.salesforce.com/tools/sfdxcli)
2. A Git repository
3. [Visual Studio Code + all the Salesforce extensions installed](https://developer.salesforce.com/tools/vscode/)

If you are new to any of these tools, you should complete the [Set Up Your Workspace and Install Developer Tools](https://trailhead.salesforce.com/en/content/learn/trails/set-up-your-workspace-and-install-developer-tools) trail on Salesforce Trailhead.

### Add Repository to VSC
A lot of this process is documented in the [Salesforce VSC documentation](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models/). Below is a summary of the required steps.

1. Clone this repository to your local computer and open the directory in VSC.
2. In VSC open the command palette (ctrl + shift + p), start typing *Run SFDX: Authorize an Org* and select it. Select the right SF domain to login to (developer orgs are login.salesforce.com and sandboxes and scratch orgs are test.salesforce.com). On the next step, give the org an alias and then a browser window will open for you to login to Salesforce. Once you login, your VSC project will be connected to the Salesforce org.\
*Important Note:* If you have already authorized an org on your computer using sfdx, there is a place on the VSC status bar (at bottom) where you can select an org that's already been authenticated. You can select this for the project instead of authorizing again.
3. Once you've authorized an Org, right click on the manifest/package.xml file and select *SFDX: Deploy Source in Manifest to Org*. This will push all the metadata and code from the repository into your SF Org.
