{ config, pkgs, ... }:

{
  home.username = "takiguchi-yu";
  home.homeDirectory = "/Users/takiguchi-yu";
  home.stateVersion = "25.11";
  home.packages = with pkgs; [
    gh
    ripgrep
  ];
  home.file = {
  };
  home.sessionVariables = {
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}