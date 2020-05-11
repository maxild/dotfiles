# Dynamic linking -- debugging, fixing load errors

See https://discourse.nixos.org/t/libgl-undefined-symbol-glxgl-core-functions/512

## Linux

When looking for a shared library, the dynamic linker(ld.so) checks the paths listed in DT_RPATH (unless DT_RUNPATH Is set) , the paths listed in the environment variable LD_LIBRARY_PATH, the paths listed in DT_RUNPATH, the libraries listed in /etc/ld.so.cache, and finally /usr/lib and /lib.  It checks in that order and takes the first library found.  At least on my linux box, LD_LIBRARY_PATH does NOT override the paths in DT_RPATH even though the documentation implies that it does.   LD_LIBRARY_PATH does override DT_RUNPATH.

## Darwin

When looking for shared libraries, the dynamic linker (dyld) first scans the directories in DYLD_LIBRARY_PATH, then checks the location in the install name (which is per library), and finally checks the standard locations.

DYLD_LIBRARY_PATH successfully overrides the the path embedded in the executable.

Caveat 1: LD_LIBRARY_PATH has no runtime impact, but it does impact where the static linker looks for share libraries.  It looks first in the directories specified using -L, the the directories in LD_LIBRARY_PATH, and finally in /lib, /usr/lib, & /usr/local/lib.  This is particularly confusing  because many configure scripts seem to ignore LD_LIBRARY_PATH and you can get inconsistent results from configure and gcc/ld on whether a library is present.
Caveat 2: Mac OS X has a set of compiler/linker switches for dealing with Frameworks (packages of shared libraries and include files).  These are installed outside the typical *nix directory structure.  These switches act like -I (to gcc) and -L (to ld).  If you end up totally confused about where to find something, read up on this.  The OpenGL and OpenAL headers and libraries are in Frameworks, for example.

## Windows

See https://gitlab.haskell.org/ghc/ghc/-/wikis/shared-libraries/management

# Installing Nix Package manager on Ubuntu

## Keyboard

The Ubuntu 18.04 LTS is running inside virtual box on a macbook

In the terminal of the Ubuntu type this to fix keyboard issue wity tilde and backtick.

```bash
setxkbmap -option apple:badmap
```

The above should be added to ~/.profile

## Source this script

Finally, for your convenience, the installer modified ~/.profile to automatically enter
the Nix environment. What `~/.nix-profile/etc/profile.d/nix.sh` really does is simply to
add `~/.nix-profile/bin` to PATH and `~/.nix-defexpr/channels/nixpkgs` to NIX_PATH. We'll discuss NIX_PATH later.

```bash
. ~/.nix-profile/etc/profile.d/nix.sh
```

Read nix.sh, it's short.

## Default shell

Setting the default shell

```bash
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "$USER"
echo $SHELL
```

This requires a restart before $SHELL is changes to `/home/maxfire/.nix-profile/bin/zsh`.

## .profile in zsh

You can add this to your `.zshrc` file suh that .profile is shared between bash and zsh.
Otherwise use .zprofile if they should not be shared.

```
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'
```

* `.profile` is for env variables. Executed once
* `.bash_profile` is bash specific profile, and .zprofile is zsh specfic
* `.bashrc` and .zshrc are called for every shell/subshell.

# Installing Nix package manager on windows

https://dev.to/notriddle/installing-nix-under-wsl-2eim

# Important package sets

nix-darwin (modules and darwin-rebuild program)
https://github.com/LnL7/nix-darwin/
https://github.com/LnL7/nix-darwin/blob/master/modules/examples/lnl.nix

home-manager
https://github.com/rycee/home-manager/

nixos (nixpkgs)
https://github.com/NixOS/nixpkgs/

nixos (channels): a read-only miror, where master is pushed/merged upstream to different "release" branches
https://github.com/NixOS/nixpkgs-channels/i

Alternative home-manager or cli
https://github.com/bobvanderlinden/pocnix

./nix folder: the configuration to pin Nixpkgs
niv: pin nixpkgs
direnv: setup nix-shell automagically (`use nix` in `.envrc`)

# Nix, Nixpkgs, Nixos and Nix-darwin is a mess

* You have nix-shell to get an environment of a local project.
* You have nix-env to install packages at user level.
* You have nixos-rebuild (darwin-rebuild) to configure your system.

These all have very different workflows. nix-shell and nixos-rebuild are declarative and
you have to edit files to be able to make changes. nix-env is imperative in the sense that
every command changes some state in your home directory.

Especially for new people this is a burden to know the differences. I much rather have
something that is declarative, but works for local projects, user environments and system configuration.

In addition, nix-env being imperative doesn't really fit Nix. reproducability is one of the main points,
but getting the same user environment is not trivial with channels and nix-env.

Inheriting home-manager would at least allow declarative use of Nix in each environment. Having nix-env
next to home-manager results in a unpredictable situation where packages are installed in different places.

A next step (imo) is to align the tools so that system, home and local environments feel the same way to use.

## Is this correct?

nix-build, nix-instantiate, nix-store, nix-shell only depend on pkgs (derivations) and lib (stdlib of nix)

nixos-rebuild, darwin-rebuild and home-manager also depend on nixos modules (nixos/modules, nixos/lib etc)
is the sense they only quary the result (config attr set)

# Overlay pattern

http://blog.tpleyer.de/posts/2020-01-26-Nix-overlay-evaluation-example.html

http://r6.ca/blog/20140422T142911Z.html

In Nix a recursive attribute set is syntactic sugar for a special function called an
explicit self-referential attribute set

```
self : { bindings }
# Example
rattrs = self : { x = 2; y = 3; z = self.x + self.y; }
```

The overlay pattern is a special function (called an overlay) that can be used to override
attributes via late binding

```
overlay = self: super : { updated_bindings }
# Examples
let overlay1 = self: super:
{
  a = 1;
  b = 2;
  c = 3;
  d = self.a + self.b;
  e = self.c + self.d;
};
let overlay2 = self: super:
{
  x = super.a;
  b = 22;
  c = 11;
};
```

Overlays can compose because we can combine them one after another to get "overlayed" self-referential recursive attribute set

This is done by using extend defined by

```
extends = f: rattrs: self: let super = rattrs self; in super // f self super;
```

Example

```
# base (aka super, type :: a -> a)
f = self: { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; }
# overlay (aka an override, type : (a -> a -> a))
g = self: super: { foo = super.foo + " + "; }
# derived (type :: a -> a)
v = (extends g f) = g `extends` f
```

Reductions show that the overlay is injected into the evaluation

```
extends g f = self: let super = f self; in super // g self super;
            = self: let super = { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; }; in super // g self super
            = self: { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; } // g self { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; }
            = self: { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; } // { foo = "foo" + " + "; }
            = self: { foo = "foo + "; bar = "bar"; foobar = self.foo + self.bar; }

```

foo attribute have been overriden.

