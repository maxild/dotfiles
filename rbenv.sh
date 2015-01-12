#!/usr/bin/env bash

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install rbenv
#    (ruby..ore more correct 'rubies')

# core
brew install rbenv ruby-build

# utilities
#brew install rbenv-gem-rehash               # never run rbenv rehash again
#brew install rbenv-default-gems             # Specify gems in ~/.rbenv/default-gems by name, one per line.

# Remove outdated versions from the cellar.
brew cleanup
