# Claude Code の図表を端末で見やすくする方法の調査（herdr＋Ghostty）

応答に載せる図と表はテキスト（Markdown 表と、導入済みの `mmd2txt`）のまま出す。それで足りない大きな図は、herdr の右ペインで「Claude が書いた `.mmd` を監視 → mermaid-cli で PNG → `chafa -f kitty` で表示」するプレビューに逃がす構成を推奨する。macOS では、mermaid-cli に使うブラウザの場所を渡す必要がある。
表示経路（Claude Code → herdr 0.9.4 → Ghostty 1.3.1）を端から端まで通る画像形式は Kitty graphics protocol だけで、Sixel と iTerm2 形式は herdr でも Ghostty でも落ちる。
Claude Code の画面の中に画像を出したいなら、mod の `Image` 要素が使える。ただし herdr の中では Claude Code の自動検出が通らない見込みなので、`CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1` を付けて起動する必要がある。

調査日: 2026-10-15 / 対象: Claude Code 2.1.299、herdr 0.9.4、Ghostty 1.3.1（macOS）、シェル fish

根拠は一次情報に限った。公式ドキュメント、公式 changelog、各リポジトリのソースとマニュアル、プロトコル仕様、手元のインストール物とコマンド出力である。解説記事は根拠にしていない。各主張に出典番号 `[n]` を付けた（末尾「出典」）。

この調査は TTY を持たない環境で行った。画像が実際に映るかは実測していない。末尾の「ユーザーが実際の herdr ペインで実行する確認手順」で実測する。

## 要約

- **経路を通る画像形式は Kitty graphics だけ。**
  - Ghostty は Kitty graphics とその Unicode placeholder に対応する。Sixel と iTerm2 の画像（OSC 1337 `File=`）は実装していない [15][16]
  - herdr はペイン内の Kitty graphics を自分で解釈し、外側の端末へ描き直す。既定で有効 [12][14]
  - herdr が埋め込む libghostty-vt も、Sixel と OSC 1337 `File=` を扱わない [13]
- **Claude Code 本体は Markdown 表を罫線付きで描くが、Mermaid は描かない。**
  - 本文と transcript に画像をインラインで描く機能は、ドキュメントにも changelog にも見当たらない [8]
  - 「mermaid フェンスを罫線文字で描く」組み込み mod `cc-plugin-mermaid` はバイナリに入っている。ただしサーバー側の機能フラグ（既定は無効）で止まっており、ドキュメントにも載っていない [9]
- **Claude Code から画像を出す正規の口は、mod の `Image` 要素だけ。**
  - hooks は制御端末を持たない。`terminalSequence` で出せるのも通知系の OSC に限られる [6]
  - statusline のドキュメントに書かれているのは、色と OSC 8 リンクまで [7]
- **mod の `Image` は、herdr の中ではそのままだと描かれない見込み。**
  - `Image` は Kitty graphics の Unicode placeholder で描かれる。自動検出が成功するのは kitty 0.28 以降と Ghostty だけ [1][9]
  - herdr のペインは、端末名の問い合わせ（XTVERSION）に `libghostty` と答える作りになっている（ソースからの推定）[13]。そのため検出が落ち、画像の代わりに `alt` テキストが出る見込み
  - `CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1` を付けると検出を飛ばせる [2]
- **日本語ラベルを表示幅で数えているテキスト図の生成器は、mermaid-ascii だけ。**
  - mermaid-ascii は go-runewidth で幅を数える [20][21]
  - Graph::Easy、D2 の txt 出力、beautiful-mermaid は、文字数かバイト数で幅を数えている。日本語ラベルで桁がずれる見込み [22][23][24]
- **依頼文の前提と手元の状態が 1 点食い違っていた。**
  - 依頼時点の前提では mermaid-ascii は未導入だった
  - 実際には、作業中の変更（未コミット）で mermaid-ascii 1.6.1 と変換スクリプト `mmd2txt` が入り、`.claude/DIAGRAM.md` が「図は mmd2txt で描く」と定めていた [Obs-2]
  - そのため系統 A は導入済みとして扱った

## 表示経路を層ごとに確定する

### Claude Code 2.1.299

- **Markdown 表**
  - 罫線付きで描かれる。狭い端末では縦積みのレイアウトに切り替わる（2.1.152）
  - 200 行を超える表は先頭 200 行だけ出す（2.1.208）
  - `maxProseWidth` を設定しても、表とコードブロックは全幅のまま（2.1.282）
  - 2.1.299 でも、CJK を含む折り返しや表の罫線の修正が入っている [8]
- **文字幅の数え方**
  - 文字幅を数える関数は `Bun.stringWidth(…, {ambiguousIsNarrow: true})` で定義されている。East Asian Ambiguous を 1 セルと数えるので、Ghostty の実測（Ambiguous＝1 セル）と一致する [9]
  - 表の整形がこの関数を通るかまでは追っていない（未確認）
- **Mermaid**
  - 本体は描画しない。公式ドキュメント全文（llms-full.txt）で "mermaid" に当たるのは、出力スタイルの作例 1 箇所だけだった。そこでも描画機能には触れていない [Obs-3]
  - バイナリには組み込み mod `cc-plugin-mermaid` があり、説明文は "flowcharts and sequence diagrams in a reply's mermaid code fences are drawn in place as box-drawing text"。ただし利用可否が機能フラグ `tengu_mermaid_mod`（既定値 `false`）で決まり、`claude plugin list` にも出ない [9][Obs-4]
  - 実装では East Asian Wide を 2 セル、それ以外を 1 セルと数えている [9]
