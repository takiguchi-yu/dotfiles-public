## HTML は全幅で出す

HTML を出力するときは**全幅**にする。全幅とは、ページの外枠に上限の幅が無く、文章の段落（`p`）だけを `max-width: 45em`（全角 45 字前後）で折り返すこと。
`artifact-design` スキルの「本文は 65 文字幅前後（Keep running text near 65 characters wide）」より、この規定を優先する。65ch は日本語では全角 32 字前後（約 500px）になり、広い画面で細くて読みにくいため。

### 対象

| 出力 | 全幅にする方法 |
| --- | --- |
| 自分で書く HTML（claude.ai の Artifact、ローカルの HTML、GitHub Issue の HTML artifact） | 下の CSS で書く |
| `archify` の一枚ページ（explainer）、`html-plan` | 下の「第三者スキルの出力」の CSS を、出力した HTML に足す |
| `archify` の図のページ | そのままにする。図を 1 画面に収めるため、JS が幅を計算している |

```css
.page {                      /* 外枠。width は既定の auto のまま（100% は padding の分はみ出す） */
  max-width: none;
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px));
}
.page p { max-width: 45em; } /* 段落だけ止める。表・図・コード・カードの並びは外枠いっぱいに広げる */
```

### 第三者スキルの出力

上書きは、出力した HTML の中で、スキルの CSS より後ろに `<style>` を足して行う。

| スキル | 足す CSS | 足す場所と時機 |
| --- | --- | --- |
| `archify` の explainer | `@media (min-width: 1101px) { .shell { width: calc(100% - 64px); } } .panel-body p { max-width: 45em; }` | 最後の `finalize` が通った後の HTML。`finalize` を回し直したら、もう一度足す |
| `html-plan` | `:root body { --col: none; --wide: 100vw; } :root body main p, :root body .dek { max-width: 45em; }` | pack 前の `plan.html` の `<link rel="stylesheet" href="htmlplan.css">` より後ろ。pack し直しても残る |

- explainer の `@media` は、1100px 以下の狭い画面用の幅（`reader.css` の `max-width:1100px` と `760px`）を残すためのもの
- CSS を足した explainer は、archify の provenance（成果物の SHA-256 との照合）の検査から外れる。報告には「検査後に幅の CSS を足した」と書く
- `html-plan` の `--wide` は `min(var(--wide), 100vw - 40px)` の中で使われるので、長さで上書きする
- スキルの更新で効かなくなったら、`archify/explainer/reader.css` と `html-plan/runtime/htmlplan.css` を読み直して CSS を直す

完了条件: 出力した HTML で、外枠の幅が画面幅から左右の余白を引いた値に等しく、`p` の `max-width` が `45em`。

## HTML の見た目は Sumi Shu で組む

HTML を出力するときは、自分用のデザインシステム **Sumi Shu**（https://claude.ai/artifact/AFvmwNNqyM6ZyxqbUKhRfq ）で組む。
Artifact は誰かに説明するためのプレゼン資料として扱い、墨の文字と朱 1 色、罫線と余白だけで、整列・近接・反復・対比・余白・分割の 6 原則に沿って組む。グラデーション・カード・絵文字のような定番の装飾は、AI が作った見た目に見えるので使わない。
`artifact-design` スキルや `frontend-design` スキルの見た目の指示（題材ごとに配色や書体を選ぶなど）より、この規定を優先する。

### 出力ごとの当て方

| 出力 | 当て方 |
| --- | --- |
| 自分で書く HTML（Artifact、ローカルの HTML、GitHub Issue の HTML artifact） | 書く前に Sumi Shu の `project/README.md` と `project/components/bundle.css` を Artifact ツールの `read`（`path` 指定）で読み、README の「使い方」のとおりに組む |
| Slides 型・Design 型 | デザインシステムに Sumi Shu を使う（URL を渡す） |
| `archify` の explainer | 下の `archify-explainer.css` を、幅の CSS と同じ場所に足す |
| `archify` の図のページ | 下の `archify-diagram.css` を、テンプレートの `<style>` より後ろに足す。幅は上の規定どおり触らない |
| `html-plan` | 下の `html-plan.css` を、幅の CSS と同じ場所に足す |

第三者スキル用の CSS は、`~/git/private/dotfiles-public/.claude/artifact-theme/` にある。中身を `<style>` で貼り、ファイルの先頭の `@import` の行はその `<style>` の先頭に置く。寄せるのは色と書体だけで、レイアウトはスキルのままにする。
archify の図を SVG・画像で書き出したものは対象外にする。書き出しの処理が独自の書体を埋め込むため、上書きが届かない。
状態を表す色（archify の `--good` `--caution` `--bad`、html-plan の `--green` `--amber` `--red` など）は、図表の意味を壊さないよう上書きしない。
スキルの更新で効かなくなったら、`archify/explainer/reader.css`、`archify/assets/template.html`、`html-plan/runtime/htmlplan.css` の変数名を読み直して CSS を直す。

完了条件:
- 自分で書く HTML: 地が `paper`、文字が `ink`、強調色が `shu`、書体が IBM Plex Sans JP。README の「禁止」に当たる装飾が 0 件で、「仕上げの検査」を満たす
- 第三者スキルの出力: 地・文字・強調色・書体の 4 つだけが上と同じ。レイアウトと状態を表す色は、スキルのままでよい
