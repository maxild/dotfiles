# up to you (me) if you want to run this as a file or copy paste at your leisure


# https://github.com/jamiew/git-friendly
# the `push` command which copies the github compare URL to my clipboard is heaven
#bash < <( curl https://raw.githubusercontent.com/jamiew/git-friendly/master/install.sh)

# https://github.com/isaacs/nave
# needs npm, obviously.
# TODO: I think i'd rather curl down the nave.sh, symlink it into /bin and use that for initial node install.
#npm install -g nave


# homebrew!
# you need the CLI tools (or xCode).
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"


# https://github.com/rupa/z
# z, oh how i love you
cd ~/dev
git clone https://github.com/rupa/z.git
chmod +x ~/dev/z/z.sh
# also consider moving over your current .z file if possible. it's painful to rebuild :)

# z binary is already referenced from .bash_profile

# python (need this for pip and vim)
brew install python

# for the c alias (syntax highlighted cat)
#sudo easy_install Pygments
pip install pygments
# Powerline should get installed to /usr/local/lib/python2.7/site-packages/powerline
#pip install https://github.com/Lokaltog/powerline/tarball/develop
#pip install git+git://github.com/Lokaltog/powerline

# Install powerline fonts (Meslo, Source Code Pro etc.)
cd ~/dev
git clone https://github.com/powerline/fonts.git powerline-fonts
cd powerline-fonts
./install.sh