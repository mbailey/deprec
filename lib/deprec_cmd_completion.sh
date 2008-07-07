export CAP_TASKS=$( cap -T | grep '^cap' | cut -d' ' -f 2 )
_cap() 
{
	local cur tasks colonprefixes
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"

	tasks=$CAP_TASKS
    # uncomment this for dynamic task lists
	# tasks=$( cap -T | cut -d' ' -f 2 | grep deprec)

	# Work-around bash_completion issue where bash interprets a colon
	# as a separator.
	# Work-around borrowed from the darcs work-around for the same
	# issue.
	colonprefixes=${cur%"${cur##*:}"}
	COMPREPLY=( $(compgen -W "${tasks}" -- ${cur}) )
	local i=${#COMPREPLY[*]}
	while [ $((--i)) -ge 0 ]; do
		COMPREPLY[$i]=${COMPREPLY[$i]#"$colonprefixes"}
	done

	return 0

}
complete -F _cap cap
