## Script Setup
```
git clone git@github.com:eddiemoya/git-jira-jenkins.git ~/git-jira-jenkins
git config --global alias.pdp '!. ~/git-jira-jenkins/git-pdp.sh'
```

This script will frequently interact with jenkins and jira. To avoid getting repeatedly prompted for username and password, fill in their values in the `set_vars.sh` file of this script. You can set one of them, or both, or neither. You will be prompted each time for which ever is blank.

## JQ http://stedolan.github.io/jq/

This tool relies heavily on a tool called "jq" to parse JSON at the command line. 

OSX: `brew install jq`
Everyone else: http://stedolan.github.io/jq/download/

Keep in mind ja needs to be in your PATH for this script to be able to use it.


## Jira Issue ID
In most instances, a jira issue can be passed as either PDP-# or the number by itself. So, PDP-2000 and 2000 both work. This script does not currently interact with JIRA's outside the PDP project.


## Commands 


### Setup Command:
#### Description
Sets up the release or master branch for the purpose of preparing to merge and/or deploy to prod or staging. 

For staging this involves force-checking out of release, and then resetting hard based off origin/master. 

For setting up master (in prep of a prod deploy), it involves resetting the local master branch based off origin/master (to get any artifactory commits any deploys done by someone else on the team), followed by a non-fastforward merge of origin/release.

#### Usage
```
git pdp setup <branch>
```
#### Arguments 
Arguments for <branch> can be `master` or `release`.

*Note: For backward compatibility - the word `prod` is interchangable with the word `master` - in this context* ***ONLY***.

### Merge Command:
#### Description
Takes any number of space delimited JIRA ID's and attempts to merge them in.

#### Usage
```
git pdp merge <issue_id> <issue_id> <issue_id> ...
```

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's.

#### Arguments
Pass space delimited jira numbers. PDP project only. The numbers do not need the "PDP-" portion of the ID.

*Note:* ***NEVER*** *resolve any merge conflicts within the `release` branch.* ***Ever.***

### Release Command:
#### Description
Builds a release branch based off a filter in jira. This works just like the `merge` command, except that its pulling the list of ID's from that filter. 

#### Usage
```
git pdp release
```

Follow prompts - ensure that each jira has been QA verifed. This can be done after the fact, to avoid having to look at jira's that end up with merge conflicts anyway. Try to avoid double-commenting conflicts on JIRA's

*NOTE: Please be sure when starting a new release branch, to run: `git pdp setup release`. See the `setup` command below.*
*NOTE:* ***NEVER*** *resolve any merge conflicts within the `release` branch.* ***Ever.***

### Checkout Command:
#### Description
Attemtps to lookup a JIRA's branch from the API and tries to check it out locally

#### Usage
```
git pdp checkout <issue_id>
```

### Open Command:
#### Description
Opens any number of JIRA issies in a new tab in your chrome browser (Only works in OSX)

#### Usage:
```
git pdp open <issue_id> <issue_id> <issue_id> ...
```
#### Arguments
Pass space delimited jira numbers. PDP project only. The numbers do not need the "PDP-" portion of the ID.

### Deploy Command:
#### Description
Force pushes the release or master branch to origin (depending on which environment is passed), and triggers the Jenkins job responsible for deploying that branch to that environment. 

#### Usage
```
git pdp deploy <environment>
```
#### Arguments
Options for <environment> include `prod` and `staging`

*Note: This also does not handle any pdp-script changes, only pdp-web changes*

*Note: This works fully for staging deploys. However production deploys are not fully automatable. The artifactory release staging which creates the actual version numbers must be triggered through the browser, as do the final deployments to CH3 and CH4 of those newly created version numbers. The script will try to open tabs for these jobs at the appropriate time for each of the browser-based actions - howevre as noted in the "open" command's notes - it actually only works on OSX (for now).*


### Additional functions

```
git pdp transition_release_jiras
```
Magically figures out the issues in latest release on the origin/release branch - and transitions them in JIRA to the **"In Staging"** status.

```
git pdp transition_production_jiras
```
See above - same but transition to the **"In Production"** status.


## Process

### Setup and Deployment

#### Staging
Our general process begins with creating a new release branch after a prod deploy. To do this run the following set of commands

