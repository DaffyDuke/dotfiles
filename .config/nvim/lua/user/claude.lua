-- Mapping Neovim : Claude sur sélection visuelle
-- Place ce fichier dans ~/.config/nvim/lua/user/claude.lua

vim.keymap.set('v', '<leader>c', function()
  -- Sauve la sélection dans un fichier temporaire
  local tmpfile = os.tmpname()
  vim.cmd('write! ' .. tmpfile)
  -- Demande un prompt à l'utilisateur
  local prompt = vim.fn.input('Prompt Claude: ', 'Peux-tu expliquer ce code ?')
  -- Appelle le script shell et récupère la réponse
  local handle = io.popen('cat ' .. tmpfile .. ' | nvim-claude "' .. prompt .. '"')
  local result = handle:read('*a')
  handle:close()
  -- Ouvre un nouveau buffer pour la réponse
  vim.cmd('new')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result, '\n'))
end, { desc = 'Claude: prompt sur sélection', noremap = true, silent = true })
