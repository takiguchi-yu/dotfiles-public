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
    python3
    pipx
    jq
    gitleaks
    glow
  ]
  # 公式バイナリを取り込むので、配布物を確かめた環境だけに入れる
  ++ pkgs.lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [
    (pkgs.callPackage ./pkgs/mermaid-ascii.nix { })
  ];

  # シェルに依存しない PATH の追加
  home.sessionPath = [
    "$HOME/.local/bin"
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

  # colima 本体もここで入る。ログインのたびに launchd が default の VM を起動する
  # （Mac を再起動した日に Docker が止まったままにならないように）
  # 止めるときは、先に launchd から外す（外さないと launchd が起動し直すことがある）:
  #   launchctl bootout gui/$(id -u)/org.nix-community.home.colima-default && colima stop
  # 自動起動に戻すときは、次のログインを待つか bootstrap する:
  #   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.colima-default.plist
  services.colima.enable = true;
  # stateVersion を 26.05 以上にすると既定が変わる（~/.config/colima に移って既存の VM が見えなくなり、
  # DOCKER_HOST も固定されて docker context の切り替えが効かなくなる）ので、今の挙動に固定する
  services.colima.colimaHomeDir = ".colima";
  # profiles を 1 キーでも書くとモジュールの既定（isActive・isService が true）が丸ごと置き換わるので、3 つとも書く
  services.colima.profiles.default = {
    isActive = true;
    isService = true;
    setDockerHost = false;
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