- **画像のインライン表示**
  - 本文とツール結果には無い。貼り付けた画像は `[Image #N]` のリンクになり、既定のビューアで開く（2.0.73）[8]
  - 画像を端末に描く口は、mod の `Image` だけ（後述）[1][3]
- **本文とツール出力に含まれるエスケープシーケンス**
  - 返答に残った色や conceal の SGR が、リンク表示に影響したことがある（2.1.295 で修正）。SGR は解釈されている [8]
  - Kitty graphics の APC がそのまま端末まで届くかは、ドキュメントに記載が無く未確認。正規の経路ではないので、本調査の選択肢からは外した
- **statusline**
  - ANSI の色と OSC 8 のリンクが使えると書かれている。画像の記載は無い [7]
- **hooks**
  - command hook は制御端末を持たずに走る。`/dev/tty` を開けず、Claude Code の画面へ直接エスケープシーケンスを送れない [6]
  - 代わりに使える `terminalSequence` は、OSC `0`/`1`/`2`/`9`/`99`/`777` と BEL だけを通す [6]
  - 結論として、hook は画像を描けない。描くのは別プロセス（横ペインなど）に任せることになる
  - 使える hook は 3 つある
    - `MessageDisplay`: 返答の表示テキストだけを差し替える。表示専用で、Claude と transcript には原文が残る [6]
    - `PostToolUse`: ツール実行後に外部コマンドを起動できる [6]
    - `FileChanged`: ファイル変更で外部コマンドを起動できる [6]
- **mod の要素**
  - 端末の画面で使える絵の要素は `Raster` と `Image`。`Svg` は Desktop アプリだけ [3][10]
  - `Image` は PNG か RGBA を受け取る。base64 なら 2 MiB まで、ファイルのパスでもよい。大きさは `columns`／`rows` で 255 セルまで、`alt` は必須 [3][10]
  - 描画方式は「kitty graphics protocol where the terminal has it (kitty, Ghostty), its `alt` elsewhere」[10]
  - 実装は `a=T,U=1,…` の仮想配置と Unicode placeholder を使う [9]
  - mod は `AssistantMessage`（返答）の描画を書き換えたり、置き換えたりできる [4]
  - `$.process.run` で外部コマンドを起動できる。シェルは通さず、既定のタイムアウトは 30 秒 [5]
- **mod の `Image` の自動検出**
  - 起動時に 2 つを送る。1 つは Kitty graphics の問い合わせ（`i=31,s=1,v=1,a=q,t=d,f=24;AAAA`）、もう 1 つは端末名の問い合わせ（XTVERSION）[9]
  - 検出の条件は 2 つ。問い合わせに応答があること、そして XTVERSION の名前が `kitty(…)`（0.28.0 以上）か、`kitty`／`ghostty` そのもの、またはその後に空白が続く形であること [9]
  - tmux／screen の中（`TMUX`／`STY` が設定されている）とバックグラウンドセッションでは、常に失敗する [1][9]
  - `CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1` で検出を飛ばせる。「Unicode placeholder 付きの Kitty graphics を描ける端末なのに検出されない」場合のための変数として、公式に書かれている [2]

### herdr 0.9.4

- **Kitty graphics**
  - ペインのアプリが出した標準の Kitty graphics を herdr が描く。配置・切り抜き・表示を herdr 自身が管理する [12]
  - 0.9.0 で既定が有効になった。設定は `[terminal] kitty_graphics = true` [12][14]
  - Unicode placeholder の仮想配置は 0.6.0 から描かれる [12]
  - 0.9.2 で、手元の Ghostty には画像データを一時ファイルで渡すようになった [12]
  - 0.9.4 で、Kitty graphics を切るとペインが画像対応を名乗らなくなった。裏返せば、有効なときは名乗る [12]
- **外側の端末の判定**
  - 一時ファイル経由で渡す最適化は、外側が Ghostty・WezTerm・kitty のときだけ効く（`TERM_PROGRAM` と `TERM` で判定）[12]
  - 画像の出力そのものは、設定の `kitty_graphics` で有効になる [12]
- **Sixel**: 外側には届かないと推定する [13]
  - herdr が埋め込む libghostty-vt（1.3.2-HEAD）の DCS 処理が扱うのは、tmux control mode・XTGETTCAP・DECRQSS だけ。それ以外は捨てる
  - herdr のソース（`src/`、`crates/`）を検索しても、Sixel を外側へ通すコードは見つからなかった
- **iTerm2 の画像（OSC 1337 `File=`）**: 届かない
  - libghostty-vt の OSC 1337 パーサが `File` を「unimplemented」として無効にしている [13]
- **XTVERSION**: `libghostty` と答えると推定する
  - libghostty-vt は、組み込み側がコールバックを設定しなければ `libghostty` と答える [13]
  - herdr のソースには、このコールバックを設定する箇所が見つからなかった（推定。末尾の手順 1 で確かめる）
- **ペインの分割**
  - `herdr pane split --direction right|down` で分割できる。`herdr pane run <pane_id> <command>` でペインにコマンドを送れる [12]
  - キー割り当て（`[[keys.command]]`）で、ペインやポップアップを開いてコマンドを走らせることもできる [12][14]
  - plugin の pane も、普通の herdr ペインとして開ける [12]
  - ポップアップの中で画像が描かれるかは未確認

### Ghostty 1.3.1

- **Kitty graphics と Unicode placeholder: 対応**
  - 公式サイトに "Ghostty supports the Kitty graphics protocol" とある [15]
  - ソースに `src/terminal/kitty/graphics_*.zig` がある。U+10EEEE の Unicode placeholder（`graphics_unicode.zig`）も実装済み [16]
  - PNG（`f=100`）と、転送方式 `d`／`f`／`t`／`s` を受け付ける [16]
