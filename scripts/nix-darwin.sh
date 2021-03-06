#!/bin/bash

source `dirname "$0"`/logging.sh
# log all messages
verbosity=5

BACKUP_FOLDER=$HOME/.dotfiles.bak/`date +'%Y-%m-%dT%H-%M-%S'`
mkdir -p $BACKUP_FOLDER

# Install Nix
function install_nix() {
  inf "Installing Nix"
  mkdir -p /tmp/install_nix
  cd /tmp/install_nix

  curl -O https://nixos.org/nix/install
  curl -O https://nixos.org/nix/install.sig
  gpg2 --verify ./install.sig
  sh ./install
}

error_exit()
{
	echo "$1" 1>&2
	exit 1
}

# If nix-env does not exist, install it.
inf "Checking whether nix-env is already installed"
command -v nix-env >/dev/null 2>&1 || error_exit "Nix is not installed, aborting!"  # install_nix
inf "Checking whether darwin-rebuild is already installed"
command -v darwin-rebuild >/dev/null 2>&1 || error_exit "Nix-Darwin is not installed, aborting!"

# Link Nix configuration
if [ -e $HOME/.nixpkgs ]; then
  debug "Backing up ~/.nixpkgs"
  mv $HOME/.nixpkgs $BACKUP_FOLDER/.nixpkgs
fi
inf "Linking ~/.nixpkgs -> $(pwd)/nixpkgs"
ln -s $(pwd)/nixpkgs $HOME/.nixpkgs

# Install essential pacakges defined in nixpkgs/config.nix
# TODO: Uncomment when I understand ~/.nixpkgs/config.nix and shell.nix logic
#inf "Installing essential packages defined in ~/.nixpkgs/config.nix"
#nix-env -i all

# Remove the backup folder if it is empty
[ "$(ls -A $BACKUP_FOLDER)" ] \
  && inf "Backup files are stored in $BACKUP_FOLDER" \
  || (inf "Nothing is backed up, removing $BACKUP_FOLDER" && rm -r $BACKUP_FOLDER)

# read -p "Do you want to run `darwin-rebuild switch`? (y/n) " -n 1
#   echo ""
#   echo ""
#   if [[ $REPLY =~ ^[Yy]$ ]]; then
#     darwin-rebuild switch
#   fi