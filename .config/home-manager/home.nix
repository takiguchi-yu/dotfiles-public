{
  pkgs,
  username,
  homeDirectory,
  ...
}:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
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
    jq
    gitleaks
    glow
  ];

  # シェルに依存しない PATH の追加
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.orbstack/bin"
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # AD 参加の Mac で AD がオフラインのとき、stdlib の
    # `~$rel_path` がユーザー名検索で 60 秒止まるため、
    # チルダを展開しない版で上書きする
    stdlib = ''
      user_rel_path() {
        local abs_path=''${1#-}
        if [[ -z $abs_path ]]; then return; fi
        if [[ -n $HOME ]]; then
          local rel_path=''${abs_path#"$HOME"}
          if [[ $rel_path != "$abs_path" ]]; then
            abs_path="~$rel_path"
          fi
        fi
        echo "$abs_path"
      }
    '';
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
      c = "clear";
      hm = "home-manager";
      hms = "home-manager switch --impure";
      nixu = "cd ~/.config/home-manager/ && nix flake update && cd -";
      glow = "glow -w $COLUMNS";
      # claude = "headroom wrap claude";
      # copilot = "headroom wrap copilot";
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
