# Generate/update dependency implementations (lines sourcing script snippets)
# in all the scripts specified in the command line. Alternatively, a list of
# pathnames to such scripts can be fed via standard input.
#
# Version 2022.9

# Requires: println-871v57a0dzb6d3rxykj87vsnf
# Requires: qin-32r1h6hwy9bst69b8zpw5uqf0
# Requires: show_failures-ci9hjhmyjuy0cx1wmguv7n6h0

marker_uuid=b83iv5hz8sbpbv4i80t9v5rwv
ref_cmd='Requires'
def_cmd='Provides'
new_start_mark="# Generated $marker_uuid: {"
new_gen_pfx='. "$lib"/'
new_end_mark="# }"

set -e
base=`readlink -f -- "$0"`
base=`dirname -- "$base"`
base=`dirname -- "$base"`

# Generated bj2lapzmr8ydaa4jmq66c9kr0: {
lib=$base/libexec/lib/sh
# Generated b83iv5hz8sbpbv4i80t9v5rwv: {
. "$lib"/println-871v57a0dzb6d3rxykj87vsnf.sh
. "$lib"/scopes-hqxbfzp9026esereelim9tbyk.sh
. "$lib"/cleanup-l98e2762zc08fyiqt8787lpk5.sh
# }
# }

opt='\{0,1\}'
plus='\{1,\}'
s='[[:space:]]'
S="[^[:space:]]$plus"
# $1 := Prefix.
idrx='[-_[:alnum:]]'
start_rx="^\\($s*\\)#[^{:}]*$marker_uuid[^{}[:alnum:]]*{$s*\$"
end_rx="^$s*#$s}$s*\\(#.*\\)$opt\$"
uurx=0-9a-np-z # Base 35 alphabet: Omit 'o'.
nurx="[^$uurx]$opt"
uurx="[$uurx]\\{25\\}"
xtrx="\\([.]$idrx*\\)$opt"
# $1 := Prefix /w cmd, $2 := cmd, $3 := ref/def UUID, $4 := Suffix.
cmd_rx="^\\($s*#$s*\([PR][re][oq][a-z]*\):$s*\\)$S\\($uurx\\)\\($nurx.*\\)"
preproc_script="
	h
	s|$cmd_rx|\\2|; t ck_cmd
	/$start_rx/,/$end_rx/ b generated
	:other
	s/^/*O\\n/
	b
	:ck_cmd
	s/^$ref_cmd\$/*R/; t valid
	s/^$def_cmd\$/*D/; t valid
	g
	b other
	:valid
	p # cmd
	g; s|$cmd_rx|\\1|; p # pfx /w cmd
	g; s|$cmd_rx|\\3|; p # UUID
	g; s|$cmd_rx|\\4| # sfx
	b
	:generated
	/$star_rx/ b other
	/$end_rx/ b other
	/.*$nurx$uurx\\$/ b valid_gen
	/.*$nurx$uurx$nurx.*/ b valid_gen
	b other
	:valid_gen
	# $1 := prefix, $2 := UUID, $4 := suffix
	s|\\(.*/\\)$idrx*\\($uurx\\)$xtrx\\(.*\\)|*G\\n\\1\\n\\2\\n\\4|
"

dry_run=false
while getopts n opt
do
	case $opt in
		n) dry_run=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

preproc() {
	sed "$preproc_script"
}

# Read $1 (default: 1) lines, leaving the last one in $result.
nread() {
	scope
		var i
		i=${1-1}
		while test $i != 0
		do
			IFS= read -r result
			i=`expr $i - 1 || :`
		done
	unwind
}

# Write definitions to fd # 5 and write references to fd # 6.
extract_dcl() {
	scope
		var result cf
		cf=
		while IFS= read -r result
		do
			case $result in
				"*F") nread; cf=$result;;
				"*D")
					test "$cf"; nread 2
					echo "$result:$cf" >& 5
					nread
					;;
				"*R")
					test "$cf"; nread 2
					echo "$result:$cf" >& 6
					nread
					;;
				"*O") nread;;
				"*G") nread 3;;
				*) false || exit
			esac
		done
	unwind
}

