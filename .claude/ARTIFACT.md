## HTML は Sumi Shu で組む

HTML を出力するときは、自分用のデザインシステム **Sumi Shu**（https://claude.ai/artifact/AFvmwNNqyM6ZyxqbUKhRfq ）で組む。
Artifact は誰かに説明するためのプレゼン資料として扱い、墨の文字と朱 1 色、罫線と余白だけで、整列・近接・反復・対比・余白・分割の 6 原則に沿って組む。グラデーション・カード・絵文字のような定番の装飾は、AI が作った見た目に見えるので使わない。
ページは**全幅**にする。外枠に上限の幅を付けず、文章の段落（`p`）だけを `max-width: 45em`（全角 45 字前後）で折り返す。
`artifact-design` スキルや `frontend-design` スキルの見た目の指示（題材ごとに配色や書体を選ぶ、本文を 65 文字幅前後にする など）より、この規定を優先する。65ch は日本語では全角 32 字前後（約 500px）になり、広い画面で細くて読みにくいため。

### 出力ごとの当て方

| 出力 | 当て方 |
| --- | --- |
| 自分で書く HTML（Artifact、ローカルの HTML、GitHub Issue の HTML artifact） | 書く前に Sumi Shu の `project/README.md` と `project/components/bundle.css` を Artifact ツールの `read`（`path` 指定）で読み、README の「使い方」のとおりに組む。全幅は `bundle.css` に入っている |
| Slides 型・Design 型 | デザインシステムに Sumi Shu を使う（URL を渡す） |
| `archify` の explainer | `artifact-theme/archify-explainer.css`（幅・色・書体）を、最後の `finalize` が通った後の HTML に足す。`finalize` を回し直したら、もう一度足す |
| `archify` の図のページ | `artifact-theme/archify-diagram.css`（色・書体）を、テンプレートの `<style>` より後ろに足す。幅はそのままにする |
| `html-plan` | `artifact-theme/html-plan.css`（幅・色・書体）を、pack 前の `plan.html` の `<link rel="stylesheet" href="htmlplan.css">` より後ろに足す |

第三者スキル用の CSS は `~/git/private/dotfiles-public/.claude/artifact-theme/` にある。中身を `<style>` で貼り、ファイルの先頭の `@import` の行はその `<style>` の先頭に置く。寄せるのは幅（図のページを除く）・色・書体だけで、レイアウトはスキルのままにする。図のページは JS が図を 1 画面に収める幅を計算しているので、幅は触らない。

- 状態を表す色（archify の `--good` `--caution` `--bad`、html-plan の `--green` `--amber` `--red` など）は、図表の意味を壊さないよう上書きしない
- archify の図を SVG・画像で書き出したものは対象外にする。書き出しの処理が独自の書体を埋め込むため、上書きが届かない
- CSS を足した explainer は、archify の provenance（成果物の SHA-256 との照合）の検査から外れる。報告には「検査後に幅と配色の CSS を足した」と書く
- スキルの更新で効かなくなったら、`archify/explainer/reader.css`、`archify/assets/template.html`、`html-plan/runtime/htmlplan.css` の変数名を読み直して CSS を直す

完了条件:
- 自分で書く HTML: 地が `paper`、文字が `ink`、強調色が `shu`、書体が IBM Plex Sans JP。外枠の幅が画面幅から左右の余白を引いた値に等しく、`p` の `max-width` が `45em`。README の「禁止」に当たる装飾が 0 件で、「仕上げの検査」を満たす
- 第三者スキルの出力: 幅（図のページを除く）・地・文字・強調色・書体が上と同じ。レイアウトと状態を表す色は、スキルのままでよい
