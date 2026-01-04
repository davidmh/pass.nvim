(import-macros {: tx} :pass.macros)
(local {: define} (require :pass.module))
(local utils (require :pass.utils))

(local M (define :pass {}))

(fn update-password-on-save [{: buf
                              : old-content
                              : path
                              : picker}]
  (local new-lines (vim.api.nvim_buf_get_lines buf 0 -1 false))
  (local new-content (table.concat new-lines "\n"))

  (when (= (vim.trim new-content)
           (vim.trim old-content))
    (utils.debug "The password didn't change")
    (lua :return))

  (when (= new-content "")
    (vim.schedule #(M.delete picker {:text path}))
    (lua :return))

  (local (ok?) (pcall utils.save-content path new-content))
  (if ok?
    (do
      (utils.info (.. "Password saved: " path))
      (vim.api.nvim_set_option_value :modified false {:scope :local
                                                      :buf buf}))
    (utils.error (.. "Failed to save password: " path)))

  nil)

(fn M.edit [picker entry]
  (local path (or (and entry entry.text)
                  (and picker picker.finder.filter.pattern)))

  (if (and picker picker.close) (picker:close))

  (if (= (vim.trim path) "")
    (lua :return))

  (local (ok? result) (pcall utils.show path))

  (local content (if ok?
                  result
                  ""))

  (local label (if ok?
                   "Edit"
                   "Insert"))

  ;; create a scratch buffer
  (local buf (vim.api.nvim_create_buf false true))
  (vim.api.nvim_buf_set_name buf (.. "pass://" path))
  (vim.api.nvim_set_option_value :buftype :acwrite {:scope :local
                                                    :buf buf})
  (vim.api.nvim_set_option_value :filetype :pass {:scope :local
                                                  :buf buf})
  (vim.api.nvim_set_option_value :bufhidden :wipe {:scope :local
                                                   :buf buf})

  ;; load the value into the buffer
  (vim.api.nvim_buf_set_lines buf
                              0
                              -1
                              false
                              (vim.split content "\n"))

  ;; create a floating window
  (local width (math.min 80 (- vim.o.columns 4)))
  (local height (math.min 20 (- vim.o.lines 4)))
  (local row (math.floor (/ (- vim.o.lines height) 2)))
  (local col (math.floor (/ (- vim.o.columns width) 2)))

  (local win-config {:relative :editor
                     : width
                     : height
                     : row
                     : col
                     :style :minimal
                     :border :rounded
                     :title (.. " " label ": " path " ")
                     :title_pos :center})

  (local win (vim.api.nvim_open_win buf true win-config))
  (vim.api.nvim_set_option_value :winblend 0 {:win win})
  (utils.disable-backup-options)

  ;; update the pass entry on save
  (vim.api.nvim_create_autocmd :BufWriteCmd {:buffer buf
                                             :callback #(update-password-on-save {: buf
                                                                                  : path
                                                                                  : picker
                                                                                  :old-content content})}))

(fn M.rename [picker entry]
  (if (not entry) (lua :return))

  (local old-path entry.text)

  (fn on-rename [new-path]
    (when (or
            (not new-path)
            (= new-path old-path))
      (lua :return))

    (local (ok?) (pcall utils.mv old-path new-path))

    (if ok?
      (utils.info (.. "Renamed " old-path " to " new-path))
      (utils.error (.. "Failed to rename " old-path)))

    (local pattern (or (and picker
                            picker.finder.filter.pattern)
                       ""))

    (when picker
      ; Close the old one
      (picker:close)

      ; Open a fresh picker
      (M.open pattern)))

  (vim.ui.input {:prompt (.. "Rename " old-path)
                 :default old-path}
                on-rename))

(fn M.delete [picker entry]
  (local pattern (or (and picker picker.finder.filter.pattern)
                     ""))
  (if (and picker picker.close) (picker:close))

  (if (not entry) (lua :return))

  (local path entry.text)
  (utils.prompt-bool (.. "Delete " path "?")
                    (fn [choice]
                       (when (= choice :Yes)
                         (local (ok?) (pcall utils.rm path))
                         (if ok?
                           (utils.info (.. "Deleted: " path))
                           (utils.error (.. "Failed to delete: " path)))
                         (if picker
                             (vim.schedule #(M.open pattern)))))))

(fn M.copy [entry]
  "Copy the password into the system clipboard"

  (local path entry.text)

  (if (= (vim.trim path) "")
    (lua :return))

  (local password (utils.show path))

  (vim.fn.setreg :+ password)

  (utils.info (.. "Copied " path)))

(fn M.log []
  "Show the git log for the password store"

  (local snacks-picker (require :snacks.picker))

  (snacks-picker.git_log {:cwd (utils.get-password-store-dir)}))

(fn auto-close-picker [action]
  (fn [picker entry]
    (picker:close)
    (action entry)))


(fn M.insert [picker]
  (local pattern (or (and picker
                          picker.finder.filter.pattern)
                     ""))
  (if (and picker picker.close) (picker:close))
  (vim.ui.input {:prompt "New password's path"
                 :default pattern}
                (fn [new-path]
                  (M.edit picker {:text new-path}))))

(fn M.open [pattern]
  (local (ok? snacks-picker) (pcall require :snacks.picker))

  (when (not ok?)
    (utils.error "snacks.nvim is required to run the picker")
    (lua :return))

  (snacks-picker.pick {:title "Password Store"
                       :pattern pattern
                       :items (utils.list-passwords)
                       :format :text
                       :layout {:preset :select}
                       :win {:input {:keys {:<c-r> (tx :rename {:mode [:i :n]})
                                            :<c-d> (tx :delete {:mode [:i :n]})
                                            :<c-e> (tx :edit {:mode [:i :n]})
                                            :<c-i> (tx :insert {:mode [:i :n]})
                                            :<c-l> (tx :log {:mode [:i :n]})}}}
                       :confirm :copy
                       :actions {:rename M.rename
                                 :insert M.insert
                                 :edit M.edit
                                 :delete M.delete
                                 :log (auto-close-picker M.log)
                                 :copy (auto-close-picker M.copy)}}))

M
