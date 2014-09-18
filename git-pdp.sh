#!/bin/bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/set_vars.sh;
source $DIR/helpers.sh;
source $DIR/git-pdp-jira.sh;
source $DIR/git-pdp-merge.sh;
source $DIR/git-pdp-deploy.sh;


##

## Installation ##
# > git clone https://gist.github.com/1367d0aae9e059a57ebf.git ~/git-jira.sh
# > git config --global alias.jira '!. ~/git-jira.sh'
#

## Commands ##

# git pdp setup <release|prod>
# Sets up the master or release branch to get it ready for the next release

# git pdp release 
# Grabs all issues in Queued for Staging, merges each one into the *current branch* - run pdp setup release first!

# git merge <issue> <issue> <issue> ... 
# Pass PDP-#### or just #### , merges each issue passed.

# git pdp deploy <staging|prod>
# Deploys the master branch to prod, or the release branch to staging. 
# Note: With prod, there are portions that can not be triggered via API, and must done in the browser.

## TODO ##
# * 
# * Ensure that response from JIRA is not null. Fail gracefully.
# * Rewrite this crap in a better langange!
##


# JIRA Username - uncomment and provide values to avoid having to enter them each you use the script.
user="";
password="";

# Configs
auto_merge_release_jiras=true;
origin_branches_only=true;
ask_for_missing_branch=true; # TODO: Setting this to false causes branch lookups to fail.

#colors
attention=${bred};
problem=${red};
good=${green};
update=${cyan};
question=${yellow}



# Will be used to store info about JIRA's who's branches had conflicts
had_conflicts=();

# Will be used to store info about JIRA's which had no branches assoicated with them
no_branch=();

# Will be used to store info about JIRA's which were skipped during the process
skipped=();

# Will be used to store info about JIRA's which were successfully merged
merged=();

function set_creds {

    if [ -z "$user" ]; then
        read -p "${question}[?] JIRA Username: ${reset}" user;
    fi

    if [ -z "$password" ]; then
        read -s -p "${question}[?] JIRA Password (${user}): ${reset}" password;
    fi
}

function complete_jira_id 
{
        local jira_id='';
        # The jira number may be passed as PDP-#### or as simply ####.
        if [[ $1 =~ PDP-.*  ]]; then
            jira_id="${jira_number}";
        else
            jira_id="PDP-${jira_number}";
        fi

        echo $jira_id;
}

function autocomplete_jira_name {
    local prefix=$1;
    local id=$2;

    if ! [[ $id =~ $prefix-.* ]]; then
        id="${prefix}-${id}";
    fi

    echo $id;
}

function fetch {
    echo "${update}";
    git fetch --all;
    echo "${reset}";
}

##
# Verifies that a given branch exists
#
# First checks if the branch name is set in the $jira_branch veriable.
# If its not, prompts user for a branch
#
# Check to see if branch exists locally 
# If it does not, check in origin
# 
# If a branch is found, it is set to the $branch_exists variable
# If not found, prompt user if we should try again.
# 
# If user opts to try again, function call itself.
# If user opts not to try again, jira is added to $no_branch array
##
function check_branch_exists {

    local cont;

    if [ "${jira_branch}" == "null" ]; then

        open_jira $jira_id;

        if [ "$ask_for_missing_branch" = true ]; then
            
            echo " ${bred}[!] ${red}No branch set in git_branch property...${reset}"

            printf " ${question}[?] Branch for ${jira_id}?${reset} : "
            read branch;
        fi

    else
        echo " ${good}[+] Branch set in git_branch property: ${jira_branch}";
        branch=${jira_branch};
    fi

    branch_exists=$(git branch -l --list ${branch});

    if [ -n "$branch_exists" ] && [ !"$origin_branches_only" ]; then
    	echo " ${good}[+] Branch Found Locally:${branch_exists}${reset}";
        echo " ${update}[.] Merging...${reset}";
    else

    	branch="origin/${branch}";
    	branch_exists=$(git branch -r --list ${branch});

    	if [ -n "${branch_exists}" ]; then
    	   echo " ${good}[+] Branch Found Remotely: ${branch_exists}${reset}";
    	else

            echo " ${problem}[!] Branch [${branch}] does not exist locally, or in origin.${reset}";

            if [ "$ask_for_missing_branch" == true ]; then
    		
                printf "${question}[?] Try again [y/n]?${reset} "
                read cont;
            fi

            if [[ $cont == "y" ]]; then
    		  check_branch_exists;
            else
                no_branch+=("* $comment\n");
            fi
    	fi
    fi
}




