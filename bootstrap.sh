#!/usr/bin/env bash

rootFolder=$(dirname "${BASH_SOURCE}")

cd "$rootFolder"

git pull origin master

buildFolder="$rootFolder/build"

# files to build with platform dependent sections
declare -a filesToBuild=(".hgrc" ".hgignore" ".gitconfig" ".gitignore")

# concatenates base and platform specific files
function build() {
  [[ -e "$buildFolder" ]] || mkdir "$buildFolder";
  for file in "${filesToBuild[@]}"; do
    cat "$file (Base)" "$file (OSX)" > "${buildFolder}/$file"
  done
}

# wrapper around rsync for easier building --excludes options
function sync() {
  local sourceDir="$1"
  local destinationDir="$2"
  local excludeOptions=

  if (( $# == 3 )); then
    declare -a argAry=("${!3}")
    for file in "${argAry[@]}"; do
      if [[ ! -n "$excludeOptions" ]]; then
        excludeOptions="--exclude=$file "
      else
        excludeOptions="$excludeOptions--exclude=$file "
      fi
    done
  fi

  # Note --dry-run (or -n) option will make rsync only list files to be synced
  eval "rsync $excludeOptions-avh --no-perms $sourceDir $destinationDir"
}

function doIt() {

  build

  # sync builded files (no excludes)
  echo "Syncing build folder..."
  echo ""
  sync "$buildFolder" "$HOME"

  # excludeOptions=
  # for file in "${filesToBuild[@]}"; do
  #   excludeOptions="$excludeOptions --exclude='/${file} (Base)'"
  # done

  # http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
  sep=','
  joinedFilesToBuild=$(printf "${sep}%s" "${filesToBuild[@]}")
  joinedFilesToBuild=${joinedFilesToBuild:${#sep}}

  # Notes about --excludes patterns and wildcards:
  # /.gitignore* matches .gitignore, '.gitignore (Base)' etc.
  # '.git/' excludes any .git directory in ../dotfiles tree.
  # '.DS_Store' excludes any Finder created dot file in ../dotfiles tree.
  # '/bootstrap.sh' excludes only this file.
  # '/scripts/' excludes ./scripts directory (i.e. only ../dotfiles/scripts/ folder).
  # etc....

  # Array to build --excludes options for rsync
  local -a excludes=(
    ".git/"
    "/{$joinedFilesToBuild}*"
    ".DS_Store"
    "/{build,scripts,docs}/"
    "bootstrap.{sh,ps1}"
    "/README.md"
    "/LICENSE-MIT.txt")

  echo ""
  echo "Syncing root folder..."
  echo ""
  sync "$rootFolder" "$HOME" excludes[@]

  source "$HOME/.bash_profile"
}

if [[ "$1" == "--build" || "$1" == "-b" ]]; then
  build
elif [[ "$1" == "--force" || "$1" == "-f" ]]; then
  doIt
else
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
  echo ""
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    doIt
  fi
fi

unset -f doIt;
