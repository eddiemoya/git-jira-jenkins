## Setup
`git clone git@github.com:eddiemoya/git-jira-jenkins.git ~/git-jira-jenkins`

`git config --global alias.pdp '!. ~/git-jira-jenkins/git-pdp.sh'`


## Jira Issue ID
In most instances, a jira issue can be passed as either PDP-# or the number by itself. So, PDP-2000 and 2000 both work. This script does not currently interact with JIRA's outside the PDP project.


## Commands 


### Setup:
Sets up the release or master branch for the purpose of preparing to merge and/or deploy to prod or staging. 

For staging this involves force-checking out of release, and then resetting hard based off origin/master. 

For setting up master (in prep of a prod deploy), it involves resetting the local master branch based off origin/master (to get any artifactory commits any deploys done by someone else on the team), followed by a non-fastforward merge of origin/release.

#### Usage
`git pdp setup <branch>`

Options for <branch> include "master" and "release".
Note: For backward compatibility - the word "prod" is interchangable with the word "master" - in this context ONLY.

### Merge
Takes any number of space delimited JIRA ID's and attempts to merge them in.

#### Usage:
`git pdp merge <issue_id> <issue_id> <issue_id> ...`

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's.


### Release
Builds a release branch based off a filter in jira. This works just like the `merge` command, except that its pulling the list of ID's from that filter. 

NOTE: Please be sure when starting a new release branch, to run: `git pdp setup release`. See the `setup` command below.

#### Usage:
`git pdp release`

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's


### Checkout
Attemtps to lookup a JIRA's branch from the API and tries to check it out locally

#### Usage:
`git pdp checkout <issue_id>`

### Open
Opens any number of JIRA issies in a new tab in your chrome browser (probably OSX specific, maybe some other *nix)

#### Usage:
`git pdp open <issue_id> <issue_id> <issue_id> ...`

### Deploy
Force pushes the release branch to origin, and triggers the Jenkins job responsible for deploying the release branch to the staging environment. 

Note: This works fully for staging deploys. However production deploys are not fully automatable. The artifactory release staging which creates the actual version numbers must be triggered through the browser, as do the final deployments to CH3 and CH4 of those newly created version numbers - the script will prompt you at the appropriate time for each of the browser-based actions.

#### Usage:
`git pdp deploy <environment>`

Options for <environment> include "prod" and "staging"
Note: This also does not handle any pdp-script changes, only pdp-web changes










