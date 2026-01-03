(local M {})

(local notification-chrome {:icon :🛂
                            :title :pass.nvim})

(fn read-lines [path]
  (if (= (vim.fn.filereadable path) 1)
    (vim.fn.readfile path)
    []))

(fn get-gpg-ids []
  (local store-dir (M.get-password-store-dir))
  (read-lines (.. store-dir ".gpg-id")))

(fn get-keygrips [gpg-id]
  (let [result (-> [:gpg :--list-secret-keys :--with-colons gpg-id]
                   (vim.system {:text true})
                   (: :wait))]
    (if (= result.code 0)
      (let [grips []]
        (each [line (result.stdout:gmatch "[^\r\n]+")]
          (when (line:match "^grp:")
            (let [fields (vim.split line ":")]
              (table.insert grips (. fields 10)))))
        grips)
      [])))

(fn is-cached? [keygrip]
  "Query the agent for the key's status. The 7th field in the response
  indicates if the key is currently cached in memory (1) or not."

  ;; Connect using the given key grip and exit immediately
  (local result (-> [:gpg-connect-agent (.. "KEYINFO " keygrip) "/bye"]
                    (vim.system {:text true})
                    (: :wait)))
  (when (= result.code 0)
    (local lines (-> result.stdout
                     (vim.trim)
                     (vim.split "\n")))
    (each [_ line (ipairs lines)]
      (case (vim.split line " ")
        ["S" "KEYINFO" _ _ _ _ "1"] (lua "return true"))))
  false)

(fn M.verify-gpg-auth []
  "Checks if at least one GPG key required for the store is unlocked."
  (local ids (get-gpg-ids))

  (if (vim.tbl_isempty ids)
    true
    (each [_ id (ipairs ids)]
      (local grips (get-keygrips id))
      (each [_ grip (ipairs grips)]
        (when (is-cached? grip)
          (lua "return true")))))
  false)

(fn M.unlock-gpg-key []
  "Triggers a dummy signing to prompt for the GPG password via pinentry."
  (local ids (get-gpg-ids))
  (if (vim.tbl_isempty ids)
      false
      (let [key-id (vim.trim (. ids 1))
            result (-> [:gpg :--clearsign :--quiet :--no-tty :--default-key key-id]
                       (vim.system {:text true
                                    :stdin "unlock check"})
                       (: :wait))]
         (= result.code 0))))

(fn M.get-password-store-dir []
  (let [dir (or vim.env.PASSWORD_STORE_DIR
                (.. vim.env.HOME "/.password-store/"))]
    (if (= (dir:sub -1) "/")
      dir
      (.. dir "/"))))

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

(fn M.debug [msg]
  (when vim.g.pass_debug
    (vim.notify msg vim.log.levels.ERROR notification-chrome)))

(fn M.prompt-bool [question action]
  (vim.ui.select [:Yes :No]
                 {:prompt question}
                 action))

M
