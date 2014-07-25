#!/bin/sh


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/set_vars.sh;
source $DIR/helpers.sh;


##

## Installation ##
# > git clone https://gist.github.com/1367d0aae9e059a57ebf.git ~/git-jira.sh
# > git config --global alias.jira '!. ~/git-jira.sh'
##

## Commands ##
#
# General Usage:
# git jira <command> <jira_id>
# * Note: If no command is given, defaults to "lookup".
# * Note: All JIRA_ID inputs can be prefixed with PDP- or be just the number.
#
# Command: git jira lookup <jira_id>
# Description: Outputs simplified version of JIRA API output for either a single jira or a space delimited list of JIRAs
# 
# Command: git jira merge <jira_id> (<jira_id> <jira_id> ...)
# Description: Takes a space delimited list of jira ID's (or single jira), 
#  looks it up via the API and tries to merge its branch and automatically builds a commit message.
#  Rejects merge conflicts. Keeps track of rejected jiras or those without branches. Reports success/failures 
#  after the final jira is completed.
#
# Command: git jira release
# Takes no parameters. Looks for a list of potential JIRAs from a filter in JIRA - passes the whole list to the "git jira merge" command.
# 

# 
##

## TODO ##
# * 
# * Ensure that response from JIRA is not null. Fail gracefully.
# * Rewrite this crap in a better langange!
##


# JIRA Username
# user="emoya1";

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
        echo "/n";
    fi

    if [ -z "$password" ]; then

        read -s -p "${question}[?] JIRA Password (${user}): ${reset}" password;
        echo "/n";
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
##
# Checks for conflicts.
# If conflicts, back out merge, display error messege, and add to $had_conflicts array.
# If no conflicts, perform merge, add to $merged array.
##
function do_merge {
	git merge --squash --quiet $branch > /dev/null;

	local has_conflicts=$(git status --porcelain | grep "UU");
    local merged_files=$(git status --porcelain);

	if [ -n "$has_conflicts" ]; then

        echo ${has_conflicts} | sed 's/UU/\'$'\nUU/g';
        
        echo "\n${attention}[!] Branch has conflicts. Resetting back to HEAD and moving to the next JIRA${reset}";
        git reset --hard HEAD;

        printf "${question}[?] Submit a comment explaining the conflict? [y/n]: ${reset}";
        read comment_answer;

        if [[ $comment_answer == "y" ]]; then
            local formatted_conflicts=$(echo ${has_conflicts} | sed 's/UU/\'$'\\n  UU/g');
            local jcomment="The branch *${branch}* was found to have conflicts in the following file(s): ${formatted_conflicts}";
            send_comment $jira_name $jcomment;
        fi

        
        local conflicts=$(echo $has_conflicts | sed 's/UU/\'$'\n     UU/g')

        had_conflicts+=("* $comment$conflicts\n");
		
	else
        if [ -n "$merged_files" ]; then
            git add --all; # needed in cases where files have been deleted
    		git commit -m "$(echo $comment)";
            merged+=("* $comment\n");
        else
            echo "${problem}[!] Nothing to merge, issue skipped.${reset}";
            skipped+=("* $comment\n");
        fi
	fi
}

function send_comment {
    local id="$1";
    local jira_comment="${@:2}";

    set_creds;

    echo "${update}[.] Sending Comment...\n${reset}";
    curl -D -s -u $user:$password -X POST --data "{\"body\": \"${jira_comment}\"}" -H "Content-Type: application/json" https://obujira.searshc.com/jira/rest/api/2/issue/$id/comment > /dev/null
    echo "${good}[+] Comment Sent\n${reset}";

    echo "${id} ${jira_comment}";
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

        open_tabs $jira_id;

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


function get_jira {
    
    local jira_slug=$1;

    if [[ $jira_slug =~ PDP-.*  ]]; then
        jira_slug="${jira_slug}";
    else
        jira_slug="PDP-${jira_slug}";
    fi

    set_creds;
    echo
    echo "\n${update}[.] Fetching JIRA Issue: ${jira_slug}...${reset}";

    local jira_properties="{git_branch: .fields.customfield_14267, summary: .fields.summary, assignee: .fields.assignee.displayName, name: .key, priority: .fields.priority.name}";

    jira=$(curl -s -u $user:$password https://obujira.searshc.com/jira/rest/api/2/issue/$jira_slug | jq "${jira_properties}");
    # echo ${jira_properties};
    # echo ${jira};

}

function get_jira_properties {
     
    jira_name="$(echo "${jira}" | jq '.name' | tr -d '\"')";
    jira_title=$(echo $jira | jq '.summary');
    jira_priority=$(echo $jira | jq '.priority' | tr -d '\"');
    jira_branch=$(echo $jira | jq '.git_branch' | tr -d '\"' | sed -e 's/  *$//');

    comment="[${jira_name}] (${jira_priority}) ${jira_title}";
}

function autocomplete_jira_name {
    local prefix=$1;
    local id=$2;

    if ! [[ $id =~ $prefix-.* ]]; then
        id="${prefix}-${id}";
    fi

    echo $id;
}


function get_jiras {

    local cont;
    echo "${update}";
    git fetch --all;
    echo "${reset}";

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

function get_release_jiras
{
    set_creds;
    echo "${update}[.] Fetching Release Candidates from JIRA...${reset}";

    local jira_properties=".issues[].key";
    local response=$(curl -s -u $user:$password https://obujira.searshc.com/jira/rest/api/2/search?jql=filter=79520 | jq "${jira_properties}" | tr -d '"');

    # local issue_count=$(echo $response | jq '.issues[].key' | tr -d '"');
    echo "${good}[+] Found Release Candidates...${reset}";
    echo "${good}${response[@]}${good}";

    get_jiras ${response};
    # echo $response | jq "$jira_properties";
}

function open_tabs
{ 
    for jira_number in "$@"
    do
        local jira_id="$(autocomplete_jira_name "PDP" $jira_number)";
        open -a "Google Chrome" https://obujira.searshc.com/jira/browse/$jira_id; 
    done
}

function checkout_branch {

    local jira_id="$(autocomplete_jira_name "PDP" "2356")";

    get_jira $jira_id;

    get_jira_properties ${jira};

    git checkout $jira_branch;
}


function deploy {
    local env="$1";

    if [[ $env == "staging" ]]; then
        echo "${update}[.] Pushing release branch to origin...${reset}";
        git push -f origin release;

        echo "${update}[.] Starting Jenkins job: PDP_Web_Build_STAG..\n\n${reset}";

        java -jar ${DIR}/jenkins-cli.jar -s http://obuci301p.dev.ch3.s.com:8180/jenkins/ build -s -v PDP_Web_Build_STAG

    fi
}

case "$1" in 
    (merge) get_jiras "${@:2}";;
    (lookup) get_jira $2;;
    (release) get_release_jiras;;
    (open) open_tabs "${@:2}";;
    (comment) send_comment "${@:2}" ;;
    (checkout) checkout_branch $2;;
    (deploy) deploy "${@:2}";;
    (*) get_jira $2;;
esac



