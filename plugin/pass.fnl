(local pass (require :pass))
(local utils (require :pass.utils))

(local subcmds [:copy :edit :insert :delete :rename :log])

(fn complete [arg-lead cmd-line cursor-pos]
  (local args (vim.split cmd-line " "))
  (local n (length args))

  (if (= n 2)
      (icollect [_ v (ipairs subcmds)]
         (if (vim.startswith v arg-lead)
           v))
      (do
        (local cmd (. args 2))
        (when (and (not= cmd :log)
                   (vim.list_contains subcmds cmd))
          (local passwords (utils.list-passwords))
          (icollect [_ v (ipairs passwords)]
            (if (vim.startswith v.text arg-lead)
                v.text))))))
(fn tail [arr]
  (local elems (vim.tbl_extend :keep arr []))
  (table.remove elems 1)
  elems)

(fn command-handler [{: args : fargs}]
  (local cmd (. fargs 1))
  (local path (table.concat (tail fargs) " "))

  (when (not (utils.verify-gpg-auth))
    (utils.debug "GPG key locked. Attempting to unlock...")
    (when (not (utils.unlock-gpg-key))
      (utils.error "Failed to unlock GPG key.")
      (lua :return)))

  (case cmd
    :copy (pass.copy {:text path})
    :edit (pass.edit nil {:text path})
    :insert (if (= path "")
              (pass.insert {:finder {:filter {:pattern path}}})
              (pass.edit nil {:text path}))
    :delete (pass.delete nil {:text path})
    :rename (pass.rename nil {:text path})
    :log (pass.log)
    _ (pass.open args)))

(vim.api.nvim_create_user_command :Pass command-handler {:nargs :*
                                                         : complete})
