#!/bin/sh

GVF=GIT-VERSION-FILE
DEF_VER=v0.0.1

# AngularJS Example Tags
#  Unstable
#    v1.1.0-rc.4
#    v1.1.0-rc.2
#    v1.1.0-beta.4
#    v1.1.0-beta.2
#    v0.0.1-build.2342
#  Stable
#    v1.1.0-rc.3
#    v1.1.0-rc.1
#    v1.1.0-beta.3
#    v1.1.0-beta.1
#    v1.0.3
#    v1.0.2
#    v1.0.1
#    v1.0.0

LF='
'

# First see if there is a version file (included in release tarballs),
# then try git-describe, then default.
if test -f version
then
	VN=$(cat version) || VN="$DEF_VER"
elif test -d ${GIT_DIR:-.git} -o -f .git &&
	VN=$(git describe --match "v[0-9]*" --abbrev=7 HEAD 2>/dev/null) &&
	case "$VN" in
	*$LF*) (exit 1) ;;
	v[0-9]*)
		git update-index -q --refresh
		test -z "$(git diff-index --name-only HEAD --)" ||
		VN="$VN-dirty" ;;
	esac
then
	VN=$(echo "$VN" | sed -e 's/-/./g');
else
	VN="$DEF_VER"
fi

VN=$(expr "$VN" : v*'\(.*\)')

if test -r $GVF
then
	VC=$(sed -e 's/^GIT_VERSION = //' <$GVF)
else
	VC=unset
fi
test "$VN" = "$VC" || {
	echo >&2 "GIT_VERSION = $VN"
	echo "GIT_VERSION = $VN" >$GVF
}
