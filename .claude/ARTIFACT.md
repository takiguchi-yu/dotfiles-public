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