- **Sixel: 非対応**
  - 端末属性の問い合わせ（DA1）への応答が `ESC[?62;22;52c`（または `ESC[?62;22c`）で、Sixel を示す `4` を含まない [16]
  - `src/terminal` を検索しても `sixel` に当たらない [16]
- **iTerm2 の画像（OSC 1337 `File=`）: 非対応**
  - herdr と同じく「unimplemented」[16]
- **XTVERSION**: `ghostty 1.3.1` の形で答える [16]
  - herdr の外で Claude Code を動かせば、Ghostty として検出される
- **関連する設定キー**
  - `image-storage-limit`（既定 320,000,000 バイト）。0 にすると、すべての画像プロトコルが無効になる [17]
  - Ambiguous 幅を切り替える設定は無い。ユーザーの実測では 1 セル

### 層ごとのまとめ

| 層 | Kitty graphics | Sixel・iTerm2 |
| --- | --- | --- |
| Ghostty 1.3.1 | 対応 | 非対応 |
| herdr 0.9.4 | 自前で描き直す | 届かない |
| Claude Code 本文 | 経路なし | 経路なし |
| Claude Code mod | `Image` で可 | 経路なし |

経路を通る画像形式は Kitty graphics だけ。`chafa -f sixels`、`timg -ps`／`-pi`、iTerm2 の `imgcat` といった Sixel・iTerm2 系の表示は、この環境では候補から外れる。

## 解決策の系統ごとの評価

### A. Claude Code の出力内に描くテキスト図（導入済み）

**表示経路: 常に通る。** 普通の文字なので、herdr と Ghostty の画像対応に左右されない。

表と図で扱いが分かれる。

- **表**
  - Markdown の表をそのまま書かせる。罫線と列幅は Claude Code が描く [8][9]
  - モデルに罫線の表を手で書かせると、Ambiguous と全角の数え違いで桁がずれる（ユーザーが実害を確認済み）
- **図: 生成器の比較**（日本語ラベルの扱いはソースで確認した）
  - **mermaid-ascii 1.6.1**（導入済み）: 対応は `graph`／flowchart、`sequenceDiagram`、ER（`pkg/er`）。ラベルの幅は go-runewidth の `StringWidth` で数える。CJK ラベルで全行の表示幅が揃うことをテストで確かめている [20]
    - go-runewidth は、ロケール（`LC_ALL` → `LC_CTYPE` → `LANG`）が `ja`／`ko`／`zh` で始まると Ambiguous を 2 セルと数える [21]
    - 今の環境は `LANG=en_US.UTF-8` なので 1 セル（Ghostty と一致）[Obs-1]
    - ロケールを日本語にするなら、`RUNEWIDTH_EASTASIAN=0` を付けないとずれる [21]
  - **Graph::Easy 0.76**（2016 年版、nixpkgs の `graph-easy`）: ノードの幅を Perl の `length`（文字数）で数える。全角ラベルは幅を半分に見積もられ、ずれる見込み（未実測）[22]
  - **D2 0.9.0 の txt／ascii 出力**: ラベル幅を Go の `len(label)`（UTF-8 のバイト数）で数える。日本語 1 字は 3 バイトだが 2 セルなので、箱が広がり中央寄せもずれる見込み（未実測）[23]
  - **beautiful-mermaid 1.1.3**: ASCII 出力でラベル幅を JavaScript の `.length`（UTF-16 の単位数）で数える。全角はずれる見込み（未実測）[24]
