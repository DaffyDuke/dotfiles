return {
  {
    "ravitemer/mcphub.nvim",
    cmd = "MCPHub",
    build = "npm install -g mcp-hub@latest",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("mcphub").setup()
    end,
  },
}
