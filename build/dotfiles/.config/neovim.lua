-- Vim configuration converted from Vimscript to Lua

-- Turn on syntax highlighting
vim.cmd("syntax on")

-- Basic Vim options
-- vim.opt.nocompatible = true
vim.opt.shortmess:append("I")  -- Disable startup message
vim.opt.number = true          -- Show line numbers
vim.opt.relativenumber = true  -- Show relative line numbers
vim.opt.laststatus = 2         -- Always show status line
vim.opt.backspace = "indent,eol,start"  -- Backspace behavior
vim.opt.hidden = true          -- Allow hidden buffers with unsaved changes
vim.opt.ignorecase = true      -- Case insensitive search
vim.opt.smartcase = true       -- Case sensitive when uppercase present
vim.opt.incsearch = true       -- Search as you type
-- vim.opt.noerrorbells = true    -- Disable error bells
vim.opt.visualbell = true       -- Use visual bell
-- vim.opt.t_vb = ""              -- Disable terminal bell
vim.opt.mouse = "a"            -- Enable mouse support
vim.opt.shiftwidth = 4         -- Indentation width
vim.opt.tabstop = 4            -- Tab width
vim.opt.timeoutlen = 200       -- Timeout length for mappings

-- Key mappings
-- Unbind Q (enters Ex mode)
vim.keymap.set('n', 'Q', '<Nop>', { noremap = true })

-- Disable arrow keys in normal mode with messages
vim.keymap.set('n', '<Left>', ':echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('n', '<Right>', ':echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('n', '<Up>', ':echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('n', '<Down>', ':echoe "Use j"<CR>', { noremap = true })

-- Disable arrow keys in insert mode with messages
vim.keymap.set('i', '<Left>', '<ESC>:echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('i', '<Right>', '<ESC>:echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('i', '<Up>', '<ESC>:echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('i', '<Down>', '<ESC>:echoe "Use j"<CR>', { noremap = true })

-- Copy to clipboard in visual mode
vim.keymap.set('v', '<C-C>', '"*y', { noremap = true })

-- Paste from clipboard in insert mode
vim.keymap.set('i', '<C-V>', '<ESC>"*p', { noremap = true })

-- Map jk to <Esc> in insert mode
vim.keymap.set('i', 'jk', '<Esc>', { noremap = true })
