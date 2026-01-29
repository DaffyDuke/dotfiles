return {
  {
    "ravitemer/mcphub.nvim", -- Ajout du .nvim ici
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Ce plugin nécessite souvent une étape de build pour installer le serveur node
    build = "npm install -g mcp-hub@latest",
    config = function()
      require("mcphub").setup()
    end,
  },
}
