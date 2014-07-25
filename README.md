## Setup
`git clone git@github.com:eddiemoya/git-jira-jenkins.git ~/git-jira-jenkins`

`git config --global alias.pdp '!. ~/git-jira-jenkins/git-pdp.sh'`


## Jira Issue ID
In most instances, a jira issue can be passed as either PDP-# or the number by itself. So, PDP-2000 and 2000 both work. This script does not currently interact with JIRA's outside the PDP project.


## Commands 
### Release: Builds a release branch based off a filter in jira. Please be sure when starting a new release branch, to run 

`git fetch`
`git checkout release`
`git reset --hard origin/master`

The above will eventually just be a release setup command.

#### Usage:
`git pdp release`

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's