- **応答への載せ方**（3 案）
  1. **モデルが `mmd2txt` を実行して出力を貼る**（今の `.claude/DIAGRAM.md` の方式）。仕組みは要らない。トークンを二重に使い、転記を誤る余地も残る
  2. **`MessageDisplay` hook** で ```` ```mermaid ```` フェンスを `mmd2txt` の出力に差し替える
     - 表示専用で、Claude と transcript には Mermaid の原文が残る [6]
     - hook は「新しく確定した行のまとまり」ごとに呼ばれる。そのため、フェンスの開始から終了までを `message_id` ごとに溜める実装が要る
     - 既定のタイムアウトは 10 秒 [6]
     - 次の 2 点は未確認。溜めている間に `displayContent` を空にすれば行が消えるか。差し替えた文字列が Markdown として描かれるか
  3. **mod の `ui.render`（`AssistantMessage`）で `props.text` を書き換える**
     - 組み込みの `cc-plugin-mermaid` と同じ方式 [4][9]
     - `e.viewport.columns` を見て、mermaid-ascii の `--max-width` を変えられる
- **必要なもの**: 導入済み（mermaid-ascii、`mmd2txt`）。案 2・3 は hook か mod を書く
- **日本語ラベル**: mermaid-ascii なら表示幅で揃う。ロケールの条件は上記のとおり
- **手間**: 小（案 1）／中（案 2・3）
- **制約**
  - 罫線の図なので、ノードが増えると読みにくい
  - 対応する図の種類は mermaid-ascii 次第。`.claude/DIAGRAM.md` の記録では、ER は記号が崩れ、state と class は未対応

### B. 横ペインでのプレビュー（推奨）

「プレビュー形式」に一番近い。Claude Code の外側で描くので、Claude Code の制約を受けない。

**表示経路: 通る見込み。** 使うのは Kitty graphics の直接配置で、herdr が描き直す [12]。実際に映るかは手順 2 で実測する。

- **構成**
  1. herdr で右にペインを割る（`herdr pane split --direction right --no-focus`）[12]
  2. そのペインで監視ツールを走らせる。Claude が書いた `.mmd` が変わるたびに、mermaid-cli（`mmdc`）が PNG を描き直す
  3. 同じペインで、PNG を `chafa -f kitty` で表示する
  4. herdr がその Kitty graphics を Ghostty に描き直す（[12]、未実測）
- **再描画の起点**（3 案。推奨は 1）
  1. **ペイン内の監視ツール**（watchexec／entr）
     - Write／Edit／Bash／外部プロセスのどれで書かれても拾える
     - Claude Code の設定に触れない
  2. **`PostToolUse` hook**（matcher `Write|Edit`）
     - Bash や外部プロセスで書き換えたファイルは拾わない [6]
     - hook は画面に描けないので、`herdr pane run <id> …` でペインにコマンドを送ることになる [6][12]
  3. **`FileChanged` hook**
     - 監視対象は、作業ディレクトリ直下のファイル名をそのまま列挙したものだけ。正規表現は効かない [6]
- **表示ツールの比較**（いずれも `-f kitty` 相当を明示する。版は home-manager が固定している nixpkgs のもの [30]）
  - **chafa 1.18.1**
    - `--watch` でファイルの変更を監視し、描き直す
    - `-f kitty`、`--passthrough none|tmux|screen` を持つ。SVG を読む機能（librsvg）もある
    - 1.14.3 で Ghostty に対応、1.16.0 で `--probe` を追加 [25]
    - herdr の中（`TERM_PROGRAM=herdr`）で自動判定が kitty を選ぶかは未確認。`-f kitty` を明示する
  - **timg 1.6.3**
    - `-pk` で Kitty graphics を使う
    - 自動判定できない端末では quarter（ブロック文字）に落ちる、とマニュアルにある [26]
  - **kitten icat**（kitty 0.46.2 に同梱）
    - `--transfer-mode detect|file|stream|memory`、`--unicode-placeholder`、`--passthrough detect|tmux|none` を持つ [27]
    - herdr の中でどの転送方式が通るかは未確認。だめなら `--transfer-mode=stream` を指定する
- **描画ツール**
  - **mermaid-cli 11.12.0**: `mmdc -i in.mmd -o out.png -t dark -b transparent`。描画には Puppeteer 経由でブラウザを使う [28]
    - **macOS では nixpkgs の版にブラウザが付かない。** nixpkgs の定義は、ビルド時に Puppeteer のブラウザのダウンロードを止めている（`PUPPETEER_SKIP_DOWNLOAD = true`）。`PUPPETEER_EXECUTABLE_PATH` を設定するのは、その環境で nixpkgs の chromium が使えるときだけ [32]
    - 固定している nixpkgs では、aarch64-darwin で `chromium.meta.available = false` [30]
    - そのため、使うブラウザを自分で渡す。方法は `PUPPETEER_EXECUTABLE_PATH` か、`--puppeteerConfigFile` の `executablePath`。後者は mermaid-cli の文書に手順がある。ただし「バンドル版以外の Chrome は自己責任」と書かれている [28]
    - 手元には `/Applications/Google Chrome.app` がある [Obs-2]。Chrome の版で mmdc が動くかは未確認
  - **D2**（固定 nixpkgs では 0.7.1、調査したソースは 0.9.0）: PNG を出すには Chromium が要る。0.8.2 からは、起動時にダウンロードするか確認される。SVG なら要らない [23]
    - SVG を chafa で表示する手もある（ブラウザ不要の代替）。日本語の字形が出るかは未確認
- **必要なもの**: mermaid-cli とブラウザの指定、chafa（または timg／kitty）、watchexec（または entr）
  - いずれも未導入
  - home-manager が固定している nixpkgs で、aarch64-darwin 向けに `meta.available = true` になっている [30]
- **日本語ラベル**
  - 画像として描くので、セル幅による桁ずれは起きない
  - 字形は Chromium が使うフォント次第
- **手間**: 中（パッケージ 3 つと、ペインで走らせるコマンド 1 本）
- **制約**
  - Claude 自身は描かれた画像を見ない
  - 画像はペインの大きさに縮む
  - ペインの大きさを変えたとき、自動で描き直されるかは未確認（chafa の `--watch` はファイルの変更で描き直す）
  - 画面を消去すると画像も消える、と仕様で決まっている [18]。描き直しの前の消去はそれで足りる

### C. Claude Code の mod のペインに画像を描く

Claude Code の画面の中で完結する構成。mod の土台はユーザーが既に持っている。

**表示経路: 環境変数を付ければ通る見込み。** 付けなければ `alt` のテキストになる見込み。使うのは Kitty graphics の Unicode placeholder で、手順 3・4 で実測する。

- **仕組み**
  - mod が `$.ui.open({ id })` でペインを開き、`Image` 要素で PNG を描く [3][4]
  - 幅の広い全画面表示（`/tui fullscreen`）では、ペインが transcript の横のサイドバーになる。それ以外では、プロンプトの上の枠になる [4][11]
  - PNG はファイルのパスで渡せる（`source: { file, format: 'png', generation }`）。`generation` を変えれば読み直させられる [10]
  - 描き直しの起点は 2 案。`$.clock.every` で `$.fs.stat` の更新時刻を見るか、`tool.call` のイベントを使う [3][5]
  - 描画は `$.process.run(['mmdc', …])` で起動する [5]
- **herdr の中で使う条件**
  - `env CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1 claude` で起動する [2]
  - herdr は Unicode placeholder を描くので、検出を飛ばせば描かれるはず（未実測。末尾の手順 3・4 で確かめる）[12]
- **派生案 C'**: `AssistantMessage` の描画を置き換え、返答の中の ```` ```mermaid ```` を `Image` にする。返答の位置にインラインで図が出る。transcript の描画場所に `Image` を返せるかは未確認 [4]
- **必要なもの**: mod 1 つ、mermaid-cli とブラウザの指定（B と同じ）、起動時の環境変数
- **日本語ラベル**: 画像なので B と同じ
- **手間**: 大（mod を書いてテストする）
- **制約**
  - `Image` は 255×255 セル、base64 なら 2 MiB まで [3]
  - バックグラウンドセッションでは描けない [1]
  - 強制した状態で外側が描けない端末だと、`alt` も出ずに空白になる。tmux の例がドキュメントに書かれている [1]

