(fn open-picker [{: args}]
  (local pass (require :pass))
  (pass.open args))

(vim.api.nvim_create_user_command :Pass open-picker {:nargs :?})
