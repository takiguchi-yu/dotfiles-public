-- markdown を normal モードでは preview 表示、insert モードでは生の markdown に切り替える
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    -- normal / command / terminal で描画。insert (i) を含めないので編集中は生 markdown に戻る
    render_modes = { "n", "c", "t" },
    anti_conceal = {
      -- normal では anti conceal を無効化し、カーソル行の extmark も描画したままにする
      disabled_modes = { "n" },
    },
    win_options = {
      concealcursor = {
        -- 既定は "" で全モードでカーソル行の conceal が解除される。
        -- n/c を指定してカーソル行でも記法 (`` ` `` や ** など) を隠す。
        -- i を含めないので insert に入れば生 markdown が見える。
        rendered = "nc",
      },
    },
    -- 以下は LazyVim の extra が抑制している装飾を、プラグイン既定値に戻すもの
    heading = {
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    },
    checkbox = { enabled = true },
  },
}