```
=
extends' (extends' (extends' (self: {}) overlay1) overlay2) overlay3
=
extends' (extends' (self: let super = (self: {}) self; in super // overlay1 self super) overlay2) overlay3
=
extends' (extends' (self: {} // overlay1 self {}) overlay2) overlay3
=
extends' (self: let super = (self: {} // overlay1 self {}) self; in super // overlay2 self super) overlay3
=
extends' (self: ({} // overlay1 self {}) // overlay2 self ({} // overlay1 self {})) overlay3
=
self: let super = (self: ({} // overlay1 self {}) // overlay2 self ({} // overlay1 self {})) self in super // overlay3 self super
=
self: (({} // overlay1 self {}) // overlay2 self ({} // overlay1 self {})) // overlay3 self (({} // overlay1 self {}) // overlay2 self ({} // overlay1 self {}))
```

# Nix REPL

https://nixos.wiki/wiki/Nix-repl

And `nix repl '<nixpkgs>'` is the same as doing `nix repl` and then `:l <nixpkgs>`.

> Note that the Nix search path is impractical in many situations. You can only pass it from the
  outside, and it easily creates impurity. In my experience, problems are better solved with explicit
  argument passing or the functions relating to fix-points like callPackage and the overlay system.

You can evaluate <nixpkgs> in the REPL

```bash
nix-repl> <nixpkgs>
```

## Inspecting packages

You can use `builtins.functionArgs` to see what named arguments a Nix lambda takes. This
is the way `callPackage` automatically dios dependency injection into the lambdas that create
derivations.

```bash
$ nix repl '<nixpkgs>'
nix-repl> f = import "${pkgs.path}/pkgs/servers/varnish"
nix-repl> f
nix-repl> builtins.functionArgs f
```

## Inspecting nixos modules (config)

```bash
$ nix repl '<nixpkgs>'
nix-repl> :l <nixpkgs/nixos>
# This line requires a (dummy) configuration.nix file configured via NIXOS_CONFIG or <nixos-config>
nix-repl> (nixos {}).config.services.nginx.enable # Use TAB completaion to discover options
```

# Catalina installation

https://tutorials.technology/tutorials/using-nix-with-catalina.html
https://github.com/NixOS/nix/issues/2925#issuecomment-604501661

```bash
# Create a volume for the nix store and configure it to mount at /nix.
wget https://raw.githubusercontent.com/LnL7/nix/darwin-10.15-install/scripts/create-darwin-volume.sh
bash create-darwin-volume.sh
# The following options can be enabled to disable spotlight indexing of the volume, which might be desirable.
sudo mdutil -i off /nix
# Hides the "Nix Store" disk on Desktop, need to relaunch Finder to see effect. Will not be necessary after the PR comment https://git.io/Jv2xT is accepted.
sudo SetFile -a V /nix
```

# CLI

NOTE: For profiles to work, you should put ~/.nix-profile/bin in your PATH

## Install

nix-end -iA <pkg>

## Install for duration of session

nix-shell -p libjpeg openjdk

## Uninstall

nix-env -e <pkg>

## Search: available packages

nix-env -qaP | grep <pkg> # list too long not to grep

Query `-q` available `-a` packages that match the provided argument
while preserving `-P` already installed packages on the system (i.e.:
retain formerly installed versions of a specified derivation while
attempting to install the version specified in the argument).

Equivalent to: apt-cache search <pkg>

## List: installed packages

nix-env -q
nix-env -q | grep <pkg>

## Upgrade

Don't use it. Use install

nix-env -uA <pkg>

## See Current Profile

ls -la ~/.nix-profile

## Switch Profile (environment)

nix-env --switch-profile $NIX_USER_PROFILE_DIR/<profile

If the profile doesn’t exist, it will be created automatically. >

## List Profiles

ls -al $NIX_USER_PROFILE_DIR

## List Generations

nix-env --list-generations

## Switch genaration

nix-env --switch-generation 23
nix-env --rollback

## Delete generations

nix-env --delete-generations <old>
nix-env --delete-generations 10 23 56

# stdenv.mkShell

https://rycwo.xyz/2019/02/16/nixos-series-dev-env
nix-shell is similar to nix-build in that it receives a file defining a package as input, except
it does not execute the build, stopping beforehand and entering the environment to be used for
building the package.

initial PR link
https://github.com/NixOS/nixpkgs/issues/58624#issuecomment-499005757

shellHook composes
https://github.com/NixOS/nixpkgs/pull/63701

# direnv tool

* You do not have to use a sub shell, and it integrates with nix (use_nix)
* You can set any environment variables (secrets etc), and gitignore the .envrc file
* You can execute any bash script. It is like having a project based .bashrc/.zshrc

Install through nix and add the following to your profile

For bash

```bash
val "$(direnv hook bash)"
```

For zsh

```zsh
eval "$(direnv hook zsh)"
```