### D. ブラウザへの退避（基準線）

端末の外に出るが、忠実度は一番高い。比較の基準として載せる。

**表示経路: 端末の外。** herdr と Ghostty を通らない。

- **archify スキル**: 図を、インライン SVG を含む単体の HTML にする。確認用に Chrome で PNG のキャプチャも出せる [31]。その PNG を B のペインで表示する使い方もできる
- **Artifact**: HTML を claude.ai に非公開で公開する
- **その他**: `d2 --watch`（ブラウザで自動再読み込み）、`mmdc` で描いて `open` で開く [23][28]
- **必要なもの**: ブラウザ（archify と Artifact は既にある）
- **日本語ラベル**: ブラウザのフォントで描かれるので、問題は起きない
- **手間**: 小
- **制約**: 端末から目を離す。herdr の中には収まらない

## 推奨構成

1. **表と小さな図は A のまま**。表は Markdown 表、図は `mmd2txt` で応答に載せる。今の `.claude/DIAGRAM.md` の運用を変えない。貼る手間を省きたくなったら、`MessageDisplay` hook か mod で ```` ```mermaid ```` を差し替える（A の案 2・3）
2. **大きな図は B に逃がす**。導入は home-manager で行う。次は手順の案で、未実行
   - `home.nix` に `mermaid-cli`、`chafa`、`watchexec` を足す
   - herdr で右にペインを作り、次を走らせる（fish。`.preview/` は `.gitignore` に入れる）

     ```fish
     mkdir -p .preview
     set -x PUPPETEER_EXECUTABLE_PATH "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
     watchexec -w .preview -e mmd --clear -- 'mmdc -i .preview/diagram.mmd -o .preview/diagram.png -t dark -b transparent && chafa -f kitty --passthrough none .preview/diagram.png'
     ```

   - `PUPPETEER_EXECUTABLE_PATH` の行は、macOS の nixpkgs 版 mmdc にブラウザが付かないためのもの [28][32]
   - Chrome で mmdc が動かない場合は、ブラウザ不要の代替に切り替える。D2 で SVG を出して `chafa --watch` で表示する（日本語の字形は未確認）

   - `CLAUDE.md` 側に「端末に収まらない図は `.preview/diagram.mmd` に Mermaid で書き出す」と書く。`.claude/DIAGRAM.md` の「端末に収まらない図」の手順 3（Artifact）の手前に入れる位置になる
   - watchexec は `$SHELL`（fish）でコマンドを走らせる [29]
3. **C は確認手順 3・4 が通ってから**。Claude Code の画面の中に図を出したい動機が強ければ、mod の `Image` ペインを試作する

## 未確認

確かめ方は各項目の後に書いた。

- **herdr のペインが XTVERSION に何と答えるか**: ソースからは `libghostty` と推定した。確認は末尾の手順 1
- **herdr → Ghostty で Kitty graphics の画像が実際に映るか**: 直接配置は手順 2、Unicode placeholder は手順 3 で確認する
- **herdr の中で Claude Code の画像検出が落ちるか、`CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1` で通るか**: 手順 4 で確認する
- **mod の `Image` が herdr の中で実際に描かれるか**: 手順 4 の後、`Image` を 1 つだけ描く小さな mod で確かめる
- **返答やツール出力に含めた Kitty graphics の APC が端末まで届くか**: 正規の経路ではないので試していない。確かめるなら、返答に APC を含めたときの表示を見る
- **statusline から画像を出せるか**: ドキュメントに記載が無い。試すなら、Kitty graphics の APC を出すスクリプトを statusline に設定して見る
- **`MessageDisplay` hook について 2 点**: `displayContent` を空にすると行が消えるか。差し替えた文字列が Markdown として描かれるか。返答の途中にフェンスがある応答で、hook を試して見る
- **`AssistantMessage` の置き換えに `Image` を返せるか（C'）**: mod で試作して確かめる
- **Graph::Easy、D2 txt、beautiful-mermaid で日本語がずれるか**: ソースで幅の数え方を見ただけで、出力は見ていない。日本語ラベルの図を各ツールで描いて、右端が揃うかを見る
- **chafa の自動判定と kitten icat の転送方式（herdr の中）**: `chafa --probe on file.png` と `kitten icat --detect-support` で確かめる
- **herdr のポップアップと、ペインの大きさを変えたときの画像**: 実機で見る
- **組み込みの `cc-plugin-mermaid` をユーザーが有効にできるか**: ドキュメントに記載が無い。機能フラグはサーバー側にある
- **macOS の nixpkgs 版 mmdc が、手元の Google Chrome で動くか**: Puppeteer は、バンドル版以外のブラウザでの動作を保証していない。`PUPPETEER_EXECUTABLE_PATH` を設定して `mmdc -i x.mmd -o x.png` を 1 回走らせて確かめる
- **mmdc の所要時間**: 未計測。`time mmdc -i x.mmd -o x.png` で測る

## ユーザーが実際の herdr ペインで実行する確認手順

herdr のペインの中で、fish からそのまま貼れる形にした。エスケープシーケンスはすべて仕様から組み立てた [18][19]。

- Kitty graphics の命令は `ESC _ G <制御データ> ; <ペイロード> ESC \` の形をとる（APC）[18]
- 終端の `ESC \` は、fish の単一引用符の中でも崩れないように `\x1b\x5c` と書いた（`\x5c` はバックスラッシュ）
- Python のコードは fish の構文検査（`fish -n`）と `py_compile` を通してある

### 手順 1: 画像対応の問い合わせと端末名

送るものは 3 つ。

- 端末名の問い合わせ（XTVERSION）: `CSI > 0 q`。応答は `DCS > | 名前 ST` [19]
- Kitty graphics の問い合わせ: 仕様の例 `ESC_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA ESC\` [18]
- 端末属性の問い合わせ（DA1）: `ESC[c`

仕様では、DA1 の応答より先に Kitty graphics の応答が返ってくれば対応、DA1 の応答しか来なければ非対応と判定する [18]。

```fish
python3 -c '
import os, sys, termios, tty, select, time
fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
tty.setraw(fd)
try:
    os.write(1, b"\x1b[>0q" + b"\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\x5c" + b"\x1b[c")
    buf = b""
    end = time.time() + 2
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.1)
        if r:
            buf += os.read(fd, 1024)
            if buf.endswith(b"c") and b"\x1b[?" in buf:
                break
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old)
print(repr(buf))
'
```

読み方:

- `\x1b_Gi=31;OK\x1b\\` が含まれていれば、herdr のペインは Kitty graphics に対応している [18]
- `\x1bP>|…\x1b\\` の `…` が端末名。予想は `libghostty`
  - `ghostty 1.3.1` なら、herdr の中でも Claude Code の自動検出が通る
  - それ以外なら通らない [9][13][16]
- 比較のため、herdr の外の Ghostty でも同じものを実行する。予想は `ghostty 1.3.1` と `OK`

### 手順 2: 画像を直接置く（chafa・timg・icat と同じ経路）

40×20 ピクセルの 2 色の格子を、RGB（`f=24`。この形式では幅 `s` と高さ `v` が必須）で送る。表示は 20 列×5 行（`c=20,r=5`）で、送ると同時に表示する（`a=T`）[18]。ペイロードは 3,200 文字で、仕様の分割上限 4,096 に収まる [18]。

```fish
python3 -c '
import base64, os
w, h = 40, 20
px = b"".join(bytes((255, 80, 0)) if (x // 10 + y // 5) % 2 else bytes((0, 120, 255)) for y in range(h) for x in range(w))
os.write(1, b"\x1b_Ga=T,f=24,s=40,v=20,c=20,r=5;" + base64.b64encode(px) + b"\x1b\x5c" + b"\n")
'
```

結果の読み方:

- 橙と青の格子が出れば、herdr → Ghostty の経路は通っている。系統 B が使える
- 何も出なければ、herdr の設定を確認する（`herdr --default-config` の `[terminal] kitty_graphics`）[14]

### 手順 3: Unicode placeholder で置く（Claude Code の mod の `Image` と同じ方式）

緑の画像を ID 42 で送る。応答は抑止（`q=2`）、仮想配置（`U=1`）、2 列×2 行。そのあと placeholder の文字 U+10EEEE を 2×2 で並べる。

- 前景色 `38;5;42` が画像 ID を表す
- 結合文字 U+0305 が 0、U+030D が 1 を表し、行・列の順に付ける
- 並べ方は仕様の 2×2 の例と同じ [18]

```fish
python3 -c '
import base64, os
px = bytes((0, 200, 80)) * (40 * 20)
os.write(1, b"\x1b_Ga=T,U=1,q=2,i=42,f=24,s=40,v=20,c=2,r=2;" + base64.b64encode(px) + b"\x1b\x5c")
P, D = chr(0x10EEEE), [chr(0x305), chr(0x30D)]
for r in range(2):
    row = "".join(P + D[r] + D[c] for c in range(2))
    os.write(1, ("\x1b[38;5;42m" + row + "\x1b[39m\n").encode())
'
```

結果の読み方:

- 緑の四角（2 列×2 行）が出れば、Claude Code の mod の `Image` が使う経路も、herdr → Ghostty で通る
- 豆腐や記号が出るなら、placeholder が描かれていない

### 手順 4: Claude Code が画像に対応と判定するか

debug ログには、起動時の判定が 1 行で出る見込み。形式はバイナリ内の文字列から推定した [9]。

- 形式は `Terminal capabilities: …; kittyGraphics=yes|no (<理由>); …`
- 理由は、問い合わせの結果か環境変数のどちらか（`probe: graphics reply OK, terminal libghostty` や `env: CLAUDE_CODE_FORCE_TERMINAL_IMAGES` など）
- debug ログの出し方（`--debug-file`）はドキュメントに従った [11]

```fish
claude --debug-file /tmp/cc-probe.log
# 起動したら /exit で抜ける
grep -o 'kittyGraphics=[^;]*' /tmp/cc-probe.log

env CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1 claude --debug-file /tmp/cc-probe-forced.log
# 起動したら /exit で抜ける
grep -o 'kittyGraphics=[^;]*' /tmp/cc-probe-forced.log
```

予想:

- 1 回目は `kittyGraphics=no (probe: graphics reply OK, terminal libghostty)`
- 2 回目は `kittyGraphics=yes (env: CLAUDE_CODE_FORCE_TERMINAL_IMAGES)`
- 1 回目が `yes` なら、環境変数は要らない
- 手順 3 が通り、2 回目が `yes` なら、系統 C の前提がそろう

## 出典

公式ドキュメント（Claude Code）。行番号は各ページの `.md` 版（`https://code.claude.com/docs/en/<page>.md`、2026-10-15 取得）のもの。

- [1] Interface gallery for mods「`Image` and `Client`」: https://code.claude.com/docs/en/plugins/mods/gallery （L376–388）
- [2] Environment variables `CLAUDE_CODE_FORCE_TERMINAL_IMAGES`: https://code.claude.com/docs/en/env-vars （L307）
- [3] Mods reference「Render sites」「Elements」「Tools」: https://code.claude.com/docs/en/plugins/mods/reference （L51–60、L205–252）
- [4] Draw in the interface with a mod「Pick where to draw」「Change what Claude Code already draws」: https://code.claude.com/docs/en/plugins/mods/interface （L186–296）
- [5] Use the mods API「Reach files, processes, and the network」: https://code.claude.com/docs/en/plugins/mods/api （L261–288）
- [6] Hooks reference: https://code.claude.com/docs/en/hooks （制御端末なし L724、`terminalSequence` L1035・L1047、stdout の扱い L810、MessageDisplay L1568–1616、PostToolUse L2139–2149、FileChanged L3022–3031）
- [7] Status line: https://code.claude.com/docs/en/statusline （L163–164）
- [8] Claude Code CHANGELOG: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md （2.1.299 の表と CJK の修正、2.1.295 の SGR、2.1.282 `maxProseWidth`、2.1.208 の 200 行、2.1.198 と 2.1.152 の表のレイアウト、2.0.73 `[Image #N]`）
- [11] Troubleshoot a mod「Read the debug log」: https://code.claude.com/docs/en/plugins/mods/troubleshoot 、Fullscreen rendering（`/tui fullscreen`）: https://code.claude.com/docs/en/fullscreen

手元のインストール物（Claude Code）。

- [9] Claude Code 2.1.299 のバイナリ（`~/.local/share/claude/versions/2.1.299`）に埋め込まれた JS。`strings` で抽出した。次の文字列で再現できる
  - `{ambiguousIsNarrow:!0}`
  - `var c=["kitty","ghostty"],m="0.28.0"`（検出の許可リスト）
  - `multiplexed:Boolean(a.TMUX)||Boolean(a.STY)`
  - `probe: graphics reply`
  - `a=T,U=1,q=2`（`Image` の送出）
  - `Mermaid diagrams in the terminal: flowcharts and sequence diagrams in a reply's mermaid code fences are drawn in place as box-drawing text`
  - `Rr("tengu_mermaid_mod",ae)`（`ae=!1`）
  - `"Terminal capabilities: "`
- [10] Claude Code が展開する組み込みスキル plugin-authoring（2.1.299）。`/private/tmp/claude-<uid>/bundled-skills/2.1.299/<hash>/plugin-authoring/` 配下の 2 ファイル
  - `reference.md`（L148–150）
  - `types/claude-code.d.ts`（`ImageProps` L5383–5420、`ImageSource` L5422–5500）

herdr。

- [12] herdr v0.9.4 のソース（タグ v0.9.4、commit 7e26bad、https://github.com/herdrdev/herdr ）
  - `CHANGELOG.md`: 0.9.4 L34、0.9.2 L66・L79、0.9.0 L187、0.7.1 L589、0.6.0 L841、0.5.9 L909
  - `docs/next/website/src/content/docs/configuration.mdx`（L526–549 Kitty graphics、L197–208 popup）
  - `socket-api.mdx`（L179–188）
  - `cli-reference.mdx`（L205–258）
  - `plugins.mdx`（L299–338）
  - `src/client/handshake.rs`（L58–70）、`src/client/mod.rs`（L209–210）
- [13] herdr が取り込む libghostty-vt（`vendor/libghostty-vt.vendor.json`: `libghostty-vt-1.3.2-HEAD-+44f2a44df`）
  - `src/terminal/osc/parsers/iterm2.zig`（L160–195、`File` は unimplemented）
  - `src/terminal/dcs.zig`（L52–108）
  - `src/terminal/stream_terminal.zig`（L1399–1407、L4755–4757: 既定の応答は `libghostty`）
  - herdr の `src/`・`crates/ghostty-vt/src/`（`bindings.rs` を除く）に `OPT_XTVERSION` の使用は無かった（`grep -rn` で確認）
- [14] `herdr --version`（0.9.4）、`herdr --help`、`herdr --default-config`（`[terminal]` の `# kitty_graphics = true`）、https://herdr.dev/llms.txt

Ghostty。

- [15] Ghostty Features: https://ghostty.org/docs/features
- [16] Ghostty v1.3.1 のソース（commit 332b2ae、https://github.com/ghostty-org/ghostty ）
  - `src/terminal/kitty/graphics_unicode.zig`（L1–16）
  - `src/terminal/kitty/graphics_command.zig`（L386–448）
  - `src/termio/stream_handler.zig`（L815–827 DA1、L976–984 XTVERSION）
  - `src/terminal/osc/parsers/iterm2.zig`（L160–195）
  - `src/terminal` を `grep -rn -i sixel` した結果は 0 件
- [17] `ghostty +show-config --default --docs`（`image-storage-limit`）、`ghostty +version`（1.3.1）

プロトコル仕様。

- [18] Kitty terminal graphics protocol: https://sw.kovidgoyal.net/kitty/graphics-protocol/ 。原文は kitty master（commit 0d006c4）の `docs/graphics-protocol.rst`
  - APC の形式 L254
  - 分割上限 4096 L404–423
  - 対応の問い合わせ L429–474
  - Unicode placeholder L579–623
  - 制御データ一覧 L1061–1118
  - 画面消去で画像も消える L1175–1179
- [19] XTerm Control Sequences: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html （XTVERSION `CSI > Ps q` と応答 `DCS > | text ST`、DA1 `CSI Ps c`）

テキスト図の生成器。

- [20] mermaid-ascii 1.6.1（タグ 1.6.1 = commit 5f00e3d、https://github.com/AlexanderGrooff/mermaid-ascii ）
  - `go.mod`（go-runewidth v0.0.19）
  - `pkg/graph/label.go` L30
  - `pkg/graph/render_graph_test.go` L31–56
  - `pkg/sequence/renderer.go`、`pkg/er/`
  - README（`--ascii`、`--max-width`）
- [21] go-runewidth v0.0.19: `runewidth.go` L26–40、`runewidth_posix.go` L54–69（https://github.com/mattn/go-runewidth ）
- [22] Graph::Easy 0.76（CPAN、2016-06-06）: `lib/Graph/Easy/Node.pm` L1603–1617（https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/Graph-Easy-0.76.tar.gz ）
- [23] D2 v0.9.0（commit d5a5174、https://github.com/d2lang/d2 ）
  - `ci/release/changelogs/v0.7.1.md` L3（ASCII 出力の追加）
  - `v0.8.2.md` L32–38
  - `d2renderers/d2ascii/asciishapes/asciishapes.go` L83–104
  - `d2cli/main.go` L106・L148、`d2cli/help.go`
- [24] beautiful-mermaid 1.1.3（commit 2ac8bbb、https://github.com/lukilabs/beautiful-mermaid ）: `src/ascii/draw.ts` L107–150、`src/ascii/edge-routing.ts` L230

画像の表示・描画・監視ツール。

- [25] chafa（https://github.com/hpjansson/chafa 、commit be73375）
  - `NEWS`: 1.12.0 SVG の読み込み、1.14.0 `--passthrough`、1.14.3 Ghostty、1.16.0 `--probe`
  - `docs/chafa.xml`（`--probe`、`-f`、`--passthrough`、`--watch`、`--clear`）
- [26] timg のマニュアル: https://github.com/hzeller/timg/blob/main/man/timg.1.md （L46–104）
- [27] kitten icat: https://github.com/kovidgoyal/kitty/blob/master/kittens/icat/main.py （L63–80、L145–170）、https://sw.kovidgoyal.net/kitty/kittens/icat/
- [28] mermaid-cli README: https://github.com/mermaid-js/mermaid-cli
- [29] watchexec のマニュアル: https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md （`--shell` L237–251、`--clear` L969）
- [30] nixpkgs の版と利用可否。2 つの nixpkgs で評価した
  - **home-manager が固定している版**: `.config/home-manager/flake.lock` の nixpkgs（nixos-unstable、rev 549bd84）。`nix eval github:nixos/nixpkgs/<rev>#<pkg>.version`、`.meta.available`、`.meta.broken` の結果は次のとおり。どれも aarch64-darwin で `available = true`、`broken = false`
    - mermaid-cli 11.12.0、chafa 1.18.1、timg 1.6.3、kitty 0.46.2、watchexec 2.5.1、entr 5.8、d2 0.7.1
    - 同じ rev で `chromium.meta.available` は `false`
  - **参考（flake レジストリの最新）**: `nixpkgs`（DeterminateSystems nixpkgs-weekly、rev 494ce7f）
    - d2 0.9.0、chafa 1.18.2、mermaid-cli 11.17.0、kitty 0.49.2、entr 5.9、graph-easy 0.76
    - mermaid-ascii はどちらの nixpkgs にも無い
- [32] nixpkgs の mermaid-cli の定義（rev 549bd84）: `pkgs/by-name/me/mermaid-cli/package.nix`
  - L30 `PUPPETEER_SKIP_DOWNLOAD = true`
  - L35: `PUPPETEER_EXECUTABLE_PATH` を設定するのは、chromium がその環境で使えるときだけ
  - mermaid-cli 側の文書: https://github.com/mermaid-js/mermaid-cli/blob/master/docs/already-installed-chromium.md
- [31] archify スキル（`~/.claude/skills/archify/SKILL.md` version 3.1、`references/delivery-contract.md` L480–495）

手元の観測。

- [Obs-1] 環境変数
  - `TERM_PROGRAM=herdr`、`TERM_PROGRAM_VERSION=0.9.4`、`TERM=xterm-256color`
  - `TMUX`／`STY` は未設定
  - `LANG=en_US.UTF-8`（`LC_ALL`／`LC_CTYPE` は未設定）
  - `claude --version` は 2.1.299
- [Obs-2] dotfiles-public の作業ツリー（2026-10-15 時点で未コミット）
  - `.claude/DIAGRAM.md`、`.local/bin/mmd2txt`、`.config/home-manager/pkgs/mermaid-ascii.nix`（1.6.1 の公式バイナリ）
  - `~/.nix-profile/bin/mermaid-ascii` は mermaid-ascii-1.6.1 を指す
  - chafa・timg・mmdc・d2・graph-easy・kitten・watchexec・entr は PATH に無い
  - `/Applications/Google Chrome.app` はある
- [Obs-3] https://code.claude.com/docs/llms-full.txt を `grep -i mermaid` した結果は 1 件。出力スタイルの作例の "start with a Mermaid diagram"
- [Obs-4] `claude plugin list` の出力に、組み込み（`@builtin`）のプラグインは出ない
