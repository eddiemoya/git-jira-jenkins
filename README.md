## Setup
`git clone git@github.com:eddiemoya/git-jira-jenkins.git ~/git-jira-jenkins`

`git config --global alias.pdp '!. ~/git-jira-jenkins/git-pdp.sh'`


## Jira Issue ID
In most instances, a jira issue can be passed as either PDP-# or the number by itself. So, PDP-2000 and 2000 both work. This script does not currently interact with JIRA's outside the PDP project.


## Commands 

### Merge
Takes any number of space delimited JIRA ID's and attempts to merge them in.

#### Usage:
`git pdp merge <issue_id> <issue_id> <issue_id> ...`

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's.


### Release
Builds a release branch based off a filter in jira. This works just like the `merge` command, except that its pulling the list of ID's from that filter. 

NOTE: Please be sure when starting a new release branch, to run:

`git fetch`
`git checkout release`
`git reset --hard origin/master`

The above will eventually just be a release setup command.

#### Usage:
`git pdp release`

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's


### Checkout
Attemtps to lookup a JIRA's branch from the API and tries to check it out locally

#### Usage:
`git pdp checklout <issue_id>`

### Open
Opens any number of JIRA issies in a new tab in your chrome browser (probably OSX specific, maybe some other *nix)

#### Usage:
`git pdp open <issue_id> <issue_id> <issue_id> ...`

### Deploy
Force pushes the release branch to origin, and triggers the Jenkins job responsible for deploying the release branch to the staging environment. 

Note: This only works for staging at the moment.

#### Usage:
`git pdp deploy <environment>`

Note: Just to repeat - the only valid environment at the moment is "staging"







