(fn open-picker []
  (local pass (require :pass))
  (pass.open))

(vim.api.nvim_create_user_command :Pass open-picker {:nargs 0})