```
git pdp setup release
git pdp release
git pdp deploy staging
```

This assumes the release is *normal*, and is comprised of whatever is ready for staging. Sometimes however we receive specific instructions for which issues must go to staging. For this, use these commands instead.

```
git pdp setup release
git pdp merge #### #### #### ...
git pdp deploy staging
```

The `####` reflect the numeric numbers for the issues being merged. See the details on the merge command.

#### Production

Once the QA team has signed off that all issues in staging have been tested and have passed - and that regression has not found new issues - we can deploy to production. Generally we limit production deploys to ~3PM at the latest on Monday-Thursdays **ONLY**.

*Note: Be aware that sometimes issues being deployed need to be coordinated with services changes - in these cases coordinate with that team and keep in mind Akamai clear cache - which must be cleared immediately after the services and web changes.*

To deploy to production follow use this set of commands:

```
git pdp setup master
git pdp deploy prod
```

### Rollback Scenarios

#### What is a rollback?

Rolling back is not the same as a revert. A rollback keeps all of the code in master as it is, but simply deploys the previous release to production. The code in master stays in master and is authoritative - ***NEVER RESET master to get rid of a commit in origin***.

#### Procedure

*Note: None of this is automated at this time.*

*NOTE NOTE NOTE:::: !!1!$ NOTE;: While in a rollbacked state - the train is stopped. Everything tested in staging is invalidated, and all testing there is stopped. The rolledback state must be resolved before moving forward with everything else.* **REMEMBER!** *The broken code is* **STILL** *in master which means its in* **EVERYONE's** *branches.* ***Trying to deploy anything else before either reverting or hotfixing the issue will simply reintroduce the problem into production!!#@#~)!***


Before rolling back, try to ensure that the rollback will actually remove the problem. If there is any doubt - test it by deploying the previous release to staging. This of course only works if the problem is present in staging to begin with.

When problems are found in production, and they are caused by the most recent release, the first reaction should typically be to rollback. This means going the CH3 and CH4 Jenkins jobs, and simply deploying the version number prior to the most recent production deployment. This will remove the entire release from production. 

Following the rollback.
* Have a developer attempt to reproduce the issue locally.
* Inform QA to stop testing whatever is currently in staging (anything in staging will not be invalid, regardless of how much its been tested).

If a developer can not reproduce the issue in production try to reproduce it staging. If desparate... try in the QA environments. Once this issue has been reproduced - try to determine which of the multiple issues in the release is causing the problem. This can be done locally using `git bisect`

Once the offending issue is found - there are two options. 
* Wait for a fix.
* Revert the offending issue. 

Generally speaking, we should revert the issue - waiting can often be indefinit and unpredictable. The only exception is if the solution is very obvious and found immediately or if the items waiting for the next release are not as critical as the feature(s) that were rolled back.

### Revert

#### Revert vs. Reset
A revert is not the same as a reset. In `git`, a revert is a *new* commit that *undoes* the work of its target. By contrast, a `reset` would simply *delete* the commit from history. Never delete or modify any commits that have made it to origin/master. ***Ever.*** Other developers pull from the master branch. So if you simply delete the commit - that commit will simply end up back in master when their branches are merged in at a later point in time.

#### Prodedure

After a rollback, it may be necessary to revert is specific issue from a given release. Once that issue is indentified, copy the SHA1 for that commit, then run the following commands.

```
git pdp setup release
git revert <sha1>
git pdp deploy staging
```

This will setup a new release branch, revert the code for the offending issue - and reploy it to staging, where this new configuration and be tested. Once tested and passed in staging, this can be deployed to production in the normal manner.

At this point, anything that was in staging needs to be retested. Recreate the release branch from scratch by using `git pdp release` or `git pdp merge ### ...` as normal.

### Hotfix

The term is misused here, but people will ask for a "hotfix". This is how we do them.

After a rollback, if a developer has found the solution for the problem in production then it maybe reasonable (if time permits, or pressure demands) to deploy the proposed fix to staging **alone** so it can be tested and later deployed to prod. The QA team probably opened a JIRA for the defect, so simply start a new release as normal, and include that issue **alone** in that release. Deploy to release as normal.

As with the revert, anything that had been in staging will be wiped out - and will afterward need to be retested in a newly created release branch.










