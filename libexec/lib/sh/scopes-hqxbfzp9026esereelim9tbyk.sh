#! /bin/false
#
# POSIX-compliant portable replacement for the "local"-extension of many
# shells.
#
# It is also much more powerful because it provides a destructor-like
# "finally" mechanism.
#
# It works like this: Start a logical scope by calling "scope". A good place
# for this is the beginning of a shell function (but it can really be done
# anywhere). Then declare as many variables with "var" as you like and/or use
# "finally" to queue any number of cleanup commands to be executed later.
# "Declaring" variables will queue destructors for restoring the old values
# later. When you are done, call "unwind" at the end of the logical scope
# (such as before leaving a function. This will restore all the original
# variable values and also execute all the "finally" destructors.
#
# Note that "scope"/"unwind" can be nested to arbitrary depth. Functions using
# scopes can thus call other functions using their own scopes.
#
# Arguments for a destructor may be pushed onto the stack using pushvar() and
# push() before queueing the destructor itself with finally(). The destructor
# can then pop the pushed values off the stack (in reverse order) with
# popvar() and use them.
#
# pushvar() is more efficient than push(). Use push() only if the value to be
# pushed onto the stack is not already stored within some variable.
#
# At the end of your script, call shutdown_scopes(). This is not strictly
# necessary but recommended. It verifies that no one forgot to call unwind().
# Never "return" without calling unwind() first from within a scope inside a
# function! shutdown_scopes() also unsets all global variables set by THIS
# script snippet, which means the scope framework functions cannot be called
# any longer.
#
# Not all functions need to use scope/unwind. Only such functions which need
# local variables or destructor functionality should do so.
#
# Version 2022.84
#
# Copyright (c) 2022 Guenther Brunthaler. All rights reserved.
#
# This shell script snippet is free software.
# Distribution is permitted under the terms of the GPLv3.

# Provides: scopes-hqxbfzp9026esereelim9tbyk
# Requires: trap_errors-3vnzcvh9hfs134g6ln6cy567k

# Push value from variable with name $1 onto the stack.
pushvar() {
	eval stack_$stack_pointer=\$$1
	stack_pointer=`expr $stack_pointer + 1`
}
stack_pointer=1

# Pop variable with name $1 off the stack.
popvar() {
	stack_pointer=`expr $stack_pointer - 1`
	eval $1=\$stack_$stack_pointer
	unset stack_$stack_pointer
}

# Push value $* onto the stack.
push() {
	v_l9mcnt736v1nhnvy8z2zif4gq=$*
	pushvar v_l9mcnt736v1nhnvy8z2zif4gq
}

# Schedule an expression for evaluation when unwind() is called.
finally() {
	push "$@"
}

# Define a new scope where unwind() will stop.
scope() {
	push
}

# Schedule another list of variables to be restored when unwind() is called.
var() {
	for v_kxelefrxs6up7y7kmkdy194n0
	do
		eval v_l9mcnt736v1nhnvy8z2zif4gq=\${$v_kxelefrxs6up7y7kmkdy194n0+set}
		case $v_l9mcnt736v1nhnvy8z2zif4gq in
			'')
				finally unset $v_kxelefrxs6up7y7kmkdy194n0
				;;
			*)
				pushvar $v_kxelefrxs6up7y7kmkdy194n0
				finally popvar $v_kxelefrxs6up7y7kmkdy194n0
		esac
	done
}

# Excute all scheduled "finally" expressions until beginning of scope().
unwind() {
	while :
	do
		popvar v_bwpyjg117sqz7tintf1ridnua
		case $v_bwpyjg117sqz7tintf1ridnua in
			'') break
		esac
		eval "$v_bwpyjg117sqz7tintf1ridnua"
	done
}

# Verify that all resources on the stack have been cleaned up and all
# scheduled destructors have been run. Then unset all global variables set by
# the scope helpers framework. This effectively shuts down the framework.
shutdown_scopes() {
	case $stack_pointer in
		1) ;;
		*) echo "Resource leak!" >& 2; false || exit
	esac
	unset stack_pointer v_bwpyjg117sqz7tintf1ridnua \
		v_kxelefrxs6up7y7kmkdy194n0 v_l9mcnt736v1nhnvy8z2zif4gq
}