function get_jira_properties {
     
    jira_name="$(echo "${jira}" | jq '.name' | tr -d '\"')";
    jira_title=$(echo $jira | jq '.summary');
    jira_priority=$(echo $jira | jq '.priority' | tr -d '\"');
    jira_branch=$(echo $jira | jq '.git_branch' | tr -d '\"' | sed -e 's/  *$//');
    jira_status=$(echo $jira | jq '.status' | tr -d '\"');

    jira_assignee="$(echo $jira | jq '.assignee' | tr -d '\"')";
    jira_reporter="$(echo $jira | jq '.assignee' | tr -d '\"')";
    jira_delivery_lead="$(echo $jira | jq '.delivery_lead' | tr -d '\"')";
    jira_engineer="$(echo $jira | jq '.engineer' | tr -d '\"')";
    jira_engineer_username="$(echo $jira | jq '.engineer_username' | tr -d '\"')";

    comment="[${jira_name}] (${jira_priority}) ${jira_title}";

}

function get_jiras {

    local cont;
    # fetch;

    for jira_number in "$@"
    do
        # The jira number may be passed as PDP-#### or as simply ####.
        if [[ $jira_number =~ PDP-.*  ]]; then
            jira_id="${jira_number}";
        else
            jira_id="PDP-${jira_number}";
        fi

        if [ "$auto_merge_release_jiras" ]; then
            cont="y";
        else
            printf " q\n${question}[?] Look for ${bold}${jira_id}${reset}${question} [y/n]? ${reset}";
            read cont;  
        fi

        if [[ $cont == "y" ]]; then

            get_jira $jira_id;

            get_jira_properties ${jira};
            
            echo " ${good}[+] Found ${comment}${reset}";

            check_branch_exists;

            if [ -n "${branch_exists}" ]; then
                do_merge;
            fi
        else
            skipped+=("* $jira_id\n");
        fi
    done

    echo "\n${bold}${update}[.]================= Report =================[.]${reset}";
    echo "\n${bold}${good}[+] Merged: The following JIRA's were successfully merged.${reset}";
    echo "${good} ${merged[@]}${reset}";

    echo "${bold}${update}[.] Skipped: The following JIRA's were skipped.${reset}";
    echo "${update} ${skipped[@]}${reset}";

    echo "${attention}[!] Conflicts: The following JIRA's encountered merge conflicts.${reset}";
    echo "${red} ${had_conflicts[@]}${reset}";

    echo "${attention}[!] No Branch: The following JIRA's did not have a branch to merge.${reset}";
    echo "${red} ${no_branch[@]}${reset}";

    echo "${bold}${update}[.]================= Report =================[.]${reset}\n";
}

function open_jira
{ 
    for jira_number in "$@"
    do
        local jira_id="$(autocomplete_jira_name "PDP" $jira_number)";
        open -a "Google Chrome" https://obujira.searshc.com/jira/browse/$jira_id; 
    done
}

function open_job
{
    local job=$1;
    open_tab "${jenkins}job/${job}";
}

function open_tab 
{
    local url=$1;
    open -a "Google Chrome" "${url}";
}


function checkout_branch {

    local jira_id="$(autocomplete_jira_name "PDP" $1)";

    get_jira $jira_id;

    get_jira_properties ${jira};

    git checkout $jira_branch;
}

case "$1" in 
    (merge) get_jiras "${@:2}";;
    (lookup) get_jira $2;;
    (release) get_release_jiras;;
    (open) open_jira "${@:2}";;
    (comment) send_comment "${@:2}" ;;
    (checkout) checkout_branch $2;;
    (deploy) deploy "${@:2}";;
    (setup) setup "${@:2}";;
    (show) show_jira $2;;
    (trans) perform_transition "${@:2}";;
    (assign) assign_jira "${@:2}";;
    (*) $1 "${@:2}";;
esac



