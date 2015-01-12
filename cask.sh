# Install native apps
# Usage: `brew bundle cask`
#
# https://github.com/caskroom/homebrew-cask/blob/master/USAGE.md

##################################################################################
# NOTE: In order to make your Casks install to sensible and predictable locations,
# I recommend adding the following line to your ~/.zshrc or ~/.bash_profile:
#       export HOMEBREW_CASK_OPTS="--appdir=/Applications --caskroom=/etc/Caskroom"
###################################################################################
export HOMEBREW_CASK_OPTS="--appdir=/Applications --caskroom=/etc/Caskroom"

install caskroom/cask/brew-cask
#tap caskroom/versions  # contains alternate versions of Casks (e.g. betas, nightly releases, old versions)

# daily
cask install alfred                 2> /dev/null
cask alfred link                    2> /dev/null
#cask install divvy                  2> /dev/null
cask install dropbox                2> /dev/null
#cask install gyazo                  2> /dev/null
#cask install onepassword                2> /dev/null
#cask install rescuetime                 2> /dev/null
# cask install flux                     2> /dev/null

# dev
#cask install iterm2                     2> /dev/null
#cask install sublime-text               2> /dev/null
#cask install imagealpha                 2> /dev/null
#cask install imageoptim                 2> /dev/null
#cask install totalfinder            2> /dev/null
cask install sourcetree             2> /dev/null
cask install cheatsheet             2> /dev/null

# fun
#cask install limechat                   2> /dev/null
#cask install miro-video-converter       2> /dev/null

# browsers
cask install google-chrome           2> /dev/null
#cask install google-chrome-canary           2> /dev/null
#cask install firefox-nightly                2> /dev/null
cask install firefox                2> /dev/null
#cask install webkit-nightly                 2> /dev/null
#cask install torbrowser                     2> /dev/null

# less often
#cask install disk-inventory-x               2> /dev/null
#cask install screenflow                     2> /dev/null
cask install vlc                            2> /dev/null

# Not on cask but I want regardless.

# 3Hub
# File Multi Tool 5
# Phosphor