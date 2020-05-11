{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      bashInteractive = super.bashInteractive_5;
    })
  ];

  environment.systemPackages = with pkgs;  [
      bashInteractive_5 # bash with ncurses support
      # TODO: Why does vim build, pin version of nixpkgs
      vim
    ];

  # list of login shells /etc/shells is needed
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  environment.systemPath = [
    # "$HOME/.npm/bin"
  ];

  environment.variables = {
    # TODO: nvim here
    EDITOR = "vim";
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

  # option ‘build-use-sandbox’ must be set to one of ‘true’, ‘false’ or ‘relaxed’
  nix.useSandbox = false;

  # relaxed means, that fixed-output derivations and derivations that have the __noChroot
  # attribute set to true do not run in sandboxes.
  # I prefer "relaxed", which allows derivations to opt-out by having a __noChroot = true' attribute.
  #nix.useSandbox = "relaxed";

  # We need to add impurities here into xcode commandline tooling
  nix.sandboxPaths = [
    "/System/Library/Frameworks"
    "/System/Library/PrivateFrameworks"
    "/usr/lib"
    "/private/tmp"
    #"/private/var/select"
    "/private/var/tmp"
    "/usr/bin/env"
  ];

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
