# @param 
function jenkins_build {
    local job=$1;

    echo "${update}[.] Starting Jenkins job: ${job}..\n${reset}";
    java -jar ${DIR}/jenkins-cli.jar -s ${uri_jenkins_api} build -s -v ${job}
}

function deploy_staging {
	
    echo "${update}[.] Checking modified paths...${reset}";
    local modified_paths="$(git diff origin/master..origin/release --name-only | awk -F "/" '{print $1}' | sort -urd)";

    echo "${modified_paths[@]}";

    while read -r path; do

        case $path in
            (pdp-web) 
            jenkins_build "PDP_Web_Build_STAG"
            ;;

            # (pdp-scripts)
            # echo "${update}[.] Starting Jenkins job: PDP_Apache_Config_Deploy_STAGING..\n${reset}";
            # java -jar ${DIR}/jenkins-cli.jar -s ${uri_jenkins_api} build -s -v PDP_Apache_Config_Deploy_STAGING
        esac  

    done <<< "$modified_paths"

    transition_release_jiras;
}
function deploy_prod {

	        jenkins_build "PDP_Web_Release";

            open_job "PDP_Web_Release";

            echo "${update}[.] Please trigger the Artifactory Release Staging build in the browser. Press enter to continue. ${reset}";
            read > /dev/null;

            open_job "PDP_Web_Deploy_Apache_CH3_PROD";
            open_job "PDP_Web_Deploy_Apache_CH4_PROD";
            # jenkins_build "PDP_Web_Deploy_Apache_CH4_PROD";
            # jenkins_build "PDP_Web_Deploy_Apache_CH3_PROD";
}

function deploy {
    local env="$1";

    #fetch;

    case "$env" in
        (staging)
    
            echo "${update}[.] Pushing release branch to origin...${reset}";
            git push -f origin release:release;

            deploy_staging;
        	;; # Ends staging deploy

        (prod)
        	echo "${update}[.] Pushing master branch to origin...${reset}";
            git push origin master:master;

            deploy_prod;
            ;;


    esac
}

