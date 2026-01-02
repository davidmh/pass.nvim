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

| Key     | Action                      |
| ---     | ---                         |
| `<CR>`  | Copy password to clipboard  |
| `<C-e>` | Edit entry                  |
| `<C-r>` | Rename entry                |
| `<C-d>` | Delete entry                |
| `<C-l>` | Show password store git log |

[snacks]: https://github.com/folke/snacks.nvim
[pass]: https://www.passwordstore.org/
[lazy.nvim]: https://github.com/folke/lazy.nvim
