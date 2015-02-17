DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/set_vars.sh;

function send_comment {
    local id="$1";
    local jira_comment="${@:2}";

    set_creds;

    echo "${update}[.] Sending Comment...\n${reset}";
    curl -D -s -u ${user}:${password} -X POST --data "{\"body\": \"${jira_comment}\"}" -H "Content-Type: application/json" ${uri_jira_api}${id}/comment > /dev/null
    echo "${good}[+] Comment Sent\n${reset}";

    echo "${id} ${jira_comment}";
}

function perform_transition {
    local issue_id="$(autocomplete_jira_name "PDP" $1)";
    local transition_id="$2";
    local payload="{\"transition\": {\"id\": \"${transition_id}\"}}";

    set_creds;

    # echo $payload;

    echo "${update}[.] Transitioning Issue...\n${reset}";
    curl -D -s -u ${user}:${password} -X POST -d "${payload}" -H "Content-Type: application/json" ${uri_jira_api}${issue_id}/transitions > /dev/null
}

function assign_jira {
	local issue_id="$(autocomplete_jira_name "PDP" $1)";
	local user_id="$2";
    local payload="{\"name\": \"${user_id}\"}";

    set_creds;

    echo $payload;

    echo "${update}[.] Assigning Issue to ${user_id}...\n${reset}";
    curl -D -s -u ${user}:${password} -X PUT --data "${payload}" -H "Content-Type: application/json" ${uri_jira_api}${issue_id}/assignee;


}

function transition_release_jiras {

    printf "${question}[?] Transition all the jiras in the release branch? [y/n]: ${reset}"
    read transition_answer;

    if [[ $transition_answer == "y" ]]; then
    
            local staging_issues=$(git log origin/master..release --pretty=format:"%s" | awk '{print $1}' | tr -d '[]' | grep "PDP" );

            while read -r issue;
            do
                echo "Transitioning Issue: ${issue}";
                perform_transition "${issue}" "761";
            done <<< "$staging_issues";
    
    fi
}

function transition_production_jiras {
    printf "${question}[?] Transition all the jiras in the this production release? [y/n]: ${reset}"
    read transition_answer;

    if [[ $transition_answer == "y" ]]; then

        local prod_issues=$(git log origin/master^..origin/master --pretty=format:"%s" | awk '{print $1}' | tr -d '[]' | grep "PDP" );

        while read -r issue;
        do
            echo "Transitioning Issue: ${issue}";
            perform_transition "${issue}" "791";
        done <<< "$prod_issues";
    
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

    echo "\n${update}[.] Fetching JIRA Issue: ${jira_slug}...${reset}";

    local jira_properties="{ 
    assignee: .fields.assignee.displayName, 
    reporter: .fields.reporter.displayName,
    engineer: .fields.customfield_15060.displayName, 
    engineer_username: .fields.customfield_15060.name,
    delivery_lead: .fields.customfield_15062.displayName, 
    status: .fields.status.name, 
    git_branch: .fields.customfield_14267, 
    summary: .fields.summary, 
    name: .key, 
    priority: .fields.priority.name}";


    jira=$(curl -s -u $user:$password ${uri_jira_api}${jira_slug} | jq "${jira_properties}");
    # echo ${jira_properties};
    # echo ${jira};

}

function get_release_jiras
{
    set_creds;
    echo "${update}[.] Fetching Release Candidates from JIRA...${reset}";

    local jira_properties=".issues[].key";
    local response=$(curl -s -u $user:$password "https://obujira.searshc.com/jira/rest/api/2/search?jql=project%20%3D%20PDP%20AND%20status%20%3D%20%22Queued%20for%20Staging%22%20AND%20sprint%20in%20openSprints()%20ORDER%20BY%20priority%20DESC%2C%20cf%5B12762%5D%20DESC" | jq "${jira_properties}" | tr -d '"');

    # local issue_count=$(echo $response | jq '.issues[].key' | tr -d '"');
    echo "${good}[+] Found Release Candidates...${reset}";
    echo "${good}${response[@]}${good}";

    get_jiras ${response};
    # echo $response | jq "$jira_properties";
}

function show_jira {
    set_creds;

    local issue_id="$(autocomplete_jira_name "PDP" $1)";

    get_jira $issue_id;
    get_jira_properties ${jira};

  
    echo "\n${update}[:] Details [:] ${reset}";
    printf "%-10s %-40s\n" "Priority:" $jira_priority;
    printf "%-10s %-40s\n" "ID:" $jira_name;
    printf "%-10s %-40s\n" "Title:" "$jira_title";
    printf "%-10s %-40s\n" "Status:" "$jira_status";
    printf "%-10s %-40s\n" "Branch:" $jira_branch;

    printf "\n${update}[:] People [:] ${reset}\n";
    printf "%-10s %-40s\n" "Asignee:" "${jira_assignee}";
    printf "%-10s %-40s\n" "Reporter:" "${jira_reporter}";
    printf "%-10s %-60s\n" "Delivery Lead:" "${jira_delivery_lead}";
    printf "%-10s %-40s\n" "Engineer:" "${jira_engineer}";

    # echo $jira | jq '.';
 
    echo "[.] Getting Issue Transition Options...\n";
    local transitions=$(curl -s -u ${user}:${password} ${uri_jira_api}${issue_id}/transitions | jq '.transitions[]');
    echo $transitions | jq '{name: .name, id: .id}';

    echo "Chose a transition (by id): ";
    read tid;

    echo $tid;
    perform_transition $issue_id $tid;


    # echo "$transitions" | jq '{id: .transitions[].id, label: .transitions[].name, description: .transitions[].to.description}';
    # declare -a transition_ids=$(echo "${transitions}" | jq -r '.name')
    # local tcount=0;    

    # echo "[:] Transition Options [:]";
    # while read -r tid; do

    #     tcount=$((tcount+1));
    #     echo "\t$tcount) $tid";

    # done <<< "$transitions";

  

}

