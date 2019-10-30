#! /bin/false
PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
ENV=~/.shellrc

case $TERM in
	screen | linux) color_eg56i26inepyujgl5jcd0x1i7=true;;
	*) color_eg56i26inepyujgl5jcd0x1i7=false
esac
PS1=
for p_eg56i26inepyujgl5jcd0x1i7 in \
	'\n' '\[\033[0;33m\]' 'cwd: \w' '\[\033[0m\]' '\n' '\[\033[1;32m\]' \
	'\[\033[35m\]' '[recovery]' '\[\033[32m\]' '@\h ' '\[\033[0m\]' \
	'\[\033[41;37m\]' '${?#0}' '\[\033[0;1;34m\]' \
	'#' '\[\033[0m\]' ' '
do
	case $p_eg56i26inepyujgl5jcd0x1i7 in
		'\['*) $color_eg56i26inepyujgl5jcd0x1i7 || continue
	esac
	PS1=$PS1$p_eg56i26inepyujgl5jcd0x1i7
done
unset p_eg56i26inepyujgl5jcd0x1i7 color_eg56i26inepyujgl5jcd0x1i7

export PATH PS1 ENV

if test -f "$ENV"
then
	. "$ENV"
fi
