(local M {})

(local notification-chrome {:icon :🛂
                            :title :pass.nvim})

(fn M.get-password-store-dir []
  (or vim.env.PASSWORD_STORE_DIR
      (.. vim.env.HOME "/.password-store/")))

(fn M.list-passwords []
  (local store-dir (M.get-password-store-dir))
  (local extension ".gpg$")

  (local files (vim.fs.find
                 (fn [name] (name:match extension))
                 {:path store-dir
                  :limit math.huge}))

  (vim.tbl_map (fn [file]
                 {:text (-> file
                            (string.sub (+ (length store-dir) 1)
                                        (length file))
                            (string.gsub extension ""))})
               files))

(fn run [{: cmd : stdin}]
  (local result (-> cmd
                    (vim.system {:text true
                                 :stdin stdin})
                    (: :wait)))

  (if (= result.code 0)
    (result.stdout:gsub "\n$" "")
    (error result.stderr)))

(fn M.show [path]
  "Show existing password"
  (run {:cmd [:pass :show path]}))

(fn M.save-content [path content]
  "Insert or update a password"
  (run {:cmd [:pass :insert :-m :-f path]
        :stdin content}))

(fn M.mv [old-name new-name]
  "Renames or moves old-path to new-path"
  (run {:cmd [:pass :mv old-name new-name]}))

(fn M.rm [path]
  "Remove existing password or directory"
  (run {:cmd [:pass :rm :-f path]}))

(fn M.disable-backup-options []
  "Disables the neovim options that could leak the password into a text file"
  (set vim.opt_local.backup false)
  (set vim.opt_local.writebackup false)
  (set vim.opt_local.swapfile false)
  (set vim.opt_local.shada "")
  (set vim.opt_local.undofile false)
  (set vim.opt_local.shelltemp false)
  (set vim.opt_local.history 0)
  (set vim.opt_local.modeline false))


(fn M.info [msg]
  (vim.notify msg vim.log.levels.INFO notification-chrome))

(fn M.error [msg]
  (vim.notify msg vim.log.levels.ERROR notification-chrome))

M
