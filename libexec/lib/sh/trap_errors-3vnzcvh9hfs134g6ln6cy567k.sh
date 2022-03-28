# v2022.10

# Verifies that "set -e" has been set before sourcing this snippet.

# Provides: trap_errors-3vnzcvh9hfs134g6ln6cy567k

case $- in
	*e*) ;;
	*) false || exit
esac
