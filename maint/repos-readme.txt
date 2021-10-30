#! /bin/sh -v
# Add special entries to your ~/.gitconfig, allowing git to resolve the
# indirect "tag:"-URLs from repos.txt into actual ones.
#
# This has the advantage that if the repository base URL should change later,
# it suffices to edit the "[url]"-sections in ~/.gitconfig but no changes are
# necessary in the actual per-repository settings of "git remote".
#
# v2021.303

cat << 'EOF' >> ~/.gitconfig 
[url "https://github.com/guenther-brunthaler/"]
	insteadof = tag:xworld.mine.nu,2009:
[url "git@github.com:guenther-brunthaler/"]
	#insteadof = tag:xworld.mine.nu,2009:
[url "rpo-root:/srv/scm/replicas/"]
	#insteadof = tag:xworld.mine.nu,2009:
EOF
