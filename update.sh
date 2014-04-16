#/bin/sh -e

# Pinoccio firmware repository update script
#
# Copyright (C) 2014 Matthijs Kooijman <matthijs@stdin.nl>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# return 0 if program version is equal or greater than minimum version
# based on http://fitnr.com/bash-comparing-version-strings.html
check_version()
{
    version=$1 minimum=$2
    # This uses --key instead of --version-sort, since OSX sort (and probably
    # older gnu versions) don't support --version-sort. This only checks the first
    # four version components (so the minimum version must not have more
    # than 3 components).
    winner=$( (echo "$version"; echo "$minimum") | sort -t . -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr | head -1)
    [ "$winner" = "$version" ] && return 0
    return 1
}

GIT_VERSION=$(git --version | sed 's/^[^.0-9]*//')
GIT_REQUIRED=1.8.3
if ! check_version "$GIT_VERSION" "$GIT_REQUIRED"; then
	echo "Git version too old. Found: $GIT_VERSION. Required: $GIT_REQUIRED"
	exit 1;
fi

echo "Updating..."

# Resync submodule urls in case .submodules changed (.git/config
# contains a copy of them)
git submodule --quiet sync

# Update all submodules, using the latest version from the remote
# repository (--remote). Instead of creating a detached HEAD
# (--checkout), rebase the remote changes into the local branch
# (--rebase). If you don't have any local changes, this will just do a
# fast-forward. Finally, if the submodule wasn't initialized yet, do
# that now (--init).
git submodule update --init --remote --rebase

if [ $? -ne 0 ]; then 
	echo "Update failed"
	exit 1; 
fi

echo "Current status is:"

git submodule status

echo -e "\n\nUpdate successful!\n"