scope
	var TD
	TD=`mktemp -d -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`
	cleanup_tmpdir() {
		rm -r -- "$TD"
	}
	finally cleanup_tmpdir
	var LC_COLLATE
	export LC_COLLATE=C
	case $# in
		0) cat;;
		*)
			var arg
			for arg
			do
				println "$arg"
			done
	esac \
	| while IFS= read -r script
	do
		test -f "$script"
		test -r "$script"
		{
			printf '*F\n%s\n' "$script"
			preproc < "$script"
		} | extract_dcl 
		println "$script"
	done 5> "$TD"/defs 6> "$TD"/refs \
	| sort -u > "$TD"/scripts
	
	find -H "$lib" -type f \
	| sed "
		s/^\\($uurx\\)$nurx.*/\\1:&/; t
		s/.*$nurx\\($uurx\\)$nurx.*/\\1:&/; t
		s/.*$nurx\\($uurx\\)\$/\\1:&/; t
		q
	" \
	| {
		while IFS=: read -r u f
		do
			printf '*F\n%s\n*D\n-\n%s\n-\n' "$f" "$u"
			preproc < "$f"
		done | extract_dcl
	} 5>> "$TD"/defs 6>> "$TD"/refs
	# Deduplicate and sort defs(UUID^, path).
	sort -o "$TD"/defs -u -- "$TD"/defs
	# Deduplicate and sort refs(UUID^2, path^).
	cat < "$TD"/refs > "$TD"/tmp
	sort -u < "$TD"/tmp | sort -t : -k 2 -k 1,1 > "$TD"/refs
	# Create unchecked(path^) with (possibly) yet-unsatisfied references.
	cp -- "$TD"/scripts "$TD"/unchecked
	# Create need(UUID^, path) required by already-checked paths.
	> "$TD"/need
	# Iterate until all references have been checked.
	#echo "# BEGIN"; sep='***************************************'
	while test -s "$TD"/unchecked
	do
		#echo "# NEXT ITERATION"
		#list-files-and-contents "$TD"/refs "$TD"/unchecked
		#echo "# Create new(UUID^, path) of refs directly required by"
		#echo "# yet-unchecked."
		sort -t : -k 2,2 < "$TD"/refs \
		| join -o 2.1,2.2 -t : -2 2 -- "$TD"/unchecked - \
		| sort > "$TD"/new
		#list-files-and-contents "$TD"/refs "$TD"/new
		#echo "$sep"
		#echo "# Create missing(UUID^, path) as new() not in need()."
		join -v 1 -t : -- "$TD"/new "$TD"/need > "$TD"/missing
		#list-files-and-contents "$TD"/missing
		#echo "$sep"
		#list-files-and-contents "$TD"/defs
		#echo "# Create definers(UUID^, path) for missing()."
		join -o 2.1,2.2 -t : -- \
			"$TD"/missing "$TD"/defs > "$TD"/definers
		#list-files-and-contents "$TD"/definers
		#echo "$sep"
		#echo "# Merge definers() into need()."
		sort -m -o "$TD"/need -- "$TD"/definers "$TD"/need
		#list-files-and-contents	"$TD"/need
		#echo "$sep"
		#echo "# Extract unchecked() as path from definers()."
		cut -d : -f 2 < "$TD"/definers | sort > "$TD"/unchecked
		#list-files-and-contents "$TD"/unchecked
		#echo "$sep"
	done
	#echo "# Done!"
	#list-files-and-contents	"$TD"/defs "$TD"/refs "$TD"/need
	while false IFS= read -r script
	do
		join -t : 
		process_script < "$script" > "$TD"/new
		if $dry_run
		then
			echo "--- SIMULATED new \"$script\":"
			cat < "$TD"/new
			echo "--- END of \"$script\"."
		else
			cat < "$TD"/new > "$script"
		fi
	done < "$TD"/scripts
unwind
