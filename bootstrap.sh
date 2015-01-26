#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
  # '.git/' excludes any .git directory in ../dotfiles tree.
  # '.DS_Store' excludes any Finder created dot file in ../dotfiles tree.
  # '/bootstrap.sh' excludes only this file.
  # '/scripts/' excludes ./scripts directory (i.e. only ../dotfiles/scripts/ folder).
  # etc....
	rsync --exclude ".git/" --exclude ".DS_Store" --exclude "/bootstrap.sh" \
        --exclude "bootstrap.ps1" -exclude "/scripts/" --exclude "/docs/" \
        --exclude "/README.md" --exclude "/LICENSE-MIT.txt" \
        -avh --no-perms . ~;
	source ~/.bash_profile;
}

if [[ "$1" == "--force" || "$1" == "-f" ]]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;

unset -f doIt;
