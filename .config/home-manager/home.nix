{ config, pkgs, ... }:

{
  home.username = "takiguchi-yu";
  home.homeDirectory = "/Users/takiguchi-yu";
  home.stateVersion = "25.11";
  
  home.packages = with pkgs; [
    gh
    ripgrep
    lefthook
    mysql84
    postgresql_18
    golangci-lint
    ollama
    docker
    docker-compose
    colima
    python3
    pipx
  ];

  # シェルに依存しない PATH の追加
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.orbstack/bin"
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  programs.fish = {
    enable = true;

    # エイリアスの設定
    shellAliases = {
      ls = "ls -p -G";
      la = "ls -A";
      ll = "ls -l";
      lla = "ll -A";
      g = "git";
      hm = "home-manager";
      hms = "home-manager switch";
      nixu = "cd ~/.config/home-manager/ && nix flake update && cd -";
      claude = "headroom wrap claude";
      copilot = "headroom wrap copilot";
    };

    # ASDFの設定とCopilot用関数の直接定義
    shellInit = ''
      set fish_greeting ""
      
      # ASDF configuration code
      if test -z $ASDF_DATA_DIR
          set _asdf_shims "$HOME/.asdf/shims"
      else
          set _asdf_shims "$ASDF_DATA_DIR/shims"
      end

      # Do not use fish_add_path because it potentially changes the order
      if not contains $_asdf_shims $PATH
          set -gx --prepend PATH $_asdf_shims
      end
      set --erase _asdf_shims
    '';
  };

  programs.home-manager.enable = true;
}
