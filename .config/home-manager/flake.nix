{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ユーザー名・ホーム・リポジトリの場所は実行環境から取るので、--impure で評価する。
  outputs =
    { nixpkgs, home-manager, ... }:
    let
      username = builtins.getEnv "USER";
      homeDirectory = builtins.getEnv "HOME";
      dotfilesDir =
        let
          fromEnv = builtins.getEnv "DOTFILES_DIR";
        in
        if fromEnv != "" then fromEnv else "${homeDirectory}/git/private/dotfiles-public";
      pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./links.nix
        ];
        extraSpecialArgs = { inherit username homeDirectory dotfilesDir; };
      };
    };
}
