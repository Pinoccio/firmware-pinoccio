#/bin/sh -e

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

echo "Done, current status is:"

git submodule status
