{ config, pkgs, ... }:

let
  #inherit (pkgs) lorri;
  # TODO: Unused...remove it (invesdigate rev and ref arguments)
  antigen = pkgs.fetchgit {
      url = "https://github.com/zsh-users/antigen";
      rev = "v2.2.3";
      sha256 = "1hqnwdskdmaiyi1p63gg66hbxi1igxib6ql8db3w950kjs1cs7rq";
    };
in
{
  nixpkgs.overlays = [
    (self: super: {
      bashInteractive = super.bashInteractive_5;
    })
  ];

  environment.systemPackages = with pkgs;  [
      bashInteractive_5 # bash with ncurses support
      #pkgs.bash-completion
      #pkgs.zsh
      #pkgs.zsh-syntax-highlighting # https://github.com/zsh-users/zsh-syntax-highlighting/
      #pkgs.zsh-autosuggestions     # https://github.com/zsh-users/zsh-autosuggestions/
      #pkgs.oh-my-zsh               # https://github.com/ohmyzsh/ohmyzsh/
      git

      curl
      wget

      vim

      # nix-shell on steroids
      #direnv
      #lorri
    ];

  # See also alternative workaround https://github.com/target/lorri/issues/96#issuecomment-545152525
  # XXX: Copied verbatim from https://github.com/iknow/nix-channel/blob/7bf3584e0bef531836050b60a9bbd29024a1af81/darwin-modules/lorri.nix
  # Check the status of the lorri daemon with 'launchctl list | grep lorri'
  # launchd.user.agents = {
  #   "lorri" = {
  #     serviceConfig = {
  #       WorkingDirectory = (builtins.getEnv "HOME");
  #       EnvironmentVariables = { };
  #       KeepAlive = true;
  #       RunAtLoad = true;
  #       StandardOutPath = "/var/tmp/lorri.log";
  #       StandardErrorPath = "/var/tmp/lorri.log";
  #     };
  #     script = ''
  #       source ${config.system.build.setEnvironment}
  #       exec ${lorri}/bin/lorri daemon
  #     '';
  #   };
  # };

  # Use https://nixos.org/nixos/options.html#programs.zsh

  # Shell configuration
  #environment.shells = ["/run/current-system/sw/bin/zsh"];
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  # programs.zsh = {
  #   enable = true;

  #   #syntaxHighlighting.enable = true;
  #   #autosuggestions.enable = true;

  #   # We define these in the interactiveShellInit below
  #   # ohMyZsh.enable = true;
  #   # ohMyZsh.plugins = [ "git"
  #   #                     "dotenv"
  #   #                     "osx" ];
  #   # ohMyZsh.theme = "robbyrussell";   # ZSH_THEME

  #   promptInit = ""; # Clear this to avoid a conflict with oh-my-zsh

  #   ##  ZSH Configuration  ##
  #   ## NOTE: https://github.com/zsh-users/antigen/wiki/Troubleshooting#my-bundles-wont-update
  #   interactiveShellInit = ''
  #     # BAD: disable caching
  #     export ANTIGEN_CACHE=false

  #     source ${antigen}/antigen.zsh

  #     # Load the oh-my-zsh's library.
  #     antigen use oh-my-zsh

  #     antigen bundle <<EOBUNDLES
  #         # Bundles from the default repo (robbyrussell's oh-my-zsh).
  #         git
  #         cabal
  #         osx
  #         web-search

  #         # Syntax highlighting bundle.
  #         zsh-users/zsh-syntax-highlighting

  #         # Fish-like auto suggestions
  #         zsh-users/zsh-autosuggestions

  #         # Extra zsh completions
  #         zsh-users/zsh-completions
  #     EOBUNDLES

  #     # Load the theme.
  #     antigen theme robbyrussell

  #     # Tell antigen that you're done.
  #     antigen apply

  #     ####
  #     ####

  #     # if ls -l /nix/store | grep sudo | grep -q nogroup; then
  #     #   #mount -o remount,rw  /nix/store
  #     #   #chown -R root:nixbld /nix/store
  #     #   chown -R root:staff /nix/store
  #     # fi

  #     # Grab locations in the nix store
  #     # export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
  #     # export ZSH_AUTOSUGGESTIONS=${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions
  #     # export ZSH_SYNTAX_HIGH=

  #     # ZSH_THEME="robbyrussell"

  #     # plugins=(
  #     #   git
  #     #   osx
  #     #   #zsh-syntax-highlighting
  #     #   #zsh-autosuggestions
  #     #   web-search
  #     # )

  #     # BAD: temporary workaround
  #     # export ZSH_DISABLE_COMPFIX=true

  #     # source $ZSH/oh-my-zsh.sh
  #     # source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  #     # source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  #   '';
  # };

  # nix-darwin won't handle changing chsh due to /etc/shell
  #users.defaultUserShell = pkgs.zsh;
  #users.shell = pkgs.zsh;

  environment.systemPath = [
    # "$HOME/.npm/bin"
  ];

  environment.variables = {
    # TODO: nvim here
    EDITOR = "vim";
    # TODO: fasd
    # FZFZ_RECENT_DIRS_TOOL = "fasd";
  };

  environment.shellAliases = {
    g = "git";
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  #
  # Nix configuration in /etc/nix/nix.conf
  #
  # See also https://github.com/LnL7/nix-darwin/blob/master/modules/nix/default.nix

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # This option specifies the package or profile that contains the version of Nix to use throughout the system.
  nix.package = pkgs.nix;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 8;      # This option defines the maximum number of jobs that Nix will try to build in parallel.
  nix.buildCores = 1;   # This option defines the maximum number of concurrent tasks during one build.

  # Prevent impurities in builds
  # option ‘build-use-sandbox’ must be set to one of ‘true’, ‘false’ or ‘relaxed’
  #nix.useSandbox = true;
  # relaxed means, that fixed-output derivations and derivations that have the __noChroot
  # attribute set to true do not run in sandboxes.
  # I prefer "relaxed", which allows derivations to opt-out by having a __noChroot = true' attribute.
  nix.useSandbox = "relaxed";
  #nix.sandboxPaths = []; # you can add impurities here into your own file system

  # NOTE: You can defins the default Nix expression search path, used by the Nix
  #       evaluator to look up paths enclosed in angle brackets
  # Example
  # nix.nixPath = [
  #   { trunk = "/src/nixpkgs"; }
  # ];
  # Default Value
  # nix.nixPath = [
  #   { darwin-config = "${config.environment.darwinConfig}"; }
  #   "/nix/var/nix/profiles/per-user/root/channels"
  #   "$HOME/.nix-defexpr/channels"
  # ];

  # TODO: This seems okay
  # nix.nixPath =
  # [ # Use local nixpkgs checkout instead of channels.
  #   "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
  #   "darwin=$HOME/Projects/nix-darwin"
  #   "nixpkgs=$HOME/Projects/nixpkgs"
  # ];
}
