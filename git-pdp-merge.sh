DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/set_vars.sh;
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

        printf "${question}[?] Update issue as \"Build Failed\"? [y/n]: ${reset}";
        read update_answer;

        if [[ $update_answer == "y" ]]; then
            perform_transition $jira_name "851";
        fi

        printf "${question}[?] Assign issue to Engineer: ( ${jira_engineer}|${jira_engineer_username} ) ? [y/n]: ${reset}";
        read reassign_answer;

        if [[ $reassign_answer == "y" ]]; then
            assign_jira $jira_name "${jira_engineer_username}";
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
function release_setup {
    local cont;

    echo "${update}[.] Setting up new release...${reset}";
    echo "${attention}[!] Warning, this will remove all current uncommitted changes!${reset}";
    printf "${question}[?] Are you sure you want to continue? [y/n]: ${reset}";
    read cont;

    if [[ $cont == "y" ]]; then
        fetch;
        git checkout release
        git reset --hard origin/master
    fi
}

function prod_setup {
        fetch;
        git checkout master;
        git merge --ff-only origin/master;
        git merge --no-ff origin/release;
}

function setup {
    local setup_type="$1";

    case "$setup_type" in
        (release) release_setup;;
        (master) prod_setup;;
        (prod) prod_setup;;
    esac
}