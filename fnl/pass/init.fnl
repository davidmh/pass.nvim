(import-macros {: tx} :pass.macros)
(local utils (require :pass.utils))
(local actions (require :pass.actions))

(local M {})

(fn M.open []
  (local (ok? snacks-picker) (pcall require :snacks.picker))

  (when (not ok?)
    (M.error "snacks.nvim is required")
    (lua :return))

  (snacks-picker.pick {:title "Password Store"
                       :items (utils.list-passwords)
                       :format :text
                       :layout {:preset :select}
                       :win {:input {:keys {:<c-r> (tx :rename {:mode [:i :n]})
                                            :<c-d> (tx :delete {:mode [:i :n]})
                                            :<c-e> (tx :edit {:mode [:i :n]})
                                            :<c-l> (tx :log {:mode [:i :n]})}}}
                       :confirm :copy
                       :actions actions}))

M
