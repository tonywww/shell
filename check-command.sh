echo "
#
# check-command.sh
# System command checker
#
# Type \"exit\" to exit.
#
"

while [[ "$command" != "exit" ]]; do

read -p "Please input command to check: " command

    if ! command -v $command >/dev/null 2>&1; then
        echo $command "doesn't exist!"
    else
        echo $command "exist!"
    fi

done


exit 0


