# v2022.10

# Install a simple error handler which just notifies the user briefly about
# the error but does not attempt to clean up anything.

# Provides: show_failures-ci9hjhmyjuy0cx1wmguv7n6h0
# Requires: trap_errors-3vnzcvh9hfs134g6ln6cy567k

trap 'test $? = 0 || echo "\"$0\" failed!" >& 2' 0