Too see logged information from direnv (see also https://github.com/direnv/direnv/issues/68)

```bash
DIRENV_LOG_FORMAT='direnv: %s'
```

Functions in stdlib

* dotenv .env
* layout (ruby|python|...|node)
* use (ruby|...) <-- don't use it, use nix-shell integration
* use nix

In `~/.config/direnv/direnvrc` you can put extensions to the stdlib.

env | grep DIRENV_

direnv show_dump "$DIRENV_DIFF"

n: new environment
p: previous environment

direnv show_dump "$DIRENV_WATCHES"

watch_file is for reloading

.envrc should probably not be committed (it is for personal use), because users cannot
override the environment. Everybody gets the same environment.

NOTE: lorri uses direnv under the hood. lorri is good for large nix projects (loading is expensive)

# Lazy Evaluation in Nixpkgs

A nix file contains a single top-level expression with no free variables.

Nix evaluate expression outside-in, left-to-right (aka call by name)

And more importantly, as soon as the Nix interpreter sees that the outermost thing is no longer
an operator but a data constructor (like string, integer, or set), it stops. You have to force
evaluation of nested attributes in any attribute set in Nix. This is why we can evaluate infinite
structures or very big structures like the giant <nixpkgs> package set without doing more work than
required by the code traversing the tree of packages (dependencies).

Just as with sets, the list elements are left unevaluated unless they are forced. To extract an element
from a list, we can use a built-in function called builtins.elemAt.

About imports. The substitution of the file contents for the import expression happens lazily,
just like all other expressions. This means the file is only loaded when the import expression is forced.
If your program does not force the import, the file is not loaded.

The only (sensible) constraint is that the imported Nix expression must not contain any free variables;
it is an error for the imported expression to try to use anything defined in the file doing the importing.
However the imported expression can be a function, and this way you can pass (bound) variables to the imported
expression using application of an abstraction (in lambda calculus terms).

# Standard variables in Nix

## pkgs

## lib

There are more than one lib

* pkgs.lib: The pkgs.lib isn’t related to NixOS. It comes from the fact that pkgs.callPackage automatically passes arguments defined in the pkgs scope. So by having pkgs.lib, you can callPackage files like `{ lib, ... }: { … }`. The module system is defined in the lib, which include all the functions used to change the definitions such as mkForce and mkIf, as well as all function used to declare options such mkOption or types.

* pkgs.stdenv.lib: stdenv has lib because that way if you just need to toss in a lib function you can write stdenv.lib.foo without touching the arguments list at the top of your file (since every package already includes stdenv). In fact, all the packages I’ve touched access lib via stdenv, and using `meta = with stdenv.lib; { … }` seems to be extremely common. I don’t think I’ve actually seen a package yet that pulls in lib as an argument, though surely they exist.

NOTE: There's no difference between pkgs.lib and pkgs.stdenv.lib. lib is imported [here](https://github.com/NixOS/nixpkgs/blob/abf27609c6ffd4d90932219a2c839679fbeb0da3/pkgs/top-level/default.nix#L46) and passed down to the [pkgs attrset](https://github.com/NixOS/nixpkgs/blob/072febaa922635bd048d683ef51c408c1873f348/pkgs/top-level/all-packages.nix#L30). The [same lib expression](https://github.com/NixOS/nixpkgs/blob/983e74ae4e9092a302ba281357e33ae9f32a2024/pkgs/stdenv/generic/default.nix#L1) is [used](https://github.com/NixOS/nixpkgs/blob/983e74ae4e9092a302ba281357e33ae9f32a2024/pkgs/stdenv/generic/default.nix#L137) for stdenv.

* nixos/lib: The lib parameter in NixOS modules comes from the module system itself and is the preferred way to reference it in NixOS. It’s the only `lib` that doesn’t depend on `pkgs` and therefore doesn’t lead to infinite recursion when you use it to define modules themselves (which might define overlays, which can influence pkgs).


# Playing with evaluating nix expressions

There are two approaches

* Use the REPL
* Use nix-instantiate

I will use `nix-instantiate` in the following.

Lets say we have a nix expression defined in a file called `test.nix` with the contents

```nix
rec {
  i = "like Nix";
  you = i;
}
```

Then we can test it like this

```bash
nix-instantiate --eval --json --strict test1.nix | jq
```

Here we use `--strict`, because it will force the nix interpreter to recursively evaluate list elements and
attribute sets. Normally, such sub-expressions are left unevaluated (since the Nix expression language is lazy).
We also use `--json` to print the resulting value as an JSON representation of the abstract syntax tree rather
than as an ATerm, because then we can easily pretty-pring using `jq` tool.

NOTE: You can also use `--show-trace` with nix-instantiate to show stack traces on errors.

# Playing with evaluating nixos module system

> NixOS is a Nix module system that builds a system configuration,
  and home-manager is a Nix module system that builds a user-home configuration.

> NixOS doesn't actually use callPackage. it uses lib.evalModules. The fact there is a difference between
how NixOS is evaluated, vs how Nixpkgs is evaluated is something I actually find quite annoying. Whilst
nixpkgs is all about functions and dependency injection, NixOS is all about merging dictionaries.

In most places in the nixpkgs repository, the function in `nixos/lib/eval-config.nix` is used for evaluation
but there are convenience wrappers like `nixos/default.nix` and the `nixos` function in the top level
nixpkgs set. The latter is only available starting with the soon-to-be-released NixOS 18.09.

For instance, to evaluate our local NixOS configuration we could use:

```bash
$ nix-build -E "(import <nixpkgs/nixos> { configuration = /etc/nixos/configuration.nix; }).system"
```


Or even simpler:

```bash
$ nix-build '<nixpkgs/nixos>' -A system --arg configuration /etc/nixos/configuration.nix
```

We use the built-in import function to evaluate the nixos/default.nix file from nixpkgs.

The result of this expression is an attribute set that contains the system closure,
the kernel, the initial ramdisk and possibly other build targets defined by NixOS modules.

If we are on 18.09 or later, we can use the `nixpkgs.nixos` function like this:

```bash
$ nix-build -E "(import <nixpkgs> {}).nixos /etc/nixos/configuration.nix"
```

Note that nixpkgs is a function that takes an attribute set with configuration like overlays,
overrides or the target platform for cross compiling. This function returns the complete package set.


```nix
let
  myOS = pkgs.nixos ({ lib, pkgs, config, ... }: {
    config.services.nginx = {
      enable = true;
      # ...
    };
    # Use config.system.build to exports relevant parts of a
    # configuration. The runner attribute should not be
    # considered a fully general replacement for systemd
    # functionality.
    config.system.build.run-nginx = config.systemd.services.nginx.runner;
  });
in
  myOS.run-nginx
```




See also: https://nixos.mayflower.consulting/blog/2018/09/11/custom-images/

## Idea

In the user environment, all programs should be available as symlinks in `~/.nix-profile/bin/` into the nix store,
and in the system environment, all programs should be available as `/run/current-system/sw/bin/` into the nix store.

Because symlinks are atomic (cannot be created in a hal baked state) your build build system is fault tolerant when
using the Nix build tool.

## Profiles (aka Environments)

In NixOS (nix-darwin, home-manager), there are three environments:

* system environment (managed by `configuration.nix` and `nixos-rebuild`/`darwin-rebuild`)
* user environment (managed by `home.nix` and `home-manager` declaratively, or `nix-env` in a more imperative style)
* development environment (managed by `shell.nix` and `nix-shell`).

## Home manager

If you cannot install NixOS, and you want that:

> User-installed programs, on the other hand, are available at their respective ~/.nix-profile/bin/

The home-manager tool should now be installed and you
can edit

    ~/.config/nixpkgs/home.nix

to configure Home Manager. Run 'man home-configuration.nix' to
see all available options.

The file `~/.config/nixpkgs/home.nix` contains the declarative specification of your Home Manager
configuration. The command `home-manager` takes this file and realises the user environment
configuration specified therein.

NOTE: If instead of using channels you want to run Home Manager from a Git checkout of the
repository then you can use the programs.home-manager.path option to specify the absolute
path to the repository.

### Manual
https://rycee.gitlab.io/home-manager/options.html

# The installer created this in /etc/bashrc and /etc/zshrc

```bash
# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
. '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
```

## On both

Notice the environment variable NIX_USER_PROFILE_DIR that will be used later to define profiles.

Notice that each user can have as many profiles as he wants.

Your current profile is defined by the the .nix-profile symbolic link in your home directory.
Nix automaticaly creates your first “default” profile : it’s a symbolic link pointing to /nix/var/nix/profiles/default.

To create a new profile, use nix-env command (remind that NIX_USER_PROFILE_DIR has been set to /nix/var/nix/profiles/per-user/), for instance:

```bash
nix-env --switch-profile $NIX_USER_PROFILE_DIR/<my-profile>
```

To see list of your profiles

```bash
ls -al $NIX_USER_PROFILE_DIR

```

To see your current profile

```bash
ls -al ~/.nix-profile
```

## Nix

```bash
echo $NIX_USER_PROFILE_DIR
/nix/var/nix/profiles/per-user/maxfire
$ echo $NIX_PROFILES
/nix/var/nix/profiles/default /Users/maxfire/.nix-profile
$ echo $NIX_PATH

nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:

/nix/var/nix/profiles/per-user/root/channels
```

Notice the `<nixpkgs>` channel `nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs` of the root
user (because of multiuser install the nic package manager is run by a daemon under root)

You can also use nix-instantiate to resolve <nixpkgs>

```bash
$ nix-instantiate --eval -E '<nixpkgs>'
/nix/var/nix/profiles/per-user/root/channels/nixpkgs
```

The <nixpkgs> syntax that we use in our nix expressions, is referring to a path in the filesystem specified by NIX_PATH.

You can list that directory and realize it's simply a checkout of the nixpkgs repository at a specific commit (hint: .version-suffix).

The NIX_PATH variable is exported by nix.sh (or nix-daemon.sh), and that's the reason why I always asked you to
source nix.sh at the beginning of my posts.

A best practice is to specify a different nixpkgs path to, e.g., a git checkout of nixpkgs.

We can also make our own <mypkgs> to be used on the commandline:

```bash
$ export NIX_PATH=mypkgs=$HOME/Projects/nix/playground:$NIX_PATH
$ nix-instantiate --eval '<mypkgs>'
```

Paths can also be specified between angle brackets, e.g. <nixpkgs>. This means that the directories listed in the environment variable NIX_PATH will be searched for the given file or directory name.

This is not a good description because it suggests that <nixpkgs> is special, while in fact it can be any path resolved via the Nix search path (e.g. <foo/bar/xyzzy.nix>). Also, the search path is not just determined by NIX_PATH but also by -I flags.

# nix-env is different

The `nix-env` command is a little different than nix-instantiate and nix-build. Whereas nix-instantiate
and nix-build require a starting nix expression, nix-env does not.

You may be crippled by this concept at the beginning, you may think nix-env uses NIX_PATH to find the
nixpkgs repository. But that's not it.

The nix-env command uses `~/.nix-defexpr`, which is also part of NIX_PATH by default, but that's only a coincidence.
If you empty NIX_PATH, nix-env will still be able to find derivations because of ~/.nix-defexpr.

So if you run `nix-env -i graphviz` inside your repository, it will install the <nixpkgs> one. Same if you set
NIX_PATH to point to your repository.

In order to specify an alternative to ~/.nix-defexpr it's possible to use the [-f] option:

```bash
nix-env -f '<mypkgs>' -i graphviz
```

```bash
nix-env -f '<mypkgs>' -qaP
```

## Nix-Darwin

```bash
$ echo $NIX_USER_PROFILE_DIR
/nix/var/nix/profiles/per-user/maxfire
$ echo $NIX_PROFILES
/nix/var/nix/profiles/default /run/current-system/sw /Users/maxfire/.nix-profile
$ Projects echo $NIX_PATH

darwin-config=/Users/maxfire/.nixpkgs/darwin-configuration.nix:

/nix/var/nix/profiles/per-user/root/channels:

/Users/maxfire/.nix-defexpr/channels
```

Notice the extra (system) profile `/run/current-system/sw`

Notice the extra channel `darwin-config=~/.nixpkgs/darwin-configuration.nix` and the other extra channel `~/.nix-defexpr/channels`


## Docs

Most nix tools operate, by default, on the nix expression <nixpkgs>. When a nix expression has
an identifier in angle brackets like that, nix determines what it refers to by looking for it
in the NIX_PATH environment variable.

Nix looks for expressions matching that name in all the directory entries in NIX_PATH (separated by :),
but also if there is a path entry that are of the form some_alias=/some/path and the name matches
the alias given <some_alias>, it will just resolve to that given path exactly and stop searching.

So the NIX_PATH for your user account is going to be something like this:

```
# user channels
~/.nix-defexpr/channels:                                                                   #
# root (system) channels
nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:                                # nixos channel
{darwin|nixos}-config={~/.nixpkgs/darwin-configuration.nix|/etc/nixos/configuration.nix}:  # system configuration.nix
/nix/var/nix/profiles/per-user/root/channels                                               #
```

The first entry is `~/.nix-defexpr/channels`, which means that when looking for something like <nixpkgs>,
nix will resolve it to any user channel named 'nixpkgs'. If none is found, it moves onto the next
entry `nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos`, which means that if looking
for <nixpkgs> specifically, it will match a root channel called 'nixos' if that exists (in your case,
most likely this will exist and it will stop there). Then there's an entry for <nixos-config> which
is unrelated, then finally /nix/var/nix/profiles/per-user/root/channels which means that if root has
a channel named 'nixpkgs' it will match that.

nix-env works slightly differently than other nix tools and looks at the channels
in ~/.nix-defexpr/channels/ all at once, rather than looking just inside the <nixpkgs> expression.
This means that if you do nix-env -i mycoolpackage, nix-env will look for 'mycoolpackage' in all
of the channels you've added, and pick based on I think its own version picking algorithm and
then possibly after that by channel order? In any case, if your user has no channels, since it
actually looks in all subdirectories of ~/.nix-defexpr and there is also ~/.nix-devexpr/channels_root,
nix-env will actually look at all of root's channels as well for any package you want to install.

# Git Checkout Model

You can clone and checkout the nixpkgs repository in any folder you like. Here we use a subfolder
of the users home directory.

```bash
git clone https://github.com/nixos/nixpkgs ~/nixpkgs
```

Then the nix commands take extra arguments (switches) such that nixpkgs are pinned to the git checkout

```bash
nix-env -f ~/nixpkgs/default.nix -iA <some-package>
```

# The Channel Model

Let’s use the unstable channel. It’s not as dated as the stable (19.09) channel, nor as recent as the
git checkout. To subscribe to the unstable channel, run:

```bash
$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
```

This fetches the channel labeled nixpkgs-unstable from nixos.org, then installs it to your user profile.

In the directory being pointed to by the the nixpkgs attribute, there’s a .git-revision file. Let’s view its contents:

```bash
$ cat /nix/var/nix/profiles/per-user/root/channels/nixpkgs/.git-revision
9b3515eb95d9b3bc033f43cd562fe2b14f9efd86%
```

Installing packages into your user profile is done by running

```bash
$ nix-env -iA darwin.<some-package>
$ nix-env -iA nixos.<some-package>
```

or


```bash
$ nix-env -iA nixpkgs.<some-package>
```

On NixOS (or Nix-Darwin), the channel used by the root user is important because it is the one used when
rebuilding the system with nixos-rebuild (darwin-rebuild) switch after changes to /etc/nixos/configuration.nix
(~/.nixpkgs/darwin-rebuild.nix) are made.

# Overlays: Monkey Patching Nixpkgs

There will be times when you need to make modifications to the package system, but you’re not willing to go
full nuts and mess around with the Git repository. There will also be times when you want to have your
own private package, which you’re not willing to push out into the public. Overlays can greatly help you with that.

Overlay files are your familiar Nix expressions, with a specific format. They live in `~/.config/nixpkgs/overlays/`.
If you have no such that directory, you may create it with:

```bash
$ mkdir -p ~/.config/nixpkgs/overlays
```

I structure my overlay files so that each file corresponds to one package, whose behavior I want to change.


## Overrides

> override overrides arguments of a function (i.e. the dependencies of a package), and overrideAttrs overrides
the package definition itself.

```nix
{ stdenv, bar, baz }: # this part gets overriden by `override`
stdenv.mkDerivation { # This part gets overriden by overrideAttrs
  pname = "test";
  version = "0.0.1";
  buildInputs = [bar baz];
  phases = ["installPhase"];
  installPhase = "touch $out";
}
```

So, to change the version of the package, you'd do `example.overrideAttrs (_: { version = "0.0.2"; })` and
to replace baz with some customBaz, you'd do `example.override { baz = customBaz; }`.



For example, if you want to make sure that the documentation for Racket is installed, create the file
`~/.config/nixpkgs/overlays/racket.nix` with the following contents:

```nix
self: super: {
  racket = super.racket.override {
    disableDocs = false;
  };
}
```

It’s a Nix function with two arguments—self and super. super refers to the expressions that belong to the system,
while self refers to the set of expressions that are defining it. It’s mandatory that there are two arguments
and that they are self and super.

????
Next, specify that for the racket attribute, it will call the override function from the source layer, passing
it an attribute set that will contain the overrides.

### Create new package by using overlay

Using the overlay system to create a new packages is ideal if you don’t want to make the package part
of Nixpkgs, you want to make it private, or you want to add a new infrastructure without handling the
extra complexity.

Let’s say you want to package `kapo`. To do that, you’ll be writing two things:

1. the top-level overlay file in ~/.config/nixpkgs/overlays/; and
2. the Nix expression that will actually build kapo.

For #1, create the file `~/.config/nixpkgs/overlays/kapo.nix` with the following contents:

```nix
self: super: {
  kapo = super.callPackage ./pkgs/kapo { };
}
```

Then, for #2, create the directory tree for the expression. Take note that it doesn’t have to have the name pkgs:

```bash
$ cd ~/.config/nixpkgs/overlays
$ mkdir -p pkgs/kapo
```

Then create the file `~/.config/nixpkgs/overlays/pkgs/kapo/default.nix` with the following contents:

```nix
{ stdenv, fetchFromGitHub, bash }:

stdenv.mkDerivation rec {
  name = "kapo-${version}";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "ebzzry";
    repo = "kapo";
    rev = "abd22b4860f83fe7469e8e40ee50f0db1c7a5f2c";
    sha256 = "0jh0kdc7z8d632gwpvzclx1bbacpsr6brkphbil93vb654mk16ws";
  };

  buildPhase = ''
    substituteInPlace kapo --replace "/usr/bin/env bash" "${bash}/bin/bash"
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp kapo $out/bin
    chmod +x $out/bin/kapo
  '';

  meta = with stdenv.lib; {
    description = "Vagrant helper";
    homepage = https://github.com/ebzzry/kapo;
    license = licenses.cc0;
    maintainers = [ maintainers.ebzzry ];
    platforms = platforms.all;
  };
}
```

# If you follow a Nixpkgs version 19.09 channel.

```bash
$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable
$ nix-channel --update
```

will add <nixpkgs> to the the store

```bash
nix-channel --add https://nixos.org/channels/nixos-19.09
nix-channel --update
```

will add nixos-19.09 to the store


```bash
nix-channel --add https://github.com/rycee/home-manager/archive/release-19.09.tar.gz home-manager
nix-channel --update
```

HM master does not automatically use Nixpkgs master, it uses whatever is in <nixpkgs>.
So if <nixpkgs> points to, for example, the nixos-19.09 channel by default, then you should make sure
to override it when running the home-manager tool. The easiest way to do this is to make a shell alias
that adds the -I option.

For example,

```
alias hm="home-manager -I nixpkgs=/path/to/nixpkgs-unstable"
```

or

```
program.bash.shellAliases.hm = "home-manager -I nixpkgs=/path/to/nixpkgs-unstable";
```

```bash
nix-build -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz -A ...
```


Add the Home Manager channel that you wish to follow. This is done by running

$ nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
$ nix-channel --update

if you are following Nixpkgs master or an unstable channel and

$ nix-channel --add https://github.com/rycee/home-manager/archive/release-19.09.tar.gz home-manager
$ nix-channel --update

if you follow a Nixpkgs version 19.09 channel.

If instead of using channels you want to run Home Manager from a Git checkout of the repository then
you can use the programs.home-manager.path option to specify the absolute path to the repository.

https://discourse.nixos.org/t/how-to-build-configuration/2480

https://rycee.net/posts/2017-07-02-manage-your-home-with-nix.html\

Channels
https://github.com/nixos/nixpkgs-channels
https://status.nixos.org/


```bash
# symbolic link into the store for 20.09pre217526.9b3515eb95d (unstable channel)
$ ls -la  ~/.nix-defexpr/channels_root/nixpkgs
/Users/maxfire/.nix-defexpr/channels_root/nixpkgs -> /nix/store/k496j3vwr9n4ch0x6wxf11m8w5i13c9f-nixpkgs-20.09pre217526.9b3515eb95d/nixpkgs
# symbolic link into the store
$ ls -la  ~/.nix-defexpr/channels/darwin
/Users/maxfire/.nix-defexpr/channels/darwin -> /nix/store/l8fxqw5sfs997r84n50gbcsc7c0m75jm-darwin/darwin
```

# Links

https://discourse.nixos.org/

https://nixos.org/nixos/packages.html?channel=nixos-19.09

https://nixos.org/nixos/options.html#

Great Nix Language Overview
https://medium.com/@MrJamesFisher/nix-by-example-a0063a1a4c55
https://jameshfisher.com/2014/09/28/nix-by-example/
https://learnxinyminutes.com/docs/nix/

NixOS: For developers
https://myme.no/posts/2020-01-26-nixos-for-development.html

Great overview blog posts
https://ejpcmac.net/blog/about-using-nix-in-my-development-workflow/

Great Overview how to create/change package (i.e. sending PR)
https://xebzzry.io/en/nix/#nix
https://ebzzry.io/en/nix/#nixpkgs
https://ebzzry.io/en/nix/#environments
https://ebzzry.io/en/nix/#overlays


Great tutorial
https://gricad.github.io/calcul/nix/tuto/2017/07/04/nix-tutorial.html

Great article about derivation
http://sandervanderburg.blogspot.com/2018/07/layered-build-function-abstractions-for.html

Module system (imports, options, config)
https://tech.ingolf-wagner.de/nixos/nix-instantiate/

Nix Pills
https://nixos.org/nixos/nix-pills/index.html

Nix (Language) Articles
https://www.sam.today/blog/environments-with-nix-shell-learning-nix-pt-1/
https://github.com/samdroid-apps/nix-articles
http://www.binaryphile.com/nix/2018/07/22/nix-language-primer.html


* General (nix-shell, direnv, lorri etc)
https://medium.com/better-programming/easily-reproducible-development-environments-with-nix-and-direnv-e8753f456110



* Haskell

Nix Package Manager Guide
https://nixos.org/nix/manual/

Nixpkgs users and contributors guide
https://nixos.org/nixpkgs/manual/

NixOS Hardware Guide
https://github.com/NixOS/nixos-hardware

Haskell with Nix Tutorial
https://github.com/Gabriel439/haskell-nix

https://nixos.wiki/wiki/Nix_Cookbook
http://chriswarbo.net/projects/nixos/useful_hacks.html

Links to Nix resources
https://gist.github.com/shanesveller/be0c9faca9ff0ac4e81464a5b5758adf

Home-manager and Brew
https://www.reddit.com/r/Nix/comments/bdyfe4/migrating_from_homebrew_to_nix/en54drx/


# Home Manager

https://discourse.nixos.org/t/is-this-a-good-way-to-modularize-home-manager-home-nix-for-home-work/5817/5


# Developer Shells

NOTE: [mkShell](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/mkshell/default.nix) is
like stdenv.mkDerivation, but is has been tailored to be used in `shell.nix`.
It adds one more feature where multiple buildInputs can all be merged together.

nodejs
https://www.breakds.org/post/nix-shell-for-nodejs/

haskell

dotnet

agda




https://github.com/yrashk/nix-home

https://github.com/JonathanReeve/dotfiles/blob/minimal/dotfiles/home.nix

I have managed to find the the dir /nix/var/nix/profiles/default/etc/profile.d/ containing both nix.sh and nix-daemon.sh. I guess those are for setting up NIX_PATH, PATH, NIX_PROFILES etc in single-user/multi-user mode. But I can't seem to find where symlinks to those files are defined.

It seems like NIX_LINK is undefined in multiuser mode and /nix/var/nix/profiles/default corresponds to ~/.nix-profile when it comes to the etc/ subfolder

# Create new package

Create a project dir for your new package in the (giant) tree

1. vim pkgs/hello/default.nix

```nix
{ stdenv, fetchurl }:
stdenv.mkDerivation {
  pname = "hello";
  version = "2.10";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/hello/hello-2.10.tar.gz";
     sha256 = "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i";
  };
}
```

2. Edit `pkgs/top-level/all-packages.nix`

```nix
#hello = callPackage ../applications/misc/hello { };
hello = callPackage ../hello { };
```

Then build

```bash
$ nix-build -A hello 2>&1 | less
```

# Debug the build

You can debug the build in the REPL

```bash
nix-repl > :s hello
```

All the drivations are present as environment variables

$src

And the phases of the generic builder can be run

* unpackPhase
* etc

# Debug with nix-shell

You can run

```bash
$ nix-shell -p hello
```

and run the phases in sequence - that is don't start running installPhase



# callPackage

Why don't we just write


```nix
#hello = callPackage ../applications/misc/hello { };
#hello = callPackage ../hello { };
hello = import ../hello {
  stdenv = stdenv;
  fetchurl = fetchurl;
}
```

this would actually work for this simple C program build. But callPackage has some advantages

It does

* dependency injection (stdenv, fetchurl are magically injected)
* overide/overlays possible


# Tips

use [direnv](https://direnv.net/)

nix-env -q     # installed packages
nix-env -qa    # available packages
nix-env -qc    # compare packages (outdated like)



```bash
nix-env -qaP | grep boost
```

Closure (aka transitive closure)

nix-store -q --tree ~/.nix-profile

```bash
nix-env --switch-profile $NIX_USER_PROFILE_DIR/tuto-jdev
```

$ cat ~/.nix-channels
https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin

$ nix-channel --list
darwin https://github.com/LnL7/nix-darwin/archive/master.tar.gz

$ nix-channel --update # Will download the latest packages, and create a new generation (similar to `apt-get update`)

$ nix-shell -p nix-info --run "nix-info -m")
 - system: `"x86_64-darwin"`
 - host os: `Darwin 19.4.0, macOS 10.15.4`
 - multi-user?: `yes`
 - sandbox: `no`
 - version: `nix-env (Nix) 2.3.3`
 - channels(maxfire): `"darwin"`
 - channels(root): `"nixpkgs-20.09pre217526.9b3515eb95d"`
 - nixpkgs: `/nix/var/nix/profiles/per-user/root/channels/nixpkgs`

In a multi-user installation, you may also have `~/.nix-defexpr/channels_root`, which links to the channels of the root user.

# Aliases

alias nixre="darwin-rebuild switch"
alias nixgc="nix-collect-garbage -d"
alias nixq="nix-env -qaP"
alias nixupgrade="sudo -i sh -c 'nix-channel --update && nix-env -iA nixpkgs.nix && launchctl remove org.nixos.nix-daemon && launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist'"
alias nixup="nix-env -u"
alias nixcfg="nvim ~/.nixpkgs/darwin-configuration.nix"

# Notes

* Nix automaticaly creates your first “default” profile : it’s a symbolic link pointing to /nix/var/nix/profiles/default.
* Always create one (or more) profile(s), to organise properly your different environments
* What is my current profile? `ls -al ~/.nix-profile`
* Create/switch between profiles? `nix-env --switch-profile $NIX_USER_PROFILE_DIR/some_name`
* What are my available profiles? `ls -al $NIX_USER_PROFILE_DIR`
  * The available profiles contains `channel` and `profile` that are pointing to other profiles named `channel-1-link`, `channel-2-link`, etc and other profile named `profile-1-link`, `profile-2-link` etc.

* a good pratice : always use install with complete attributes list to avoid confusion and unexpected behavior.
  * `nix-env -i boost-1.60.0` vs `nix-env -iA nixpkgs.boost160`
* Search for packages with i`nix-env -qaP | grep ...`
* Install packages with `nix-env -i <package_name>` or `nix-env -iA <attribute>`
* List installed packages with `nix-env -q`
* Remove packages with `nix-env -e <package>`

* Rollback or jump to a specific version of your profile with

```bash
nix-env --rollback or nix-env --switch-generation <id>
```


* a package is made by writing a nix expression into a file
* `stdenv.mkDerivation` is a powerful function used to create a new package with a lot of possible attributes.
* use nix-build to build your package
* use nix-shell to enter into the environment of your package, check, debug and build manually

* You can get a copy of your current nixpkgs channel by executing

```bash
cp -a ~/.nix-defexpr/channels_root/nixpkgs/ .
```
## Fixed output derivation

* To get a sha256 hash of a new source, you can use the Trust On First Use (TOFU) model: use a probably-wrong hash (for example: `sha256 = "0000000000000000000000000000000000000000000000000000";`) then replace it with the correct hash Nix expected after inspecting the error message produced by nix-build.
* NOTE: `lib.fakeSha256` can be used to create the zeroed/fake hash.
* You can calculate sha256 using `nix-prefetch-url --unpack` or `nix-prefetch-git`
* There as an emacs [command](https://github.com/jwiegley/nix-update-el) for updating nix fetch commands in place in the editor
* There is a `nix-hash` [program](https://www.mankier.com/1/nix-hash)
* You can install coreutils: `nix-env -i coreutils`. And suddenly you have `sha256sum` function to print or check sha256 checksums.
* Investigate `nix build --hash`

```bash
$ nix-shell -p nix-prefetch-scripts
[nix-shell:~]$ nix-prefetch-git https://gitlab.com/gitlab-org/gitlab-runner.git
.
.
hash is 119na7a8nmv589pcvp2d6g51v0867pgkh346dk5875dqq6hrmnb4
{
  "url": "https://gitlab.com/gitlab-org/gitlab-runner.git",
  "rev": "1255dcaab58b3d4aeb7dcddeff61c47942f87b87",
  "date": "2020-04-08T08:15:12+00:00",
  "sha256": "119na7a8nmv589pcvp2d6g51v0867pgkh346dk5875dqq6hrmnb4",
  "fetchSubmodules": false,
  "deepClone": false,
  "leaveDotGit": false
}
[nix-shell:~]$ nix-prefetch-url --unpack https://gitlab.com/gitlab-org/gitlab-runner/-/archive/master/gitlab-runner-master.tar.gz
unpacking...
[7.0 MiB DL]
path is '/nix/store/8ia8ahjx7l5rcmkqmsgmw9y8i4z8kaqz-gitlab-runner-master.tar.gz'
1a46c26l1s45c0rbz7xv8liy76dcs03hv9qvbsd5crnsyhnyvw9d
```

When instantiating a fixed output derivation, Nix computes its store path (/nix/store/{storehash}-{name}), and if this path does not exist, it builds it and verifies that the actual sha256 of the contents matches the specified sha256. The storehash part of the store path depends on its name and sha256, but it does not depend on other arguments to fetchFromGithub (such as repo or rev). This is conceptually right since different repos and revs can have the same content, but this also lets you change rev and miss that you should change sha256 too. If you really want to prevent this, you can include rev in name like this:

```nix
src = fetchFromGitHub rec {
  # NOTE: name has included the rev, and this way store path includes git rev (sha1)
  name = "github-${owner}-${repo}-${rev}";
  owner = "nh2";
  repo = "bup";
  rev = "5170c3fde72d45ddcf4e1d657e2788f7b4560831";
  sha256 = "0401067152dx9z878d4l6dryy7f611g2bm8rq4dyn366w6c9yrcb";
};
```

## From drv to requisites: aka Dependency Graph

```bash
$ nix-instantiate build_with_dependencies.nix
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/q7sj774558h9nyjvlfjgvbh6v5qngbra-build-with-dependencies.drv

$ nix-store --query --requisites /nix/store/q7sj774558h9nyjvlfjgvbh6v5qngbra-build-with-dependencies.drv
/nix/store/23w63m4jipdm14f3ay665yzzxqkhh24p-unpack-bootstrap-tools.sh
/nix/store/5pgkcx95qbbjsdk04hxngqc1fnaxgjgf-mkdir.drv
/nix/store/fn6dmhxmki9ppkfgibr054z65sqxnw34-cpio.drv
/nix/store/mswwp45p6pzbb3zv604h3li6lsm43l6s-bzip2.drv
.
.
.
/nix/store/s6mwqpdapkq5rplfh2i42w0j5dl5hwxa-talk.md
/nix/store/q7sj774558h9nyjvlfjgvbh6v5qngbra-build-with-dependencies.drv
```

other formats possible

```bash
$ nix-store --query --tree /nix/store/q7sj774558h9nyjvlfjgvbh6v5qngbra-build-with-dependencies.drv

$ nix-store --query --graph /nix/store/q7sj774558h9nyjvlfjgvbh6v5qngbra-build-with-dependencies.drv
```

## From outPath to derivation

```bash
$ nix-store --query --deriver /nix/store/wg25igm8ycjmz80yaiprfffz1k2yskld-mkdir
```

## From outPath to referrers, and why some referrer depends on that outPath

```bash
$ ls -la $(which bash)
/run/current-system/sw/bin/bash -> /nix/store/h4nzmfvvddvjc74jrqkmk88in3w9k73a-bash-interactive-5.0-p16/bin/bash
$ nix-store --query --referrers /nix/store/h4nzmfvvddvjc74jrqkmk88in3w9k73a-bash-interactive-5.0-p16/bin/bash
/nix/store/h4nzmfvvddvjc74jrqkmk88in3w9k73a-bash-interactive-5.0-p16
/nix/store/32xfgzfr2vj9gpm8bfgmrsqm8h2qd603-system-path
/nix/store/4fv27iicp3vi93vwh0wvqvszldd5p2an-system-path
/nix/store/53h24f7n4wncs8j8wsq1pkcpzpxasf5x-system-path
/nix/store/76fhz68307sqr6sw57z61fhdp1ay40qp-system-path
/nix/store/a8xgpqlx4347b8cn03r0jkjqzb113aly-system-path
/nix/store/b73qz0i90dn69vzwbkbakr2cksd11rmd-system-path
/nix/store/b9i900gbhzwx6vy13vkik86rnlqdd6jk-system-path
/nix/store/bpb6djkjyqsnnril8b48x9b21zjszrzm-system-path
/nix/store/hi0lvl9m18v0cr7rbchpf09wpnfdsr38-system-path
/nix/store/ipp0z0mh3laiplxjlf37xvfwka1d72l0-system-path
/nix/store/q2l236jb3sln3g1n51yi811c5nn47vg1-system-path
/nix/store/sib6id7fqv6d54wx3cdgdvxzbyjxhnh2-set-environment
/nix/store/x19z4g3b4kqm493ajxla0pq33lxfa3vj-system-path
/nix/store/x4nd49hpvgiy1i8v7625ap38wf48pdhk-system-path
/nix/store/zagp7gdy4c1ixsi9iyzg5vl371588a7l-system-path

$ nix why-depends /nix/store/b73qz0i90dn69vzwbkbakr2cksd11rmd-system-path /nix/store/h4nzmfvvddvjc74jrqkmk88in3w9k73a-bash-interactive-5.0-p16/bin/bash
/nix/store/b73qz0i90dn69vzwbkbakr2cksd11rmd-system-path
╚═══bin/bash -> /nix/store/h4nzmfvvddvjc74jrqkmk88in3w9k73a-bash-interactive-5.0-p16/bin/bash
    => /nix/store/h4nzmfvvddvjc74jrqkmk88in3w9k73a-bash-interactive-5.0-p16
```





nix-repl> builtins.currentSystem
"x86_64-darwin"

* Nix converts a set to a string when there's an outPath, that's very convenient. With that, it's easy to refer to other derivations.
* When Nix builds a derivation, it first creates a .drv file from a derivation expression (called instantiation), and uses it to
build the output. It does so recursively for all the dependencies (inputs). It then "executes" the .drv files like a machine
(called realisation), and the outputs are cached in the store.

$ nix build --file ./pill7.nix
$ nix-store --read-log result
declare -x HOME="/homeless-shelter"
declare -x NIX_BUILD_CORES="1"
declare -x NIX_BUILD_TOP="/private/tmp/nix-build-foo.drv-0"
declare -x NIX_LOG_FD="2"
declare -x NIX_STORE="/nix/store"
declare -x OLDPWD
declare -x PATH="/path-not-set"
declare -x PWD="/private/tmp/nix-build-foo.drv-0"
declare -x SHLVL="1"
declare -x TEMP="/private/tmp/nix-build-foo.drv-0"
declare -x TEMPDIR="/private/tmp/nix-build-foo.drv-0"
declare -x TERM="xterm-256color"
declare -x TMP="/private/tmp/nix-build-foo.drv-0"
declare -x TMPDIR="/private/tmp/nix-build-foo.drv-0"
declare -x builder="/nix/store/2kcifdkr7m14csgch00ajbz28irdwhff-bash-4.4-p23/bin/bash"
declare -x name="foo"
declare -x out="/nix/store/0i6x1gq9xzyckzkr7k152xa7z0h0iin4-foo"
declare -x system="x86_64-darwin"


Assuming `default.nix` is in the current directory, then:

$ nix build
$ nix log ./result

works too.

* `nix-build` is (almost) equivalent to `nix-store --realise $(nix-instantiate)`, the only difference is that symlinked `./result` is not created for you. (after the build the underlying drv won't be a root either)
* The trick: every attribute in the set passed to a derivation will be converted to a string and passed to the builder as an environment variable. This is how the builder gains access to coreutils and gcc: when converted to strings, the derivations evaluate to their output paths, and appending /bin to these leads us to their binaries.

```bash
$ nix-store --query --deriver /nix/store/5j3znxbfrlrw1xr7p4l4hrx4226wgc73-simple
$ nix show-derivation /nix/store/cmlvwc30xw52nxl8c4l2xf8s84937j78-simple.drv
```

* In a nix environment you don't have access to libraries and programs unless you install them with `nix-env`. However installing libraries with `nix-env` is not good practice. We prefer to have isolated environments for development.

# Misc

warning: not linking environment.etc."shells" because /etc/shells exists, skipping...
warning: not linking environment.etc."zprofile" because /etc/zprofile exists, skipping...
warning: not linking environment.etc."zshrc" because /etc/zshrc exists, skipping...

sudo mv /etc/zprofile /etc/zprofile.backup-before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.backup-before-nix-darwin
sudo mv /etc/shels /etc/shells.backup-before-nix-darwin



This is the `nix.sh` login script:


```bash
if [ -n "$HOME" ] && [ -n "$USER" ]; then

    # Set up the per-user profile.
    # This part should be kept in sync with nixpkgs:nixos/modules/programs/shell.nix

    NIX_LINK=$HOME/.nix-profile

    NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/$USER

    # Append ~/.nix-defexpr/channels to $NIX_PATH so that <nixpkgs>
    # paths work when the user has fetched the Nixpkgs channel.
    export NIX_PATH=${NIX_PATH:+$NIX_PATH:}$HOME/.nix-defexpr/channels

    # Set up environment.
    # This part should be kept in sync with nixpkgs:nixos/modules/programs/environment.nix
    export NIX_PROFILES="/nix/var/nix/profiles/default $HOME/.nix-profile"

    # Set $NIX_SSL_CERT_FILE so that Nixpkgs applications like curl work.
    if [ -e /etc/ssl/certs/ca-certificates.crt ]; then # NixOS, Ubuntu, Debian, Gentoo, Arch
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    elif [ -e /etc/ssl/ca-bundle.pem ]; then # openSUSE Tumbleweed
        export NIX_SSL_CERT_FILE=/etc/ssl/ca-bundle.pem
    elif [ -e /etc/ssl/certs/ca-bundle.crt ]; then # Old NixOS
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    elif [ -e /etc/pki/tls/certs/ca-bundle.crt ]; then # Fedora, CentOS
        export NIX_SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
    elif [ -e "$NIX_LINK/etc/ssl/certs/ca-bundle.crt" ]; then # fall back to cacert in Nix profile
        export NIX_SSL_CERT_FILE="$NIX_LINK/etc/ssl/certs/ca-bundle.crt"
    elif [ -e "$NIX_LINK/etc/ca-bundle.crt" ]; then # old cacert in Nix profile
        export NIX_SSL_CERT_FILE="$NIX_LINK/etc/ca-bundle.crt"
    fi

    if [ -n "${MANPATH-}" ]; then
        export MANPATH="$NIX_LINK/share/man:$MANPATH"
    fi

    export PATH="$NIX_LINK/bin:$PATH"
    unset NIX_LINK NIX_USER_PROFILE_DIR
fi
```

This is the multi-user `nix-daemon.sh` login script

```bash
# Only execute this file once per shell.
if [ -n "${__ETC_PROFILE_NIX_SOURCED:-}" ]; then return; fi
__ETC_PROFILE_NIX_SOURCED=1

export NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/$USER"
export NIX_PROFILES="/nix/var/nix/profiles/default $HOME/.nix-profile"

# Set $NIX_SSL_CERT_FILE so that Nixpkgs applications like curl work.
if [ ! -z "${NIX_SSL_CERT_FILE:-}" ]; then
    : # Allow users to override the NIX_SSL_CERT_FILE
elif [ -e /etc/ssl/certs/ca-certificates.crt ]; then # NixOS, Ubuntu, Debian, Gentoo, Arch
    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
elif [ -e /etc/ssl/ca-bundle.pem ]; then # openSUSE Tumbleweed
    export NIX_SSL_CERT_FILE=/etc/ssl/ca-bundle.pem
elif [ -e /etc/ssl/certs/ca-bundle.crt ]; then # Old NixOS
    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
elif [ -e /etc/pki/tls/certs/ca-bundle.crt ]; then # Fedora, CentOS
    export NIX_SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
else
  # Fall back to what is in the nix profiles, favouring whatever is defined last.
  for i in $NIX_PROFILES; do
    if [ -e $i/etc/ssl/certs/ca-bundle.crt ]; then
      export NIX_SSL_CERT_FILE=$i/etc/ssl/certs/ca-bundle.crt
    fi
  done
fi

export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:/nix/var/nix/profiles/per-user/root/channels"
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
```

id
id -u
id -un
id -g
id -gn
groups $(whoami) | cut -d' ' -f1.


$ nix-instantiate '<nixpkgs>' -A hello
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/r9gfiysi3bsfmj4v78msg5nc4ka0vphb-hello-2.10.drv

--add-root $DIR/.nix-gc-roots/shell.drv

Causes the result of a realisation (--realise and --force-realise) to be registered as a root of
           the garbage collector. The root is stored in path, which must be inside a directory that is
           scanned for roots by the garbage collector (i.e., typically in a subdirectory of
           /nix/var/nix/gcroots/) unless the --indirect flag is used.

           If there are multiple results, then multiple symlinks will be created by sequentially numbering
           symlinks beyond the first one (e.g., foo, foo-2, foo-3, and so on).



The option `programs.zsh.ohMyZsh' defined in `/Users/maxfire/.nixpkgs/darwin-configuration.nix' does not exist.




program.bash.shellAliases.hm = "home-manager -I nixpkgs=/path/to/nixpkgs-unstable";
