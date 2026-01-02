# pass.nvim

A neovim [snacks] picker for [pass], the standard unix password manager.

## Installation

Install with your favorite package manager. For example, using [lazy.nvim]:

```lua
{
  "davidmh/pass.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = "Pass",
}
```

## Usage

Run the command `:Pass` to open the password picker.

While in the picker, the following mappings are available:

| Key     | Action                      |
| ---     | ---                         |
| `<CR>`  | Copy password to clipboard  |
| `<C-e>` | Edit entry                  |
| `<C-r>` | Rename entry                |
| `<C-d>` | Delete entry                |
| `<C-l>` | Show password store git log |

## Requirements & Caveats

This plugin assumes a standard GPG setup:

1.  **GPG Agent**: `gpg-agent` must be running and configured. The plugin
    checks for unlocked keys by querying the agent.
2.  **Pinentry**: If your GPG key is locked, the plugin will attempt to trigger
    a system-level pinentry prompt. Ensure you have a `pinentry` program
    configured (e.g., `pinentry-curses`, `pinentry-mac`, `pinentry-gnome3`) so that
    GPG can prompt you outside of the neovim process.
3.  **GPG 2.x**: The commands used (`gpg-connect-agent`, `gpg --with-colons`)
    assume a modern GPG 2.x installation.

[snacks]: https://github.com/folke/snacks.nvim
[pass]: https://www.passwordstore.org/
[lazy.nvim]: https://github.com/folke/lazy.nvim
