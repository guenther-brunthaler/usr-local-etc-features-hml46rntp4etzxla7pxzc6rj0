# v2022.84
#
# Install an error handler which calls unwind() to run all (if any)
# outstanding finally() handlers for cleaning up before actually exiting.

# Provides: cleanup-l98e2762zc08fyiqt8787lpk5
# Requires: scopes-hqxbfzp9026esereelim9tbyk
# Requires: trap_errors-3vnzcvh9hfs134g6ln6cy567k

cleanup_l98e2762zc08fyiqt8787lpk5() {
	rc_l98e2762zc08fyiqt8787lpk5=$?
	case $stack_pointer in
		'') ;;
		*)
			while test "$stack_pointer" != 1
			do
				unwind
			done
			shutdown_scopes
	esac
	test $rc_l98e2762zc08fyiqt8787lpk5 = 0 || echo "\"$0\" failed!" >& 2
	unset rc_l98e2762zc08fyiqt8787lpk5
}
trap cleanup_l98e2762zc08fyiqt8787lpk5 0
trap 'exit $?' INT HUP QUIT TERM
