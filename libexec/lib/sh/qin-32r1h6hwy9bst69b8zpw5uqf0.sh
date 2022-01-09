# v2022.9

# Requires: println-871v57a0dzb6d3rxykj87vsnf
# Requires: scopes-hqxbfzp9026esereelim9tbyk

# "Quote if (more precisely: what is) necessary": Print command $@ in such a
# way that it could be sourced by a POSIX shell.
qin() {
	scope
		var c a
		c=
		for a
		do
			expr x"$a" : x'[-+_/%=,:.[:alnum:]]*$' >& 7 || {
				a=`println "$a" | sed "s/'/'\\\\\\\\''/g"`
				a="'$a'"
			}
			c=$c${c:+ }$a
		done 7> /dev/null
		println "$c"
	unwind
}
