# links.txt の link / each を home.file に変換する。
# mkOutOfStoreSymlink でリポジトリの作業ツリーを直接指すので、ホームでの編集がそのままリポジトリに入る。
{
  config,
  lib,
  dotfilesDir,
  ...
}:
let
  toRepo = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";

  lines = lib.splitString "\n" (builtins.readFile "${dotfilesDir}/links.txt");
  fields = line: lib.filter (s: builtins.isString s && s != "") (builtins.split "[[:space:]]+" line);
  entries = lib.filter (e: e != [ ] && !(lib.hasPrefix "#" (builtins.head e))) (map fields lines);

  # link <ホーム> [<リポジトリ>]
  linkEntry =
    e:
    let
      home = builtins.elemAt e 1;
      repo = if builtins.length e > 2 then builtins.elemAt e 2 else home;
    in
    {
      ${home}.source = toRepo repo;
    };

  # each <ディレクトリ>: リポジトリにある直下の項目を 1 件ずつリンクする
  eachEntry =
    e:
    let
      dir = builtins.elemAt e 1;
      children = lib.filterAttrs (name: _: name != ".DS_Store") (builtins.readDir "${dotfilesDir}/${dir}");
    in
    lib.mapAttrs' (name: _: lib.nameValuePair "${dir}/${name}" { source = toRepo "${dir}/${name}"; }) children;

  ofKind = kind: lib.filter (e: builtins.head e == kind) entries;
in
{
  home.file = lib.mkMerge (map linkEntry (ofKind "link") ++ map eachEntry (ofKind "each"));
  home.sessionVariables.DOTFILES_DIR = dotfilesDir;
}
