# Read about dotfiles projects at:
# http://code.tutsplus.com/tutorials/setting-up-a-mac-dev-machine-from-zero-to-hero-with-dotfiles--net-35449

# Add `~/bin` (users private bin) to the `$PATH`
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH";
fi

# ghcup environment setup: $HOME/.cabal/bin and $HOME/.ghcup/bin are added to path
if [ -f "$HOME/.ghcup/env" ]; then
    source "$HOME/.ghcup/env"
fi

# ghc/ghci (Haskell compiler) from ppa (https://launchpad.net/~hvr/+archive/ubuntu/ghc)
# See also https://www.haskell.org/downloads/linux/
if [ -d "/opt/ghc/bin" ]; then
    export PATH="/opt/ghc/bin:$PATH";
fi

# cabal from ppa (https://launchpad.net/~hvr/+archive/ubuntu/ghc)
# See also https://www.haskell.org/downloads/linux/
if [ -d "/opt/cabal/bin" ]; then
    export PATH="/opt/cabal/bin:$PATH";
fi

# stack install places executables in ~/.cabal/bin
if [ -d "$HOME/.local/bin" ]; then
    export PATH=~/.local/bin:$PATH;
fi

# Test with: > nix-shell -p nix-info --run "nix-info -m"
# Nix package manager
# if [ -e /home/maxfire/.nix-profile/etc/profile.d/nix.sh ]; then
#     . /home/maxfire/.nix-profile/etc/profile.d/nix.sh;
# fi

# Nix Package Manager
#if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then source $HOME/.nix-profile/etc/profile.d/nix.sh; fi
# Completions
#if [ -e $HOME/.nix-profile/etc/profile.d/bash_completion.sh ]; then source $HOME/.nix-profile/etc/profile.d/bash_completion.sh; fi
#if [ -e $HOME/.nix-profile/etc/bash_completion.d/git-completion.bash ]; then source $HOME/.nix-profile/etc/bash_completion.d/git-completion.bash; fi
#export XDG_DATA_DIRS="$HOME/.nix-profile/share/:$XDG_DATA_DIRS"


# BC4 support in WSL
# See https://www.chenjianjx.com/miscellaneous-tips-while-developing-in-wsl-windows-subsystem-for-linux/
export TMPDIR='/mnt/c/Users/Maxfire/AppData/Local/Temp'

# Note: Bash on Windows does not currently apply umask properly.
if [ "$(umask)" = "0000" ]; then
  umask 0022
fi

# Load the dotfiles:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
    if [[ -f "$file" ]]; then
        if [[ ! -r "$file" ]]; then
            echo "$file is not readable by you."
            chmod u+r "$file"
        fi
        if [[ ! -x "$file" ]]; then
            echo "$file is not executable by you."
            chmod u+x "$file"
        fi
        source "$file"
    fi
done;
unset file;

# Initialize z. See https://github.com/rupa/z
# Installed by running install-deps.sh
if [[ -e "$HOME/dev/z/z.sh" ]]; then
  source ~/dev/z/z.sh
fi

# generic colouriser (http://kassiopeia.juls.savba.sk/~garabik/software/grc.html)
# prerequisite: brew install grc
GRC=$(which grc)
if [[ "$TERM" != dumb ]] && [[ -n "$GRC" ]]; then
    alias colourify="$GRC -es --colour=auto"
    alias configure='colourify ./configure'
    alias diff='colourify diff'
    alias make='colourify make'
    alias gcc='colourify gcc'
    alias g++='colourify g++'
    alias as='colourify as'
    alias gas='colourify gas'
    alias ld='colourify ld'
    alias netstat='colourify netstat'
    alias ping='colourify ping'
    alias traceroute='colourify /usr/sbin/traceroute'
fi

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if which brew > /dev/null && [[ -f "$(brew --prefix)/etc/bash_completion" ]]; then
	source "$(brew --prefix)/etc/bash_completion";
elif [[ -f /etc/bash_completion ]]; then
	source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git > /dev/null 2>&1 && [[ -f "/usr/local/etc/bash_completion.d/git-completion.bash" ]]; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[[ -e "$HOME/.ssh/config" ]] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;
