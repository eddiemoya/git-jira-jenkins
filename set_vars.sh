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



set_colors_vars;

