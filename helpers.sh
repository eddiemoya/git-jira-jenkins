function set_color {
	tput setaf $1;
}

function menufy
{
	local item_number;
	declare -i item_number=0

	for option in "$@"
	do
		item_number=item_number+1;
		echo "[$(set_color 31)$item_number${reset}]${yellow}$option${reset} ";
	done
}

function menufi
{

	select action in $@;
	do
		echo $action;
	done
}

# function show_help {

# }

