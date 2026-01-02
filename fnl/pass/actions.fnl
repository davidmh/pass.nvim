(local utils (require :pass.utils))

(local M {})

(fn update-password-on-leave [{: buf
                               : old-content
                               : path}]
  (local new-lines (vim.api.nvim_buf_get_lines buf 0 -1 false))
  (local new-content (table.concat new-lines "\n"))

  (when (= (vim.trim new-content)
           (vim.trim old-content))
    (utils.info "The password didn't change")
    (lua :return))

  (when (= new-content "")
    (M.delete nil {:text path})
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
  (picker:close)
  (if (not entry) (lua :return))

  (local path entry.text)
  (local (ok? result) (pcall utils.show path))

  (if (not ok?)
    (utils.error (.. "Failed to read: " path))
    (lua :return))

  ;; create a scratch buffer
  (local buf (vim.api.nvim_create_buf false true))
  (vim.api.nvim_set_option_value :filetype :pass {:scope :local
                                                  :buf buf})
  (vim.api.nvim_set_option_value :bufhidden :wipe {:scope :local
                                                   :buf buf})

  ;; load the value into the buffer
  (vim.api.nvim_buf_set_lines buf
                              0
                              -1
                              false
                              (vim.split result "\n"))

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
                     :title (.. " Edit " path " ")
                     :title_pos :center})

  (local win (vim.api.nvim_open_win buf true win-config))
  (vim.api.nvim_set_option_value :winblend 0 {:win win})
  (utils.disable-backup-options)

  ;; update the pass entry on window close
  (vim.api.nvim_create_autocmd :BufWinLeave {:buffer buf
                                             :callback #(update-password-on-leave {: buf
                                                                                   : path
                                                                                   :old-content result})}))

(fn M.rename [picker entry]
  (picker:close)
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
      (utils.error (.. "Failed to rename " old-path))))

  (vim.ui.input {:prompt (.. "Rename " old-path)
                 :default old-path}
                on-rename))

(fn M.delete [picker entry]
  (if picker (picker:close))
  (if (not entry) (lua :return))

  (local path entry.text)
  (vim.ui.select [:Yes :No]
                 {:prompt (.. "Delete " path "?")}
                 (fn [choice]
                    (when (= choice :Yes)
                      (local (ok?) (pcall utils.rm path))
                      (if ok?
                        (utils.info (.. "Deleted: " path))
                        (utils.error (.. "Failed to delete: " path)))))))

(fn M.copy [picker entry]
  "Copy the password into the system clipboard"

  (picker:close)
  (if (not entry) (lua :return))

  (local path entry.text)
  (local password (utils.show path))

  (vim.fn.setreg :+ password)

  (utils.info (.. "Copied " path)))

(fn M.log []
  "Show the git log for the password store"

  (local snacks-picker (require :snacks.picker))

  (snacks-picker.git_log {:cwd (utils.get-password-store-dir)}))

M
