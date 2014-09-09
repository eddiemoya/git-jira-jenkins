function set_colors_vars
{
	underline=$(tput sgr 0 1)          # Underline
	bold=$(tput bold)             # Bold
	normal=$(tput rmso)				# Normal

	# Dims
	red=$(tput setaf 1) # red
	green=$(tput setaf 2) # magenta
	blue=$(tput setaf 4) # blue
	yellow=$(tput setaf 3) # yellow
	magenta=$(tput setaf 5) # magenta
	cyan=$(tput setaf 6) # cyan
	white=$(tput setaf 7) # white

	#Bolds
	bred=${bold}${red} # red
	bgreen=${bold}$(tput setaf 2) # magenta
	bblue=${txtbld}$(tput setaf 4) # blue
	byellow=${txtbld}$(tput setaf 3) # yellow
	bmagenta=${txtbld}$(tput setaf 5) # magenta
	bcyan=${txtbld}$(tput setaf 6) # cyan
	bwhite=${txtbld}$(tput setaf 7) # white

	#Resets
	reset=$(tput sgr0)             # Reset
}

function set_uris {
	uri_jira_api="https://obujira.searshc.com/jira/rest/api/2/issue/";
	uri_jenkins_api="http://obuci301p.dev.ch3.s.com:8180/jenkins/";
}

function set_transitions {
	transition_deployed_staging="761";
	transition_deployed_prod="";
	transition_build_failed="";
}

set_transitions;
set_uris;
set_colors_vars;

