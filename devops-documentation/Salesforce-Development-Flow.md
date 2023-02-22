# Salesforce Development Flow


### SFDX Commands
Here's a list of useful and common SFDX (the Salesforce CLI tool) commands you'll use when developing and packaging in Salesforce. These commands need to run in the root directory of your Salesforce project which is the same directory this README.md file is located. You can run these commands using the Terminal in VSC or a Windows cmd prompt. You can view all commands in the [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_top.htm) document for more details.


#### Org Authentication
Authenticate to a devhub org with an alias = devhub so SFDX is authorized to use it. The devhub authentication is used to build scratch orgs and build packages. You only need to authenticate to an org once.
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


#### Create a Scratch Org (a Dev Hub is Required)
Authenticate to a devhub org with an alias = devhub and sets it as the default devhub org. The devhub org authentication is used to create scratch orgs and build packages. You only need to login to the devhub org once - you will remain authorized to the devhub org until you run the `sfdx auth:logout` command.
```
sfdx auth:web:login --setalias devhub --setdefaultdevhubusername --instanceurl https://login.salesforce.com
```

Change the `adminEmail` in the script above to your email address so you'll receive Apex errors and package install emails. Also change the `username` value to include your email address with something unique at the end. This command builds a scratch org that lasts 30 days with a *scratch* alias and sets it as your default org.
```
sfdx force:org:create -f config/project-scratch-def.json --durationdays 30 --setalias scratch --setdefaultusername --targetdevhubusername devhub adminEmail=quentin@github.com username=quentin@github.com.2021.10.31
```

Deploy all metadata defined in the manifest/package.xml to your Salesforce scratch org.
```
sfdx force:source:deploy -u scratch -x manifest/package.xml
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

#### Deploy (Push) Metadata to Org
Deploy (push) all metadata and code from the Git branch on your local computer to your SF dev org. Only metadata defined in manifest/package.xml is deployed.
```
sfdx force:source:deploy -u dev -x manifest/package.xml
```


#### Retrieve (Pull) Metadata from Org
Retrieve (pull) all metadata and code defined in the manifest/package.xml from your SF dev org to your computer.
```
sfdx force:source:retrieve -u dev -x manifest/package.xml
```


### Run Tests and Check Development Standards
Runs all unit tests in your dev org.
```
sfdx force:apex:test:run -u dev --testlevel RunLocalTests --codecoverage --resultformat human
```

Lint all LWC and Aura components in the repository.
```
npm run lint
```

Run the Apex static source scanner on code in the repository. Requires the sfdx scanner plugin.
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
