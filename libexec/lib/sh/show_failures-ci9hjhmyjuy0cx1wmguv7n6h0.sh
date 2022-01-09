# v2022.9

# Install a simple error handler which just notifies the user briefly about
# the error but does not attempt to clean up anything.
#
# This snippet also provides the functionality
# "trap_errors-3vnzcvh9hfs134g6ln6cy567k", which means it verifies that
# "set -e" has been set before sourcing this snippet.

# Provides: trap_errors-3vnzcvh9hfs134g6ln6cy567k

case $- in
	*e*) ;;
	*) false || exit
esac

trap 'test $? = 0 || echo "\"$0\" failed!" >& 2' 0
