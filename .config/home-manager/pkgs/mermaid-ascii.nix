# Mermaid を罫線のテキスト図に変換する CLI。nixpkgs に無いので公式のリリースバイナリを取り込む。
# 日本語ラベルの表示幅を数えるのは 1.6.1 から（.local/bin/mmd2txt が呼ぶ）。
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mermaid-ascii";
  version = "1.6.1";

  src = fetchurl {
    url = "https://github.com/AlexanderGrooff/mermaid-ascii/releases/download/${version}/mermaid-ascii_Darwin_arm64.tar.gz";
    hash = "sha256-m393iL0llkN9koVummC3sF7LX294bIwLHLNp90K/gGM=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 mermaid-ascii $out/bin/mermaid-ascii
    runHook postInstall
  '';

  meta = {
    description = "Render Mermaid diagrams as ASCII/Unicode text";
    homepage = "https://github.com/AlexanderGrooff/mermaid-ascii";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "mermaid-ascii";
  };
}
