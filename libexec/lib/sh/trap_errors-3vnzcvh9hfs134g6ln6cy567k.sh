# v2022.10

# Verifies that "set -e" has been set before sourcing this snippet.

case $- in
	*e*) ;;
	*) false || exit
esac
