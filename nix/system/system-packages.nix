{ config, pkgs, ... }:

{
  imports = [
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
  ];
 
  environment.systemPackages = with pkgs; [
    # login
    greetd.tuigreet

    # utilities
    vim
    tmux
    ripgrep
    git
    exa
    neofetch 
  ];
}
