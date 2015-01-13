#!/usr/bin/env bash

##################################################################
# Nave (nave.sh) is really handy if you want to test things
# in different versions of node and use stable release
# versions of things.
#
# To install nodies
#      nave install 0.8.8
# To unisntall nodies
#     nave uninstall 0.8.8
# To use a version of node in a virtual environment
#      nave use <version>
#      npm install whatever etc and do stuff...
#      nave use <other-version>
#      etc...
# To return to non-nave-land
#      exit
# To use as your main node (install in /usr/local/bin)
#      nave usemain stable
#
# <version> can be the string "latest" to get the latest distribution.
# <version> can be the string "stable" to get the latest stable version.
################################################################

fail () {
  echo "$@" >&2
  exit 1
}

# By default, nave puts its stuff in ~/.nave/. If this directory does not exist
# and cannot be created, then it will attempt to use the location of the nave.sh
# bash script itself. If it cannot write to this location, then it will exit with an error.
# Therefore make a folder where nave can put its stuff.
if [[ ! -d ~/.nave ]]; then
    mkdir ~/.nave || fail 'Error: could not create ~/.nave'
fi
# wget down the bash script and make it executable,
cd ~/.nave
wget http://github.com/isaacs/nave/raw/master/nave.sh &> /dev/null
chmod a+x nave.sh
# and symlink the bash script into /usr/local/bin/nave
if [[ ! -e /usr/local/bin/nave ]]; then
  ln -s $PWD/nave.sh /usr/local/bin/nave
fi