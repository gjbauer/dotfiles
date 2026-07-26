vim.cmd([[
	source ~/.nvimrc
]])

local fzf = require('fzf-lua')

-- Open file finder (git files or files)
vim.keymap.set('n', '<leader>ff', fzf.files, { desc = 'Fzf files' })

-- Open live grep (search text across project)
vim.keymap.set('n', '<leader>fg', fzf.live_grep, { desc = 'Fzf live grep' })

-- Open buffers list
vim.keymap.set('n', '<leader>fb', fzf.buffers, { desc = 'Fzf buffers' })

