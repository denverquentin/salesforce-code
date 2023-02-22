# Continuous Integration - Continuous Delivery

`Continuous integration` is a software development practice where members of a team use a version control system and frequently integrate their work to the same location, such as a main branch. Each change is built and verified to detect integration errors as quickly as possible. Continuous integration is focused on automatically building and testing code, as compared to continuous delivery, which automates the entire software release process up to production.

`Continuous delivery` is a software development methodology where the release process is automated. Every software change is automatically built, tested, and packaged. Before the final push to package, the team decides when the final push should occur. Although every successful software change can be immediately released to production with continuous delivery, not all changes need to be released right away.

These article details some great benefits from using CI/CD.

- https://developer.salesforce.com/blogs/2022/01/set-up-continuous-integration-for-your-salesforce-projects
- https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment

![CI-CD.png](images/CI-CD.png)

## Git Commit Triggers

We'll fire our CI/CD processes based on Git commits to specific branches and the process will be different depending on the branch receiving the commit.

### Commit to feature branch

We will have a CI process to build a namespaced scratch org with a duration of 1 day upon every commit to a `feature` branch. This verifies:

- that the metadata deploys correctly

- runs a lint utility on LWC and Aura Javascript

- all unit tests pass

- that each apex class and trigger has > 80% coverage

This is a great check for developers that everything is ready for a Pull Request. It also lets the Pull Request approver know that the feature changes is ready for review.

### Merge feature branch to dev branch (Pull Request approved)

We will have a CI process to build a namespaced scratch org with a duration of 10 days upon every commit to the `dev` branch. This build validates the same things the the feature branch build does but also:

- creates a username and password we can use to login to this org to test the new feature

- assign our permission set to the scratch org user

- create a community and deploy our “shell” community pages

- run any other Apex scripts necessary to get the org ready for UAT

- maybe also build a beta package that should pick up any errors based on metadata or code changes (global to non-global, deleted metadata, etc)

### Merge dev branch or hotfix branch to main branch

We will have a CI process to build a released package based on the main branch. This process may also:

- build a non-namespaced scratch org and install the UST Secure managed package to test that a new install is successful.

- upgrade the UST Secure package in a permanent org to make sure it is successful. this get's complicated because we have to setup JWT authentication for the permanent org.

## Setup JWT Bearer Flow Authorization for Salesforce CI-CD

Continuous integration (CI) environments are fully automated and don't support the human interactivity of the OAuth 2.0 web server authorization flow. In these environments, we must use the JSON web tokens (JWT) bearer flow to authorize an org. With this flow, explicit user interaction isn’t required.

The JWT bearer authorization flow requires a digital certificate, also called a digital signature, to sign the JWT request. We will create a self-signed certificate using OpenSSL.

Follow all the instructions documented in [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_jwt_flow.htm#sfdx_dev_auth_jwt_flow).